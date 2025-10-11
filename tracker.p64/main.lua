--[[pod_format="raw",created="2025-05-21 04:11:58",modified="2025-05-21 04:11:59",revision=1]]
DATP = ""
if not fetch"src/main.lua" then
	cd("/ext/tracker")
	DATP = "tracker.p64/"
end
include"src/main.lua"