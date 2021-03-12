set -e
DOCKERS="systemone-fitnesse systemone solr idplogin apptokenverifier gatekeeper alvin-fitnesse alvin-cora alvin-cora-fedora alvin-solr alvin-idplogin alvin-apptokenverifier alvin-gatekeeper diva-fitnesse diva-cora diva-cora-fedora diva-solr diva-idplogin diva-apptokenverifier diva-gatekeeper diva-synchronizer"
#excluded = alvin-cora-postgresql, alvin-cora-docker-postgresql, diva-cora-docker-postgresql, diva-cora-postgresql fitnesse therest 


for DOCKER in $DOCKERS
do
	echo ""
	echo ""
	echo $DOCKER
	docker exec $DOCKER java -version
done