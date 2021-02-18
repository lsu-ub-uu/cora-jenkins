docker stop diva-cora-docker-postgresql diva-fitnesse diva-cora diva-cora-fedora diva-cora-postgresql diva-solr diva-idplogin diva-apptokenverifier diva-gatekeeper && echo nothingToSeeMoveOnToNextCommand
docker rm diva-cora-docker-postgresql diva-fitnesse diva-cora diva-cora-fedora diva-cora-postgresql diva-solr diva-idplogin diva-apptokenverifier diva-gatekeeper && echo nothingToSeeMoveOnToNextCommand
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand
#diva
docker run --net=diva-cora --restart always -v /mnt/data/basicstorage -p 8610:8009 --name diva-cora --link diva-gatekeeper:gatekeeper --link diva-solr:solr --link diva-cora-fedora:diva-cora-fedora --link diva-cora-docker-postgresql:diva-cora-docker-postgresql -d  diva-docker-cora:1.0-SNAPSHOT
#solr
docker run --net=diva-cora --restart always --name diva-solr -d cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore
#gatekeeper
docker run --net=diva-cora --restart always  --volumes-from diva-cora --name diva-gatekeeper --link diva-cora-docker-postgresql:diva-cora-docker-postgresql -d diva-docker-gatekeeper:1.0-SNAPSHOT
#apptokenverifier
docker run --net=diva-cora --restart always -e "JAVA_OPTS=-Dapptokenverifier.public.path.to.system=/diva/apptokenverifier/rest/" --volumes-from diva-cora -p 8611:8009 --name diva-apptokenverifier --link diva-gatekeeper:gatekeeper -d  cora-docker-apptokenverifier:1.0-SNAPSHOT
#idplogin
docker run --net=diva-cora --restart always -e "JAVA_OPTS=-Dmain.system.domain=https://cora.epc.ub.uu.se -Dtoken.logout.url=https://cora.epc.ub.uu.se/diva/apptokenverifier/rest/apptoken/" -p 8612:8009 --name diva-idplogin --link diva-gatekeeper:gatekeeper -d  cora-docker-idplogin:1.0-SNAPSHOT
#synchronizer
docker run --net=diva-cora --restart always --name diva-synchronizer -e "JAVA_OPTS=-DapptokenVerifierURL=http://diva-apptokenverifier:8080/apptokenverifier/ -DbaseURL=http://diva-cora:8080/diva/rest/ -DuserId=${USER_ID} -DappToken=${AUTH_TOKEN}" -d cora-docker-synchronizer:1.0-SNAPSHOT
#fitnesse
docker run --net=diva-cora --restart always  --volumes-from diva-cora -p 8690:8090 --name diva-fitnesse --link diva-cora:diva --link diva-apptokenverifier:apptokenverifier --link diva-idplogin:idplogin --link diva-synchronizer:synchronizer -e tokenLogoutURL=https://cora.epc.ub.uu.se/diva/apptokenverifier/rest/apptoken/ -d diva-cora-docker-fitnesse:1.0-SNAPSHOT
#fedora with db
docker run --net=diva-cora --restart always -e POSTGRES_DB=fedora32 -e POSTGRES_USER=fedoraAdmin -e POSTGRES_PASSWORD=fedora --name diva-cora-postgresql -d diva-cora-docker-fcrepo-postgresql:1.0.0
#wait for fedora db to start
sleep 20
docker run --net=diva-cora --restart always --name diva-cora-fedora --link diva-cora-postgresql:postgres-fcrepo -d diva-cora-docker-fedora-3.2.1:1.0.2
#db with diva data
docker run --net=diva-cora --restart always -e POSTGRES_DB=diva -e POSTGRES_USER=diva -e POSTGRES_PASSWORD=diva --name diva-cora-docker-postgresql -d diva-cora-docker-postgresql
