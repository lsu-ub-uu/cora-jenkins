echo "Kill dockers"
docker kill alvin-fitnesse-test alvin-fedora-test alvin-test alvin-solr-test alvin-apptokenverifier-test alvin-idplogin-test alvin-gatekeeper-test  alvin-postgresql-test && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Remove dockers"
docker rm alvin-fitnesse-test alvin-fedora-test alvin-test alvin-solr-test alvin-apptokenverifier-test alvin-idplogin-test alvin-gatekeeper-test  alvin-postgresql-test && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand