#! /bin/bash
ENVIRONMENT=$1

start(){
	setParameters "$ENVIRONMENT"
	killDockers
	removeDockers
	removeVolumes
	
	startRabbitMq
	startSolr
	startFedora
	startPostgresql
	startIIP
	
	sleepAndWait 20
	
	startBinaryConverters
	startSystemone
	startGatekeeper
	startIdplogin
	startLogin
	
	startFitnesse
	
	sleepAndWait 20
	
	echoStartingWithMarkers "dockers FINISHED"
}

setParameters(){
if [ "$1" == "preview" ]; then
    echo "Choosen environment: preview"
    ENV_SUFFIX=""
	SHARED_FILE_SUFFIX=""
	SOLR_PORT="-p 8983:8983"
	SYSTEMONE_PORT="-p 8210:8009"
	IDPLOGIN_OPTIONS="JAVA_OPTS=-Dmain.system.domain=https://cora.epc.ub.uu.se -Dtoken.logout.url=https://cora.epc.ub.uu.se/systemone/login/rest/authToken/" 
	IDPLOGIN_PORT="-p 8212:8009"
	LOGIN_OPTIONS="JAVA_OPTS=-Dlogin.public.path.to.system=/systemone/login/rest/ -Ddburl=jdbc:postgresql://systemone-postgresql:5432/systemone -Ddbusername=systemone -Ddbpassword=systemone" 
	LOGIN_PORT="-p 8211:8009" 
	FITNESSE_PORT="-p 8290:8090"
else
    echo "Choosen environment: build"
    ENV_SUFFIX="-test"
	SHARED_FILE_SUFFIX="Test"
	SOLR_PORT=""
	SYSTEMONE_PORT=""
	IDPLOGIN_OPTIONS="JAVA_OPTS=-Dtoken.logout.url=http://login$ENV_SUFFIX:8080/login/rest/" 
	IDPLOGIN_PORT=""
	LOGIN_OPTIONS="JAVA_OPTS=-Ddburl=jdbc:postgresql://systemone-postgresql$ENV_SUFFIX:5432/systemone -Ddbusername=systemone -Ddbpassword=systemone -Dlogin.public.path.to.system=/systemone/login/rest/" 
	LOGIN_PORT=""
	FITNESSE_PORT="-p 8190:8090"
fi

NETWORK=cora$ENV_SUFFIX
SOURCE_SHARED_ARCHIVE=systemOneArchive$SHARED_FILE_SUFFIX
SOURCE_SHARED_FILE=sharedFileStorage$SHARED_FILE_SUFFIX
TARGET_SHARED_ARCHIVE=/tmp/sharedArchiveReadable/systemOne
TARGET_SHARED_FILE=/tmp/sharedFileStorage/systemOne

DOCKERS=(
    "systemone-rabbitmq$ENV_SUFFIX"
    "solr$ENV_SUFFIX"
    "systemone-fedora$ENV_SUFFIX"
    "systemone-postgresql$ENV_SUFFIX"
    "systemone-iipimageserver$ENV_SUFFIX"
    "systemone-smallImageConverterQueue$ENV_SUFFIX"
    "systemone-jp2ConverterQueue$ENV_SUFFIX"
    "systemone-pdfConverterQueue$ENV_SUFFIX"
    "systemone$ENV_SUFFIX"
    "gatekeeper$ENV_SUFFIX"
    "idplogin$ENV_SUFFIX"
    "login$ENV_SUFFIX"
    "systemone-fitnesse$ENV_SUFFIX"
)

}

killDockers() {
    docker kill "${DOCKERS[@]}" && echo nothingToSeeMoveOnToNextCommand
}

removeDockers() {
    docker rm "${DOCKERS[@]}" && echo nothingToSeeMoveOnToNextCommand
}

removeVolumes() {
    docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand
}

startRabbitMq() {
	echoStartingWithMarkers "rabbitmq"
    docker run -d --name systemone-rabbitmq$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=systemone-rabbitmq \
     --restart unless-stopped \
     --hostname systemone-rabbitmq \
     cora-docker-rabbitmq:1.0-SNAPSHOT
}

echoStartingWithMarkers() {
	local text=$1
	echo ""
	echo "------------ STARTING ${text^^} ------------"
}

startSolr() {
	echoStartingWithMarkers "solr"
    docker run -d --name solr$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=solr \
     $SOLR_PORT \
     --restart unless-stopped \
     cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore
}

startFedora() {
	echoStartingWithMarkers "fedora"
    docker run -d --name systemone-fedora$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=systemone-fedora \
     --restart unless-stopped \
     --mount source=$SOURCE_SHARED_ARCHIVE,target=/usr/local/tomcat/fcrepo-home/data/ocfl-root \
     cora-docker-fedora:1.0-SNAPSHOT
}

startPostgresql() {
	echoStartingWithMarkers "postgresql"
    docker run -d --name systemone-postgresql$ENV_SUFFIX \
     --network=$NETWORK \
     --net-alias=systemone-postgresql \
     --restart unless-stopped \
     -e POSTGRES_DB=systemone \
     -e POSTGRES_USER=systemone \
     -e POSTGRES_PASSWORD=systemone \
     -e DATA_DIVIDERS="cora jsClient systemOne testSystem" \
     systemone-docker-postgresql:1.0-SNAPSHOT
}

startIIP() {
	echoStartingWithMarkers "IIPImageServer"
	docker run -d --name systemone-iipimageserver$ENV_SUFFIX \
	 --network=$NETWORK \
     --net-alias=systemone-iipimageserver \
     --restart unless-stopped \
	 -e VERBOSITY=0 \
	 -e FILESYSTEM_PREFIX=$TARGET_SHARED_FILE/streams/ \
	 -e FILESYSTEM_SUFFIX=-jp2 \
	 -e CORS=* \
	 -e MAX_IMAGE_CACHE_SIZE=1000 \
	 --mount source=$SOURCE_SHARED_FILE,target=$TARGET_SHARED_FILE,readonly \
	 cora-docker-iipimageserver:1.0-SNAPSHOT
}

startBinaryConverters() {
    echoStartingWithMarkers "binary converters"
    startBinaryConverterUsingQueueName "smallImageConverterQueue"
    startBinaryConverterUsingQueueName "jp2ConverterQueue"
    startBinaryConverterUsingQueueName "pdfConverterQueue"
}

startBinaryConverterUsingQueueName() {
    local queueName=$1

    echo "starting binaryConverter for $queueName"
    docker run -it -d --name systemone-$queueName$ENV_SUFFIX \
     --network=$NETWORK \
     --restart unless-stopped \
     --mount source=$SOURCE_SHARED_ARCHIVE,target=$TARGET_SHARED_ARCHIVE,readonly \
     --mount source=$SOURCE_SHARED_FILE,target=$TARGET_SHARED_FILE \
     -e coraBaseUrl="http://systemone:8080/systemone/rest/" \
     -e apptokenVerifierUrl="http://login:8080/login/rest/" \
     -e loginId="systemoneAdmin@system.cora.uu.se" \
     -e appToken="5d3f3ed4-4931-4924-9faa-8eaf5ac6457e" \
     -e rabbitMqHostName="systemone-rabbitmq" \
     -e rabbitMqPort="5672" \
     -e rabbitMqVirtualHost="/" \
     -e rabbitMqQueueName=$queueName \
     -e fedoraOcflHome="$TARGET_SHARED_ARCHIVE" \
     -e fileStorageBasePath="$TARGET_SHARED_FILE/" \
     cora-docker-binaryconverter:1.0-SNAPSHOT
}

startSystemone() {
	echoStartingWithMarkers "systemone"
    docker run -d --name systemone$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=systemone \
     $SYSTEMONE_PORT \
     --restart unless-stopped \
     --mount source=$SOURCE_SHARED_FILE,target=/mnt/data/basicstorage \
     systemone-docker:1.0-SNAPSHOT
}

startGatekeeper() {
	echoStartingWithMarkers "gatekeeper"
    docker run -d --name gatekeeper$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=gatekeeper \
     --restart unless-stopped \
     systemone-docker-gatekeeper:1.0-SNAPSHOT
}

startIdplogin() {
	echoStartingWithMarkers "idplogin"
    docker run -d --name idplogin$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=idplogin \
     --restart unless-stopped \
     -e "$IDPLOGIN_OPTIONS" \
     $IDPLOGIN_PORT \
     cora-docker-idplogin:1.0-SNAPSHOT
}

startLogin() {
   	echoStartingWithMarkers "login"
    docker run -d --name login$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=login \
     $LOGIN_PORT \
     --restart unless-stopped \
     -e "$LOGIN_OPTIONS" \
     cora-docker-login:1.0-SNAPSHOT
}

startFitnesse() {
	echoStartingWithMarkers "fitnesse"
    docker run -d --name systemone-fitnesse$ENV_SUFFIX \
     --network=$NETWORK \
     $FITNESSE_PORT \
     --restart unless-stopped \
     --mount source=$SOURCE_SHARED_ARCHIVE,target=$TARGET_SHARED_ARCHIVE,readonly \
     --mount source=$SOURCE_SHARED_FILE,target=$TARGET_SHARED_FILE,readonly \
     systemone-docker-fitnesse:1.0-SNAPSHOT
}

sleepAndWait(){
	local timeToSleep=$1
	echo ""
	echo "Waiting $timeToSleep seconds before to continue"
	sleep $timeToSleep
}

start
