#!/bin/bash

OP=$1
SRC_NS=$2
DST_NS=$3
[ -z "$OP" ] && exit 1
[ -z "$SRC_NS" ] && exit 2
[ -z "$DST_NS" ] && exit 3

SNP_CLASS=csi-rbdplugin-snapclass
FLAVOR=`helm -n ${SRC_NS} list -o json | jq -r '.[].name' | sed -n 's/-.*//p'`
GATEWAY=`kubectl -n ${SRC_NS} get httproute -o json | jq -r '.items[0].spec.parentRefs[0].name'`
NFS_EXPORTS=nfs-exports
declare -A VOLUMES
declare -A SIZES
declare -A SOURCES
declare -A CLASSES


function run_helm() {
    pushd cora-deployment/helm
    helm dependency build cora/
    helm dependency update ${FLAVOR}/
    kubectl apply -f ${FLAVOR}-secret.yaml --namespace=${DST_NS}
    kubectl apply -f ${FLAVOR}-config-map.yaml --namespace=${DST_NS}
    helm upgrade --install ${DST_NS} ${FLAVOR} --namespace ${DST_NS} -f ../../values.yaml
    popd
}

function http_route() {
    # extract domain name
    HOSTNAME=`cat values.yaml | sed -n 's!^.*systemUrl.*//!!p'`

    # install HTTP route
    cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: ${FLAVOR}-http
  namespace: ${DST_NS}
spec:
  hostnames:
  - ${HOSTNAME}
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: ${GATEWAY}
    namespace: envoy-gateway
    sectionName: http
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: apache
      port: 80
      weight: 1
    matches:
    - path:
        type: PathPrefix
        value: /.well-known/acme-challenge/
  - filters:
    - requestRedirect:
        scheme: https
        statusCode: 302
      type: RequestRedirect
    matches:
    - path:
        type: PathPrefix
        value: /
EOF

    # install HTTPS route
    cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: ${FLAVOR}-https
  namespace: ${DST_NS}
spec:
  hostnames:
  - ${HOSTNAME}
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: ${GATEWAY}
    namespace: envoy-gateway
    sectionName: https
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: apache
      port: 80
      weight: 1
    matches:
    - path:
        type: PathPrefix
        value: /
    timeouts:
      request: 0s
EOF
}


function ensure_ns() {
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
    name: $DST_NS
EOF
}


function register_volumes() {
    for SRC_PVC in `kubectl -n ${SRC_NS} get pvc -o json | jq -r '.items[].metadata.name'`; do {
        UUID=`uuidgen`
        NAME=uub-${UUID}
        VOLUMES[${NAME}]=${SRC_PVC}
        SOURCES[${NAME}]=`kubectl -n ${SRC_NS} get pvc ${SRC_PVC} -o jsonpath='{.spec.volumeName}'`
        CLASSES[${NAME}]=`kubectl -n ${NFS_EXPORTS} get pvc ${SOURCES[${NAME}]} -o jsonpath='{.spec.storageClassName}'`
        SIZES[${NAME}]=`kubectl -n ${NFS_EXPORTS} get pvc ${SOURCES[${NAME}]} -o jsonpath='{.spec.resources.requests.storage}'`
    } done
}


function create_snapshots() {
    for NAME in ${!VOLUMES[@]}; do {
        cat <<EOF
---
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: ${NAME}
  namespace: ${NFS_EXPORTS}
  labels:
    target: "${DST_NS}"
spec:
  volumeSnapshotClassName: ${SNP_CLASS}
  source:
    persistentVolumeClaimName: ${SOURCES[${NAME}]}
EOF
    } done
}


function wait_for_snapshots() {
    for NAME in ${!VOLUMES[@]}; do {
        kubectl -n ${NFS_EXPORTS} wait \
            --for=jsonpath='{.status.readyToUse}'=true \
            volumesnapshot ${NAME} --timeout=10m
    } done
}


function create_pvc() {
    for NAME in ${!VOLUMES[@]}; do {

        cat <<EOF
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${NAME}
  namespace: ${NFS_EXPORTS}
  annotations:
    namespace.nfs.uub: "${DST_NS}"
    pvc.nfs.uub: "${VOLUMES[${NAME}]}"
  labels:
    target: "${DST_NS}"
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ${CLASSES[${NAME}]}
  resources:
    requests:
      storage: ${SIZES[${NAME}]}
EOF

      [ "$OP" = "clone" ] || continue
      cat <<EOF
  dataSourceRef:
    name: ${NAME}
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
EOF
    } done
}


function create_nfs_config() {
    #8<-----------------------------------------------------------
    cat <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: nfs-${DST_NS}
  namespace: ${NFS_EXPORTS}
data:
  ganesha.conf: |
    NFS_CORE_PARAM {
        Protocols = 4;
        Enable_UDP = false;
        Allow_Set_Io_Flusher_Fail = true;
        Nb_Worker = 128;
    }
    NFSV4 {
        Only_Numeric_Owners = true;
    }
    CacheInode {
        Attr_Expiration_Time = 60;
        Dir_Expiration_Time = 60;
        Cache_FDs = true;
    }
EOF
    #8<-----------------------------------------------------------
    EXPORT_ID=10
    for PVC_NAME in ${!VOLUMES[@]}; do {
        EXPORT_ID=$(( EXPORT_ID + 1 ))
        cat <<EOF
    EXPORT {
      Export_Id = $EXPORT_ID;
      Path = /${PVC_NAME};
      Pseudo = /${PVC_NAME};
      FSAL {
        Name = VFS;
        cache_fd = true;
      }
      Sync = false;
      SecType = sys;
      CLIENT {
        Clients = 10.244.0.0/16;
        Access_Type = RW;
        Squash = No_Root_Squash;
      }
    }
EOF
    } done
}


function create_nfs_exporter() {

    #8<-----------------------------------------------------------
    cat <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nfs-${DST_NS}
  namespace: ${NFS_EXPORTS}
spec:
  selector:
    matchLabels:
      app: nfs-${DST_NS}
  serviceName: nfs-${DST_NS}
  replicas: 1
  template:
    metadata:
      labels:
        app: nfs-${DST_NS}
    spec:
      containers:
      - name: nfs-${DST_NS}
        image: ghcr.io/svinota/nfs-exports:0.1
        securityContext:
          privileged: true
        ports:
        - containerPort: 2049
          name: nfs
          protocol: TCP
        volumeMounts:
        - name: exports
          mountPath: /etc/ganesha
          readOnly: true
EOF

    #8<-----------------------------------------------------------
    for PVC_NAME in ${!VOLUMES[@]}; do {
        cat <<EOF
        - name: ${PVC_NAME}
          mountPath: /${PVC_NAME}
EOF
    } done

    #8<-----------------------------------------------------------
    cat <<EOF
      volumes:
      - name: exports
        configMap:
          name: nfs-${DST_NS}
EOF
    
    #8<-----------------------------------------------------------
    for PVC_NAME in ${!VOLUMES[@]}; do {
        cat <<EOF
      - name: ${PVC_NAME}
        persistentVolumeClaim:
          claimName: ${PVC_NAME}
EOF
    } done
}


function create_nfs_service() {
    cat <<EOF
apiVersion: v1
kind: Service
metadata:
  name: nfs-${DST_NS}
  namespace: ${NFS_EXPORTS}
spec:
  selector:
    app: nfs-${DST_NS}
  ports:
  - name: nfs
    port: 2049
    targetPort: 2049
    protocol: TCP
  type: ClusterIP
EOF
}


function create_nfs() {
    register_volumes
    [ "$OP" = "clone" ] && {
		echo "Create snapshots..."
		create_snapshots | kubectl create -f -
		echo "Wait for snapshots to be ready..."
        wait_for_snapshots
    } ||:
    create_pvc | kubectl create -f -
    create_nfs_config | kubectl create -f -
    create_nfs_exporter | kubectl create -f -
    create_nfs_service | kubectl create -f -
}


function create_app_pv() {
    for NAME in ${!VOLUMES[@]}; do {
        cat <<EOF
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${NAME}
  labels:
    target: ${DST_NS}
spec:
  capacity:
    storage: ${SIZES[${NAME}]}
  accessModes: ["ReadWriteMany"]
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Filesystem
  csi:
    driver: nfs.csi.k8s.io
    volumeHandle: ${NAME}
    volumeAttributes:
      server: nfs-${DST_NS}.nfs-exports.svc.cluster.local
      share: /${NAME}
      mountOptions: "actimeo=60,lookupcache=positive,nocto,noatime,nodiratime"
EOF
    } done
}


function create_app_pvc() {
    for NAME in ${!VOLUMES[@]}; do {
        cat <<EOF
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${VOLUMES[${NAME}]}
  namespace: ${DST_NS}
  labels:
    target: ${DST_NS}
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: ${SIZES[${NAME}]}
  volumeName: ${NAME}
  volumeMode: Filesystem
  storageClassName: ""
EOF
    } done
}


function create_debug_workload() {
    cat <<EOF
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nfs-debug
  namespace: ${DST_NS}
spec:
  selector:
    matchLabels:
      app: nfs-debug
  serviceName: nfs-debug
  replicas: 1
  template:
    metadata:
      labels:
        app: nfs-debug
    spec:
      containers:
      - name: nfs-debug
        image: alpine:latest
        command: ["sleep", "inf"]
        volumeMounts:
EOF
    for NAME in ${!VOLUMES[@]}; do {
        cat <<EOF
        - mountPath: /${VOLUMES[${NAME}]}
          name: ${VOLUMES[${NAME}]}
EOF
    } done
    cat <<EOF
      volumes:
EOF
    for NAME in ${!VOLUMES[@]}; do {
        cat <<EOF
      - name: ${VOLUMES[${NAME}]}
        persistentVolumeClaim:
          claimName: ${VOLUMES[${NAME}]}
EOF
    } done
}


function create_app_volumes() {
    create_app_pv | kubectl create -f -
    create_app_pvc | kubectl create -f -
    create_debug_workload | kubectl create -f -
}


function cleanup_nfs() {
    kubectl -n ${NFS_EXPORTS} delete service nfs-${DST_NS}
    kubectl -n ${NFS_EXPORTS} delete statefulset nfs-${DST_NS}
    kubectl -n ${NFS_EXPORTS} delete configmap nfs-${DST_NS}
    kubectl -n ${NFS_EXPORTS} delete pvc -l target=${DST_NS}
    kubectl -n ${NFS_EXPORTS} delete volumesnapshot -l target=${DST_NS}
}

function cleanup_app_volumes() {
    kubectl -n ${DST_NS} delete statefulset nfs-debug
    kubectl -n ${DST_NS} delete pvc -l target=${DST_NS}
    kubectl delete pv -l target=${DST_NS}
}
# 
#
case ${OP} in
    add|clone)
        # look if NFS exporter is running for this DST_NS
        [ `kubectl -n ${NFS_EXPORTS} get statefulsets | grep ${DST_NS} | wc -l` -eq 0 ] || {
        	echo "statefulsets already exist"; exit 4
		}
        [ `kubectl -n ${NFS_EXPORTS} get configmaps | grep ${DST_NS} | wc -l` -eq 0 ] || {
        	echo "configmaps already exist"; exit 5
		}
        ensure_ns
        # 1. create
        # 1.1. create the NFS level from clones
        create_nfs
        # 1.2. use existing NFS level
        create_app_volumes
        ;;
    del)
        #
        # 2. cleanup
        # 2.1. remove the APP namespace
        cleanup_app_volumes
        # 2.2. remove the NFS level
        cleanup_nfs
        ;;
esac
