#!/bin/bash
CLUSTER_NAME=$1
NAMESPACE=$2
APPPLICATION_NAME=$3
#NAMESPACE="$APPPLICATION_NAME"

cd helm
curl http://test.ub.uu.se:8000/v1/config/$CLUSTER_NAME > kubeconfig
#
#echo ""
#echo "Applying secret"
#kubectl --kubeconfig kubeconfig apply -f ${APPPLICATION_NAME}-secret.yaml --namespace=$NAMESPACE
#
#echo ""
#echo "Applying persistent volume definitions"
#kubectl --kubeconfig kubeconfig apply -f ${NAMESPACE}-minikube-persistent-volumes.yaml --namespace=$NAMESPACE

echo ""
echo "Updating helm chart '$APPPLICATION_NAME' as release '$NAMESPACE' in namespace '$NAMESPACE'..."
helm --kubeconfig kubeconfig repo update
helm --kubeconfig kubeconfig uninstall $NAMESPACE --namespace $NAMESPACE

kubectl  --kubeconfig kubeconfig  delete pvc $APPPLICATION_NAME-postgres-volume-claim -n $NAMESPACE
kubectl  --kubeconfig kubeconfig  delete pvc $APPPLICATION_NAME-archive-read-write-volume-claim -n $NAMESPACE
kubectl  --kubeconfig kubeconfig  delete pvc $APPPLICATION_NAME-credentials-read-write-volume-claim -n $NAMESPACE
kubectl  --kubeconfig kubeconfig  delete pvc $APPPLICATION_NAME-postgres-volume-claim -n $NAMESPACE
kubectl  --kubeconfig kubeconfig  delete pvc $APPPLICATION_NAME-converted-files-read-write-volume-claim -n $NAMESPACE

kubectl --kubeconfig kubeconfig apply -f ${NAMESPACE}-$CLUSTER_NAME-persistent-volume-claims.yaml -n $NAMESPACE

helm --kubeconfig kubeconfig install $NAMESPACE epc/$APPPLICATION_NAME --namespace $NAMESPACE -f ${NAMESPACE}-${CLUSTER_NAME}-values.yaml

echo ""
echo "Waiting for all pods in '$NAMESPACE' namespace to become ready (timeout: 300s)..."
if ! kubectl --kubeconfig kubeconfig wait --for=condition=Ready pod --all --namespace=$NAMESPACE --timeout=300s; then
    echo "Timeout waiting for pods to become ready"
    exit 1
fi

echo "Deployment of $NAMESPACE completed successfully on cluster $CLUSTER_NAME."