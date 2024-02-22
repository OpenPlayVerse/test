#!/bin/pleal
local url = "https://panel.openplayverse.net"
local serverID = "aa34a02e"
local timeout = 3
local updateNameString = "[UPDATING] "

local http = require("http.request")
local ut = require("UT")
local json = require("json")

local token = ut.readFile("api.token")
local server = {}

local function dump(...)
	print(ut.tostring(...))
end
local function dump1(msg)
	print(ut.tostring(msg))
end
local function log(msg, ...)
	print("[INFO]: " .. tostring(msg), ...)
end
local function warn(msg, ...)
	print("[WARN]: " .. tostring(msg), ...)
end
local function err(msg, ...)
	io.stderr:write("[ERROR]: " .. tostring(msg), ...)
	io.stderr:flush()
end
local function fatal(msg, ...)
	io.stderr:write("[FATAL]: " .. tostring(msg), ...)
	io.stderr:flush()
	os.exit(1)
end

local function sendRequest(type, uri, body)
	local request = http.new_from_uri(uri)
	local resHeaders, resStatus, resBody, resErr
	local stream
	local resHeadersTable = {}

	if not body then body = {} end

	local orgHeaderUpsert = request.headers.upsert
	request.headers.upsert = function(self, name, value)
		orgHeaderUpsert(self, string.lower(name), value)
	end
	request.headers:upsert(":method", type)
	request.headers:upsert("Content-Type", "application/json")
	request.headers:upsert("Accept", "Application/vnd.pterodactyl.v1+json")
	request.headers:upsert("Authorization", "Bearer $token")
	request:set_body(json.encode(body))

	resHeaders, stream = request:go()
	if resHeaders == nil then
		fatal("Could not get response headers: " .. tostring(stream))
	end
	for index, header in resHeaders:each() do
		resHeadersTable[index] = header
	end
	resBody, resErr = stream:get_body_as_string()
	if not resBody or resErr then
		fatal("Could not process response body: " .. tostring(resErr))
	end

	if resHeadersTable[":status"] ~= "200" then
		fatal("Request returned an error:\n" .. "[HEADERS]: " .. ut.tostring(resHeaders) .. "\n[BODY]: " .. ut.tostring(json.decode(resBody)))
	end

	return json.decode(resBody), resHeadersTable
end

--===== prog start =====--
do --get server data
	log("Get server data")
	local response = sendRequest("GET", "${url}/api/client/servers/${serverID}")
	server.id = response.attributes.internal_id
	response = sendRequest("GET", "${url}/api/application/servers/${server.id}")
	server.user = response.attributes.user
	server.name = response.attributes.name
end

--local response = sendRequest("GET", "https://panel.openplayverse.net/api/application/servers/4", {name = "TEST"})
do --prepare server
	log("Preparing server for update")
	if false then
	local response, responseHeaders = sendRequest("PATCH", "${url}/api/application/servers/${server.id}/details", {
		user = server.user,
		--name = "${updateNameString}${server.name}"
		name = "TEST"
	})
	end

	
	dump1(sendRequest("GET", "${url}/api/application/users"))



end




print(ut.tostring(response))