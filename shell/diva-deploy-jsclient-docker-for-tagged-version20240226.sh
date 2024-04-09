docker stop diva-jsclient-20240226 && echo nothingToSeeMoveOnToNextCommand
docker rm diva-jsclient-20240226  && echo nothingToSeeMoveOnToNextCommand
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand
docker run --net=diva-cora-20240226 --restart always  -p 8783:8080 --name diva-jsclient-20240226 -d cora-docker-jsclient:1.0-SNAPSHOT