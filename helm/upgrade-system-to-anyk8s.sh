#!/bin/bash
start(){
	setEnvironmentVariables
	readKubeconfig
	unistallPreviousVersion
	applySecretsAndPersistentClaims
	installApplication
	waitUntilAllPodsAreRunning
}

setEnvironmentVariables(){
	CLUSTER_NAME=$1
	ENVIRONMENT=$2
	APPPLICATION_NAME=$3
	NAMESPACE=${APPPLICATION_NAME}-${ENVIRONMENT}
}

readKubeconfig(){
	curl http://test.ub.uu.se:8000/v1/config/$CLUSTER_NAME >kubeconfig
}

unistallPreviousVersion(){
	echo ""
	echo "Updating helm chart '$APPPLICATION_NAME' as release '$NAMESPACE' in namespace '$NAMESPACE'..."
	helm --kubeconfig kubeconfig repo update
	helm --kubeconfig kubeconfig uninstall $NAMESPACE --namespace $NAMESPACE
	
	kubectl --kubeconfig kubeconfig delete pvc $APPPLICATION_NAME-postgres-volume-claim -n $NAMESPACE
	kubectl --kubeconfig kubeconfig delete pvc $APPPLICATION_NAME-archive-read-write-volume-claim -n $NAMESPACE
	kubectl --kubeconfig kubeconfig delete pvc $APPPLICATION_NAME-credentials-read-write-volume-claim -n $NAMESPACE
	kubectl --kubeconfig kubeconfig delete pvc $APPPLICATION_NAME-converted-files-read-write-volume-claim -n $NAMESPACE
}

applySecretsAndPersistentClaims(){
	echo ""
	echo "Applying secret"
	kubectl --kubeconfig kubeconfig apply -f helm/${APPPLICATION_NAME}-secret.yaml --namespace=$NAMESPACE
	
	echo "Applying PVCs"
	kubectl --kubeconfig kubeconfig apply -f helm/${APPPLICATION_NAME}-${ENVIRONMENT}-persistent-volume-claims.yaml -n $NAMESPACE
}

installApplication(){
	echo ""
	echo "Installing helm chart '$APPPLICATION_NAME' as release '$NAMESPACE' in namespace '$NAMESPACE'..."
	helm --kubeconfig kubeconfig repo update
	helm --kubeconfig kubeconfig install $NAMESPACE epc/$APPPLICATION_NAME --namespace $NAMESPACE -f helm/${APPPLICATION_NAME}-${ENVIRONMENT}-values.yaml
}

waitUntilAllPodsAreRunning()
	echo ""
	echo "Waiting for all pods in '$NAMESPACE' namespace to become ready (timeout: 300s)..."
	if ! kubectl --kubeconfig kubeconfig wait --for=condition=Ready pod --all --namespace=$NAMESPACE --timeout=300s; then
	    echo "Timeout waiting for pods to become ready"
	    exit 1
	fi
	
	echo "Deployment of $NAMESPACE completed successfully on cluster $CLUSTER_NAME."
}

start