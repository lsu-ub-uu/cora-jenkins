docker stop diva-jsclient && echo nothingToSeeMoveOnToNextCommand
docker rm diva-jsclient  && echo nothingToSeeMoveOnToNextCommand
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand
docker run --net=diva-cora --restart always  -p 8683:8080 --name diva-jsclient -d cora-docker-jsclient:1.0-SNAPSHOT