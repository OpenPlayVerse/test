#!/usr/bin/pleal
local version = "0.1"
local name = "GithubReleaseHelper"

--===== conf =====--
local url = "https://api.github.com/repos/OpenPlayVerse/test/releases"
local releaseFiles = "release"
local tokenPath = "ghAPI.token"
local tmpReleaseFileLocation = ".compressedReleaseFiles.zip"

--===== runtime vars =====--
local http = require("http.request")
local ut = require("UT")
local json = require("json")
local argparse = require("argparse")
local len = require("utf8").len
local lfs = require("lfs")

local args
local token = ut.readFile("ghAPI.token")
local uploadUrl
local uploadedFiles = {}


--===== init =====--
do --arg parsing 
	local parser = argparse(name)

	parser:option("-t --tag", "Release tag"):count(1):args(1):target("tag")
	parser:option("-n --name", "Relase name"):count(1):args(1):target("name")
	parser:option("-d --description", "Relase description"):count(1):args(1):target("description")
	parser:option("-T --target", "Target branch"):count(1):args(1):target("target")
	
	parser:flag("-D --draft", "Draft"):target("draft")
	parser:flag("-P --prerelease", "Prerelease"):target("prerelease")
	parser:flag("-G --generate-release-notes", "Generate release notes"):target("notes")

	parser:flag("-v --version", "log version and exit"):action(function() 
		log("$name: v$version")
		os.exit(0)
	end)

	parser:flag("--dry", "Dry run"):target("dry")
	parser:option("--log-level", "Set the log level"):default(0):target("logLevel")

	args = parser:parse()
end


--===== local functions =====--
local function log(...)
	io.write("[" .. tostring(os.date("%X")) .. "]: ")
	print(...)
end
local function verboseLog(level, ...)
	if tonumber(args.logLevel) >= level then
		io.write("[" .. tostring(os.date("%X")) .. "][$level]: ")
		print(...)
	end
end

local function sendRequest(url, headers, body)
	log("Send API request to: $url")

	local request = http.new_from_uri(url)
	local responseHeaders, responseStatus, responseBody, responseError
	local stream

	verboseLog(1, "Build headers")
	do --make all upsert names lowercase
		local orgHeaderUpsert = request.headers.upsert
		request.headers.upsert = function(self, name, value)
			orgHeaderUpsert(self, string.lower(name), value)
		end
	end
	for i, v in pairs(headers) do
		if i:lower() ~= "auth" and i:lower() ~= "authorization" then
			verboseLog(2, "Add header: $i, $v")
		else
			verboseLog(2, "Add header (Censored): $i, TOKEN")
		end
		request.headers:upsert(i, v)
	end
	verboseLog(1, "Add body")
	verboseLog(2, "Body: $body")
	request:set_body(body)
	verboseLog(1, "Send request")
	verboseLog(1, "Process response")
	responseHeaders, stream = request:go()
	if responseHeaders == nil then
		io.stderr:write(tostring(stream))
		io.stderr:flush()
		os.exit(1)
	elseif responseHeaders:get(":status") ~= "201" then
		responseBody, responseError = stream:get_body_as_string()
		log("API returned an error\n\n")
		io.stderr:write("Headers: ", ut.tostring(responseHeaders), "\n\n")
		io.stderr:write("Body dump: ", responseBody, "\n\n")
		io.stderr:flush() --in case the body decodeation fails.
		io.stderr:write("Body: ", ut.tostring(json.decode(responseBody)), "\n\n")
		io.stderr:flush()
		os.exit(2)
	end
	responseBody, responseError = stream:get_body_as_string()
	return responseHeaders, json.decode(responseBody)
end

local function uploadFile(path, name, fileType)
	log("Upload $fileType: $path")
	local _, file, ending = ut.seperatePath(name)
	local responseHeaders, responseTable
	local headers
	local fileHandler = io.open(path, "r")

	if ending == ".gz" then
		ending = "gzip"
	end
	
	verboseLog(1, "Build release file request")
	headers = {
		[":method"] = "POST",
		["X-GitHub-Api-Version"] = "2022-11-28",
		["Accept"] = "json",
		["Authorization"] = "Bearer $token",
		["content-type"] = "application/$ending"
	}
	responseHeaders, responseTable = sendRequest("${uploadUrl}?name=${file}${ending}", headers, fileHandler:read("*a"))
	fileHandler:close()
end
local function collectReleaseFiles(path, fileType)
	log("Prepare ${fileType}s from: $path")
	local dirName
	for file in lfs.dir(path) do
		if file:sub(1, 1) ~= "." then
			if lfs.attributes("$path/$file").mode == fileType then
				if fileType == "directory" then
					dirName = file
					file = "${file}.zip"
				end
				if not uploadedFiles[file] then
					if fileType == "directory" then
						log("Zip dir: $path/$dirName")
						os.execute("zip -r $tmpReleaseFileLocation $path/$dirName")
						uploadFile("$tmpReleaseFileLocation", "${dirName}.zip", fileType)
						os.execute("rm $tmpReleaseFileLocation")
					else
						uploadFile("$path/$file", file, fileType)
					end
					uploadedFiles[file] = true
				else
					log("Skipping $fileType: $path/$file: file already uploaded")
				end

			end
		end
	end
end

--===== prog start =====--
--=== create release ===--
do
	local currentReleaseTag = ut.readFile(".currentReleaseTag") --debug
	do
		local file = io.open(".currentReleaseTag", "w")
		file:write(currentReleaseTag + 1)
	end

	local responseHeaders, responseTable
	log("Build release creation request")
	local headers = {
		[":method"] = "POST",
		["X-GitHub-Api-Version"] = "2022-11-28",
		["Accept"] = "json",
		["Authorization"] = "Bearer $token",
	}
	log("Build body")

	local requestTable = {
		tag_name = args.tag,
		tag_name = tostring(currentReleaseTag),
		name = args.name,
		body = args.description,
		target_commitish = args.target,

		draft = args.draft,
		prerelease = args.prerelease,
		generate_release_notes = args.notes
	}
	responseHeaders, responseTable = sendRequest(url, headers, json.encode(requestTable))
	uploadUrl = responseTable.upload_url
	do --cut uploadUrl
		local brakedPos = uploadUrl:find("{")
		uploadUrl = uploadUrl:sub(0, brakedPos - 1)
	end
end

--=== collect/upload release files ===--
log("Prepare release folders")
collectReleaseFiles(releaseFiles, "file")
collectReleaseFiles(releaseFiles, "directory")













