#!/usr/bin/pleal
local version = "0.0.1"
local name = "GithubReleaseHelper"

--===== conf =====--
local url = "https://api.github.com/repos/OpenPlayVerse/test/releases"
local releaseFiles = {
	"release/*",
	"test",
}
local tokenPath = "ghAPI.token"
local tmpReleaseFileLocation = ".compressedReleaseFiles"

--===== runtime vars =====--
local http = require("http.request")
local ut = require("UT")
local json = require("json")
local argparse = require("argparse")
local len = require("utf8").len

local args
local token = ut.readFile("ghAPI.token")
local request = http.new_from_uri(url)
local resHeaders, resStatus, resBody, resErr
local stream
local resTable


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

	parser:flag("-v --version", "Print version and exit"):action(function() 
		print("$name: v$version")
		os.exit(0)
	end)

	parser:flag("--dry", "Dry run"):target("dry")

	args = parser:parse()
end


--===== prog start =====--
--=== collect release files ===--
local function collectFiles(path)
	print("Add path: $path")
	


	if path:sub(len(path), len(path)) == "*" then
		collectFiles(path:sub(0, -2))
	end
end

for _, file in ipairs(releaseFiles) do
	collectFiles(file)
end













