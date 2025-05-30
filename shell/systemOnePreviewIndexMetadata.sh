#! /bin/bash

INDEX_URL='https://cora.epc.ub.uu.se/systemone/rest/record/index'

LOGIN_URL='https://cora.epc.ub.uu.se/systemone/login/rest/apptoken'
LOGINID='systemoneAdmin@system.cora.uu.se'
APP_TOKEN='5d3f3ed4-4931-4924-9faa-8eaf5ac6457e'

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
	indexMetadata 'permissionUnit';
	logoutFromCora;
}
login(){
	local loginAnswer=$(curl -s -X POST -H "Content-Type: application/vnd.cora.login" -k -i ${LOGIN_URL} --data ${LOGINID}$'\n'${APP_TOKEN});
	echo 'LoginAnswer: '${loginAnswer} 
	AUTH_TOKEN=$(echo ${loginAnswer} | grep -o -P '(?<={"name":"token","value":").*?(?="})')
	AUTH_TOKEN_DELETE_URL=$(echo ${loginAnswer} | grep -o -P '(?<="url":").*?(?=")')
	echo 'Logged in, got authToken: '${AUTH_TOKEN} 
}
indexMetadata(){
	echo ""
	local recordType=$1
	echo 'Indexing recordType: '${recordType}
	local indexAnswer=$(curl -s -X POST -k -H "authToken: ${AUTH_TOKEN}" -H "Accept: application/vnd.cora.record+json" -i ${INDEX_URL}'/'${recordType} )
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
