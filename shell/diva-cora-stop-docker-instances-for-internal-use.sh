echo "Kill dockers"
docker kill diva-fitnesse-test diva-fedora-test diva-test diva-solr-test diva-apptokenverifier-test diva-idplogin-test diva-gatekeeper-test  diva-postgresql-test && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Remove dockers"
docker rm diva-fitnesse-test diva-fedora-test diva-test diva-solr-test diva-apptokenverifier-test diva-idplogin-test diva-gatekeeper-test  diva-postgresql-test && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand