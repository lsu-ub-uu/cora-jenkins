echo "Kill dockers"
docker kill systemone-rabbitmq systemone-smallImageConverter systemone-jp2Converter systemone-pdfConverter systemone-fitnesse systemone-postgresql systemone-fedora systemone solr idplogin apptokenverifier gatekeeper && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove dockers"
docker rm systemone-rabbitmq systemone-smallImageConverter systemone-jp2Converter systemone-pdfConverter systemone-fitnesse systemone-postgresql systemone-fedora systemone solr idplogin apptokenverifier gatekeeper && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

echo "starting rabbitmq"
docker run -d --net=cora --name systemone-rabbitmq \
--hostname systemone-rabbitmq \
cora-docker-rabbitmq:1.0-SNAPSHOT

echo "sleep 10s for rabbit to start"
sleep 10


echo ""
echo "Starting postgresql as database"
docker run -d --name systemone-postgresql \
 --net=cora \
 --restart unless-stopped  \
 --net-alias=systemone-postgresql \
 -e POSTGRES_DB=systemone \
 -e POSTGRES_USER=systemone \
 -e POSTGRES_PASSWORD=systemone \
 systemone-docker-postgresql:1.0-SNAPSHOT

echo ""
echo "Starting fedora for archive"
docker run -d --name systemone-fedora \
 --net=cora \
 --restart unless-stopped \
 --mount source=systemOneArchive,target=/usr/local/tomcat/fcrepo-home/data/ocfl-root \
 cora-docker-fedora:1.0-SNAPSHOT

echo ""
echo "Starting systemone"
#  -v /mnt/data/basicstorage \
docker run -d  --name systemone \
 --net=cora \
 --restart unless-stopped \
 --mount source=sharedFileStorage,target=/mnt/data/basicstorage \
 -p 8210:8009 \
 --link gatekeeper:gatekeeper \
 --link solr:solr \
 systemone-docker:1.0-SNAPSHOT

echo ""
echo "Starting gatekeeper"
docker run -d --name gatekeeper \
 --net=cora \
 --restart unless-stopped  \
 systemone-docker-gatekeeper:1.0-SNAPSHOT
 
echo ""
echo "starting idplogin"
docker run -d --name idplogin \
 --net=cora \
 --restart unless-stopped \
 -e "JAVA_OPTS=-Dmain.system.domain=https://cora.epc.ub.uu.se -Dtoken.logout.url=https://cora.epc.ub.uu.se/systemone/apptokenverifier/rest/apptoken/" \
 -p 8212:8009 \
 --link gatekeeper:gatekeeper \
 cora-docker-idplogin:1.0-SNAPSHOT

echo ""
echo "Starting apptokenverifier"
docker run -d  --name apptokenverifier \
 --net=cora \
 --restart unless-stopped \
 -e "JAVA_OPTS=-Dapptokenverifier.public.path.to.system=/systemone/apptokenverifier/rest/ -Ddburl=jdbc:postgresql://systemone-postgresql:5432/systemone -Ddbusername=systemone -Ddbpassword=systemone" \
 -p 8211:8009 \
 --link gatekeeper:gatekeeper \
 cora-docker-apptokenverifier:1.0-SNAPSHOT

echo ""
echo "Starting solr"
docker run -d  --name solr \
 --net=cora \
 --restart unless-stopped \
 -p 8983:8983  \
 cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

echo ""
echo "------------ STARTING BINARY CONVERTERS ------------"
echo "starting binaryConverter for smallImageConverterQueue"
docker run -it -d --name systemone-smallImageConverter \
 --mount source=systemOneArchive,target=/tmp/sharedArchiveReadable/systemOne,readonly \
 --mount source=sharedFileStorage,target=/tmp/sharedFileStorage/systemOne \
 --network=cora \
 -e coraBaseUrl="http://systemone:8080/systemone/rest/" \
 -e apptokenVerifierUrl="http://apptokenverifier:8080/apptokenverifier/rest/" \
 -e userId="141414" \
 -e appToken="63e6bd34-02a1-4c82-8001-158c104cae0e" \
 -e rabbitMqHostName="systemone-rabbitmq" \
 -e rabbitMqPort="5672" \
 -e rabbitMqVirtualHost="/" \
 -e rabbitMqQueueName="smallImageConverterQueue" \
 -e fedoraOcflHome="/tmp/sharedArchiveReadable/systemOne" \
 -e fileStorageBasePath="/tmp/sharedFileStorage/systemOne/" \
 cora-docker-binaryconverter:1.0-SNAPSHOT
 
echo "starting binaryConverter for jp2ConverterQueue"
docker run -it -d --name systemone-jp2Converter \
 --mount source=systemOneArchiveTest,target=/tmp/sharedArchiveReadable/systemOne,readonly \
 --mount source=sharedFileStorageTest,target=/tmp/sharedFileStorage/systemOne \
 --network=eclipseForCoraNet \
 -e coraBaseUrl="http://systemone-test:8080/systemone/rest/" \
 -e apptokenVerifierUrl="http://apptokenverifier-test:8080/apptokenverifier/rest/" \
 -e userId="141414" \
 -e appToken="63e6bd34-02a1-4c82-8001-158c104cae0e" \
 -e rabbitMqHostName="systemone-rabbitmq" \
 -e rabbitMqPort="5672" \
 -e rabbitMqVirtualHost="/" \
 -e rabbitMqQueueName="jp2ConverterQueue" \
 -e fedoraOcflHome="/tmp/sharedArchiveReadable/systemOne" \
 -e fileStorageBasePath="/tmp/sharedFileStorage/systemOne/" \
 cora-docker-binaryconverter:1.0-SNAPSHOT
 
echo "starting binaryConverter for pdfConverterQueue"
docker run -it -d --name systemone-pdfConverter \
 --mount source=systemOneArchive,target=/tmp/sharedArchiveReadable/systemOne,readonly \
 --mount source=sharedFileStorage,target=/tmp/sharedFileStorage/systemOne \
 --network=cora \
 -e coraBaseUrl="http://systemone:8080/systemone/rest/" \
 -e apptokenVerifierUrl="http://apptokenverifier:8080/apptokenverifier/rest/" \
 -e userId="141414" \
 -e appToken="63e6bd34-02a1-4c82-8001-158c104cae0e" \
 -e rabbitMqHostName="systemone-rabbitmq" \
 -e rabbitMqPort="5672" \
 -e rabbitMqVirtualHost="/" \
 -e rabbitMqQueueName="pdfConverterQueue" \
 -e fedoraOcflHome="/tmp/sharedArchiveReadable/systemOne" \
 -e fileStorageBasePath="/tmp/sharedFileStorage/systemOne/" \
 cora-docker-binaryconverter:1.0-SNAPSHOT
   
echo "----------------------------------------------------"

echo ""
echo "starting fitnesse"
docker run -d --name systemone-fitnesse \
 --net=cora \
 -p 8290:8090 \
 --mount source=systemOneArchive,target=/tmp/sharedArchiveReadable/systemOne,readonly \
 --link systemone:systemone \
 --link apptokenverifier:apptokenverifier \
 --link idplogin:idplogin \
 systemone-docker-fitnesse:1.0-SNAPSHOT
 
 