echo "Kill dockers"
docker kill alvin-fitnesse alvin alvin-fedora alvin-postgresql alvin-solr alvin-idplogin alvin-apptokenverifier alvin-gatekeeper && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove dockers"
docker rm alvin-fitnesse alvin alvin-fedora alvin-postgresql alvin-solr alvin-idplogin alvin-apptokenverifier alvin-gatekeeper && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand


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
 -e "JAVA_OPTS= -Ddburl=jdbc:postgresql://alvin-postgresql:5432/alvin -Ddbusername=alvin -Ddbpassword=alvin" \
 cora-docker-apptokenverifier:1.0-SNAPSHOT
 
echo ""
echo "Starting solr"
docker run -d --name alvin-solr \
 --net-alias=solr \
 --net=alvin-cora \
--restart unless-stopped  \
 cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

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