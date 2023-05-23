#!/usr/bin/pleal
local version = "0.0.2"
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
local request = http.new_from_uri(url)
local resHeaders, resStatus, resBody, resErr
local stream
local resTable
local uploadedFiles = {}


--===== init =====--
if false then --arg parsing 
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
local function uploadFile(path)
	print("Upload: $path")
end

local function collectReleaseFiles(path, fileType)
	print("Upload ${fileType}s from: $path")
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
						print("Zip dir: $path/$dirName")
						os.execute("zip $tmpReleaseFileLocation $path/$dirName")
						os.execute("rm $tmpReleaseFileLocation")
					end
					uploadFile("$path/$file")
					uploadedFiles[file] = true
				else
					print("Skipping $fileType: $path/$file; file already uploaded")
				end

			end
		end
	end
end

collectReleaseFiles(releaseFiles, "file")
collectReleaseFiles(releaseFiles, "directory")













