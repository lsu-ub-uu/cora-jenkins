#!/bin/bash
set -euo pipefail

start(){
	setEnvironmentVariables "$@"
	readKubeconfigForProdCluster
	validateChartVersionExists
#	uninstallPreviousVersion
	installApplication
	waitUntilAllPodsAreRunning
}

setEnvironmentVariables(){
	APPLICATION_NAME="$1"
	ENVIRONMENT="$2"
	HELM_CHART_VERSION="$3"

	NAMESPACE="${APPLICATION_NAME}-${ENVIRONMENT}"
	HELM_REPO_NAME="epc"
	HELM_REPO_URL="https://helm.epc.ub.uu.se/"
	KUBECONFIG_PATH="${KUBECONFIG:-kubeconfig}"
	SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
	MANIFESTS_FOLDER="${SCRIPT_DIR}/application/${NAMESPACE}"
}


readKubeconfigForProdCluster(){
	if [ -f "$KUBECONFIG_PATH" ]; then
		echo "Using existing kubeconfig at $KUBECONFIG_PATH"
		return
	fi

	echo "Downloading kubeconfig to $KUBECONFIG_PATH"
	curl -fsSL http://test.ub.uu.se:8000/v1/config/prod -o "$KUBECONFIG_PATH"
}

ensureHelmRepoExists(){
	local existing_url
	existing_url="$(helm_cmd repo list 2>/dev/null | awk -v repo="$HELM_REPO_NAME" '$1 == repo {print $2}')"

	if [ -z "$existing_url" ]; then
		helm_cmd repo add "$HELM_REPO_NAME" "$HELM_REPO_URL"
	elif [ "$existing_url" != "$HELM_REPO_URL" ]; then
		echo "Error: repo '$HELM_REPO_NAME' exists with URL '$existing_url', expected '$HELM_REPO_URL'" >&2
		exit 1
	fi
}

kubectl_cmd(){
	kubectl --kubeconfig "$KUBECONFIG_PATH" "$@"
}

helm_cmd(){
	helm --kubeconfig "$KUBECONFIG_PATH" "$@"
}

validateChartVersionExists() {
	echo "Validating chart '$HELM_REPO_NAME/$APPLICATION_NAME' version '$HELM_CHART_VERSION' exists..."

	ensureHelmRepoExists
	helm_cmd repo update >/dev/null

	# helm search output columns: NAME  CHART VERSION  APP VERSION  DESCRIPTION
	if helm_cmd search repo "$HELM_REPO_NAME/$APPLICATION_NAME" --versions \
		| awk 'NR>1 {print $2}' \
		| grep -Fxq "$HELM_CHART_VERSION"; then
		echo "Chart version '$HELM_CHART_VERSION' found."
		return
	fi

	echo "Error: chart '$HELM_REPO_NAME/$APPLICATION_NAME' version '$HELM_CHART_VERSION' not found. Aborting — current deployment is untouched." >&2
	exit 1
}

#uninstallPreviousVersion(){
#	echo "Uninstalling previous release '$NAMESPACE' from namespace '$NAMESPACE'..."
#
#	helm_cmd uninstall "$NAMESPACE" --namespace "$NAMESPACE" || true
#	kubectl_cmd delete secret binaryconverter-secret --namespace="$NAMESPACE" || true
#	kubectl_cmd delete pvc "$APPLICATION_NAME-postgres-volume-claim" -n "$NAMESPACE" || true
#	kubectl_cmd delete pvc "$APPLICATION_NAME-archive-read-write-volume-claim" -n "$NAMESPACE" || true
#	kubectl_cmd delete pvc "$APPLICATION_NAME-converted-files-read-write-volume-claim" -n "$NAMESPACE" || true
#}

#ifNamespaceExistsDeleteNamespaceAndStorage(){
#  if kubectl get namespace "$namespace" >/dev/null 2>&1; then
#    deleteNamespace
#    deleteStorage
#  else
#    echo "-> Namespace does not exist: $namespace (nothing to delete)"
#  fi
#}
#
#deleteNamespace(){
#  echo "-> Deleting existing namespace: $namespace"
#  kubectl delete namespace "$namespace"
#}
#
#deleteStorage(){
#  echo "-> Deleting existing for $namespace"
#  "${SCRIPT_DIR}/manageRBD.sh" del "$namespacePROD" "$namespace"
#}
#
#cloneNamespaceFromProd(){
#  echo "-> Cloning from $namespacePROD to $namespace..."
#  "${SCRIPT_DIR}/manageRBD.sh" clone "$namespacePROD" "$namespace"
#}


installApplication(){
	echo "Installing helm chart '$APPLICATION_NAME' as release '$NAMESPACE' in namespace '$NAMESPACE'..."

	#kubectl_cmd create namespace "$NAMESPACE" || true
	applyingManifests

	helm_cmd install "$NAMESPACE" "$HELM_REPO_NAME/$APPLICATION_NAME" \
		--namespace "$NAMESPACE" \
		--version "$HELM_CHART_VERSION" \
		-f "${MANIFESTS_FOLDER}/values.yaml"
}

applyingManifests(){
	MANIFESTS_FOLDER="${SCRIPT_DIR}/application/${NAMESPACE}"

	if [ ! -d "$MANIFESTS_FOLDER" ]; then
		echo "Error: folder '$MANIFESTS_FOLDER' does not exist." >&2
		exit 1
	fi

	echo "Applying all YAML files in '$MANIFESTS_FOLDER'..."

	for file in "$MANIFESTS_FOLDER"/*.yaml; do
		[ -f "$file" ] || continue
		
		case "$(basename "$file")" in
			values.yaml)
				echo "Skipping $file"
				continue
				;;
		esac
		
		echo "Applying $file..."
		kubectl_cmd apply -f "$file" --namespace="$NAMESPACE"
	done
	
}

waitUntilAllPodsAreRunning(){
	echo "Waiting for all pods in '$NAMESPACE' to become ready (timeout: 300s)..."

	if ! kubectl_cmd wait --for=condition=Ready pod --all --namespace="$NAMESPACE" --timeout=300s; then
		echo "Error: timeout waiting for pods to become ready." >&2
		exit 1
	fi

	echo "Deployment of '$NAMESPACE' completed successfully."
}

start "$@"