
echo ""
echo "stoping dockers"
docker stop diva-mock-classic-postgresql diva-cora-postgresql \
diva-fitnesse diva-cora diva-cora-fedora \
diva-cora-fcrepo-postgresql \
diva-solr diva-idplogin diva-apptokenverifier diva-gatekeeper diva-synchronizer \
diva-classic-fedora-synchronizer \
&& echo nothingToSeeMoveOnToNextCommand

echo ""
echo "removing dockers"
docker rm -f diva-mock-classic-postgresql diva-cora-postgresql \
diva-fitnesse diva-cora diva-cora-fedora \
diva-cora-fcrepo-postgresql \
diva-solr diva-idplogin diva-apptokenverifier diva-gatekeeper diva-synchronizer \
diva-classic-fedora-synchronizer \
&& echo nothingToSeeMoveOnToNextCommand

echo ""
echo "removing volumes"
docker volume rm -f $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "starting dockers"

echo ""
echo "starting diva"
docker run --net=diva-cora --restart always -v /mnt/data/basicstorage -p 8610:8009 --name diva-cora \
--link diva-gatekeeper:gatekeeper \
--link diva-solr:solr \
--link diva-cora-fedora:diva-cora-fedora \
--link diva-mock-classic-postgresql:diva-docker-mock-classic-postgresql \
--link diva-cora-postgresql:diva-cora-docker-postgresql \
-d  diva-docker-cora:1.0-SNAPSHOT

echo ""
echo "starting solr"
docker run --net=diva-cora --restart always --name diva-solr \
-d cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

echo ""
echo "starting gatekeeper"
docker run --net=diva-cora --restart always  --volumes-from diva-cora --name diva-gatekeeper \
--link diva-mock-classic-postgresql:diva-docker-mock-classic-postgresql \
-d diva-docker-gatekeeper:1.0-SNAPSHOT

echo ""
echo "starting apptokenverifier"
docker run --net=diva-cora --restart always --name diva-apptokenverifier \
--network-alias=diva-apptokenverifier \
-e "JAVA_OPTS=-Dapptokenverifier.public.path.to.system=/diva/apptokenverifier/rest/" \
--volumes-from diva-cora -p 8611:8009 \
--link diva-gatekeeper:gatekeeper \
-d cora-docker-apptokenverifier:1.0-SNAPSHOT

echo ""
echo "starting idplogin"
docker run --net=diva-cora --restart always --name diva-idplogin \
-e "JAVA_OPTS=-Dmain.system.domain=https://cora.epc.ub.uu.se -Dtoken.logout.url=https://cora.epc.ub.uu.se/diva/apptokenverifier/rest/apptoken/" \
-p 8612:8009 \
--link diva-gatekeeper:gatekeeper \
-d cora-docker-idplogin:1.0-SNAPSHOT

echo ""
echo "starting synchronizer"
docker run --net=diva-cora --restart always --name diva-synchronizer \
-e "JAVA_OPTS=-DapptokenVerifierURL=http://diva-apptokenverifier:8080/apptokenverifier/ -DbaseURL=http://diva-cora:8080/diva/rest/ -DuserId=${USER_ID} -DappToken=${AUTH_TOKEN}" \
-d cora-docker-synchronizer:1.0-SNAPSHOT

echo ""
echo "starting fitnesse"
docker run --net=diva-cora --restart always --name diva-fitnesse \
--volumes-from diva-cora -p 8690:8090 \
--link diva-cora:diva \
--link diva-apptokenverifier:apptokenverifier \
--link diva-idplogin:idplogin \
--link diva-synchronizer:synchronizer \
-e tokenLogoutURL=https://cora.epc.ub.uu.se/diva/apptokenverifier/rest/apptoken/ \
-d diva-cora-docker-fitnesse:1.1-SNAPSHOT

echo ""
echo "starting fedora with db"
docker run --net=diva-cora --restart always --name diva-cora-fcrepo-postgresql \
-e POSTGRES_DB=fedora32 \
-e POSTGRES_USER=fedoraAdmin \
-e POSTGRES_PASSWORD=fedora \
-d diva-cora-docker-fcrepo-postgresql:1.1-SNAPSHOT

echo ""
echo "starting wait for fedora db to start"
sleep 20

echo ""
echo "starting fedora"
docker run --net=diva-cora --restart always --name diva-cora-fedora \
--network-alias=diva-docker-fedora \
--link diva-cora-fcrepo-postgresql:postgres-fcrepo \
-d diva-cora-docker-fedora-3.2.1:1.1-SNAPSHOT

echo ""
echo "starting wait for fedora to start, before index connects"
sleep 20

echo ""
echo "starting db with diva mock data"
docker run --net=diva-cora --restart always --name diva-mock-classic-postgresql \
-e POSTGRES_DB=diva \
-e POSTGRES_USER=diva \
-e POSTGRES_PASSWORD=diva \
-d diva-docker-mock-classic-postgresql:1.0-SNAPSHOT

echo ""
echo "starting db with diva data"
docker run --net=diva-cora --restart always --name diva-cora-postgresql \
--network-alias=diva-cora-postgresql \
-e POSTGRES_DB=diva \
-e POSTGRES_USER=diva \
-e POSTGRES_PASSWORD=diva \
-d diva-cora-docker-postgresql:10.0-SNAPSHOT

echo "starting diva classic fedora synchronizer"
docker run --net=diva-cora --restart always --name diva-classic-fedora-synchronizer \
-e messaginghostname="diva-docker-fedora" \
-e messagingport="61616" \
-e messagingroutingKey="fedora.apim.update" \
-e messagingusername="fedoraAdmin" \
-e messagingpassword="fedora" \
-e databaseurl="jdbc:postgresql://diva-cora-postgresql:5432/diva" \
-e databaseuser="diva" \
-e databasepassword="diva" \
-e fedorabaseUrl="http://diva-docker-fedora:8088/fedora/" \
-e coraapptokenVerifierUrl="http://diva-apptokenverifier:8080/apptokenverifier/" \
-e corabaseUrl="http://diva-cora:8080/diva/rest/" \
-e corauserId="coraUser:490742519075086" \
-e coraapptoken="2e57eb36-55b9-4820-8c44-8271baab4e8e" \
-d diva-docker-classicfedorasynchronizer:1.0-SNAPSHOT

echo ""
echo "dockers up and running"
echo ""

echo "Indexing persons for better experience in reactClient"
##get authToken
loginData=$(curl -s -X POST https://cora.epc.ub.uu.se/diva/apptokenverifier/rest/apptoken/coraUser:1299694997493014 --data f48a2fb3-814e-404a-a2dd-9860aff4e328)
echo ""
echo "Login Data:";
echo "$loginData";
echo ""

authToken=${loginData:43:36}
echo "Auth token:";
echo "$authToken";
echo ""

#index persons
indexResult=$(curl -s -X POST -H "AuthToken: $authToken" -H 'Accept: application/vnd.uub.record+json' -H 'Content-Type: application/vnd.uub.record+json' https://cora.epc.ub.uu.se/diva/rest/record/index/person/ --data '{"name":"indexSettings","children":[]}')
echo "Index result:";
echo "$indexResult";

