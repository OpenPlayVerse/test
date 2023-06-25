#!/bin/bash
# this script automates updating an pack at a minecraft server usign packwiz. 
# creating backups where senseful.
version="0.2.1"

### config ###
serverPath="server"
worldPath="${serverPath}/world"
backupPath="${serverPath}/backups"

serverBranch="server-live"
serverBackupBranch="server-backup"

packURI="https://raw.githubusercontent.com/OpenPlayVerse/test/master/packwiz/pack.toml"
packwizArgs="-g -s server"

rconAddress="locahost"
rconPort=5050
rconPasswd="passwd"

waitCounter=60 # Default time for the script to wait before updating the server.
serverRunnerInstructionFile="${serverPath}/.runnerInstructions"
serverStatusFile="${serverPath}/.isRunning"

# arg vars
newVersion=
dryRun=0

# runntime vars
workingDir="$(pwd)"
backupFileName="$(basename ${worldPath})_$(date +%Y-%m-%d-%H%M)"
fullBackupPath="${backupPath}/${backupFileName}.tar.gz"

### functions ###
function onExit() {
	shopt -u dotglob
}	
function onError() {
	echo "ERROR: Something went wrong!"
}
function execCommand() {
	echo exec
	mcrcon mcrcon -P $rconPort -p $rconPasswd "$*"
}
function say () {
	echo "Say: " $*
	execCommand 'tellraw @a {"text":"'"$*"'","color":"blue"}'
}

### init ###
set -e
shopt -s dotglob

trap onError ERR
trap onExit EXIT

### arg parsing ###
positionalArgs=()
while [[ $# -gt 0 ]]; do
	case $1 in
		-s|--seconds)	
			waitCounter=$2
			shift
			shift  
		;;
		-m|--minutes)	
			waitCounter=$(($2 * 60))
			shift
			shift  
		;;
		-d|--dry)
			dryRun=1
			shift
		;;
		-V|--new-version)
			newVersion=$2
			shift
			shift
		;;
		-v|--version)
			echo "Server updater v$version"
			exit 0
			shift
		;;
		-*|--*)
			echo "Unknown option $1"
			exit 1
		;;
		*)
			positionalArgs+=("$1") # save positional arg
			shift # past argument
		  ;;
	esac
done

if [ -z $newVersion ]; then
	echo "ERROR: No version specified"
	exit 1
fi
if [ ! -d "${backupPath}" ]; then 
	mkdir -p ${backupPath}
fi

### prog start ###
# countdown
while [ $waitCounter -ge 0 ]; do
	if [ $(expr $waitCounter % 60) -eq 0 ] && [ $waitCounter -gt 0 ]; then
		say "Server is about to restart for an pack update in $(expr $waitCounter / 60 ) minute(s)" 
	elif [ $waitCounter -eq 30 ]; then
		say "Server is about to restart for an pack update in $waitCounter seconds" 
	elif [ $waitCounter -eq 10 ]; then
		say "Server is about to restart for an pack update in $waitCounter seconds" 
	elif [ $waitCounter -lt 10 ]; then
		say "Server restart in $waitCounter"
	fi
	waitCounter=$(($waitCounter-1))
done

echo 2 > $serverRunnerInstructionFile
execCommand "stop"

while [ ! $(cat $serverStatusFile) -eq 0 ]; do
	echo "Waiting for server to shut down"
	sleep 1
done

if [ ! $dryRun -gt 0 ]; then
	echo "Create world backup"
	tar -cz ${worldPath} -f ${fullBackupPath}
	echo "Push server backup"
	cd $serverPath
	git add .
	git commit -m "Server backup before: ${newVersion}"
	git push origin ${serverBranch}:${serverBackupBranch}
	echo "Download server pack"
	java -jar ${workingDir}/packwiz-installer-bootstrap.jar $packwizArgs $packURI
	echo "Push server repo"
	git add .
	git commit -m "Server update to: ${newVersion}"
	git push
	echo "Cleanup server dir"
	rm -r mods-server mods-client conf-server conf-client
	cd $workingDir
else
	echo "Dry run"
fi

echo 1 > $serverRunnerInstructionFile

echo "Done"