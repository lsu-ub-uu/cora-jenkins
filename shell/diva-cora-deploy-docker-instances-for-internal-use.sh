echo ""
echo "stoping dockers"
docker stop diva-cora-postgresql-test diva-mock-classic-postgresql-test \
diva-fitnesse-httplistener-test \
diva-fitnesse-test diva-cora-test diva-solr-test \
diva-apptokenverifier-test diva-gatekeeper-test diva-idplogin-test \
diva-cora-fcrepo-postgresql-test \
diva-cora-fedora-test diva-synchronizer-test \
diva-classic-fedora-synchronizer-test \
diva-docker-fedora-test \
&& echo nothingToSeeMoveOnToNextCommand

echo ""
echo "removing dockers"
docker rm -f diva-cora-postgresql-test diva-mock-classic-postgresql-test \
diva-fitnesse-httplistener-test \
diva-fitnesse-test diva-cora-test diva-solr-test \
diva-apptokenverifier-test diva-gatekeeper-test diva-idplogin-test \
diva-cora-fcrepo-postgresql-test \
diva-cora-fedora-test diva-synchronizer-test \
diva-classic-fedora-synchronizer-test \
diva-docker-fedora-test \
&& echo nothingToSeeMoveOnToNextCommand

echo ""
echo "removing volumes"
docker volume rm -f $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand


echo "Kill dockers"
docker kill diva-fitnesse-test diva-fedora-test diva-test diva-solr-test diva-apptokenverifier-test diva-idplogin-test diva-gatekeeper-test  diva-postgresql-test && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Remove dockers"
docker rm diva-fitnesse-test diva-fedora-test diva-test diva-solr-test diva-apptokenverifier-test diva-idplogin-test diva-gatekeeper-test  diva-postgresql-test && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Starting postgresql as database"
docker run -d --name diva-postgresql-test \
 --net-alias=diva-postgresql \
 --net=diva-cora-test \
 -e POSTGRES_DB=diva \
 -e POSTGRES_USER=diva \
 -e POSTGRES_PASSWORD=diva \
 diva-docker-postgresql:1.0-SNAPSHOT

echo ""
echo "Starting fedora for archive"
docker run -d --name diva-fedora-test \
 --net-alias=diva-fedora \
 --net=diva-cora-test \
 cora-docker-fedora:1.0-SNAPSHOT

echo ""
echo "Starting diva"
docker run -d --name diva-test \
 --net-alias=diva \
 --net=diva-cora-test \
 -v /mnt/data/basicstorage \
 diva-docker-cora:1.0-SNAPSHOT

echo ""
echo "Starting gatekeeper"
docker run -d --name diva-gatekeeper-test \
 --net-alias=gatekeeper \
 --net=diva-cora-test \
 diva-docker-gatekeeper:1.0-SNAPSHOT
 
echo ""
echo "starting idplogin"
docker run -d --name diva-idplogin-test \
 --net-alias=idplogin \
 --net=diva-cora-test \
 -e "JAVA_OPTS=-Dtoken.logout.url=https://apptokenverifier/rest/" \
 cora-docker-idplogin:1.0-SNAPSHOT

echo ""
echo "Starting apptokenverifier"
docker run -d --name diva-apptokenverifier-test \
 --net-alias=apptokenverifier \
 --net=diva-cora-test \
 -e "JAVA_OPTS= -Ddburl=jdbc:postgresql://diva-postgresql:5432/diva -Ddbusername=diva -Ddbpassword=diva" \
 cora-docker-apptokenverifier:1.0-SNAPSHOT

echo ""
echo "Starting solr"
docker run -d --name diva-solr-test \
 --net-alias=solr \
 --net=diva-cora-test \
 cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

echo ""
echo "Starting fitnesse"
docker run -d --name diva-fitnesse-test \
 --net=diva-cora-test \
 -p 8590:8090  \
 -e tokenLogoutURL=https://apptokenverifier/rest/ \
 diva-cora-docker-fitnesse:1.1-SNAPSHOT

echo "wait for everything to start"
sleep 20
echo "All dockers started"
