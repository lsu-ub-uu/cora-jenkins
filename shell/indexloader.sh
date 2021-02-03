#!/bin/bash
cd ../../cora-indexloader/target

java -cp cora-indexloader-0.1-SNAPSHOT-jar-with-dependencies.jar se.uu.ub.cora.indexloader.index.IndexerBatchRunner "${AUTH_TOKEN}" "${APPTOKEN_URL}" "${DIVA_REST}" "se.uu.ub.cora.javaclient.cora.CoraClientFactoryImp" "se.uu.ub.cora.indexloader.index.DataIndexerImp" "${RECORD_TYPE}"