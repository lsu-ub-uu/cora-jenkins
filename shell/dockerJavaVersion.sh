set -e
DOCKERS="alvin-fitnesse alvin-cora-fedora alvin-cora-postgresql alvin-cora-docker-postgresql alvin-solr alvin-apptokenverifier alvin-idplogin alvin-gatekeeper alvin-cora diva-cora-docker-postgresql diva-fitnesse diva-cora-fedora diva-cora-postgresql diva-solr diva-apptokenverifier diva-idplogin diva-gatekeeper diva-cora systemone-fitnesse solr apptokenverifier idplogin gatekeeper systemone diva-jsclient jsclient alvin-jsclient"

for DOCKER in $DOCKERS
do
	echo $DOCKER
	docker exec $DOCKER -version
done