echo "Stoping dockers"
docker stop alvin-fitnesse alvin-docker-fedora alvin alvin-cora-fedora alvin-cora-postgresql alvin-solr alvin-idplogin alvin-apptokenverifier alvin-gatekeeper alvin-postgresql && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove dockers"
docker rm alvin-fitnesse alvin-docker-fedora alvin alvin-cora-fedora alvin-cora-postgresql alvin-solr alvin-idplogin alvin-apptokenverifier alvin-gatekeeper alvin-postgresql && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Starting alvin"
docker run --net=alvin-cora --restart always  -v /mnt/data/basicstorage -p 8410:8009 --name alvin-cora --link alvin-gatekeeper:gatekeeper --link alvin-solr:solr --link alvin-cora-fedora:alvin-cora-fedora --link alvin-cora-docker-postgresql:alvin-cora-docker-postgresql -d  alvin-docker-cora:1.0-SNAPSHOT
echo ""
echo "Starting fedora for archive"
docker run --net=alvin-cora  --restart always --name alvin-docker-fedora -d cora-docker-fedora:1.0-SNAPSHOT
echo ""
echo "Starting gatekeeper"
docker run --net=alvin-cora --restart always --volumes-from alvin-cora --name alvin-gatekeeper --link alvin-cora-docker-postgresql:alvin-cora-docker-postgresql -d  alvin-docker-gatekeeper:1.0-SNAPSHOT
echo ""
echo "starting idplogin"
docker run --net=alvin-cora --restart always -e "JAVA_OPTS=-Dmain.system.domain=https://cora.epc.ub.uu.se -Dtoken.logout.url=https://cora.epc.ub.uu.se/alvin/apptokenverifier/rest/apptoken/" -p 8412:8009 --name alvin-idplogin --link alvin-gatekeeper:gatekeeper -d  cora-docker-idplogin:1.0-SNAPSHOT
echo ""
echo "Starting apptokenverifier"
docker run --net=alvin-cora --restart always -e "JAVA_OPTS=-Dapptokenverifier.public.path.to.system=/alvin/apptokenverifier/rest/" --volumes-from alvin-cora -p 8411:8009 --name alvin-apptokenverifier --link alvin-gatekeeper:gatekeeper -d  cora-docker-apptokenverifier:1.0-SNAPSHOT
echo ""
echo "Starting solr"
docker run --net=alvin-cora --restart always --name alvin-solr -d cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore
echo ""
echo "Starting postgress for db (classic)" 
docker run --net=alvin-cora --restart always -e POSTGRES_DB=alvin -e POSTGRES_USER=alvin -e POSTGRES_PASSWORD=alvin --name alvin-cora-docker-postgresql -d alvin-cora-docker-postgresql-9.6
echo ""
echo "Starting postgress for db (classic)"
docker run --net=alvin-cora --restart always -e POSTGRES_DB=fedora38 -e POSTGRES_USER=fedoraAdmin -e POSTGRES_PASSWORD=fedora --name alvin-cora-postgresql -d cora-docker-postgresql:9.6
echo ""
echo "wait for fedora db to start"
sleep 20
echo ""
echo "Starting fedora (classic)"
docker run --net=alvin-cora --restart always --name alvin-cora-fedora --link alvin-cora-postgresql:postgres-fcrepo -d alvin-cora-docker-fedora-3.8.1:2.2.1

echo ""
echo "Starting fitnesse"
docker run --net=alvin-cora --restart always  --volumes-from alvin-cora -p 8490:8090 --name alvin-fitnesse --link alvin-apptokenverifier:apptokenverifier --link alvin:alvin --link alvin-idplogin:idplogin -e tokenLogoutURL=https://cora.epc.ub.uu.se/alvin/apptokenverifier/rest/apptoken/ -d alvin-cora-docker-fitnesse:1.1-SNAPSHOT

echo ""
echo "All dockers started"