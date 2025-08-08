#
# DEPRECATED: This script is no longer maintained or used.
# Kubernetes and Helm are now used to handle the build and preview environments.
# For more information, please refer to the 'cora-deployment' project.
#

docker stop alvin-jsclient && echo nothingToSeeMoveOnToNextCommand
docker rm alvin-jsclient  && echo nothingToSeeMoveOnToNextCommand
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand
docker run --net=alvin-cora --restart always  -p 8483:8080 --name alvin-jsclient -d cora-docker-jsclient:1.0-SNAPSHOT