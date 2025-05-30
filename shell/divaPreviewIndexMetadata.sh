#! /bin/bash

INDEX_URL='https://cora.epc.ub.uu.se/diva/rest/record/index'
LOGIN_URL='https://cora.epc.ub.uu.se/diva/login/rest/apptoken'
LOGINID='divaAdmin@cora.epc.ub.uu.se'
APP_TOKEN='49ce00fb-68b5-4089-a5f7-1c225d3cf156'

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
	
	#indexMetadata 'person';
	indexMetadata 'divaOutput';
	indexMetadata 'nationalSubjectCategory';
	
	indexMetadata 'diva-organisation';
	indexMetadata 'diva-output'
	indexMetadata 'diva-publisher'
	indexMetadata 'diva-person'
	indexMetadata 'diva-funder'
	indexMetadata 'diva-journal'
	indexMetadata 'diva-series'
	indexMetadata 'diva-subject'
	indexMetadata 'diva-course'
	indexMetadata 'diva-project'
	indexMetadata 'diva-programme'
	indexMetadata 'diva-partOfOrganisation'
	indexMetadata 'diva-topOrganisation'
	indexMetadata 'diva-localGenericMarkup'
	
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
