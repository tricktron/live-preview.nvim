-- Acceptance test: M.start() reuses a running server
-- Outer boundary: lua/livepreview/init.lua M.start()

vim.opt.rtp:prepend(vim.uv.cwd())

local server_mod = require("livepreview.server")

-- Stub Server:new() / Server:start() / Server:stop() to avoid real TCP binding.
-- Minimal fake — just enough to make M.is_running() return true and avoid blocking I/O.
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

print("Test: M.start() with a running server reuses it — serverObj identity unchanged, same port, returns true")

-- Given: server started for file A
local ret1 = M.start(vim.uv.cwd() .. "/tests/index.html", 4000)
assert(ret1 == true, "first M.start() should return true, got: " .. tostring(ret1))
assert(M.serverObj ~= nil, "M.serverObj should be set after first M.start()")
assert(M.is_running() == true, "M.is_running() should be true after first M.start()")

local original_server = M.serverObj

-- When: M.start() called again for file B
local ret2 = M.start(vim.uv.cwd() .. "/tests/test.md", 4000)

-- Then: original server is reused unchanged
assert(ret2 == true,
    "second M.start() should return true, got: " .. tostring(ret2))
assert(M.serverObj == original_server,
    "M.serverObj identity must be unchanged — server was recreated instead of reused")
assert(M.serverObj.port == 4000,
    "server port must be preserved: expected 4000, got " .. tostring(M.serverObj and M.serverObj.port))
assert(M.is_running() == true,
    "M.is_running() should still be true after second M.start()")

print("OK")
