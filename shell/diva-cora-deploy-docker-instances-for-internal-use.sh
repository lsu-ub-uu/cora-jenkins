docker stop diva-cora-postgresql-test diva-mock-classic-postgresql-test \
diva-fitnesse-test diva-therest-test diva-solr-test \
diva-apptokenverifier-test diva-gatekeeper-test diva-idplogin-test \
diva-cora-fcrepo-postgresql-test \
diva-cora-fedora-test diva-synchronizer-test \
&& echo nothingToSeeMoveOnToNextCommand

docker rm diva-cora-postgresql-test diva-mock-classic-postgresql-test \
diva-fitnesse-test diva-therest-test diva-solr-test \
diva-apptokenverifier-test diva-gatekeeper-test diva-idplogin-test \
diva-cora-fcrepo-postgresql-test \
diva-cora-fedora-test diva-synchronizer-test \
&& echo nothingToSeeMoveOnToNextCommand

docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "starting diva"
docker run --net=diva-cora-test -v /mnt/data/basicstorage --name diva-therest-test \
--link diva-gatekeeper-test:gatekeeper \
--link diva-solr-test:solr \
--link diva-cora-fedora-test:diva-cora-fedora \
--link diva-mock-classic-postgresql-test:diva-mock-classic-postgresql \
--link diva-cora-postgresql-test:diva-cora-postgresql \
-d diva-docker-cora:1.0-SNAPSHOT

echo ""
echo "starting solr"
docker run --net=diva-cora-test --name diva-solr-test \
-d cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

echo ""
echo "starting gatekeeper"
docker run --net=diva-cora-test --volumes-from diva-therest-test --name diva-gatekeeper-test \
--link diva-mock-classic-postgresql-test:diva-mock-classic-postgresql \
-d diva-docker-gatekeeper:1.0-SNAPSHOT

echo ""
echo "starting apptokenverifier"
docker run --net=diva-cora-test --volumes-from diva-therest-test --name diva-apptokenverifier-test \
--link diva-gatekeeper-test:gatekeeper \
-d cora-docker-apptokenverifier:1.0-SNAPSHOT

echo ""
echo "starting idplogin"
docker run --net=diva-cora-test --name diva-idplogin-test \
--link diva-gatekeeper-test:gatekeeper \
-e "JAVA_OPTS=-Dtoken.logout.url=https://apptokenverifier/rest/" \
-d cora-docker-idplogin:1.0-SNAPSHOT

echo ""
echo "starting synchronizer"
docker run --net=diva-cora-test --name diva-synchronizer-test \
-e "JAVA_OPTS=-DapptokenVerifierURL=http://diva-apptokenverifier-test:8080/apptokenverifier/ -DbaseURL=http://diva-therest-test:8080/diva/rest/ -DuserId=${USER_ID} -DappToken=${AUTH_TOKEN}" \
-d cora-docker-synchronizer:1.0-SNAPSHOT

echo ""
echo "starting fitnesse"
docker run --net=diva-cora-test -p 8590:8090 --name diva-fitnesse-test \
--link diva-therest-test:diva \
--link diva-apptokenverifier-test:apptokenverifier \
--link diva-idplogin-test:idplogin \
--link diva-synchronizer-test:synchronizer \
-e tokenLogoutURL=https://apptokenverifier/rest/ \
-d diva-cora-docker-fitnesse:1.1-SNAPSHOT

echo ""
echo "starting fedora db"
docker run --net=diva-cora-test --restart always --name diva-cora-fcrepo-postgresql-test \
-e POSTGRES_DB=fedora32 -e POSTGRES_USER=fedoraAdmin -e POSTGRES_PASSWORD=fedora \
-d diva-cora-docker-fcrepo-postgresql:1.1-SNAPSHOT

echo ""
echo "wait for fedora db to start"
sleep 20

echo ""
echo "starting fedora"
docker run --net=diva-cora-test --restart always --name diva-cora-fedora-test \
--network-alias=diva-docker-fedora \
--link diva-cora-fcrepo-postgresql-test:postgres-fcrepo \
-d diva-cora-docker-fedora-3.2.1:1.1-SNAPSHOT

echo ""
echo "wait for fedora to start, before index connects"
sleep 10

echo ""
echo "starting db with diva mock data"
docker run --net=diva-cora-test --restart always --name diva-mock-classic-postgresql-test \
-e POSTGRES_DB=diva \
-e POSTGRES_USER=diva \
-e POSTGRES_PASSWORD=diva \
-d diva-mock-classic-postgresql:1.0-SNAPSHOT

echo ""
echo "starting db with diva data"
docker run --net=diva-cora-test --restart always --name diva-cora-postgresql-test \
-e POSTGRES_DB=diva \
-e POSTGRES_USER=diva \
-e POSTGRES_PASSWORD=diva \
-d diva-cora-postgresql:10.0-SNAPSHOT

echo ""
echo "#wait for everything to start"
sleep 40