#!/bin/bash
cd ../cora-indexloader/target

java -cp cora-indexloader-0.1-SNAPSHOT-jar-with-dependencies.jar se.uu.ub.cora.indexloader.index.IndexerBatchRunner "fc045d25-a5ed-41df-a09c-490f9f843e00" "https://cora.epc.ub.uu.se/apptokenverifier/" "https://cora.epc.ub.uu.se/diva/rest/" "se.uu.ub.cora.javaclient.cora.CoraClientFactoryImp" "se.uu.ub.cora.indexloader.index.DataIndexerImp" "organisation"