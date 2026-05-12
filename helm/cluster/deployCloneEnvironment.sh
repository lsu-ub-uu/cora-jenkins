#!/bin/bash
APPLICATION=$1
ENVIRONMENT=$2
[ -z "$APPLICATION" ] && exit 1
[ -z "$ENVIRONMENT" ] && exit 2

start(){
  importDependencies
  confirmContinue
  ifNamespaceExistsDeleteNamespaceAndStorage
  cloneNamespaceFromProd
}

importDependencies(){
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  namespace="${APPLICATION}-${ENVIRONMENT}"
  namespacePROD="${APPLICATION}-prod"
}


confirmContinue(){
  echo "KUBECONFIG=${KUBECONFIG:-<not set>}"
  echo -n "kubectl context: "
  kubectl config current-context 2>/dev/null || echo "<unknown>"

  echo
  echo "About to:"
  echo "  - delete namespace: ${namespace}"
  echo "  - delete storage (manageRBD): ${namespacePROD} -> ${namespace}"
  echo "  - clone storage (manageRBD):  ${namespacePROD} -> ${namespace}"
  echo

  read -r -p "Check if the kubeconfig context is correct. Do you want to continue? (y/N): " answer
  case "$answer" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
}

ifNamespaceExistsDeleteNamespaceAndStorage(){
  if kubectl get namespace "$namespace" >/dev/null 2>&1; then
    deleteNamespace
    deleteStorage
  else
    echo "-> Namespace does not exist: $namespace (nothing to delete)"
  fi
}

deleteNamespace(){
  echo "-> Deleting existing namespace: $namespace"
  kubectl delete namespace "$namespace"
}

deleteStorage(){
  echo "-> Deleting existing for $namespace"
  "${SCRIPT_DIR}/manageRBD.sh" del "$namespacePROD" "$namespace"
}

cloneNamespaceFromProd(){
  echo "-> Cloning from $namespacePROD to $namespace..."
  "${SCRIPT_DIR}/manageRBD.sh" clone "$namespacePROD" "$namespace"
}

start