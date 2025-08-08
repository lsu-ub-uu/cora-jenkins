#
# DEPRECATED: This script is no longer maintained or used.
# Kubernetes and Helm are now used to handle the build and preview environments.
# For more information, please refer to the 'cora-deployment' project.
#

docker stop diva-jsclient && echo nothingToSeeMoveOnToNextCommand
docker rm diva-jsclient  && echo nothingToSeeMoveOnToNextCommand
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand
docker run --net=diva-cora --restart always  -p 8683:8080 --name diva-jsclient -d cora-docker-jsclient:1.0-SNAPSHOT