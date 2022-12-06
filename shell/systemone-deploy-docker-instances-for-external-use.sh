echo "Stoping dockers"
docker stop systemone-fitnesse systemone-docker-postgresql systemone-docker-fedora systemone solr idplogin apptokenverifier gatekeeper && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove dockers"
docker rm systemone-fitnesse systemone-docker-postgresql systemone-docker-fedora systemone solr idplogin apptokenverifier gatekeeper && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Starting postgresql as database"
docker run -d --name systemone-docker-postgresql \
 --net=cora \
 --restart unless-stopped  \
 --net-alias=systemone-docker-postgresql \
 -e POSTGRES_DB=systemone \
 -e POSTGRES_USER=systemone \
 -e POSTGRES_PASSWORD=systemone \
 systemone-docker-postgresql:1.0-SNAPSHOT

echo ""
echo "Starting fedora for archive"
docker run -d --name systemone-docker-fedora \
 --net=cora \
 --restart unless-stopped \
 --mount source=systemOneArchive,target=/usr/local/tomcat/fcrepo-home/data/ocfl-root \
 --network-alias=systemone-docker-fedora \
 cora-docker-fedora:1.0-SNAPSHOT

echo ""
echo "Starting systemone"
docker run -d  --name systemone \
 --net=cora \
 --restart unless-stopped \
 -v /mnt/data/basicstorage \
 -p 8210:8009 \
 --link gatekeeper:gatekeeper \
 --link solr:solr \
 systemone-docker:1.0-SNAPSHOT

echo ""
echo "Starting gatekeeper"
docker run -d --name gatekeeper \
 --net=cora \
 --restart unless-stopped  \
 --volumes-from systemone \
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
 -e "JAVA_OPTS=-Dapptokenverifier.public.path.to.system=/systemone/apptokenverifier/rest/ -Ddburl=jdbc:postgresql://systemone-docker-postgresql:5432/systemone -Ddbusername=systemone -Ddbpassword=systemone" \
 --volumes-from systemone \
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
echo "starting fitnesse"
docker run -d --name systemone-fitnesse \
 --net=cora \
 -p 8290:8090 \
 --mount source=systemOneArchive,target=/tmp/sharedArchiveReadable/systemOne,readonly \
 --link systemone:systemone \
 --link apptokenverifier:apptokenverifier \
 --link idplogin:idplogin \
 systemone-docker-fitnesse:1.0-SNAPSHOT
 
 