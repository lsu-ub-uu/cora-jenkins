#! /bin/bash

INDEX_URL='https://cora.epc.ub.uu.se/alvin/rest/record/index'

LOGIN_URL='https://cora.epc.ub.uu.se/alvin/login/rest/apptoken'
LOGINID='alvinAdmin@cora.epc.ub.uu.se'
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
	local loginAnswer=$(curl -s -X POST -H "Content-Type: application/vnd.uub.login" -k -i ${LOGIN_URL} --data ${LOGINID}$'\n'${APP_TOKEN});
	echo 'LoginAnswer: '${loginAnswer} 
	AUTH_TOKEN=$(echo ${loginAnswer} | grep -o -P '(?<={"name":"token","value":").*?(?="})')
	AUTH_TOKEN_DELETE_URL=$(echo ${loginAnswer} | grep -o -P '(?<="url":").*?(?=")')
	echo 'Logged in, got authToken: '${AUTH_TOKEN} 
}
indexMetadata(){
	echo ""
	local recordType=$1
	echo 'Indexing recordType: '${recordType}
	local indexAnswer=$(curl -s -X POST -k -H "authToken: ${AUTH_TOKEN}" -H "Accept: application/vnd.uub.record+json" -i ${INDEX_URL}'/'${recordType} )
	echo 'IndexAnswer: '${indexAnswer}
	
	local indexAnswerId=$(echo ${indexAnswer} | grep -o -P '(?<="name":"id","value":").*?(?=")')
	echo 'IndexAnswerId: '${indexAnswerId}
}

logoutFromCora(){
	echo
	echo 'Loggin out on' ${AUTH_TOKEN_DELETE_URL} 
	curl -s -X DELETE -k -H 'authToken: '${AUTH_TOKEN} -i ${AUTH_TOKEN_DELETE_URL}
	echo 'Logged out' 
}

# ################# calls start here #######################################
start
