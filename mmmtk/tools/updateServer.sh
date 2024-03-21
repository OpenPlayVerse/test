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
local function nlog(msg, ...)
	if args.netlog then
		print("[NET]: " .. tostring(msg), ...)
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

	nlog("Sending ${type} request to: ${uri}")

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
	if #resBody == 0 then
		resBody = "{}"
	end

	if resHeadersTable[":status"] ~= "200" and resHeadersTable[":status"] ~= "204" then
		fatal("Request returned an error:\n" .. "[HEADERS]: " .. ut.tostring(resHeaders) .. "\n[BODY]: " .. ut.tostring(json.decode(resBody)))
	end

	return json.decode(resBody), resHeadersTable
end
function say(msg)
	sendRequest("POST", "${url}/api/client/servers/${serverID}/command", {
		command = "say $msg"
	})
end

function restartCountdown(minutes)
	local seconds = minutes * 60
	for i = seconds, 1, -1 do
		local remainingMinutes = math.floor(i / 60)
		if i % 60 == 0 then
			if i == 60 then
				say("Server restart in $remainingMinutes minute")
			else
				say("Server restart in $remainingMinutes minutes")
			end
		elseif i == 30 then
			say("Server restart in $i seconds")
		elseif i < 10 then
			say("Server restart in $i")
		end
		if i > 1 then
			os.execute("sleep 0")
		end
	end
	say("Server restart")
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
	parser:flag("-N --netlog", "Activates verbose logging"):target("netlog")
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
	log("Schedule server update")
	vlog("Rename server to: [UPDATE SCHEDULED]${server.name}")
	local response, responseHeaders = sendRequest("PATCH", "${url}/api/application/servers/${server.id}/details", {
		user = server.user,
		name = "[UPDATE SCHEDULED]${server.name}"
	})

	vlog("Starting shutdown countdown")
	


	


	log("Preparing server for update")
	vlog("Rename server to: [UPDATING]${server.name}")
	local response, responseHeaders = sendRequest("PATCH", "${url}/api/application/servers/${server.id}/details", {
		user = server.user,
		name = "[UPDATING]${server.name}"
	})
	vlog("Suspend server")
	sendRequest("POST", "${url}/api/application/servers/${server.id}/suspend")
	

	log("Update server")
	--os.execute("sleep 5")


	log("Finishing up")
	vlog("Unsuspend server")
	sendRequest("POST", "${url}/api/application/servers/${server.id}/unsuspend")
	vlog("Rename server to: ${server.name}")
	local response, responseHeaders = sendRequest("PATCH", "${url}/api/application/servers/${server.id}/details", {
		user = server.user,
		--name = "${server.name}"
		name = "TEST"
	})

end




print(ut.tostring(response))