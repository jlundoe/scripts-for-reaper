local reaper = reaper
local volIncrement = tonumber(reaper.GetExtState("itemVolumeScript", "volIncrement"))
local undoTimeThreshold = tonumber(reaper.GetExtState("itemVolumeScript", "undoTimeThreshold"))

-- convert from db and set new volume value
function setNewVolValue(currentItemVol, dBincr, isPositive)
    -- get old db
    local itemDb = 20*math.log(currentItemVol, 10)
    
    -- check if db should be added or subtracted
    if isPositive then
        itemDb = itemDb + dBincr
    else
        itemDb = itemDb - dBincr
    end
    
    -- convert new db back to float
    local newItemFloat = 10^(itemDb/20)

    return newItemFloat
end

function adjustValue()
    -- capture mouse cursor context
    reaper.BR_GetMouseCursorContext()
    -- get current item which cursor is hovering over
    local item = reaper.BR_GetMouseCursorContext_Item()
    
    if item then
        -- check item type
        local activeTake = reaper.GetActiveTake(item)
        if activeTake ~= nil then
            local itemSource = reaper.GetMediaItemTake_Source(activeTake)
            local sourceType = reaper.GetMediaSourceType(itemSource)
            -- check if audio item
            if sourceType ~= "MIDI" then
                -- get volume of hovered item
                local itemVolume = reaper.GetMediaItemInfo_Value(item, "D_VOL")
                -- get ccValue buffer
                local ccValue = tonumber(reaper.GetExtState("itemVolumeScript", "ccValueBuffer"))
                if ccValue ~= 64 then
                    local delta = ccValue - 64
                    -- reset ccValue buffer
                    reaper.SetExtState("itemVolumeScript", "ccValueBuffer", "64", false)
                    if delta ~= 0 then
                        local absoluteValue = math.abs(delta)
                        local volStepValue = volIncrement * absoluteValue
                        local goUp = delta > 0
                        local newItemVol = setNewVolValue(itemVolume, volStepValue, goUp)
                        reaper.SetMediaItemInfo_Value(item, "D_VOL", newItemVol)
                        reaper.UpdateItemInProject(item)
                    else
                    end
                end
            else
            end
        end
    end
end

function deferloop()
    -- set deferloop as running
    if (reaper.GetExtState("itemVolumeScript", "isRunningBool") ~= "1") then
        reaper.SetExtState("itemVolumeScript", "isRunningBool", "1", false)
    end
    -- reset the starting flag
    if reaper.GetExtState("itemVolumeScript", "isStarting") == "1" then
        reaper.SetExtState("itemVolumeScript", "isStarting", "0", false)
    end
    -- execute adjustValue() main method
    -- check if scheduled time snapshot is <= defined time interval from the last saved time snapshot
    local lastActivityTime = tonumber(reaper.GetExtState("itemVolumeScript", "lastActivityTime"))
    local scheduledTime = reaper.time_precise()
    local timeDifference = scheduledTime - lastActivityTime
    -- schedule new iteration if timeDifference is less defined time interval
    if timeDifference <= undoTimeThreshold then
        main()
        reaper.defer(deferloop)
    else
    end
end

function main()
    local tickListener = (reaper.GetExtState("itemVolumeScript", "tickBuffer")) == "1"
    if tickListener then
        adjustValue()
        reaper.SetExtState("itemVolumeScript", "tickBuffer", "0", false)
    end
end

function exit()
    -- set isRunning flag back to false
    reaper.SetExtState("itemVolumeScript", "isRunningBool", "0", false)
    reaper.Undo_BeginBlock()
    reaper.Undo_EndBlock("Adjust Item Volume", -1)
end

reaper.defer(deferloop)
reaper.atexit(exit)