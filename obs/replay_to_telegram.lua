obs = obslua

SCRIPT_PATH = (os.getenv("HOME") or "/home/jaennil") .. "/.config/bin/send_replay.sh"
SCRIPT_LOG = (os.getenv("HOME") or "/home/jaennil") .. "/send_replay.obs.log"

function script_description()
    return "Sends the last saved replay buffer file to Telegram using a local shell script."
end

local function log_info(message)
    obs.script_log(obs.LOG_INFO, "[replay_to_telegram] " .. message)
end

local function log_warn(message)
    obs.script_log(obs.LOG_WARNING, "[replay_to_telegram] " .. message)
end

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function on_event(event)
    if event ~= obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
        return
    end

    local path = obs.obs_frontend_get_last_replay()
    if path == nil or path == "" then
        log_warn("Replay saved event received, but last replay path is empty")
        return
    end

    local command = "/usr/bin/bash " .. shell_quote(SCRIPT_PATH) .. " " .. shell_quote(path) ..
        " >>" .. shell_quote(SCRIPT_LOG) .. " 2>&1 &"

    log_info("Sending replay: " .. path)
    local ok, _, code = os.execute(command)
    log_info("Spawned upload command: ok=" .. tostring(ok) .. " code=" .. tostring(code))
end

function script_load(settings)
    obs.obs_frontend_add_event_callback(on_event)
    log_info("Loaded")
end
