#! /bin/bash

INDEX_URL='https://cora.epc.ub.uu.se/diva/rest/record/index'
LOGIN_URL='https://cora.epc.ub.uu.se/diva/login/rest/apptoken/161616'
APP_TOKEN='f7973be9-02e0-4c42-979b-09e42372a02a'

#LOGIN_URL='https://cora.epc.ub.uu.se/diva/login/rest/apptoken/141414'
#APP_TOKEN='63e6bd34-02a1-4c82-8001-158c104cae0e'

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
	
	indexMetadata 'person';
	indexMetadata 'organisation';
	indexMetadata 'divaOutput';
	indexMetadata 'nationalSubjectCategory';
	
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
