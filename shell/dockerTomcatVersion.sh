set -e
DOCKERS="systemone idplogin login gatekeeper alvin alvin-idplogin alvin-login alvin-gatekeeper diva diva-idplogin diva-login diva-gatekeeper diva-synchronizer jsclient diva-jsclient alvin-jsclient"

for DOCKER in $DOCKERS
do
	echo ""
	echo ""
	echo $DOCKER
	docker exec $DOCKER /usr/local/tomcat/bin/version.sh
done