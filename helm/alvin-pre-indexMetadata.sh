#! /bin/bash

LOGINID='systemoneAdmin@system.cora.uu.se'
APP_TOKEN='5d3f3ed4-4931-4924-9faa-8eaf5ac6457e'

RUNNING_URL='https://cora.alvin-portal.org/rest/record/system'
LOGIN_URL='https://cora.alvin-portal.org/login/rest/apptoken'
RECORDTYPE_URL='https://cora.alvin-portal.org/rest/record/recordType'

start(){
	importIndexScript;
}

importIndexScript() {
	.  jobIndex.sh
}

start