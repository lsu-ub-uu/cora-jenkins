echo "Kill dockers"
docker kill diva-fitnesse diva diva-fedora diva-postgresql diva-solr diva-idplogin diva-apptokenverifier diva-gatekeeper && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove dockers"
docker rm diva-fitnesse diva diva-fedora diva-postgresql diva-solr diva-idplogin diva-apptokenverifier diva-gatekeeper && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand


echo ""
echo "Starting postgresql as database"
docker run -d --name diva-postgresql \
 --net=diva-cora \
 --net-alias=diva-postgresql \
 -e POSTGRES_DB=diva \
 -e POSTGRES_USER=diva \
 -e POSTGRES_PASSWORD=diva \
 diva-docker-postgresql:1.0-SNAPSHOT

echo ""
echo "Starting fedora for archive"
docker run -d --name diva-fedora \
 --net=diva-cora \
--restart unless-stopped  \
 cora-docker-fedora:1.0-SNAPSHOT

echo ""
echo "Starting diva"
docker run -d --name diva \
 --net=diva-cora \
 -p 8610:8009 \
--restart unless-stopped  \
 -v /mnt/data/basicstorage  \
 diva-docker-cora:1.0-SNAPSHOT

echo ""
echo "Starting gatekeeper"
docker run -d --name diva-gatekeeper \
 --net-alias=gatekeeper \
 --net=diva-cora \
--restart unless-stopped  \
 diva-docker-gatekeeper:1.0-SNAPSHOT
 
echo ""
echo "starting idplogin"
docker run -d --name diva-idplogin \
 --net-alias=idplogin \
 --net=diva-cora \
 -p 8612:8009 \
--restart unless-stopped  \
 -e "JAVA_OPTS=-Dmain.system.domain=https://cora.epc.ub.uu.se -Dtoken.logout.url=https://cora.epc.ub.uu.se/diva/apptokenverifier/rest/apptoken/" \
 cora-docker-idplogin:1.0-SNAPSHOT
 
echo ""
echo "Starting apptokenverifier"
docker run -d --name diva-apptokenverifier \
 --net-alias=apptokenverifier \
 --net=diva-cora \
 -p 8611:8009 \
--restart unless-stopped  \
 -e "JAVA_OPTS= -Ddburl=jdbc:postgresql://diva-postgresql:5432/diva -Ddbusername=diva -Ddbpassword=diva" \
 cora-docker-apptokenverifier:1.0-SNAPSHOT
 
echo ""
echo "Starting solr"
docker run -d --name diva-solr \
 --net-alias=solr \
 --net=diva-cora \
--restart unless-stopped  \
 cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

echo ""
echo "Starting fitnesse"
docker run -d --name diva-fitnesse \
 --net=diva-cora \
--restart unless-stopped  \
 -p 8690:8090 \
 -e tokenLogoutURL=https://cora.epc.ub.uu.se/diva/apptokenverifier/rest/apptoken/ \
 diva-cora-docker-fitnesse:1.1-SNAPSHOT

echo ""
echo "All dockers started"