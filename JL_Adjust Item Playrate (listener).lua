local reaper = reaper
local rateIncrement = tonumber(reaper.GetExtState("playrateScript", "rateIncrement"))
local undoTimeThreshold = tonumber(reaper.GetExtState("playrateScript", "undoTimeThreshold"))

function setNewRateValue(currentRateAmount, rateIncr, isPositive)
    local itemRate = currentRateAmount
    if isPositive then
        itemRate = itemRate + rateIncr
    else
        itemRate = itemRate - rateIncr
    end
    local newRateValue = itemRate
    return newRateValue
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
                -- get playrate of hovered active take
                local takePlayrate = reaper.GetMediaItemTakeInfo_Value(activeTake, "D_PLAYRATE")
                -- get ccValue buffer
                local ccValue = tonumber(reaper.GetExtState("playrateScript", "ccValueBuffer"))
                if ccValue ~= 64 then
                    local delta = ccValue - 64
                    -- reset ccValue buffer
                    reaper.SetExtState("playrateScript", "ccValueBuffer", "64", false)
                    if delta ~= 0 then
                        local absoluteValue = math.abs(delta)
                        local rateStepValue = rateIncrement * absoluteValue
                        local goUp = delta > 0
                        local newItemRate = setNewRateValue(takePlayrate, rateStepValue, goUp)
                        -- accumulate value
                        -- rateAccumulated = newItemRate
                        reaper.SetMediaItemTakeInfo_Value(activeTake, "D_PLAYRATE", newItemRate)
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
    if (reaper.GetExtState("playrateScript", "isRunningBool") ~= "1") then
        reaper.SetExtState("playrateScript", "isRunningBool", "1", false)
    end
    -- reset the starting flag
    if reaper.GetExtState("playrateScript", "isStarting") == "1" then
        reaper.SetExtState("playrateScript", "isStarting", "0", false)
    end
    -- execute adjustValue() main method
    -- check if scheduled time snapshot is <= defined time interval from the last saved time snapshot
    local lastActivityTime = tonumber(reaper.GetExtState("playrateScript", "lastActivityTime"))
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
    local tickListener = (reaper.GetExtState("playrateScript", "tickBuffer")) == "1"
    if tickListener then
        adjustValue()
        reaper.SetExtState("playrateScript", "tickBuffer", "0", false)
    end
end

function exit()
    -- set isRunning flag back to false
    reaper.SetExtState("playrateScript", "isRunningBool", "0", false)
    -- make an empty undo block to wrap all ticks together in one undo point 
    reaper.Undo_BeginBlock()
    reaper.Undo_EndBlock("Adjust Item Playrate", -1)
end

reaper.defer(deferloop)
reaper.atexit(exit)