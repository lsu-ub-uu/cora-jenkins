#! /bin/bash
ENVIRONMENT=$1

start(){
	setParameters
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
    startAlvin
    startGatekeeper
    startIdplogin
    startLogin

	startFitnesse
	
    sleepAndWait 20
    
    echoStartingWithMarkers "dockers FINISHED"
}

setParameters(){
	if [ "$ENVIRONMENT" == "preview" ]; then
	    echo "Choosen environment: $ENVIRONMENT"
	    ENV_SUFFIX=""
		SHARED_FILE_SUFFIX=""
		SOLR_PORT=""
		ALVIN_PORT="-p 8410:8009"
		IDPLOGIN_OPTIONS="JAVA_OPTS=-Dmain.system.domain=https://cora.epc.ub.uu.se -Dtoken.logout.url=https://cora.epc.ub.uu.se/alvin/login/rest/apptoken/" 
		IDPLOGIN_PORT="-p 8412:8009"
		LOGIN_PORT="-p 8411:8009" 
		FITNESSE_OPTIONS="tokenLogoutURL=https://cora.epc.ub.uu.se/alvin/login/rest/apptoken/"
		FITNESSE_PORT="-p 8490:8090"
	else
	    echo "Choosen environment: $ENVIRONMENT"
	    ENV_SUFFIX="-test"
		SHARED_FILE_SUFFIX="Test"
		SOLR_PORT=""
		ALVIN_PORT=""
		IDPLOGIN_OPTIONS="JAVA_OPTS=-Dtoken.logout.url=https://login/rest/" 
		IDPLOGIN_PORT=""
		LOGIN_PORT=""
		FITNESSE_OPTIONS="tokenLogoutURL=https://login/rest/"
		FITNESSE_PORT="-p 8390:8090"
	fi
	
	NETWORK=alvin-cora$ENV_SUFFIX
	SOURCE_SHARED_ARCHIVE=alvinSharedArchive$SHARED_FILE_SUFFIX
	SOURCE_SHARED_FILE=alvinSharedFileStorage$SHARED_FILE_SUFFIX
	TARGET_SHARED_ARCHIVE=/tmp/sharedArchiveReadable/alvin
	TARGET_SHARED_FILE=/tmp/sharedFileStorage/alvin
	LOGIN_OPTIONS="JAVA_OPTS=-Ddburl=jdbc:postgresql://alvin-postgresql$ENV_SUFFIX:5432/alvin -Ddbusername=alvin -Ddbpassword=alvin -Dlogin.public.path.to.system=/alvin/login/rest/" 
	
	DOCKERS=(
		"alvin-rabbitmq$ENV_SUFFIX"
    	"alvin-solr$ENV_SUFFIX"
    	"alvin-postgresql$ENV_SUFFIX"
    	"alvin-fedora$ENV_SUFFIX"
    	"alvin-iipimageserver$ENV_SUFFIX"
    	"alvin-smallImageConverterQueue$ENV_SUFFIX"
    	"alvin-jp2ConverterQueue$ENV_SUFFIX"
    	"alvin-pdfConverterQueue$ENV_SUFFIX"
    	"alvin$ENV_SUFFIX"
    	"alvin-login$ENV_SUFFIX"
    	"alvin-idplogin$ENV_SUFFIX"
    	"alvin-gatekeeper$ENV_SUFFIX"
    	"alvin-fitnesse$ENV_SUFFIX"
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
    docker run -d --name alvin-rabbitmq$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=alvin-rabbitmq \
     --restart unless-stopped \
     --hostname alvin-rabbitmq \
     cora-docker-rabbitmq:1.0-SNAPSHOT
}

echoStartingWithMarkers() {
	local text=$1
	echo ""
	echo "------------ STARTING ${text^^} ------------"
}

startSolr() {
	echoStartingWithMarkers "solr"
    docker run -d --name alvin-solr$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=solr \
     $SOLR_PORT \
     --restart unless-stopped \
     cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore
}

startFedora() {
	echoStartingWithMarkers "fedora"
    docker run -d --name alvin-fedora$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=alvin-fedora \
     --restart unless-stopped \
     --mount source=$SOURCE_SHARED_ARCHIVE,target=/usr/local/tomcat/fcrepo-home/data/ocfl-root \
     cora-docker-fedora:1.0-SNAPSHOT
}

startPostgresql() {
	echoStartingWithMarkers "postgresql"
    docker run -d --name alvin-postgresql$ENV_SUFFIX \
     --network=$NETWORK \
     --net-alias=alvin-postgresql \
     --restart unless-stopped \
     -e POSTGRES_DB=alvin \
     -e POSTGRES_USER=alvin \
     -e POSTGRES_PASSWORD=alvin \
     alvin-docker-postgresql:1.0-SNAPSHOT
}

startIIP() {
	echoStartingWithMarkers "IIPImageServer"
	docker run -d --name alvin-iipimageserver$ENV_SUFFIX \
	 --network=$NETWORK \
	 --net-alias=alvin-iipimageserver \
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
    docker run -it -d --name alvin-$queueName$ENV_SUFFIX \
     --network=$NETWORK \
     --restart unless-stopped \
     --mount source=$SOURCE_SHARED_ARCHIVE,target=$TARGET_SHARED_ARCHIVE,readonly \
     --mount source=$SOURCE_SHARED_FILE,target=$TARGET_SHARED_FILE \
     -e coraBaseUrl="http://alvin:8080/alvin/rest/" \
     -e apptokenVerifierUrl="http://login:8080/login/rest/" \
     -e userId="141414" \
     -e appToken="63e6bd34-02a1-4c82-8001-158c104cae0e" \
     -e rabbitMqHostName="alvin-rabbitmq" \
     -e rabbitMqPort="5672" \
     -e rabbitMqVirtualHost="/" \
     -e rabbitMqQueueName=$queueName \
     -e fedoraOcflHome="$TARGET_SHARED_ARCHIVE" \
     -e fileStorageBasePath="$TARGET_SHARED_FILE/" \
     cora-docker-binaryconverter:1.0-SNAPSHOT
}

startAlvin() {
    echoStartingWithMarkers "alvin"
    docker run -d --name alvin$ENV_SUFFIX \
        --network-alias=alvin \
        --network=$NETWORK \
        $ALVIN_PORT \
        --mount source=$SOURCE_SHARED_FILE,target=/mnt/data/basicstorage \
        alvin-docker-cora:1.0-SNAPSHOT
}

startGatekeeper() {
	echoStartingWithMarkers "gatekeeper"
    docker run -d --name alvin-gatekeeper$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=gatekeeper \
     --restart unless-stopped \
     alvin-docker-gatekeeper:1.0-SNAPSHOT
}

startIdplogin() {
	echoStartingWithMarkers "idplogin"
    docker run -d --name alvin-idplogin$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=idplogin \
     --restart unless-stopped \
     -e "$IDPLOGIN_OPTIONS" \
     $IDPLOGIN_PORT \
     cora-docker-idplogin:1.0-SNAPSHOT
}

startLogin() {
   	echoStartingWithMarkers "login"
    docker run -d --name alvin-login$ENV_SUFFIX \
     --network=$NETWORK \
     --network-alias=login \
     $LOGIN_PORT \
     --restart unless-stopped \
     -e "$LOGIN_OPTIONS" \
     cora-docker-login:1.0-SNAPSHOT
}

startFitnesse() {
	echoStartingWithMarkers "fitnesse"
    docker run -d --name alvin-fitnesse$ENV_SUFFIX \
     --network=$NETWORK \
     $FITNESSE_PORT \
     --restart unless-stopped \
     -e $FITNESSE_OPTIONS \
     --mount source=$SOURCE_SHARED_ARCHIVE,target=$TARGET_SHARED_ARCHIVE,readonly \
     --mount source=$SOURCE_SHARED_FILE,target=$TARGET_SHARED_FILE,readonly \
     alvin-cora-docker-fitnesse:1.1-SNAPSHOT
}

sleepAndWait(){
	local timeToSleep=$1
	echo ""
	echo "Waiting $timeToSleep seconds before to continue"
	sleep $timeToSleep
}

start
