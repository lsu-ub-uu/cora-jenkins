echo "Kill dockers"
docker kill alvin-rabbitmq alvin-smallImageConverter alvin-jp2Converter alvin-pdfConverter alvin-fitnesse alvin alvin-fedora alvin-postgresql alvin-solr alvin-idplogin alvin-apptokenverifier alvin-gatekeeper && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove dockers"
docker rm alvin-rabbitmq alvin-smallImageConverter alvin-jp2Converter alvin-pdfConverter alvin-fitnesse alvin alvin-fedora alvin-postgresql alvin-solr alvin-idplogin alvin-apptokenverifier alvin-gatekeeper && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "starting rabbitmq"
docker run -d --net=cora --name alvin-rabbitmq \
--hostname alvin-rabbitmq \
cora-docker-rabbitmq:1.0-SNAPSHOT

echo ""
echo "Starting postgresql as database"
docker run -d --name alvin-postgresql \
 --net=alvin-cora \
 --net-alias=alvin-postgresql \
 -e POSTGRES_DB=alvin \
 -e POSTGRES_USER=alvin \
 -e POSTGRES_PASSWORD=alvin \
 alvin-docker-postgresql:1.0-SNAPSHOT
 
 echo ""
echo "sleep 10s for rabbit and database to start"
sleep 10

echo ""
echo "Starting fedora for archive"
docker run -d --name alvin-fedora \
 --net=alvin-cora \
--restart unless-stopped  \
 cora-docker-fedora:1.0-SNAPSHOT

echo ""
echo "Starting alvin"
docker run -d --name alvin \
 --net=alvin-cora \
 -p 8410:8009 \
--restart unless-stopped  \
 -v /mnt/data/basicstorage  \
 alvin-docker-cora:1.0-SNAPSHOT

echo ""
echo "Starting gatekeeper"
docker run -d --name alvin-gatekeeper \
 --net-alias=gatekeeper \
 --net=alvin-cora \
--restart unless-stopped  \
 alvin-docker-gatekeeper:1.0-SNAPSHOT
 
echo ""
echo "starting idplogin"
docker run -d --name alvin-idplogin \
 --net-alias=idplogin \
 --net=alvin-cora \
 -p 8412:8009 \
--restart unless-stopped  \
 -e "JAVA_OPTS=-Dmain.system.domain=https://cora.epc.ub.uu.se -Dtoken.logout.url=https://cora.epc.ub.uu.se/alvin/apptokenverifier/rest/apptoken/" \
 cora-docker-idplogin:1.0-SNAPSHOT
 
echo ""
echo "Starting apptokenverifier"
docker run -d --name alvin-apptokenverifier \
 --net-alias=apptokenverifier \
 --net=alvin-cora \
 -p 8411:8009 \
--restart unless-stopped  \
 -e "JAVA_OPTS=-Dapptokenverifier.public.path.to.system=/alvin/apptokenverifier/rest/ -Ddburl=jdbc:postgresql://alvin-postgresql:5432/alvin -Ddbusername=alvin -Ddbpassword=alvin" \
 cora-docker-apptokenverifier:1.0-SNAPSHOT
 
echo ""
echo "Starting solr"
docker run -d --name alvin-solr \
 --net-alias=solr \
 --net=alvin-cora \
--restart unless-stopped  \
 cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

echo ""
echo "------------ STARTING BINARY CONVERTERS ------------"
echo "starting binaryConverter for smallImageConverterQueue"
docker run -it -d --name alvin-smallImageConverter \
 --mount source=alvinArchive,target=/tmp/sharedArchiveReadable/alvin,readonly \
 --mount source=sharedFileStorage,target=/tmp/sharedFileStorage/alvin \
 --network=cora \
 -e coraBaseUrl="http://alvin:8080/alvin/rest/" \
 -e apptokenVerifierUrl="http://apptokenverifier:8080/apptokenverifier/rest/" \
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
 --network=cora \
 -e coraBaseUrl="http://alvin-test:8080/alvin/rest/" \
 -e apptokenVerifierUrl="http://apptokenverifier-test:8080/apptokenverifier/rest/" \
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
 --network=cora \
 -e coraBaseUrl="http://alvin:8080/alvin/rest/" \
 -e apptokenVerifierUrl="http://apptokenverifier:8080/apptokenverifier/rest/" \
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
docker run -d --name alvin-fitnesse \
 --net=alvin-cora \
--restart unless-stopped  \
 -p 8490:8090 \
 -e tokenLogoutURL=https://cora.epc.ub.uu.se/alvin/apptokenverifier/rest/apptoken/ \
 alvin-cora-docker-fitnesse:1.1-SNAPSHOT

echo ""
echo "All dockers started"