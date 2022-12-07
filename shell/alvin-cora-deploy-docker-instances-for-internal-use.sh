echo "Stoping dockers"
docker stop alvin-fitnesse-test alvin-docker-fedora-test alvin-test alvin-solr-test alvin-apptokenverifier-test alvin-idplogin-test alvin-gatekeeper-test  alvin-postgresql-test alvin-cora-fedora-test && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Remove dockers"
docker rm alvin-fitnesse-test alvin-docker-fedora-test alvin-test alvin-solr-test alvin-apptokenverifier-test alvin-idplogin-test alvin-gatekeeper-test  alvin-postgresql-test alvin-cora-fedora-test && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Starting postgresql as database"
docker run -d --name alvin-postgresql-test \
 --net=alvin-cora-test \
 --net-alias=alvin-postgresql \
 -e POSTGRES_DB=alvin \
 -e POSTGRES_USER=alvin \
 -e POSTGRES_PASSWORD=alvin \
 alvin-docker-postgresql:1.0-SNAPSHOT

echo ""
echo "Starting fedora for archive"
docker run -d --name alvin-docker-fedora-test \
 --net=alvin-cora-test \
 --network-alias=alvin-docker-fedora \
 cora-docker-fedora:1.0-SNAPSHOT

echo ""
echo "Starting alvin"
docker run -d --name alvin-test \
 --net=alvin-cora-test \ 
 --net-alias=alvin \
 -v /mnt/data/basicstorage
 alvin-docker-cora:1.0-SNAPSHOT

echo ""
echo "Starting gatekeeper"
docker run -d --name alvin-gatekeeper-test \
 --net=alvin-cora-test \
 --net-alias=gatekeeper \
 alvin-docker-gatekeeper:1.0-SNAPSHOT
echo ""
echo "starting idplogin"
docker run -d --net=alvin-cora-test --name alvin-idplogin-test \
 --net-alias=idplogin \
 -e "JAVA_OPTS=-Dtoken.logout.url=https://apptokenverifier/rest/" \
 cora-docker-idplogin:1.0-SNAPSHOT

echo ""
echo "Starting apptokenverifier"
docker run -d --name alvin-apptokenverifier-test \
 --net=alvin-cora-test \ 
 --net-alias=apptokenverifier \
 -e "JAVA_OPTS= -Ddburl=jdbc:postgresql://alvin-postgresql:5432/alvin -Ddbusername=alvin -Ddbpassword=alvin" \
 cora-docker-apptokenverifier:1.0-SNAPSHOT

echo ""
echo "Starting solr"
docker run -d --name alvin-solr-test \
 --net=alvin-cora-test \
  --net-alias=solr \
 cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

echo ""
echo "Starting fitnesse"
docker run -d --name alvin-fitnesse-test \
 --net=alvin-cora-test \
 -p 8390:8090  \
 -e tokenLogoutURL=https://apptokenverifier/rest/ \
 alvin-cora-docker-fitnesse:1.1-SNAPSHOT

echo "wait for everything to start"
sleep 20
echo "All dockers started"
