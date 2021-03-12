set -e
DOCKERS="alvin-fitnesse alvin-cora-fedora alvin-solr alvin-apptokenverifier alvin-idplogin alvin-gatekeeper alvin-cora diva-fitnesse diva-cora-fedora  diva-solr diva-apptokenverifier diva-idplogin diva-gatekeeper diva-cora systemone-fitnesse solr apptokenverifier idplogin gatekeeper systemone diva-jsclient jsclient alvin-jsclient"
#excluded = alvin-cora-postgresql, alvin-cora-docker-postgresql, diva-cora-docker-postgresql, diva-cora-postgresql


for DOCKER in $DOCKERS
do
	echo $DOCKER
	docker exec $DOCKER java -version
	echo ""
	echo ""
done