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
local suspendedUsers = {}

local function dump(...)
	print(ut.tostring(...))
end
local function dump1(msg)
	print(ut.tostring(msg))
end
local function log(msg, ...)
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

local function sleep(seconds)
	if os.execute("sleep $seconds") ~= true then
		print("Aborting")
		os.exit(1)
	end
end
local function sendRequest(requestType, uri, body)
	local request = http.new_from_uri(uri)
	local resHeaders, resStatus, resBody, resErr
	local stream
	local resHeadersTable = {}

	nlog("Sending ${requestType} request to: ${uri}")

	if not body then body = {} end

	local orgHeaderUpsert = request.headers.upsert
	request.headers.upsert = function(self, name, value)
		orgHeaderUpsert(self, string.lower(name), value)
	end
	request.headers:upsert(":method", requestType)
	request.headers:upsert("Content-Type", "application/json")
	request.headers:upsert("Accept", "Application/vnd.pterodactyl.v1+json")
	request.headers:upsert("Authorization", "Bearer $token")
	if type(body) == "table" then
		request:set_body(json.encode(body))
	elseif type(body) == "string" then
		request:set_body(body)
	else
		error("Invalid body type")
	end

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
function setUserPermissions(uuid, permissionTable)
	local permissionString = "{\"permissions\": ["

	for _, perm in ipairs(permissionTable) do
		permissionString = "${permissionString} \n  \"$perm\","
	end

	permissionString = permissionString:sub(0, -2)
	permissionString = "$permissionString \n]}"
	
	sendRequest("POST", "$url/api/client/servers/$serverID/users/$uuid", permissionString)
end
function getServerState()
	local response = sendRequest("GET", "$url/api/client/servers/$serverID/resources")
	return response.attributes.current_state
end
function sendCommand(cmd)
	local serverState = getServerState()
	if getServerState() ~= "online" then
		log("Skip sending command '$cmd', server state is in '$serverState' state")
		return false
	end

	log("Send command: $cmd")
	sendRequest("POST", "$url/api/client/servers/$serverID/command", {
		command = "$cmd"
	})
end
function say(msg)
	sendCommand("say $msg")
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
			sleep(1)
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
	--parser:flag("-V --verbose", "Activates verbose logging"):target("verbose")
	parser:flag("-n --netlog", "Activates verbose logging"):target("netlog")
	parser:flag("-Y --yes", "Skips confirmation"):target("yes")
	parser:flag("-s --skip", "Skipt the restart countdown"):target("skipCountdown")
	parser:flag("-d --dry", "A dry run, does not actually update the server"):target("dry")
	
	parser:option("-m --minutes", "Time for the restart countdown in minutes"):default("1"):action(function(args, _, value)
		local newValue = tonumber(value)
		if newValue == nil then
			print("Invalid minute value '$value'")
			os.exit(1)
		end
		args.minutes = newValue
	end)

	args = parser:parse()
end

do --init 
	log("Init")
	log("Loading token")
	token = ut.readFile(tokenPath)
	token = token:gmatch("[^\n]+")() --cutout new lines
end

do --get server data
	log("Get server data")
	local response = sendRequest("GET", "$url/api/client/account")
	user.id = response.attributes.id
	user.name = response.attributes.username

	response = sendRequest("GET", "$url/api/application/users/$user.id")
	user.uuid = response.attributes.uuid

	response = sendRequest("GET", "$url/api/client/servers/$serverID")
	server.id = response.attributes.internal_id

	response = sendRequest("GET", "$url/api/application/servers/$server.id")
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
	--=== update scheduling ===--
	log("Schedule server update")
	log("Rename server to: [UPDATE SCHEDULED] ${server.name}")
	local response, responseHeaders = sendRequest("PATCH", "$url/api/application/servers/$server.id/details", {
		user = server.user,
		name = "[UPDATE SCHEDULED] ${server.name}"
	})
	if not args.skipCountdown then
		local serverState = getServerState()
		if serverState ~= "online" then
			log("Skipping restart countdown. Server is in '$serverState' state")
		else
			log("Starting shutdown countdown")
			restartCountdown(args.minutes)
		end
	else
		log("Skipping restart countdown")
	end
	
	--=== update preperation ===--
	log("Preparing server for update")
	log("Rename server to: [UPDATING] ${server.name}")
	local response, responseHeaders = sendRequest("PATCH", "$url/api/application/servers/$server.id/details", {
		user = server.user,
		name = "[UPDATING] ${server.name}"
	})

	log("Remove control permissions for users")
	local response = sendRequest("GET", "$url/api/client/servers/$serverID/users")
	for _, suser in ipairs(response.data) do --preparing and storing user data/permissions
		if suser.attributes.uuid ~= user.uuid then
			local affectedUser = {
				attributes = {username = suser.attributes.username},
				permissions = {},
				suspendedPermissions = {}
			}
			suspendedUsers[suser.attributes.uuid] = affectedUser
			for _, perm in ipairs(suser.attributes.permissions) do
				if perm == "control.start" or perm == "control.restart" then
					log("Suspent '$perm' permission for user '$affectedUser.attributes.username'")
					table.insert(affectedUser.suspendedPermissions, perm)
				else
					table.insert(affectedUser.permissions, perm)
				end
			end
		end
	end
	for uuid, suser in pairs(suspendedUsers) do
		log("Set permissions for user: $suser.attributes.username")
		setUserPermissions(uuid, suser.permissions)
	end

	log("Stop server")
	sendRequest("POST", "$url/api/client/servers/$serverID/power", {signal = "stop"})
	if getServerState() ~= "offline" then
		log("Wait for server to stop")
		sleep(5)
	end
	while true do
		local serverState = getServerState()
		if serverState ~= "offline" then
			log("Server still in '$serverState' state, wait another 10 seconds")
			sleep(10)
		else
			break
		end
	end
	log("Suspend server")
	sendRequest("POST", "$url/api/application/servers/$server.id/suspend")
	



	
	--=== update execution ===--
	log("Update server")
	

	--=== finishing up ===--
	log("Finishing up")
	log("Unsuspend server")
	sendRequest("POST", "$url/api/application/servers/$server.id/unsuspend")
	log("Revert user permissions")
	for uuid, suser in pairs(suspendedUsers) do
		log("Revert permissions for user: $suser.attributes.username")
		for _, permission in ipairs(suser.suspendedPermissions) do
			table.insert(suser.permissions, permission)
		end
		setUserPermissions(uuid, suser.permissions)
	end
	log("Rename server to: ${server.name}")
	local response, responseHeaders = sendRequest("PATCH", "$url/api/application/servers/$server.id/details", {
		user = server.user,
		--name = "${server.name}"
		name = "TEST"
	})
	log("Restart server")
	sendRequest("POST", "$url/api/client/servers/$serverID/power", {signal = "start"})

end
