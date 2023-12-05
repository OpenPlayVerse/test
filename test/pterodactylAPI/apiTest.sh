#!/bin/pleal
local timeout = 3
local uri = "https://panel.openplayverse.net/api/client/servers/aa34a02e"

local http = require("http.request")
local ut = require("UT")
local json = require("json")

local token = ut.readFile("api.token")
local request = http.new_from_uri(uri)
local resHeaders, resStatus, resBody, resErr
local stream
local resTable

local orgHeaderUpsert = request.headers.upsert
request.headers.upsert = function(self, name, value)
	orgHeaderUpsert(self, string.lower(name), value)
end
request.headers:upsert(":method", "GET")
request.headers:upsert("Content-Type", "application/json")
--request.headers:upsert("Accept", "application/json")
request.headers:upsert("Accept", "Application/vnd.pterodactyl.v1+json")
request.headers:upsert("Authorization", "Bearer $token")
request:set_body([[]])

resHeaders, stream = request:go()
if resHeaders == nil then
	io.stderr:write(tostring(stream))
	io.stderr:flush()
	os.exit(1)
end

print()
print("===HEADERS===")
for index, header in resHeaders:each() do
	print(index, header)
end

print()
print("===BODY===")
resBody, resErr = stream:get_body_as_string()
if not resBody or resErr then
	io.stderr:write(tostring(resErr))
	io.stderr:flush()
	os.exit(1)
end
print(resBody)
print()

resTable = json.decode(resBody)
print(ut.tostring(resTable))


print(resTable.attributes.current_state)