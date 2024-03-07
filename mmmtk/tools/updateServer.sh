#!/bin/pleal
local version = "0.0d"

local url = "https://panel.openplayverse.net"
local serverID = "aa34a02e"
local timeout = 3
local updateNameString = "[UPDATING] "
local tokenPath = "api.token"

local argparse = require("argparse")
local http = require("http.request")
local ut = require("UT")
local json = require("json")

local args
local token
local user = {}
local server = {}

local function dump(...)
	print(ut.tostring(...))
end
local function dump1(msg)
	print(ut.tostring(msg))
end
local function vlog(msg, ...)
	if args.verbose then
		print("[VERBOSE]: " .. tostring(msg), ...)
	end
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

	vlog("Sending ${type} request to: ${uri}")

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
do --parse args
	local parser = argparse("MMMTK server update", "Sends update request to the server using the pterodactyl API")

	parser:flag("-v --version", "Shows version and exit"):action(function() 
		print("MMMTK server update")
		print("Version: " .. version)
		os.exit(0)
	end)
	parser:flag("-V --verbose", "Activates verbose logging"):target("verbose")
	parser:flag("-Y --yes", "Skips confirmation"):target("yes")

	args = parser:parse()
end

do --init 
	log("Init")
	vlog("Loading token")
	token = ut.readFile(tokenPath)
	token = token:gmatch("[^\n]+")() --cutout new lines
end

do --get server data
	log("Get server data")
	local response = sendRequest("GET", "${url}/api/client/account")
	user.id = response.attributes.id
	user.name = response.attributes.username

	response = sendRequest("GET", "${url}/api/client/servers/${serverID}")
	server.id = response.attributes.internal_id

	response = sendRequest("GET", "${url}/api/application/servers/${server.id}")
	server.user = response.attributes.user
	server.name = response.attributes.name

	

end

if not args.yes then
	local input
	print()
	print("Updating server $serverID: $server.id ($server.name)")
	print("As user: $user.id ($user.name)")
	print()
	io.write("Do u want to continue? [y/N]: ")
	io.flush()
	input = io.read("*l")
	if not (input:lower() == "y" or input:lower() == "yes") then
		log("Aborting")
		os.exit(0)
	end
else
	log("Skipping confirmation")
end

--local response = sendRequest("GET", "https://panel.openplayverse.net/api/application/servers/4", {name = "TEST"})
do --prepare server
	log("Preparing server for update")
	if false then
	local response, responseHeaders = sendRequest("PATCH", "${url}/api/application/servers/${server.id}/details", {
		user = server.user,
		name = "${updateNameString}${server.name}"
	})
	end

	log("Blocking users server controll access")
	local serverData = sendRequest("GET", "${url}/api/application/users")
	for _, data in ipairs(serverData.data) do
		if data.object == "user" then
			if data.attributes.id ~= user.id then
				vlog("Block server control for user: ${data.attributes.id} (${data.attributes.username})")
			end
		end
	end

	--os.execute("sleep 10")

	log("Finishing up")
	if false then
	local response, responseHeaders = sendRequest("PATCH", "${url}/api/application/servers/${server.id}/details", {
		user = server.user,
		--name = "${server.name}"
		name = "TEST"
	})
	end

end




print(ut.tostring(response))