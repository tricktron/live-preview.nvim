local Server = require("livepreview.server").Server

print("Test: Server:new() returns a fresh instance with Server metatable")

-- Given the Server class table
-- When creating a new instance
local instance = Server:new(vim.uv.cwd())

-- Then it should be a distinct table, not the class table itself
assert(instance ~= Server, "Server:new() returned the class table instead of a new instance")

-- And it should have Server as its metatable (proper inheritance)
assert(getmetatable(instance) == Server, "Server:new() instance should have Server as its metatable")

print("OK")
