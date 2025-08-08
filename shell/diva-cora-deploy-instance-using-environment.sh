#
# DEPRECATED: This script is no longer maintained or used.
# Kubernetes and Helm are now used to handle the build and preview environments.
# For more information, please refer to the 'cora-deployment' project.
#

#! /bin/bash
ENVIRONMENT=$1

start(){
	setParameters
    killDockers
    removeDockers
    removeVolumes
    
	createNetwork
    startRabbitMq
    startSolr
    startFedora
    startPostgresql
    startIIP

    sleepAndWait 15

	startBinaryConverters
    startDiva
    startGatekeeper
    startIdplogin
    startLogin

	startFitnesse
	
    sleepAndWait 15
    
    echoStartingWithMarkers "dockers FINISHED"
}

setParameters(){
	LOGIN_OPTIONS="JAVA_OPTS=-Dlogin.public.path.to.system=/diva/login/rest/ -Ddburl=jdbc:postgresql://diva-postgresql:5432/diva -Ddbusername=diva -Ddbpassword=diva" 
	DIVA_POSTGRES_VERSION="1.0-SNAPSHOT"
	DIVA_VERSION="1.0-SNAPSHOT"
	
	if [ "$ENVIRONMENT" == "preview" ]; then
	    echo "Choosen environment: $ENVIRONMENT"
	    ENV_SUFFIX=""
		SHARED_FILE_SUFFIX=""
		SOLR_PORT=""
		DIVA_PORT="-p 8610:8009"
		IDPLOGIN_OPTIONS="JAVA_OPTS=-Dmain.system.domain=https://cora.epc.ub.uu.se -Dtoken.logout.url=https://cora.epc.ub.uu.se/diva/login/rest/authToken/" 
		IDPLOGIN_PORT="-p 8612:8009"
		LOGIN_PORT="-p 8611:8009" 
		FITNESSE_PORT="-p 8690:8090"
		
	else
		echo "Choosen environment: $ENVIRONMENT"
		ENV_SUFFIX="-test"
		SHARED_FILE_SUFFIX="Test"
		SOLR_PORT=""
		DIVA_PORT=""
		IDPLOGIN_OPTIONS="JAVA_OPTS=-Dtoken.logout.url=http://login:8080/login/rest/authToken/" 
		IDPLOGIN_PORT=""
		LOGIN_PORT=""
		FITNESSE_PORT="-p 8590:8090"
	fi
	
	NETWORK=diva-cora$ENV_SUFFIX
	SOURCE_SHARED_ARCHIVE=divaSharedArchive$SHARED_FILE_SUFFIX
	SOURCE_SHARED_FILE=divaSharedFileStorage$SHARED_FILE_SUFFIX
	TARGET_SHARED_ARCHIVE=/tmp/sharedArchiveReadable/diva
	TARGET_SHARED_FILE=/tmp/sharedFileStorage/diva
	
	DOCKERS=(
		"diva-rabbitmq$ENV_SUFFIX"
    	"diva-solr$ENV_SUFFIX"
    	"diva-postgresql$ENV_SUFFIX"
    	"diva-fedora$ENV_SUFFIX"
    	"diva-iipimageserver$ENV_SUFFIX"
    	"diva-smallImageConverterQueue$ENV_SUFFIX"
    	"diva-jp2ConverterQueue$ENV_SUFFIX"
    	"diva-pdfConverterQueue$ENV_SUFFIX"
    	"diva$ENV_SUFFIX"
    	"diva-login$ENV_SUFFIX"
    	"diva-idplogin$ENV_SUFFIX"
    	"diva-gatekeeper$ENV_SUFFIX"
    	"diva-fitnesse$ENV_SUFFIX"
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

createNetwork() {
    docker network create $NETWORK
}

startRabbitMq() {
	echoStartingWithMarkers "rabbitmq"
    docker run -d --name diva-rabbitmq$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=diva-rabbitmq \
     --restart unless-stopped \
     --hostname diva-rabbitmq \
     cora-docker-rabbitmq:1.1-SNAPSHOT
}

echoStartingWithMarkers() {
	local text=$1
	echo ""
	echo "------------ STARTING ${text^^} ------------"
}

startSolr() {
	echoStartingWithMarkers "solr"
    docker run -d --name diva-solr$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=solr \
     $SOLR_PORT \
     --restart unless-stopped \
     cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore
}

startFedora() {
	echoStartingWithMarkers "fedora"
    docker run -d --name diva-fedora$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=diva-fedora \
     --restart unless-stopped \
     --mount source=$SOURCE_SHARED_ARCHIVE,target=/usr/local/tomcat/fcrepo-home/data/ocfl-root \
     cora-docker-fedora:1.0-SNAPSHOT
}

startPostgresql() {
	echoStartingWithMarkers "postgresql"
    docker run -d --name diva-postgresql$ENV_SUFFIX \
     --network=$NETWORK \
     --restart unless-stopped \
     --net-alias=diva-postgresql \
     -e POSTGRES_DB=diva \
     -e POSTGRES_USER=diva \
     -e POSTGRES_PASSWORD=diva \
     -e DATA_DIVIDERS="cora jsClient diva divaClient divaPreview" \
     diva-docker-postgresql:$DIVA_POSTGRES_VERSION
}

startIIP() {
	echoStartingWithMarkers "IIPImageServer"
	docker run -d --name diva-iipimageserver$ENV_SUFFIX \
	 --network=$NETWORK \
	 --net-alias=diva-iipimageserver \
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
    docker run -it -d --name diva-$queueName$ENV_SUFFIX \
     --network=$NETWORK \
     --restart unless-stopped \
     --mount source=$SOURCE_SHARED_ARCHIVE,target=$TARGET_SHARED_ARCHIVE,readonly \
     --mount source=$SOURCE_SHARED_FILE,target=$TARGET_SHARED_FILE \
     -e coraBaseUrl="http://diva:8080/diva/rest/" \
     -e apptokenVerifierUrl="http://login:8080/login/rest/" \
     -e loginId="systemoneAdmin@system.cora.uu.se" \
     -e appToken="5d3f3ed4-4931-4924-9faa-8eaf5ac6457e" \
     -e rabbitMqHostName="diva-rabbitmq" \
     -e rabbitMqPort="5672" \
     -e rabbitMqVirtualHost="/" \
     -e rabbitMqQueueName=$queueName \
     -e fedoraOcflHome="$TARGET_SHARED_ARCHIVE" \
     -e fileStorageBasePath="$TARGET_SHARED_FILE/" \
     cora-docker-binaryconverter:1.0-SNAPSHOT
}

startDiva() {
    echoStartingWithMarkers "diva"
    docker run -d --name diva$ENV_SUFFIX \
        --network-alias=diva \
        --network=$NETWORK \
        $DIVA_PORT \
        --mount source=$SOURCE_SHARED_FILE,target=/mnt/data/basicstorage \
        diva-docker-cora:$DIVA_VERSION
}

startGatekeeper() {
	echoStartingWithMarkers "gatekeeper"
    docker run -d --name diva-gatekeeper$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=gatekeeper \
     --restart unless-stopped \
     diva-docker-gatekeeper:1.0-SNAPSHOT
}

startIdplogin() {
	echoStartingWithMarkers "idplogin"
    docker run -d --name diva-idplogin$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=idplogin \
     --restart unless-stopped \
     -e "$IDPLOGIN_OPTIONS" \
     $IDPLOGIN_PORT \
     cora-docker-idplogin:1.0-SNAPSHOT
}

startLogin() {
   	echoStartingWithMarkers "login"
    docker run -d --name diva-login$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=login \
     $LOGIN_PORT \
     --restart unless-stopped \
     -e "$LOGIN_OPTIONS" \
     cora-docker-login:1.0-SNAPSHOT
}

startFitnesse() {
	echoStartingWithMarkers "fitnesse"
    docker run -d --name diva-fitnesse$ENV_SUFFIX \
     --network=$NETWORK \
     $FITNESSE_PORT \
     --restart unless-stopped \
     --mount source=$SOURCE_SHARED_ARCHIVE,target=$TARGET_SHARED_ARCHIVE,readonly \
     --mount source=$SOURCE_SHARED_FILE,target=$TARGET_SHARED_FILE,readonly \
     diva-cora-docker-fitnesse:1.1-SNAPSHOT
}

sleepAndWait(){
	local timeToSleep=$1
	echo ""
	echo "Waiting $timeToSleep seconds before to continue"
	sleep $timeToSleep
}

start
