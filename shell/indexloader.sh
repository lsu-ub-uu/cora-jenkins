#!/bin/bash
cd ../../cora-indexloader/target

AUTH_TOKEN = $(curl -X POST -k -i 'https://cora.epc.ub.uu.se/diva/apptokenverifier/rest/apptoken/coraUser:490742519075086' --data 2e57eb36-55b9-4820-8c44-8271baab4e8e | grep -oe '[0-9a-z]\{8\}-[0-9a-z]\{4\}-[0-9a-z]\{4\}-[0-9a-z]\{4\}-[0-9a-z]\{12\}')

echo " AuthToken is: $AUTH_TOKEN"

java -cp cora-indexloader-0.1-SNAPSHOT-jar-with-dependencies.jar se.uu.ub.cora.indexloader.index.IndexerBatchRunner "${AUTH_TOKEN}" "${APPTOKEN_URL}" "${DIVA_REST}" "se.uu.ub.cora.javaclient.cora.CoraClientFactoryImp" "se.uu.ub.cora.indexloader.index.DataIndexerImp" "${RECORD_TYPE}"