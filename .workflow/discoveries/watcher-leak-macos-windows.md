# Watcher leak on macOS/Windows

## Type
pre-existing-bug

## Found during
Slice 01 — Reuse running server (PR review)

## Location
`lua/livepreview/server/init.lua:142`

## Description
`Server:watch_dir()` creates a `uv_fs_event_t` handle via `watch(self.webroot, true)` on macOS/Windows but discards the return value. The handle is never stored on `self._watcher`, so `Server:stop()` cannot close it. Each server lifecycle creates an orphaned watcher.

On Linux, the `fswatch.Watcher` is correctly stored as `self._watcher` (line 148) and closed in `Server:stop()` (line 232-234).

## Fix
```lua
-- line 142, change:
watch(self.webroot, true)
-- to:
self._watcher = watch(self.webroot, true)
```

Both `uv_fs_event_t` and `fswatch.Watcher` implement `:close()`, so `Server:stop()` handles either type.

## Impact
Low — orphaned watchers accumulate but only fire the `LivePreviewDirChanged` autocmd, which filters by extension. No incorrect behavior, just resource leak.

## Testing note
Cannot reproduce on Linux (different code path). Fix is 1 line and obvious from code reading.
