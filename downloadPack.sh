#!/bin/bash

version="0.1.1"
echo "Start pack downloader v$version"

# config
exportPath=".server"
packURI="http://localhost:8080/pack.toml"
args=""

# runntime vars
workingDir="$(pwd)"

# prog start
echo "Change working dir"
cd $exportPath
echo "Download pack"
java -jar ${workingDir}/packwiz-installer-bootstrap.jar -g $@ $args $packURI
echo "Cleaning up"
rm packwiz-installer.jar

echo "Done"

