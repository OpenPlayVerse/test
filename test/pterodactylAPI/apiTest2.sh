#!/bin/bash

apiToken=$(cat api.token)

curl "https://panel.openplayverse.net/api/client/servers/aa34a02e/command" \
	-H "Content-Type: application/json" \
	-H "Accept: application/json" \
	-H "Authorization: Bearer ${apiToken}" \
	-X "POST" \
	-d "{\"command\": \"say TEST\"}"