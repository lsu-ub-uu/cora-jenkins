#!/bin/bash
NAME=$1
NAMESPACE="$NAME-preview"

echo ""
echo "Uninstalling Helm release '$NAMESPACE' from namespace '$NAMESPACE'..."
helm uninstall $NAMESPACE -n $NAMESPACE

echo ""
echo "Deleting secret..."
kubectl delete secret ${NAME}-secret --namespace=$NAMESPACE

echo ""
echo "Deleting Kubernetes namespace '$NAMESPACE'..."
kubectl delete namespace $NAMESPACE

echo ""
echo "Deleting persistent volumes for '$NAMESPACE'..."
kubectl get pv -o name | grep "^persistentvolume/${NAMESPACE}" | xargs -r kubectl delete


echo ""
echo "Removing local persistent data from /mnt/minikube/$NAME/preview..."
minikube ssh -- "sudo rm -rf /mnt/minikube/$NAME/preview"

echo ""
echo "Creating namespace '$NAMESPACE'..."
cd helm
kubectl create namespace $NAMESPACE

echo ""
echo "Applying secret"
kubectl apply -f ${NAME}-secret.yaml --namespace=$NAMESPACE

echo ""
echo "Applying persistent volume definitions"
kubectl apply -f ${NAMESPACE}-minikube-persistent-volumes.yaml --namespace=$NAMESPACE

echo ""
echo "Applying configmap definitions"
kubectl apply -f ${NAME}-config-map.yaml --namespace=$NAMESPACE

echo ""
echo "Installing Helm chart '$NAME' as release '$NAMESPACE' with FitNesse enabled in namespace '$NAMESPACE'..."
helm repo update
helm install $NAMESPACE epc/$NAME --namespace $NAMESPACE -f ${NAMESPACE}-values.yaml

echo ""
echo "Waiting for all pods in '$NAMESPACE' namespace to become ready (timeout: 300s)..."
if ! kubectl wait -n "$NAMESPACE" --for=condition=Available deploy --all --timeout=300s \
		&& kubectl wait -n "$NAMESPACE" --for=jsonpath='{.status.readyReplicas}'=1 statefulset --all --timeout=300s \
		&& kubectl wait -n "$NAMESPACE" --for=condition=complete job --all --timeout=300s; then
    echo "Timeout waiting for pods to become ready"
    exit 1
fi

echo "Deployment of $NAMESPACE completed successfully."