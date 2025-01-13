set -e

DOCKERS=$(docker ps --format "{{.Names}}")

for DOCKER in $DOCKERS
do
	echo ""
	echo ""
	echo $DOCKER
	docker exec $DOCKER java -version || echo "Failed to execute java -version in $DOCKER"
done