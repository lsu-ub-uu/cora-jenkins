#!/bin/bash
NAME=$1
CLUSTER_NAME=$2
NAMESPACE="$NAME-$CLUSTER_NAME"

#Cleaning cluster before each re-deployment
echo ""
echo "Uninstalling helm ./kubeconfig release '$NAMESPACE' from namespace '$NAMESPACE'..."
helm ./kubeconfig uninstall $NAMESPACE -n $NAMESPACE

echo ""
echo "Deleting secret..."
kubectl ./kubeconfig delete secret ${NAME}-secret --namespace=$NAMESPACE
#
#echo ""
#echo "Deleting Kubernetes namespace '$NAMESPACE'..."
#kubectl ./kubeconfig delete namespace $NAMESPACE
#
#echo ""
#echo "Deleting persistent volumes for '$NAMESPACE'..."
#kubectl ./kubeconfig delete pv ${NAMESPACE}-postgres-volume
#kubectl ./kubeconfig delete pv ${NAMESPACE}-archive-volume
#kubectl ./kubeconfig delete pv ${NAMESPACE}-archive-read-only-volume
#kubectl ./kubeconfig delete pv ${NAMESPACE}-converted-files-volume
#kubectl ./kubeconfig delete pv ${NAMESPACE}-converted-files-read-only-volume
#kubectl ./kubeconfig delete pv ${NAME}-previewepc-credentials-read-only-volume
#
#echo ""
#echo "Removing local persistent data from /mnt/minikube/$NAME/$CLUSTER_NAME..."
#minikube ssh -- "sudo rm -rf /mnt/minikube/$NAME/$CLUSTER_NAME"

#Get kubeconfig. It expects the cluster is already created.
curl http://test.ub.uu.se:8000/v1/config/$CLUSTER_NAME >kubeconfig

echo ""
echo "Creating namespace '$NAMESPACE'..."
cd helm ./kubeconfig
kubectl ./kubeconfig create namespace $NAMESPACE

echo ""
echo "Applying secret"
kubectl ./kubeconfig apply -f ${NAME}-secret.yaml --namespace=$NAMESPACE

#echo ""
#echo "Applying persistent volume definitions"
#kubectl ./kubeconfig apply -f ${NAMESPACE}-minikube-persistent-volumes.yaml --namespace=$NAMESPACE

echo ""
echo "Installing helm ./kubeconfig chart '$NAME' as release '$NAMESPACE' with FitNesse enabled in namespace '$NAMESPACE'..."
helm ./kubeconfig repo update
helm ./kubeconfig install $NAMESPACE epc/$NAME --namespace $NAMESPACE -f ${NAMESPACE}-values.yaml

echo ""
echo "Waiting for all pods in '$NAMESPACE' namespace to become ready (timeout: 300s)..."
if ! kubectl ./kubeconfig wait --for=condition=Ready pod --all --namespace=$NAMESPACE --timeout=300s; then
    echo "Timeout waiting for pods to become ready"
    exit 1
fi

echo "Deployment of $NAMESPACE completed successfully on cluster $CLUSTER_NAME."