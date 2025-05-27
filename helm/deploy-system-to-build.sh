#!/bin/bash
NAME=$1
NAMESPACE="$NAME-build"

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
echo "Removing local persistent data from /mnt/minikube/$NAME/build..."
minikube ssh -- "sudo rm -rf /mnt/minikube/$NAME/build"

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
echo "TEMPORARY STEP BEFORE RELEASED CHARTS"
echo "setting upp $NAME chart"
helm dependency build cora/
helm dependency update $NAME/
echo "END TEMPORARY STEP BEFORE RELEASED CHARTS"

echo ""
echo "Installing Helm chart '$NAME' as release '$NAMESPACE' in namespace '$NAMESPACE'..."
helm install $NAMESPACE $NAME --namespace $NAMESPACE -f ../jenkins/${NAMESPACE}-values.yaml

echo ""
echo "Waiting for all pods in '$NAMESPACE' namespace to become ready (timeout: 300s)..."
kubectl wait --for=condition=Ready pod --all --namespace=$NAMESPACE --timeout=300s

echo "Deployment of $NAMESPACE completed successfully."