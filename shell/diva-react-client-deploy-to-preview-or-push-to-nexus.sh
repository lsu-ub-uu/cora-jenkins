#!/bin/bash

VERSION=$1

deployToPreview(){
	docker stop diva-docker-react-client && echo nothingToSeeMoveOnToNextCommand
	docker rm diva-docker-react-client  && echo nothingToSeeMoveOnToNextCommand

	docker ps | grep react

	docker run \
	    --name diva-docker-react-client \
	    --net=diva-cora \
	    --restart always \
	    -p 9876:80 \
	    -d \
	    diva-docker-react-client:preview
}

pushToNexus(){
	docker tag diva-docker-react-client:test dev-maven-repo:19003/diva-docker-react-client:test
	docker push dev-maven-repo:19003/diva-docker-react-client:test
}

if [ $VERSION = 'preview' ]
then
	echo "Deploying to preview"
	deployToPreview
elif [ $VERSION = 'test' ]
then
	echo "Pushing test-image to nexus"
    pushToNexus
fi