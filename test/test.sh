#!/usr/bin/pleal

for c = 0, 10000000 do
	local file = io.open("testfile", "r")
	file:close()
end
print("done")
os.execute("sleep 100")