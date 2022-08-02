#!/bin/bash

BASE_URL=$1
BASENAME=$2
VERSION=$3

cd ../../diva-docker-react-client

ls -ahl

./buildDocker.sh $BASE_URL $BASENAME $VERSION