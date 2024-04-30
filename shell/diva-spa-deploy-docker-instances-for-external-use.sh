echo "Kill dockers"
docker kill diva-client-gui diva-client-bff && echo nothingToSeeMoveOnToNextCommand
echo ""
echo "Remove dockers"
docker rm diva-client-gui diva-client-bff && echo nothingToSeeMoveOnToNextCommand

echo ""
echo "Starting diva-client-gui"
docker run -d --name diva-client-gui \
    --restart=unless-stopped \
    --net=diva-cora \
    -e VITE_BFF_API_URL=http://bff:8080/api \
    -p 9876:80 \
    diva-client-gui-docker:1.0-SNAPSHOT

echo ""
echo "Starting diva-client-bff"
docker run -d --name diva-client-bff \
    --net-alias=bff \
    --net=diva-cora \
    --restart=unless-stopped \
    -p 9877:8080 \
    -e CORA_API_URL=https://diva:8080/diva/rest  \
    -e CORA_LOGIN_URL=https://cora.epc.ub.uu.se/diva/apptokenverifier/rest  \
    diva-client-bff-docker:1.0-SNAPSHOT

echo ""
echo "All dockers started"
