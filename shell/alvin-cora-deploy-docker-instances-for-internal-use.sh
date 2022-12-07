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
 --net=alvin-test \
 --net-alias=alvin-postgresql \
 -e POSTGRES_DB=alvin \
 -e POSTGRES_USER=alvin \
 -e POSTGRES_PASSWORD=alvin \
 alvin-docker-postgresql:1.0-SNAPSHOT

echo ""
echo "Starting fedora for archive"
docker run --net=alvin-test  --name alvin-docker-fedora-test --network-alias=alvin-docker-fedora -d cora-docker-fedora:1.0-SNAPSHOT

echo ""
echo "Starting alvin"
docker run --net=alvin-cora-test -v /mnt/data/basicstorage --name alvin-test --link alvin-gatekeeper-test:gatekeeper --link alvin-solr-test:solr --link alvin-cora-fedora-test:alvin-cora-fedora -d  alvin-docker-cora:1.0-SNAPSHOT

echo ""
echo "Starting gatekeeper"
docker run --net=alvin-cora-test --name alvin-gatekeeper-test --link alvin-cora-docker-postgresql-test:alvin-cora-docker-postgresql \
-d  alvin-docker-gatekeeper:1.0-SNAPSHOT
echo ""
echo "starting idplogin"
docker run --net=alvin-cora-test --name alvin-idplogin-test --link alvin-gatekeeper-test:gatekeeper -e "JAVA_OPTS=-Dtoken.logout.url=https://apptokenverifier/rest/" -d  cora-docker-idplogin:1.0-SNAPSHOT

echo ""
echo "Starting apptokenverifier"
docker run --net=alvin-cora-test  --name alvin-apptokenverifier-test \
 --link alvin-gatekeeper-test:gatekeeper \
 -e "JAVA_OPTS= -Ddburl=jdbc:postgresql://alvin-postgresql:5432/alvin -Ddbusername=alvin -Ddbpassword=alvin" \
 -d  cora-docker-apptokenverifier:1.0-SNAPSHOT

echo ""
echo "Starting solr"
docker run --net=alvin-cora-test --name alvin-solr-test -d cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

echo ""
echo "Starting fitnesse"
docker run --net=alvin-cora-test -p 8390:8090 --name alvin-fitnesse-test --link alvin-therest-test:alvin --link alvin-apptokenverifier-test:apptokenverifier --link alvin-idplogin-test:idplogin -e tokenLogoutURL=https://apptokenverifier/rest/ -d alvin-cora-docker-fitnesse:1.1-SNAPSHOT

echo "wait for everything to start"
sleep 20
echo "All dockers started"
