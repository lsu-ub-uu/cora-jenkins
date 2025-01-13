set -e
#DOCKERS="systemone-fitnesse systemone solr idplogin login gatekeeper alvin-fitnesse alvin-cora alvin-cora-fedora alvin-solr alvin-idplogin alvin-login alvin-gatekeeper diva-fitnesse diva-cora diva-cora-fedora diva-solr diva-idplogin diva-login diva-gatekeeper diva-synchronizer jsclient diva-jsclient diva-jsclient"
DOCKERS="systemone idplogin login gatekeeper alvin-cora alvin-idplogin alvin-login alvin-gatekeeper diva-cora diva-idplogin diva-login diva-gatekeeper diva-synchronizer jsclient diva-jsclient alvin-jsclient"

for DOCKER in $DOCKERS
do
	echo ""
	echo ""
	echo $DOCKER
	docker exec $DOCKER /usr/local/tomcat/bin/version.sh
done