-- delete_current.lua
-- Deletes the file currently being played.
-- Bindings (put them in input.conf):
--   DEL         script-message delete-current recycle
--   Shift+DEL   script-message delete-current permanent
--
-- Mode "recycle"   -> Windows Recycle Bin (recoverable)
-- Mode "permanent" -> permanent delete, asks for a second press first
--                     (cannot be undone)

local utils = require 'mp.utils'

-- Seconds allowed between the two presses confirming a permanent delete.
local CONFIRM_WINDOW = 3

local function osd(msg) mp.osd_message(msg, 3) end

local function ps_escape(s) return (s:gsub("'", "''")) end

local function delete(mode)
    mode = mode or "recycle"

    local path = mp.get_property("path")
    if not path or path == "" then
        osd("No file playing")
        return
    end
    if path:match("^%a[%w+.-]*://") then
        osd("Deleting remote streams is not supported")
        return
    end

    local working_dir = mp.get_property("working-directory", "")
    local full = utils.join_path(working_dir, path)

    local count = mp.get_property_number("playlist-count", 0)
    local pos   = mp.get_property_number("playlist-pos", -1)

    -- Release the file handle before deleting
    if count > 1 and pos >= 0 and pos < count - 1 then
        mp.command("playlist-next")
    elseif count > 1 and pos == count - 1 then
        mp.command("playlist-prev")
    else
        mp.command("stop")
    end
    if pos >= 0 then
        mp.commandv("playlist-remove", tostring(pos))
    end

    local ps_cmd
    if mode == "permanent" then
        ps_cmd = string.format(
            "Remove-Item -LiteralPath '%s' -Force -ErrorAction Stop",
            ps_escape(full))
    else
        ps_cmd = string.format(
            "Add-Type -AssemblyName Microsoft.VisualBasic; " ..
            "[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('%s','OnlyErrorDialogs','SendToRecycleBin')",
            ps_escape(full))
    end

    local res = mp.command_native({
        name = "subprocess",
        args = { "powershell", "-NoProfile", "-NonInteractive",
                 "-WindowStyle", "Hidden", "-Command", ps_cmd },
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
    })

    if res.status == 0 then
        local label = (mode == "permanent") and "Deleted permanently" or "Moved to the Recycle Bin"
        osd(label .. ": " .. full)
    else
        osd("Delete failed: " .. (res.stderr or "unknown error"))
    end
end

-- A permanent delete cannot be undone, so it takes two presses within
-- CONFIRM_WINDOW seconds. The Recycle Bin mode acts right away.
local pending_path = nil
local pending_timer = nil

local function clear_pending()
    if pending_timer then
        pending_timer:kill()
        pending_timer = nil
    end
    pending_path = nil
end

local function request_delete(mode)
    mode = mode or "recycle"

    if mode ~= "permanent" then
        clear_pending()
        delete(mode)
        return
    end

    local path = mp.get_property("path")
    if not path or path == "" then
        osd("No file playing")
        return
    end

    if pending_path == path then
        clear_pending()
        delete("permanent")
        return
    end

    pending_path = path
    if pending_timer then pending_timer:kill() end
    pending_timer = mp.add_timeout(CONFIRM_WINDOW, function()
        pending_timer = nil
        pending_path = nil
        osd("Permanent delete cancelled")
    end)
    osd(string.format(
        "Permanent delete: press again within %d s to confirm", CONFIRM_WINDOW))
end

-- A new file means the pending confirmation no longer applies.
mp.register_event("file-loaded", clear_pending)
mp.register_event("end-file", clear_pending)

mp.register_script_message("delete-current", request_delete)
