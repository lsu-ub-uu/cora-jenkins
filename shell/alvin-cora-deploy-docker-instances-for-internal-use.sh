NETWORK=alvin-cora$SUFFIX
SUFFIX=-test

echo "Kill dockers"
docker kill \
alvin-rabbitmq$SUFFIX alvin-smallImageConverter$SUFFIX alvin-jp2Converter$SUFFIX alvin-pdfConverter$SUFFIX \
alvin-fitnesse$SUFFIX alvin-fedora$SUFFIX alvin$SUFFIX alvin-solr$SUFFIX \
alvin-apptokenverifier$SUFFIX alvin-idplogin$SUFFIX alvin-gatekeeper$SUFFIX  \
alvin-postgresql$SUFFIX && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Remove dockers"
docker rm \
alvin-rabbitmq$SUFFIX alvin-smallImageConverter$SUFFIX alvin-jp2Converter$SUFFIX alvin-pdfConverter$SUFFIX \
alvin-fitnesse$SUFFIX alvin-fedora$SUFFIX alvin$SUFFIX alvin-solr$SUFFIX \
alvin-apptokenverifier$SUFFIX alvin-idplogin$SUFFIX alvin-gatekeeper$SUFFIX  \
alvin-postgresql$SUFFIX && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "starting rabbitmq"
docker run -d --net=$NETWORK --name alvin-rabbitmq$SUFFIX \
--hostname alvin-rabbitmq \
cora-docker-rabbitmq:1.0-SNAPSHOT

echo ""
echo "Starting postgresql as database"
docker run -d --name alvin-postgresql$SUFFIX \
 --net-alias=alvin-postgresql \
 --net=$NETWORK \
 -e POSTGRES_DB=alvin \
 -e POSTGRES_USER=alvin \
 -e POSTGRES_PASSWORD=alvin \
 alvin-docker-postgresql:1.0-SNAPSHOT
 
echo ""
echo "wait 10s for rabbit and database to start"
sleep 10

echo ""
echo "Starting fedora for archive"
docker run -d --name alvin-fedora$SUFFIX \
 --net-alias=alvin-fedora \
 --net=$NETWORK \
 cora-docker-fedora:1.0-SNAPSHOT

echo ""
echo "Starting alvin"
docker run -d --name alvin$SUFFIX \
 --net-alias=alvin \
 --net=$NETWORK \
 -v /mnt/data/basicstorage \
 alvin-docker-cora:1.0-SNAPSHOT

echo ""
echo "Starting gatekeeper"
docker run -d --name alvin-gatekeeper$SUFFIX \
 --net-alias=gatekeeper \
 --net=$NETWORK \
 alvin-docker-gatekeeper:1.0-SNAPSHOT
 
echo ""
echo "starting idplogin"
docker run -d --name alvin-idplogin$SUFFIX \
 --net-alias=idplogin \
 --net=$NETWORK \
 -e "JAVA_OPTS=-Dtoken.logout.url=https://apptokenverifier/rest/" \
 cora-docker-idplogin:1.0-SNAPSHOT

echo ""
echo "Starting apptokenverifier"
docker run -d --name alvin-apptokenverifier$SUFFIX \
 --net-alias=apptokenverifier \
 --net=$NETWORK \
 -e "JAVA_OPTS=-Dapptokenverifier.public.path.to.system=/alvin/apptokenverifier/rest/ -Ddburl=jdbc:postgresql://alvin-postgresql:5432/alvin -Ddbusername=alvin -Ddbpassword=alvin" \
 cora-docker-apptokenverifier:1.0-SNAPSHOT

echo ""
echo "Starting solr"
docker run -d --name alvin-solr$SUFFIX \
 --net-alias=solr \
 --net=$NETWORK \
 cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

echo ""
echo "------------ STARTING BINARY CONVERTERS ------------"
echo "starting binaryConverter for smallImageConverterQueue"
docker run -it -d --name alvin-smallImageConverter \
 --mount source=alvinArchive,target=/tmp/sharedArchiveReadable/alvin,readonly \
 --mount source=sharedFileStorage,target=/tmp/sharedFileStorage/alvin \
 --network=$NETWORK \
 -e coraBaseUrl="http://alvin$SUFFIX:8080/alvin/rest/" \
 -e apptokenVerifierUrl="http://apptokenverifier$SUFFIX:8080/apptokenverifier/rest/" \
 -e userId="141414" \
 -e appToken="63e6bd34-02a1-4c82-8001-158c104cae0e" \
 -e rabbitMqHostName="alvin-rabbitmq" \
 -e rabbitMqPort="5672" \
 -e rabbitMqVirtualHost="/" \
 -e rabbitMqQueueName="smallImageConverterQueue" \
 -e fedoraOcflHome="/tmp/sharedArchiveReadable/alvin" \
 -e fileStorageBasePath="/tmp/sharedFileStorage/alvin/" \
 cora-docker-binaryconverter:1.0-SNAPSHOT
 
echo "starting binaryConverter for jp2ConverterQueue"
docker run -it -d --name alvin-jp2Converter \
 --mount source=alvinArchive,target=/tmp/sharedArchiveReadable/alvin,readonly \
 --mount source=sharedFileStorage,target=/tmp/sharedFileStorage/alvin \
 --network=$NETWORK \
 -e coraBaseUrl="http://alvin$SUFFIX:8080/alvin/rest/" \
 -e apptokenVerifierUrl="http://apptokenverifier$SUFFIX:8080/apptokenverifier/rest/" \
 -e userId="141414" \
 -e appToken="63e6bd34-02a1-4c82-8001-158c104cae0e" \
 -e rabbitMqHostName="alvin-rabbitmq" \
 -e rabbitMqPort="5672" \
 -e rabbitMqVirtualHost="/" \
 -e rabbitMqQueueName="jp2ConverterQueue" \
 -e fedoraOcflHome="/tmp/sharedArchiveReadable/alvin" \
 -e fileStorageBasePath="/tmp/sharedFileStorage/alvin/" \
 cora-docker-binaryconverter:1.0-SNAPSHOT
 
echo "starting binaryConverter for pdfConverterQueue"
docker run -it -d --name alvin-pdfConverter \
 --mount source=alvinArchive,target=/tmp/sharedArchiveReadable/alvin,readonly \
 --mount source=sharedFileStorage,target=/tmp/sharedFileStorage/alvin \
 --network=$NETWORK \
 -e coraBaseUrl="http://alvin$SUFFIX:8080/alvin/rest/" \
 -e apptokenVerifierUrl="http://apptokenverifier$SUFFIX:8080/apptokenverifier/rest/" \
 -e userId="141414" \
 -e appToken="63e6bd34-02a1-4c82-8001-158c104cae0e" \
 -e rabbitMqHostName="alvin-rabbitmq" \
 -e rabbitMqPort="5672" \
 -e rabbitMqVirtualHost="/" \
 -e rabbitMqQueueName="pdfConverterQueue" \
 -e fedoraOcflHome="/tmp/sharedArchiveReadable/alvin" \
 -e fileStorageBasePath="/tmp/sharedFileStorage/alvin/" \
 cora-docker-binaryconverter:1.0-SNAPSHOT
   
echo "----------------------------------------------------"


echo ""
echo "Starting fitnesse"
docker run -d --name alvin-fitnesse$SUFFIX \
 --net=$NETWORK \
 -p 8390:8090  \
 -e tokenLogoutURL=https://apptokenverifier/rest/ \
 alvin-cora-docker-fitnesse:1.1-SNAPSHOT

echo "wait for everything to start"
sleep 20
echo "All dockers started"
