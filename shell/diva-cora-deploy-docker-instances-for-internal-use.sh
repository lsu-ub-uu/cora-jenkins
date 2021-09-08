docker stop diva-cora-docker-postgresql-test diva-fitnesse-test diva-therest-test diva-solr-test \
diva-apptokenverifier-test diva-gatekeeper-test diva-idplogin-test\ 
diva-docker-mock-classic-postgresql-test diva-cora-postgresql-test \
diva-cora-fedora-test diva-synchronizer-test diva-docker-index-test \
&& echo nothingToSeeMoveOnToNextCommand

docker rm diva-cora-docker-postgresql-test diva-fitnesse-test diva-therest-test diva-solr-test \
diva-apptokenverifier-test diva-gatekeeper-test diva-idplogin-test \
diva-docker-mock-classic-postgresql-test diva-cora-postgresql-test \
diva-cora-fedora-test diva-synchronizer-test diva-docker-index-test \
&& echo nothingToSeeMoveOnToNextCommand

docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

#diva
docker run --net=diva-cora-test -v /mnt/data/basicstorage --name diva-therest-test \
--link diva-gatekeeper-test:gatekeeper \
--link diva-solr-test:solr \
--link diva-cora-fedora-test:diva-cora-fedora \
--link diva-docker-mock-classic-postgresql-test:diva-docker-mock-classic-postgresql \
--link diva-cora-docker-postgresql-test:diva-cora-docker-postgresql \
-d diva-docker-cora:1.0-SNAPSHOT

#solr
docker run --net=diva-cora-test --name diva-solr-test \
-d cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

#gatekeeper
docker run --net=diva-cora-test --volumes-from diva-therest-test --name diva-gatekeeper-test \
--link diva-cora-docker-postgresql-test:diva-cora-docker-postgresql \
-d diva-docker-gatekeeper:1.0-SNAPSHOT

#apptokenverifier
docker run --net=diva-cora-test --volumes-from diva-therest-test --name diva-apptokenverifier-test \
--link diva-gatekeeper-test:gatekeeper \
-d cora-docker-apptokenverifier:1.0-SNAPSHOT

#idplogin
docker run --net=diva-cora-test --name diva-idplogin-test \
--link diva-gatekeeper-test:gatekeeper \
-e "JAVA_OPTS=-Dtoken.logout.url=https://apptokenverifier/rest/" \
-d cora-docker-idplogin:1.0-SNAPSHOT

#synchronizer
docker run --net=diva-cora-test --name diva-synchronizer-test \
-e "JAVA_OPTS=-DapptokenVerifierURL=http://diva-apptokenverifier-test:8080/apptokenverifier/ -DbaseURL=http://diva-therest-test:8080/diva/rest/ -DuserId=${USER_ID} -DappToken=${AUTH_TOKEN}" \
-d cora-docker-synchronizer:1.0-SNAPSHOT
#fitnesse
docker run --net=diva-cora-test -p 8590:8090 --name diva-fitnesse-test \
--link diva-therest-test:diva \
--link diva-apptokenverifier-test:apptokenverifier \
--link diva-idplogin-test:idplogin \
--link diva-synchronizer-test:synchronizer \
-e tokenLogoutURL=https://apptokenverifier/rest/ \
-d diva-cora-docker-fitnesse:1.1-SNAPSHOT

#fedora db
docker run --net=diva-cora-test --restart always --name diva-cora-postgresql-test \
-e POSTGRES_DB=fedora32 -e POSTGRES_USER=fedoraAdmin -e POSTGRES_PASSWORD=fedora \
-d diva-cora-docker-fcrepo-postgresql:1.1-SNAPSHOT
#wait for fedora db to start
sleep 20

#fedora
docker run --net=diva-cora-test --restart always --name diva-cora-fedora-test \
--network-alias=diva-docker-fedora \
--link diva-cora-postgresql-test:postgres-fcrepo \
-d diva-cora-docker-fedora-3.2.1:1.1-SNAPSHOT
#wait for fedora to start, before index connects
sleep 10

#indexer
docker run -d --name diva-docker-index-test \
--network=diva-cora-test \
-e hostname="diva-cora-fedora-test" \
-e port="61616" \
-e routingKey="fedora.apim.update" \
-e username="fedoraAdmin" \
-e password="fedora" \
-e appTokenVerifierUrl="http://diva-apptokenverifier-test:8080/apptokenverifier/" \
-e baseUrl="http://diva-therest-test:8080/diva/rest/" \
-e userId="coraUser:490742519075086" \
-e appToken="2e57eb36-55b9-4820-8c44-8271baab4e8e" \
diva-docker-index:1.0-SNAPSHOT

#db with diva mock data
docker run --net=diva-cora-test --restart always --name diva-docker-mock-classic-postgresql-test \
-e POSTGRES_DB=diva \
-e POSTGRES_USER=diva \ 
-e POSTGRES_PASSWORD=diva \ 
-d diva-docker-mock-classic-postgresql:1.0-SNAPSHOT

#db with diva data
docker run --net=diva-cora-test --restart always --name diva-cora-docker-postgresql-test \
-e POSTGRES_DB=diva \
-e POSTGRES_USER=diva \ 
-e POSTGRES_PASSWORD=diva \ 
-d diva-cora-docker-postgresql:10.0-SNAPSHOT

#wait for everything to start
sleep 40