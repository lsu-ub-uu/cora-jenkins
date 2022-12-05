echo "Stoping dockers"
docker stop systemone-fitnesse-test systemone-docker-fedora-test systemone-docker-postgresql-test systemone-docker-fedora-test systemone-test solr-test apptokenverifier-test idplogin-test gatekeeper-test && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove dockers"
docker rm systemone-fitnesse-test systemone-docker-fedora-test systemone-docker-postgresql-test systemone-docker-fedora-test systemone-test solr-test apptokenverifier-test idplogin-test gatekeeper-test && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Starting postgresql as database"
docker run -d -net=cora-test --name systemone-docker-postgresql-test \
 --net-alias=systemone-docker-postgresql \
 -e POSTGRES_DB=systemone \
 -e POSTGRES_USER=systemone \
 -e POSTGRES_PASSWORD=systemone \
 systemone-docker-postgresql:1.0-SNAPSHOT

echo ""
echo "Starting fedora as archive"
docker run -d --net=cora-test --name systemone-docker-fedora-test \
 --mount source=systemOneArchiveTest,target=/usr/local/tomcat/fcrepo-home/data/ocfl-root \
 --network-alias=systemone-docker-fedora \
 cora-docker-fedora:1.0-SNAPSHOT
 
echo ""
echo "Starting systemone"
docker run -d --net=cora-test -v /mnt/data/basicstorage --name systemone-test \
 --link gatekeeper-test:gatekeeper --link solr-test:solr 
 systemone-docker:1.0-SNAPSHOT


echo ""
echo "Starting gatekeeper"
docker run -d --net=cora-test --name gatekeeper-test \
 --volumes-from systemone-test \
 systemone-docker-gatekeeper:1.0-SNAPSHOT

echo ""
echo "starting idplogin"
docker run -d --net=cora-test --name idplogin-test \
--link gatekeeper-test:gatekeeper\
cora-docker-idplogin:1.0-SNAPSHOT

echo ""
echo "Starting apptokenverifier"
docker run -d --net=cora-test --name apptokenverifier-test \
 --volumes-from systemone-test  --link gatekeeper-test:gatekeeper \
 cora-docker-apptokenverifier:1.0-SNAPSHOT

echo ""
echo "Starting solr"
docker run -d --net=cora-test --name solr-test \
 cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

echo ""
echo "starting fitnesse"
docker run -d --net=cora-test -p 8190:8090 --name systemone-fitnesse-test \
 --mount source=systemOneArchiveTest,target=/tmp/sharedArchiveReadable/systemOne,readonly \
 --link systemone-test:systemone --link apptokenverifier-test:apptokenverifier --link idplogin-test:idplogin \
 systemone-docker-fitnesse:1.0-SNAPSHOT

echo ""
sleep 20
echo "All dockers started"
