docker stop jsclient && echo nothingToSeeMoveOnToNextCommand
docker rm jsclient  && echo nothingToSeeMoveOnToNextCommand
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand
docker run --net=cora --restart always  -p 8283:8080 --name jsclient -d cora-docker-jsclient:1.0-SNAPSHOT