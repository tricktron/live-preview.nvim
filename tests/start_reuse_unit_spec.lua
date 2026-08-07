-- Unit test: M.start() returns true immediately when server is already running
-- Target: lua/livepreview/init.lua M.start() early-return guard

vim.opt.rtp:prepend(vim.uv.cwd())

local server_mod = require("livepreview.server")

-- Stub Server:new() to return a fake server so M.is_running() returns true
local FakeServer = {}
FakeServer.__index = FakeServer

function FakeServer:start(_ip, _port, _opts) end
function FakeServer:stop(cb) if cb then cb() end end

server_mod.Server.new = function(_cls, _webroot)
    local obj = setmetatable({}, FakeServer)
    obj.server = true  -- truthy so M.is_running() returns true
    obj.port   = 4000
    return obj
end

local M = require("livepreview.init")

print("Test: M.start() reuses running server — serverObj identity must be unchanged")

-- Given: server already running
M.start(vim.uv.cwd() .. "/tests/index.html", 4000)
local original_server = M.serverObj
assert(M.is_running() == true, "precondition: server must be running")

-- When: M.start() called again
M.start(vim.uv.cwd() .. "/tests/test.md", 4000)

-- Then: same serverObj (no recreate)
assert(M.serverObj == original_server,
    "M.serverObj identity must be unchanged — server was recreated instead of reused")

print("OK")
