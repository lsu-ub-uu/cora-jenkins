docker stop alvin-fitnesse-test alvin-therest-test alvin-solr-test alvin-apptokenverifier-test alvin-idplogin-test alvin-gatekeeper-test alvin-cora-docker-postgresql-test alvin-cora-postgresql-test alvin-cora-fedora-test && echo nothingToSeeMoveOnToNextCommand
docker rm alvin-fitnesse-test alvin-therest-test alvin-solr-test alvin-apptokenverifier-test alvin-idplogin-test alvin-gatekeeper-test alvin-cora-docker-postgresql-test alvin-cora-postgresql-test alvin-cora-fedora-test && echo nothingToSeeMoveOnToNextCommand
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

docker run --net=alvin-cora-test -v /mnt/data/basicstorage --name alvin-therest-test --link alvin-gatekeeper-test:gatekeeper --link alvin-solr-test:solr --link alvin-cora-fedora-test:alvin-cora-fedora --link alvin-cora-docker-postgresql-test:alvin-cora-docker-postgresql -d  alvin-docker-cora:1.0-SNAPSHOT
#docker run --net=alvin-cora-test --name alvin-solr-test -d solr solr-create -c coracore
docker run --net=alvin-cora-test --name alvin-solr-test -d cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore
docker run --net=alvin-cora-test --volumes-from alvin-therest-test --name alvin-gatekeeper-test --link alvin-cora-docker-postgresql-test:alvin-cora-docker-postgresql -d  alvin-docker-gatekeeper:1.0-SNAPSHOT
docker run --net=alvin-cora-test --volumes-from alvin-therest-test --name alvin-apptokenverifier-test --link alvin-gatekeeper-test:gatekeeper -d  cora-docker-apptokenverifier:1.0-SNAPSHOT
docker run --net=alvin-cora-test --restart always -e POSTGRES_DB=alvin -e POSTGRES_USER=alvin -e POSTGRES_PASSWORD=alvin --name alvin-cora-docker-postgresql-test -d alvin-cora-docker-postgresql-9.6
docker run --net=alvin-cora-test --restart always -e POSTGRES_DB=fedora38 -e POSTGRES_USER=fedoraAdmin -e POSTGRES_PASSWORD=fedora --name alvin-cora-postgresql-test -d cora-docker-postgresql:9.6
docker run --net=alvin-cora-test --name alvin-idplogin-test --link alvin-gatekeeper-test:gatekeeper -e "JAVA_OPTS=-Dtoken.logout.url=https://apptokenverifier/rest/" -d  cora-docker-idplogin:1.0-SNAPSHOT
#wait for fedora db to start
sleep 25
docker run --net=alvin-cora-test --restart always --name alvin-cora-fedora-test --link alvin-cora-postgresql-test:postgres-fcrepo -d alvin-cora-docker-fedora-3.8.1:2.2.1
#wait for fedora to start
sleep 25
docker run --net=alvin-cora-test -p 8390:8090 --name alvin-fitnesse-test --link alvin-therest-test:alvin --link alvin-apptokenverifier-test:apptokenverifier --link alvin-idplogin-test:idplogin -e tokenLogoutURL=https://apptokenverifier/rest/ -d alvin-cora-docker-fitnesse:1.1-SNAPSHOT

#wait for everything to start
sleep 40