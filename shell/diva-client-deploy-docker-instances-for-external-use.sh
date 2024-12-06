

echo "Kill dockers"
docker kill diva-client && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove dockers"
docker rm diva-client && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Starting diva-client"
docker run -d --name diva-client \
    --restart=unless-stopped \
    --net=diva-cora \
    -e CORA_API_URL=https://cora.epc.ub.uu.se/diva/rest \
    -e CORA_LOGIN_URL=https://cora.epc.ub.uu.se/diva/login/rest \
    -e DOMAIN=cora.epc.ub.uu.se \
    -e BASE_PATH=/divaclient \
    -e ENVIRONMENT=preview \
    -p 9876:5173 \
    diva-client:1.12-SNAPSHOT

echo ""
echo "All dockers started"