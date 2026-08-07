-- Acceptance test: M.start() reuse path updates webroot when dynamic_root is true
-- Outer boundary: lua/livepreview/init.lua M.start()

vim.opt.rtp:prepend(vim.uv.cwd())

local server_mod = require("livepreview.server")
local config = require("livepreview.config")

-- Enable dynamic_root
config.config.dynamic_root = true

-- Stub Server to avoid TCP blocking
local FakeServer = {}
FakeServer.__index = FakeServer

function FakeServer:start(_ip, _port, _opts) end
function FakeServer:stop(cb) if cb then cb() end end

server_mod.Server.new = function(_cls, webroot)
    local obj = setmetatable({}, FakeServer)
    obj.server = true
    obj.port   = 4000
    obj.webroot = webroot
    return obj
end

local M = require("livepreview.init")

print("Test: M.start() reuse path updates webroot when dynamic_root is true")

-- Given: server started for file A in /tmp/dirA
M.start("/tmp/dirA/index.html", 4000)
assert(M.serverObj.webroot == "/tmp/dirA", "webroot should be dirA after first start, got: " .. tostring(M.serverObj.webroot))

-- When: M.start() called for file B in /tmp/dirB (reuse path)
M.start("/tmp/dirB/page.html", 4000)

-- Then: webroot updated to dirB
assert(M.serverObj.webroot == "/tmp/dirB",
    "webroot must be updated to dirB on reuse, got: " .. tostring(M.serverObj.webroot))

print("OK")
