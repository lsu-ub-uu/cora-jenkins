docker stop diva-cora-docker-postgresql-test diva-fitnesse-test diva-therest-test diva-solr-test diva-apptokenverifier-test diva-gatekeeper-test diva-idplogin-test diva-cora-postgresql-test diva-cora-fedora-test && echo nothingToSeeMoveOnToNextCommand
docker rm diva-cora-docker-postgresql-test diva-fitnesse-test diva-therest-test diva-solr-test diva-apptokenverifier-test diva-gatekeeper-test diva-idplogin-test diva-cora-postgresql-test diva-cora-fedora-test && echo nothingToSeeMoveOnToNextCommand
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand
#diva
docker run --net=diva-cora-test -v /mnt/data/basicstorage --name diva-therest-test --link diva-gatekeeper-test:gatekeeper --link diva-solr-test:solr --link diva-cora-fedora-test:diva-cora-fedora --link diva-cora-docker-postgresql-test:diva-cora-docker-postgresql -d  diva-docker-cora:1.0-SNAPSHOT
#solr
docker run --net=diva-cora-test --name diva-solr-test -d cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore
#gatekeeper
docker run --net=diva-cora-test --volumes-from diva-therest-test --name diva-gatekeeper-test --link diva-cora-docker-postgresql-test:diva-cora-docker-postgresql -d diva-docker-gatekeeper:1.0-SNAPSHOT
#apptokenverifier
docker run --net=diva-cora-test --volumes-from diva-therest-test --name diva-apptokenverifier-test --link diva-gatekeeper-test:gatekeeper -d  cora-docker-apptokenverifier:1.0-SNAPSHOT
#idplogin
docker run --net=diva-cora-test --name diva-idplogin-test --link diva-gatekeeper-test:gatekeeper -e "JAVA_OPTS=-Dtoken.logout.url=https://apptokenverifier/rest/" -d  cora-docker-idplogin:1.0-SNAPSHOT
#fitnesse
docker run --net=diva-cora-test -p 8590:8090 --name diva-fitnesse-test --link diva-therest-test:diva --link diva-apptokenverifier-test:apptokenverifier --link diva-idplogin-test:idplogin -e tokenLogoutURL=https://apptokenverifier/rest/ -d diva-cora-docker-fitnesse:1.0-SNAPSHOT
#fedora with db
docker run --net=diva-cora-test --restart always -e POSTGRES_DB=fedora32 -e POSTGRES_USER=fedoraAdmin -e POSTGRES_PASSWORD=fedora --name diva-cora-postgresql-test -d diva-cora-docker-fcrepo-postgresql:1.0.0
#wait for fedora db to start
sleep 20
docker run --net=diva-cora-test --restart always --name diva-cora-fedora-test --link diva-cora-postgresql-test:postgres-fcrepo -d diva-cora-docker-fedora-3.2.1:1.0.2
#wait for fedora to start
#sleep 60

#db with diva data
docker run --net=diva-cora-test --restart always -e POSTGRES_DB=diva -e POSTGRES_USER=diva -e POSTGRES_PASSWORD=diva --name diva-cora-docker-postgresql-test -d diva-cora-docker-postgresql

#wait for everything to start
sleep 40