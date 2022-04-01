echo "Stoping dockers"
docker stop systemone-fitnesse systemone solr idplogin apptokenverifier gatekeeper && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove dockers"
docker rm systemone-fitnesse systemone solr idplogin apptokenverifier gatekeeper && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Starting systemone"
docker run --net=cora --restart always -v /mnt/data/basicstorage -p 8210:8009 --name systemone --link gatekeeper:gatekeeper --link solr:solr -d  systemone-docker:1.0-SNAPSHOT
echo ""
echo "Starting fedora"
docker run --net=cora  --restart always --name systemone-docker-fedora -d cora-docker-fedora:1.0-SNAPSHOT
echo ""
echo "Starting gatekeeper"
docker run --net=cora --restart always  --volumes-from systemone --name gatekeeper -d  systemone-docker-gatekeeper:1.0-SNAPSHOT
echo ""
echo "starting idplogin"
docker run --net=cora --restart always -e "JAVA_OPTS=-Dmain.system.domain=https://cora.epc.ub.uu.se -Dtoken.logout.url=https://cora.epc.ub.uu.se/systemone/apptokenverifier/rest/apptoken/" -p 8212:8009 --name idplogin --link gatekeeper:gatekeeper -d  cora-docker-idplogin:1.0-SNAPSHOT
echo ""
echo "Starting apptokenverifier"
docker run --net=cora --restart always -e "JAVA_OPTS=-Dapptokenverifier.public.path.to.system=/systemone/apptokenverifier/rest/" --volumes-from systemone -p 8211:8009 --name apptokenverifier --link gatekeeper:gatekeeper -d  cora-docker-apptokenverifier:1.0-SNAPSHOT
echo ""
echo "Starting solr"
docker run --net=cora --restart always -p 8983:8983 --name solr -d cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

echo ""
echo "starting fitnesse"
docker run --net=cora --restart always  --volumes-from systemone -p 8290:8090 --name systemone-fitnesse --link systemone:systemone --link gatekeeper:gatekeeper --link idplogin:idplogin -d systemone-docker-fitnesse:1.0-SNAPSHOT