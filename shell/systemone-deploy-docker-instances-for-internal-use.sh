echo "Kill dockers"
docker kill systemone-rabbitmq-test systemone-smallImageConverter-test systemone-jp2Converter-test systemone-pdfConverter-test systemone-fitnesse-test systemone-fedora-test systemone-postgresql-test systemone-test solr-test apptokenverifier-test idplogin-test gatekeeper-test && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove dockers"
docker rm systemone-rabbitmq-test systemone-smallImageConverter-test systemone-jp2Converter-test systemone-pdfConverter-test systemone-fitnesse-test systemone-fedora-test systemone-postgresql-test systemone-test solr-test apptokenverifier-test idplogin-test gatekeeper-test && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "starting rabbitmq"
docker run -d --net=cora-test --name systemone-rabbitmq-test \
--net-alias=systemone-rabbitmq \
--hostname systemone-rabbitmq \
cora-docker-rabbitmq:1.0-SNAPSHOT

echo ""
echo "Starting postgresql as database"
docker run -d --net=cora-test --name systemone-postgresql-test \
 --net-alias=systemone-postgresql \
 -e POSTGRES_DB=systemone \
 -e POSTGRES_USER=systemone \
 -e POSTGRES_PASSWORD=systemone \
 systemone-docker-postgresql:1.0-SNAPSHOT
 
echo ""
echo "wait 10s for rabbit and database to start"
sleep 10


echo ""
echo "Starting fedora as archive"
docker run -d --net=cora-test --name systemone-fedora-test \
 --mount source=systemOneArchiveTest,target=/usr/local/tomcat/fcrepo-home/data/ocfl-root \
 --network-alias=systemone-fedora \
 cora-docker-fedora:1.0-SNAPSHOT
 
echo ""
echo "Starting systemone"
# -v /mnt/data/basicstorage
docker run -d --net=cora-test --name systemone-test \
 --mount source=sharedFileStorageTest,target=/mnt/data/basicstorage \
 --link gatekeeper-test:gatekeeper \
 --link solr-test:solr \
 systemone-docker:1.0-SNAPSHOT

echo ""
echo "Starting gatekeeper"
docker run -d --net=cora-test --name gatekeeper-test \
 systemone-docker-gatekeeper:1.0-SNAPSHOT

echo ""
echo "starting idplogin"
docker run -d --net=cora-test --name idplogin-test \
 --link gatekeeper-test:gatekeeper \
 --link apptokenverifier-test:apptokenverifier \
 -e "JAVA_OPTS=-Dtoken.logout.url=http://apptokenverifier:8080/apptokenverifier/rest/" \
 cora-docker-idplogin:1.0-SNAPSHOT

echo ""
echo "Starting apptokenverifier"
docker run -d --net=cora-test --name apptokenverifier-test \
 --link gatekeeper-test:gatekeeper \
 -e "JAVA_OPTS=-Dapptokenverifier.public.path.to.system=/systemone/apptokenverifier/rest/ -Ddburl=jdbc:postgresql://systemone-postgresql:5432/systemone -Ddbusername=systemone -Ddbpassword=systemone" \
 cora-docker-apptokenverifier:1.0-SNAPSHOT

echo ""
echo "Starting solr"
docker run -d --net=cora-test --name solr-test \
 cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

echo ""
echo "------------ STARTING BINARY CONVERTERS ------------"
echo "starting binaryConverter for smallImageConverterQueue"
docker run -it -d --name systemone-smallImageConverter-test \
 --mount source=systemOneArchiveTest,target=/tmp/sharedArchiveReadable/systemOne,readonly \
 --mount source=sharedFileStorageTest,target=/tmp/sharedFileStorage/systemOne \
 --network=cora-test \
 -e coraBaseUrl="http://systemone-test:8080/systemone/rest/" \
 -e apptokenVerifierUrl="http://apptokenverifier-test:8080/apptokenverifier/rest/" \
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
docker run -it -d --name systemone-jp2Converter-test \
 --mount source=systemOneArchiveTest,target=/tmp/sharedArchiveReadable/systemOne,readonly \
 --mount source=sharedFileStorageTest,target=/tmp/sharedFileStorage/systemOne \
 --network=cora-test \
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
docker run -it -d --name systemone-pdfConverter-test \
 --mount source=systemOneArchiveTest,target=/tmp/sharedArchiveReadable/systemOne,readonly \
 --mount source=sharedFileStorageTest,target=/tmp/sharedFileStorage/systemOne \
 --network=cora-test \
 -e coraBaseUrl="http://systemone-test:8080/systemone/rest/" \
 -e apptokenVerifierUrl="http://apptokenverifier-test:8080/apptokenverifier/rest/" \
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
docker run -d --net=cora-test -p 8190:8090 --name systemone-fitnesse-test \
 --mount source=systemOneArchiveTest,target=/tmp/sharedArchiveReadable/systemOne,readonly \
 --mount source=sharedFileStorageTest,target=/tmp/sharedFileStorage/systemOne,readonly \
 --link systemone-test:systemone \
 --link apptokenverifier-test:apptokenverifier \
 --link idplogin-test:idplogin \
 systemone-docker-fitnesse:1.0-SNAPSHOT

echo ""
sleep 20
echo "All dockers started"
