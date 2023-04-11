#!/usr/bin/pleal
local version = "0.0.1"

--===== conf =====--
local baseDownloadURI = "https://github.com/OpenPlayVerse/test/raw/master/"
local dirsToAdd = {
	"server",
}
local ourputDir = "tmp"

--===== local vars =====--
local lfs = require("lfs")
local ut = require("UT")
local argparse = require("argparse")
local posix = require("posix")

--===== local functions =====--
--[[This function is ripped from DAMS v0.19.1_v1-prev41
	https://github.com/MisterNoNameLP/dams
]]
local function exec(cmd, pollTimeout)
	local execString = ""
	local handlerFile, handlerFileDescriptor, events
	local discriptorList = {}
	local returnSignal
	local tmpOutput, output = "", ""
	 
	execString = execString .. " " .. cmd .. " 2>&1; printf \"\n\$?\""

	handlerFile = io.popen(execString, "r")

	--make poopen file stream non blocking
	handlerFileDescriptor = posix.fileno(handlerFile)
	discriptorList[handlerFileDescriptor] = {events = {IN = true}}
	pollTimeout = math.floor((pollTimeout or 0.01) * 1000)

	while true do
		events = posix.poll(discriptorList)
		--reading handler file
		tmpOutput = handlerFile:read("*a")
		if tmpOutput then
			output = output .. tmpOutput
		end

		if events > 0 and discriptorList[handlerFileDescriptor].revents.HUP then
			break
		end
	end

	--reading rest of handler file
	tmpOutput = handlerFile:read("*a")
	if tmpOutput then
		output = output .. tmpOutput
	end
	handlerFile:close()

	--getting exec exit code
	for s in string.gmatch(output, "[^\n]+") do
		returnSignal = s
	end

	output = output:sub(0, -(len(returnSignal) + 2))

	if returnSignal ~= "0" then
		print("Exec failed")
		print(output)
		print("Aborting")
		os.exit(1)
	end

	return tonumber(returnSignal), output
end
local function parseDir(path)
	for file in lfs.dir(path) do
		if string.sub(file, 1, 1) ~= "." then
			local filePath = path .. "/" .. file
			local attributes = lfs.attributes(filePath)
			if attributes.mode == "directory" then
				parseDir(filePath)
			else
				local _, name, ending = ut.seperatePath(file)
				local pureName, fileHash
				local tomlFileString = ""

				print("file:", path, name, ending, "#################")

				for name in name:gmatch("[%a]+") do
					pureName = name
					break
				end

				_, fileHash = exec("sha1sum $filePath")
				for hash in fileHash:gmatch("[%w]+") do
					fileHash = hash
					break
				end

				tomlFileString = [[
name = "${pureName}${ending}"
filename = "$file"

[download]
url = "${baseDownloadURI}/$filePath"
hash-format = "sha1"
hash = "$fileHash"
				]]

				print(tomlFileString)

			end
		end
	end
end

--===== init =====--

--===== prog start =====--
for _, dir in pairs(dirsToAdd) do
	parseDir(dir)
end