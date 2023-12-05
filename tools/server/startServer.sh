#!/bin/bash
# This start script avoids the server to run while the modpack is updated. ONLY CHANGE IF YOU KNOW WHAT YOU ARE DOING.

version="0.1.1"

# conf
startCommand="java -Xms128M -XX:MaxRAMPercentage=95.0 -jar server.jar"

# internal conf
serverRunnerInstructionFile=".serverStatus"

# runtime vars
serverStatus=""

### functions ###
function onExit() {
	shopt -u dotglob
}	
function onError() {
	echo "ERROR: Something went wrong!"
    exit 1
}

### init ###
set -e
shopt -s dotglob

trap onError ERR
trap onExit EXIT

echo "[INFO]: Server start script v${version}"

touch $serverRunnerInstructionFile
serverStatus=$(cat ${serverRunnerInstructionFile})

case "$serverStatus" in
    "normal")
        echo "########### [INFO]: Starting server. ###########"
        bash -c "$startCommand"
        ;;
    "update")
        echo "########### [INFO]: Server is updating right now. Please wait a few minutes. ###########"
        ;;
    "")
        echo "########### [ERROR]: Server status unknown. Please contact an admin. ###########"
        ;;
    *)
        echo "########### [ERROR]: Server is in an unknown status ($serverStatus). Please contact an admin. ###########"
        ;;
esac

