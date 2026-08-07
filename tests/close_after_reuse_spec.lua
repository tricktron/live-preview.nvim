-- Acceptance test: M.close() after reuse path still stops the server cleanly
-- Outer boundary: lua/livepreview/init.lua M.close()

vim.opt.rtp:prepend(vim.uv.cwd())

local server_mod = require("livepreview.server")

-- Stub Server:new() / Server:start() / Server:stop() to avoid real TCP binding.
local FakeServer = {}
FakeServer.__index = FakeServer

function FakeServer:start(_ip, _port, _opts)
    -- no-op: skip real TCP bind
end

function FakeServer:stop(cb)
    if cb then cb() end
end

server_mod.Server.new = function(_cls, _webroot)
    local obj = setmetatable({}, FakeServer)
    obj.server = true  -- truthy so M.is_running() returns true
    obj.port   = 4000
    return obj
end

local M = require("livepreview.init")

print("Test: M.close() after reuse path sets M.serverObj to nil and M.is_running() returns false")

-- Given: server started for file A, then reused for file B
M.start(vim.uv.cwd() .. "/tests/index.html", 4000)
M.start(vim.uv.cwd() .. "/tests/test.md", 4000)

assert(M.is_running() == true, "M.is_running() should be true before M.close()")
assert(M.serverObj ~= nil, "M.serverObj should be set before M.close()")

-- When: M.close() is called after the reuse path
M.close()

-- Then: server is stopped cleanly
assert(M.serverObj == nil,
    "M.serverObj should be nil after M.close(), got: " .. tostring(M.serverObj))
assert(M.is_running() == false,
    "M.is_running() should be false after M.close()")

print("OK")
