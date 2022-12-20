#! /usr/bin/env bash
projectName=$1
userChoosenGroup=$2;

start(){
	importProjectListing;
	PROJECTS_TO_RUN="${!userChoosenGroup}";
	checkChoosenProjectsExists;
	createTempPomFile;
	generateProjectListFromReactor;	
}

importProjectListing(){
	.  ~/workspace/cora-eclipse/development/projectListing.sh
}

checkChoosenProjectsExists(){
	if [  ${#PROJECTS_TO_RUN} -lt 1 ]; then 
		echo "Error, choosen group ($userChoosenGroup) does not exist in projectListings.sh."
		exit 1;
	fi
}

createTempPomFile(){
	copyTempPomFileToWorkspace;
	addAllProjectsToTempPomFile;
	writeEndToTempPomFile;
}

copyTempPomFileToWorkspace(){
	touch ~/workspace/tempPom.xml
	cp ~/workspace/cora-eclipse/development/modulePomTemplate.xml ~/workspace/tempPom.xml
}

addAllProjectsToTempPomFile(){
	for PROJECT in $PROJECTS_TO_RUN; do
		echo "<module>$PROJECT</module>" >>  ~/workspace/tempPom.xml
	done
}

writeEndToTempPomFile(){
		echo "</modules>" >>  ~/workspace/tempPom.xml
		echo "</project>" >>  ~/workspace/tempPom.xml
}

generateProjectListFromReactor(){
	allProjectsSortedByMvnReactor=mvn -q -f ~/workspace/tempPom.xml -Dexec.executable="echo" -Dexec.args='${project.scm.url}'  org.codehaus.mojo:exec-maven-plugin:3.1.0:exec | sed -rn 's/(.*)\/([a-z,-]+).git/\2/p' | sed -e 'H;${x;s/\n/||/g;s/^,//;p;};d'
}

filterOutUnderDependentProjectdFromProjectList(){
	foundProject = 'false'
	IFS='||' read -ra arrayAllProjectsSortedByMvnReactor <<< "$allProjectsSortedByMvnReactor"
	
	for i in "${arrayAllProjectsSortedByMvnReactor[@]}"; do
		if [foundProject=='false'] then
			if [projectName == $arrayAllProjectsSortedByMvnReactor[i]] then
				foundProject  = 'true'
			fi
			currentProjectName = $arrayAllProjectsSortedByMvnReactor[i]
			arrayAllProjectsSortedByMvnReactor = ${arrayAllProjectsSortedByMvnReactor[@]/currentProjectName}
		fi
	done
	
	for 
	dependentProjectsToBeReleased
}

start;