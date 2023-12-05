#!/bin/bash

versionTag=$1
changelog=$(cat changelog.txt)

tools/createPackwizAliases.sh -R
cd packwiz
packwiz refresh
cd ..
git add .
git commit -m