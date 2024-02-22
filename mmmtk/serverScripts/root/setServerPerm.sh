#!/bin/bash

serverPath="/data/servers"

if [[ "$*" == *..* ]]; then
    echo "Tryed to access a forbidden path!"
    exit 1
fi

if [ -d "${serverPath}/$*" ]; then
    chmod -R g+w ${serverPath}/$*
else
    echo "Path not found: '${serverPath}/$*'"
fi

