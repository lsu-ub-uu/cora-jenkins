#! /bin/bash

INDEX_URL='https://cora.epc.ub.uu.se/alvin/rest/record/index'
#LOGIN_URL='https://cora.epc.ub.uu.se/alvin/login/rest/apptoken/systemoneAdmin@system.cora.uu.se'
#APP_TOKEN='5d3f3ed4-4931-4924-9faa-8eaf5ac6457e'

LOGIN_URL='https://cora.epc.ub.uu.se/alvin/login/rest/apptoken/alvinAdmin@cora.epc.ub.uu.se'
APP_TOKEN='a50ca087-a3f5-4393-b2bb-315436d3c3be'

start(){
	sleep 15
	login;
	#Indexera alla posttyper.
	indexMetadata 'recordType';
	indexMetadata 'validationType';
	indexMetadata 'metadata';
	indexMetadata 'text';
	indexMetadata 'collectTerm';
	indexMetadata 'presentation';
	indexMetadata 'guiElement';
	indexMetadata 'system';
	indexMetadata 'alvin-place';
	indexMetadata 'alvin-person';
	indexMetadata 'alvin-organisation';
	indexMetadata 'alvin-work';
	indexMetadata 'alvin-location';
	indexMetadata 'alvin-record';
	logoutFromCora;
}
login(){
	#AUTH_TOKEN=$(curl -s -X POST -k -i ${LOGIN_URL} --data ${APP_TOKEN} | grep -o -P '(?<={"name":"id","value":").*?(?="})')
	local loginAnswer=$(curl -s -X POST -H "Content-Type: text/plain" -k -i ${LOGIN_URL} --data ${APP_TOKEN});
	echo 'LoginAnswer: '${loginAnswer} 
	AUTH_TOKEN=$(echo ${loginAnswer} | grep -o -P '(?<={"name":"id","value":").*?(?="})')
	echo 'Logged in, got authToken: '${AUTH_TOKEN} 
}
indexMetadata(){
	echo ""
	local recordType=$1
	echo 'Indexing recordType: '${recordType}
	curl -s -X POST -k -H 'authToken: '${AUTH_TOKEN} -i ${INDEX_URL}'/'${recordType} | grep -o -P '(?<={"name":"id","value":").*?(?="})'
}
logoutFromCora(){
	echo ""
	curl -s -X DELETE -H "Content-Type: text/plain" -k  '${LOGIN_URL}' --data ${AUTH_TOKEN} 
	echo 'Logged out' 
}

# ################# calls start here #######################################
start
