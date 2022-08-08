#!/bin/bash

REST_API_BASE_URL=$1
BASENAME=$2
VERSION=$3

cd ../../diva-docker-react-client

ls -ahl

./buildDocker.sh $REST_API_BASE_URL $BASENAME $VERSION