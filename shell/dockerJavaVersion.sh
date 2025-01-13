set -e
DOCKERS="systemone-fitnesse systemone solr idplogin login gatekeeper alvin-fitnesse alvin-cora alvin-cora-fedora alvin-solr alvin-idplogin alvin-login alvin-gatekeeper diva-fitnesse diva-cora diva-cora-fedora diva-solr diva-idplogin diva-login diva-gatekeeper diva-synchronizer jsclient diva-jsclient diva-jsclient"
#excluded = alvin-cora-postgresql, alvin-cora-docker-postgresql, diva-cora-docker-postgresql, diva-cora-postgresql fitnesse therest 


for DOCKER in $DOCKERS
do
	echo ""
	echo ""
	echo $DOCKER
	docker exec $DOCKER java -version
done