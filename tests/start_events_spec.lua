-- Acceptance test: M.start() registers both TextChanged and LivePreviewDirChanged events
-- Outer boundary: lua/livepreview/init.lua M.start()

vim.opt.rtp:prepend(vim.uv.cwd())

local server_mod = require("livepreview.server")

-- Stub Server:new() / :start() / :stop() to avoid TCP blocking.
-- :start() captures on_events so we can assert on the keys passed.
local captured_on_events = nil

local FakeServer = {}
FakeServer.__index = FakeServer

function FakeServer:start(_ip, _port, opts)
    captured_on_events = opts and opts.on_events or {}
end

function FakeServer:stop(cb)
    if cb then cb() end
end

server_mod.Server.new = function(_cls, _webroot)
    local obj = setmetatable({}, FakeServer)
    obj.server = true -- truthy so M.is_running() returns true
    obj.port   = 4000
    return obj
end

local M = require("livepreview.init")

print("Test: M.start() passes both TextChanged and LivePreviewDirChanged events to Server:start()")

-- When: M.start() called once for a markdown file
M.start(vim.uv.cwd() .. "/tests/test.md", 4000)

-- Then: on_events must contain BOTH sets
assert(captured_on_events ~= nil,
    "Server:start() was never called — on_events not captured")

assert(captured_on_events["TextChanged"] ~= nil,
    "on_events must include TextChanged for markdown → websocket text updates")

assert(captured_on_events["LivePreviewDirChanged"] ~= nil,
    "on_events must include LivePreviewDirChanged for HTML dir-change reloads")

print("OK")
