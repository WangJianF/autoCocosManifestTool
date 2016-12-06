require("json")
local utf8 = require("utf8")
local assetsDir = "../assets"
local targetDir = "../target"
local invalidFiles = {}
local deleFiles = {}
local targetTab = {}

local tab = {}
tab.packageUrl = "http://localhost:8080/target"
tab.remoteManifestUrl = tab.packageUrl.."/project.manifest"
tab.remoteVersionUrl = tab.packageUrl.."/version.manifest"
tab.version = "1.0.0"
tab.engineVersion = "cocos2d-x-3.11.1"

local function travelDir(path, cb)
	for name in lfs.dir(path) do
		if name ~= "." and name ~= ".." then
			local file = path ..'/'..name
			local attr = lfs.attributes(file)
			if attr.mode == "directory" then
				travelDir(file, cb)
				cb(file, true)
			else
				cb(file)
			end
		end
	end
end

local function checkInvalidFile(file)
	if string.find(file, " ") then
		return false
	elseif string.find(file, "	") then
		return false
	elseif utf8.len(file) ~= string.len(file) then
		return false
	end
	return true
end

travelDir(assetsDir, function(file, isDir)
	file = file:sub(string.len(assetsDir) + 1)
	if not checkInvalidFile(file) then
		invalidFiles[file] = true
	end
	if not isDir then
		local tmp, err = io.open(assetsDir..file, "rb")
		local str = tmp:read("*a")
		tmp:close()
		targetTab[file] = {["md5"] = md5.sum(str)}
	end
end)

local file = io.open(targetDir.."/version.manifest", "w+")
file:write(json.encode(tab))
file:close()

tab.assets = targetTab
tab.searchPaths = {}
file = io.open(targetDir.."/project.manifest", "w+")
file:write(json.encode(tab))
file:close()

for k in pairs(invalidFiles) do
	print("warning: invalidFile name = ", k)
end