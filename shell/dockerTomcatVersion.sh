set -e
DOCKERS=$(docker ps --format "{{.Names}}")

for DOCKER in $DOCKERS
do
	echo ""
	echo ""
	echo $DOCKER
	docker exec $DOCKER /usr/local/tomcat/bin/version.sh || echo "Failed to execute version.sh in $DOCKER"
done