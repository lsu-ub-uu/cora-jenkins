echo "Kill dockers"
docker kill systemone-rabbitmq-test systemone-smallImageConverter-test systemone-jp2Converter-test systemone-pdfConverter-test systemone-fitnesse-test systemone-fedora-test systemone-postgresql-test systemone-test solr-test apptokenverifier-test idplogin-test gatekeeper-test && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove dockers"
docker rm systemone-rabbitmq-test systemone-smallImageConverter-test systemone-jp2Converter-test systemone-pdfConverter-test systemone-fitnesse-test systemone-fedora-test systemone-postgresql-test systemone-test solr-test apptokenverifier-test idplogin-test gatekeeper-test && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand