#! /usr/bin/env bash
projectName=$1
userChoosenGroup=$2;
projectListningPath=$3
#~/workspace/cora-eclipse/development/projectListing.sh
#tempPomPath is the path where the temporary tempPom will be created
tempPomPath=$4
#~/workspace/tempPom.xml
moduleTempPomPath=$5
#~/workspace/cora-eclipse/development/modulePomTemplate.xml

start(){
	importProjectListing;
	PROJECTS_TO_RUN="${!userChoosenGroup}";
	checkChoosenProjectsExists;
	createTempPomFile;
	generateProjectListFromReactor;	
	filterOutUnderDependentProjectdFromProjectList;
}

importProjectListing(){
	.  ${projectListningPath}
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
	touch $tempPomPath
	cp $moduleTempPomPath $tempPomPath
}

addAllProjectsToTempPomFile(){
	for PROJECT in $PROJECTS_TO_RUN; do
		echo "<module>$PROJECT</module>" >>  $tempPomPath
	done
}

writeEndToTempPomFile(){
		echo "</modules>" >>  $tempPomPath
		echo "</project>" >>  $tempPomPath
}

generateProjectListFromReactor(){
	delimiter=','
	allProjectsSortedByMvnReactor=$(mvn -q -f $tempPomPath -Dexec.executable="echo" -Dexec.args='${project.scm.url}'  org.codehaus.mojo:exec-maven-plugin:3.1.0:exec | sed -rn 's/(.*)\/([a-z,-]+).git/\2/p' | sed -e 'H;${x;s/\n/'$delimiter'/g;s/^,//;p;};d')
}

filterOutUnderDependentProjectdFromProjectList(){
	foundProject="false"
	IFS=',' read -ra arrayAllProjectsSortedByMvnReactor <<< "$allProjectsSortedByMvnReactor"
	
	for currentProjectName in "${arrayAllProjectsSortedByMvnReactor[@]}" ; do
		if [[ "$foundProject" == "false" ]]; then
			if [[ "$projectName" == "$currentProjectName" ]]; then
				foundProject="true"
			fi
			arrayAllProjectsSortedByMvnReactor=${arrayAllProjectsSortedByMvnReactor[@]/$currentProjectName}
		fi
	done
	echo $arrayAllProjectsSortedByMvnReactor
}

start;