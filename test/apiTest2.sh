#!/bin/pleal
local timeout = 3
--local uri = "https://damsdev.namelessserver.net/"
local uri = "https://uploads.github.com/repos/OpenPlayVerse/test/releases/99181474/assets?name=test.tar.gz"
--local uri = "http://127.0.0.1:8023/dumpRequest"

local http = require("http.request")
local ut = require("UT")
local json = require("json")

local token = ut.readFile("ghAPI.token")
local request = http.new_from_uri(uri)
local resHeaders, resStatus, resBody, resErr
local stream
local resTable

local orgHeaderUpsert = request.headers.upsert
request.headers.upsert = function(self, name, value)
	orgHeaderUpsert(self, string.lower(name), value)
end
request.headers:upsert(":method", "POST")
request.headers:upsert("Accept", "json")
request.headers:upsert("Authorization", "Bearer $token")
request.headers:upsert("X-GitHub-Api-Version", "2022-11-28")
request.headers:upsert("content-type", "application/gzip")
request:set_body(io.open("test.tar.gz"):read("*a"))

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