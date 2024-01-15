#! /bin/bash
ENV_SUFFIX=-test
SHARED_FILE_SUFFIX=Test
NETWORK=cora$ENV_SUFFIX

start(){
	setParameters "$1"
	killDockers
	removeDockers
	removeVolumes
	
	startRabbitMq
	startSolr
	startFedora
	startPostgresql
	startIIP
	
	sleepAndWait 10
	
	startBinaryConverters
	startSystemone
	startGatekeeper
	startIdplogin
	startApptokenverifier
	startFitnesse
	
	sleepAndWait 20
	
	echoStartingWithMarkers "All dockers started"
}

setParameters(){
if [ "$1" == "preview" ]; then
    echo "Choosen environment: preview"
    ENV_SUFFIX=
	SHARED_FILE_SUFFIX=
else
     echo "Choosen environment: build"
    ENV_SUFFIX=-test
	SHARED_FILE_SUFFIX=Test
fi
}



killDockers() {
    docker kill systemone-rabbitmq$ENV_SUFFIX systemone-iipimageserver$ENV_SUFFIX systemone-smallImageConverter$ENV_SUFFIX systemone-jp2Converter$ENV_SUFFIX systemone-pdfConverter$ENV_SUFFIX systemone-fitnesse$ENV_SUFFIX systemone-fedora$ENV_SUFFIX systemone-postgresql$ENV_SUFFIX systemone$ENV_SUFFIX solr$ENV_SUFFIX apptokenverifier$ENV_SUFFIX idplogin$ENV_SUFFIX gatekeeper$ENV_SUFFIX && echo nothingToSeeMoveOnToNextCommand
}

removeDockers() {
    docker rm systemone-rabbitmq$ENV_SUFFIX systemone-iipimageserver$ENV_SUFFIX systemone-smallImageConverter$ENV_SUFFIX systemone-jp2Converter$ENV_SUFFIX systemone-pdfConverter$ENV_SUFFIX systemone-fitnesse$ENV_SUFFIX systemone-fedora$ENV_SUFFIX systemone-postgresql$ENV_SUFFIX systemone$ENV_SUFFIX solr$ENV_SUFFIX apptokenverifier$ENV_SUFFIX idplogin$ENV_SUFFIX gatekeeper$ENV_SUFFIX && echo nothingToSeeMoveOnToNextCommand
}

removeVolumes() {
    docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand
}

startRabbitMq() {
	echoStartingWithMarkers "rabbitmq"
    docker run -d --network=$NETWORK --name systemone-rabbitmq$ENV_SUFFIX \
        --net-alias=systemone-rabbitmq \
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
    docker run -d --network=$NETWORK --name solr$ENV_SUFFIX \
        cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore
}

startFedora() {
	echoStartingWithMarkers "fedora"
    docker run -d --network=$NETWORK --name systemone-fedora$ENV_SUFFIX \
        --mount source=systemOneArchive$SHARED_FILE_SUFFIX,target=/usr/local/tomcat/fcrepo-home/data/ocfl-root \
        --network-alias=systemone-fedora \
        cora-docker-fedora:1.0-SNAPSHOT
}

startPostgresql() {
	echoStartingWithMarkers "postgresql"
    docker run -d --network=$NETWORK --name systemone-postgresql$ENV_SUFFIX \
        --net-alias=systemone-postgresql \
        -e POSTGRES_DB=systemone \
        -e POSTGRES_USER=systemone \
        -e POSTGRES_PASSWORD=systemone \
        systemone-docker-postgresql:1.0-SNAPSHOT
}

startIIP() {
	echoStartingWithMarkers "IIPImageServer"
	docker run -d --name systemone-iipimageserver$ENV_SUFFIX \
	 --network=$NETWORK \
	 -e VERBOSITY=0 \
	 -e FILESYSTEM_PREFIX=/tmp/sharedFileStorage/systemOne/streams/ \
	 -e FILESYSTEM_SUFFIX=-jp2 \
	 -e CORS=* \
	 -e MAX_IMAGE_CACHE_SIZE=1000 \
	 --mount type=source=sharedFileStorage$SHARED_FILE_SUFFIX,target=/tmp/sharedFileStorage/systemOne,readonly \
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
        --mount source=systemOneArchive$SHARED_FILE_SUFFIX,target=/tmp/sharedArchiveReadable/systemOne,readonly \
        --mount source=sharedFileStorage$SHARED_FILE_SUFFIX,target=/tmp/sharedFileStorage/systemOne \
        --network=$NETWORK \
        -e coraBaseUrl="http://systemone$ENV_SUFFIX:8080/systemone/rest/" \
        -e apptokenVerifierUrl="http://apptokenverifier$ENV_SUFFIX:8080/apptokenverifier/rest/" \
        -e userId="141414" \
        -e appToken="63e6bd34-02a1-4c82-8001-158c104cae0e" \
        -e rabbitMqHostName="systemone-rabbitmq$ENV_SUFFIX" \
        -e rabbitMqPort="5672" \
        -e rabbitMqVirtualHost="/" \
        -e rabbitMqQueueName=$queueName \
        -e fedoraOcflHome="/tmp/sharedArchiveReadable/systemOne" \
        -e fileStorageBasePath="/tmp/sharedFileStorage/systemOne/" \
        cora-docker-binaryconverter:1.0-SNAPSHOT
}

startSystemone() {
	echoStartingWithMarkers "systemone"
    docker run -d --network=$NETWORK --name systemone$ENV_SUFFIX \
        --mount source=sharedFileStorage$SHARED_FILE_SUFFIX,target=/mnt/data/basicstorage \
        --link gatekeeper$ENV_SUFFIX:gatekeeper \
        --link solr$ENV_SUFFIX:solr \
        systemone-docker:1.0-SNAPSHOT
}

startGatekeeper() {
	echoStartingWithMarkers "gatekeeper"
    docker run -d --network=$NETWORK --name gatekeeper$ENV_SUFFIX \
        systemone-docker-gatekeeper:1.0-SNAPSHOT
}

startIdplogin() {
	echoStartingWithMarkers "idplogin"
    docker run -d --network=$NETWORK --name idplogin$ENV_SUFFIX \
        --link gatekeeper$ENV_SUFFIX:gatekeeper \
        --link apptokenverifier$ENV_SUFFIX:apptokenverifier \
        -e "JAVA_OPTS=-Dtoken.logout.url=http://apptokenverifier$ENV_SUFFIX:8080/apptokenverifier/rest/" \
        cora-docker-idplogin:1.0-SNAPSHOT
}

startApptokenverifier() {
   	echoStartingWithMarkers "apptokenverifier"
    docker run -d --network=$NETWORK --name apptokenverifier$ENV_SUFFIX \
        --link gatekeeper$ENV_SUFFIX:gatekeeper \
        -e "JAVA_OPTS=-Dapptokenverifier.public.path.to.system=/systemone/apptokenverifier/rest/ -Ddburl=jdbc:postgresql://systemone-postgresql$ENV_SUFFIX:5432/systemone -Ddbusername=systemone -Ddbpassword=systemone" \
        cora-docker-apptokenverifier:1.0-SNAPSHOT
}


startFitnesse() {
	echoStartingWithMarkers "fitnesse"
    docker run -d --network=$NETWORK -p 8190:8090 --name systemone-fitnesse$ENV_SUFFIX \
        --mount source=systemOneArchive$SHARED_FILE_SUFFIX,target=/tmp/sharedArchiveReadable/systemOne,readonly \
        --mount source=sharedFileStorage$SHARED_FILE_SUFFIX,target=/tmp/sharedFileStorage/systemOne,readonly \
        --link systemone$ENV_SUFFIX:systemone \
        --link apptokenverifier$ENV_SUFFIX:apptokenverifier \
        --link idplogin$ENV_SUFFIX:idplogin \
        systemone-docker-fitnesse:1.0-SNAPSHOT
}

sleepAndWait(){
	local timeToSleep=$1
	echo ""
	echo "Waiting $timeToSleep seconds before to continue"
	sleep $timeToSleep
}

start
