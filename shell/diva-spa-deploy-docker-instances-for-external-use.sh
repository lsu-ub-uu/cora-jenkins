export CORA_API_URL=CORA_API_URL=https://cora.epc.ub.uu.se/diva/rest

echo "Kill dockers"
docker kill diva-react-spa-dev diva-react-spa-bff-dev && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove dockers"
docker rm diva-react-spa-dev diva-react-spa-bff-dev && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove volumes"
docker volume rm $(docker volume ls -q) && echo nothingToSeeMoveOnToNextCommand


echo ""
echo "Starting diva-react-spa-dev"
docker run -d --name diva-react-spa-dev \
    --net=diva-cora \
    --restart=unless-stopped \
     -p 9876:80 \
    diva-react-spa:latest

echo ""
echo "Starting diva-react-spa-bff-dev"
docker run -d --name diva-react-spa-bff-dev \
    --net-alias=bff \
    --net=diva-cora \
    --restart=unless-stopped \
     -p 9877:8080 \
     -e CORA_API_URL \
    diva-react-spa-bff:latest

echo ""
echo "All dockers started"