function deferloop()
    -- set deferloop as running
    reaper.SetExtState("playrateScript", "isRunningBool", "1", false)
    -- check if scheduled time snapshot is <= defined time interval from the last saved time snapshot
    local lastActivityTime = reaper.GetExtState("playrateScript", "lastActivityTime")
    -- reaper.ShowConsoleMsg("\n"..lastActivityTime)
    local scheduledTime = reaper.time_precise()
    local timeDifference = scheduledTime - lastActivityTime
    -- schedule new iteration if timeDifference is less defined time interval
    if timeDifference <= 1 then
        reaper.defer(deferloop)
        reaper.ShowConsoleMsg("listener running")
    else
        reaper.ShowConsoleMsg("listener finished")
    end
    -- reaper.ShowConsoleMsg("\n"..tostring(timeDifference))
end

function exit()
    -- set isRunning flag back to false
    reaper.SetExtState("playrateScript", "isRunningBool", "0", false)
end

reaper.defer(deferloop)
reaper.atexit(exit)