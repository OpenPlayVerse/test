#!/bin/bash

releasetagPath="test/.releasetag"
tag=$(cat ${releasetagPath})

tag=$(c "$tag + 1")

echo $tag > $releasetagPath

./tools/createRelease.sh --token ghAPI.token --url "https://api.github.com/repos/OpenPlayVerse/test/releases" -t $tag -n "Release test 3" -d "Description" -T "master" --log-level 0 -R test -r test