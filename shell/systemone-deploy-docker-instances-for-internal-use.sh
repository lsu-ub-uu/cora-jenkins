docker stop systemone-fitnesse-test systemone-test solr-test apptokenverifier-test idplogin-test gatekeeper-test && echo nothingToSeeMoveOnToNextCommand
docker rm systemone-fitnesse-test systemone-test solr-test apptokenverifier-test idplogin-test gatekeeper-test && echo nothingToSeeMoveOnToNextCommand
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand

docker run --net=cora-test --name solr-test -d cora-solr:1.0-SNAPSHOT solr-precreate coracore /opt/solr/server/solr/configsets/coradefaultcore

docker run --net=cora-test -v /mnt/data/basicstorage --name systemone-test --link gatekeeper-test:gatekeeper --link solr-test:solr -d  systemone-docker:1.0-SNAPSHOT
docker run --net=cora-test --volumes-from systemone-test --name gatekeeper-test -d  systemone-docker-gatekeeper:1.0-SNAPSHOT
docker run --net=cora-test --volumes-from systemone-test --name apptokenverifier-test --link gatekeeper-test:gatekeeper -d cora-docker-apptokenverifier:1.0-SNAPSHOT
docker run --net=cora-test --name idplogin-test --link gatekeeper-test:gatekeeper -d  cora-docker-idplogin:1.0-SNAPSHOT

docker run --net=cora-test -p 8190:8090 --name systemone-fitnesse-test --link systemone-test:systemone --link apptokenverifier-test:apptokenverifier --link idplogin-test:idplogin -d systemone-docker-fitnesse:1.0-SNAPSHOT

sleep 20