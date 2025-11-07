#! /bin/bash
CLUSTER_MIG_NAME=$1
CLUSTER_PRE_NAME=$2
$POSTGRESQL_DOCKER_NAME_MIG="alvin-postgresql-deployment-0"
$POSTGRESQL_DOCKER_NAME_PRE="alvin-postgresql-deployment-0"

start(){
	cd helm
	getKubeConfigsForMigAndPre
	exportAlvinDataFromMig
	importAlvinDataToPre
	restartAndReindexPre
}

getKubeConfigsForMigAndPre() {
	curl http://test.ub.uu.se:8000/v1/config/$CLUSTER_MIG_NAME > migKubeConfig
	curl http://test.ub.uu.se:8000/v1/config/$CLUSTER_PRE_NAME > preKubeConfig
}

exportAlvinDataFromMig() {
	kubectl --kubeconfig migKubeConfig -n alvin exec  -i $POSTGRESQL_DOCKER_NAME_MIG bash < runInsideDocker.sh
	kubectl --kubeconfig migKubeConfig -n alvin cp $POSTGRESQL_DOCKER_NAME_MIG:/dbfiles/alvinData ./dbfiles
}

importAlvinDataToPre() {
	kubectl --kubeconfig preKubeConfig -n alvin cp ./dbfiles $POSTGRESQL_DOCKER_NAME_PRE:/dbfiles/
	kubectl --kubeconfig preKubeConfig -n alvin exec -it $POSTGRESQL_DOCKER_NAME_PRE -- bash -c 'DATA_DIVIDERS="alvinData" ./docker-entrypoint-initdb.d/10importDb.sh'
}

restartAndReindexPre(){
	kubectl --kubeconfig preKubeConfig -n alvin rollout restart deployment
	. alvin-pre-indexMetadata.sh
}

start