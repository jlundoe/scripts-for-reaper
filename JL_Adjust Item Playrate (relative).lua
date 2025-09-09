-- Adjust playrate of currently hovered Item. It needs to be an endless encoder set to relative mode,
-- that outputs cc value <= 63 for decreasing values, and cc value >= 65 for increasing values.

-- USER CONFIG AREA -----------------------------------------------------------

-- set the rate increment as float (the value will either be added or subtracted depending on knob "scroll" direction)
local rateIncrement = 0.025

-- paste in the deferloop scripts action ID (this is individual to all Reaper installs, so it needs to be done manually). Be sure to remember the quotes "" around the ID.
local deferLoopActionId = "_RSfcf5445c23df5bcdf72201db4838a13024834e04"

------------------------------------------------------- END OF USER CONFIG AREA

-- set new value based on former playrate value
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

function main()
    -- capture mouse cursor context
    reaper.BR_GetMouseCursorContext()
    -- get current item which cursor is hovering over
    local item = reaper.BR_GetMouseCursorContext_Item()
    -- get precise time of when action is triggered
    local lastActivity = reaper.time_precise()
    reaper.SetExtState("playrateScript", "lastActivityTime", tostring(lastActivity), false)

    if item then
        -- check item type
        if item ~= nil then
            local activeTake = reaper.GetActiveTake(item)
            if activeTake ~= nil then
                local itemSource = reaper.GetMediaItemTake_Source(activeTake)
                local sourceType = reaper.GetMediaSourceType(itemSource)
                -- check if audio item
                if sourceType ~= "MIDI" then
                    -- get playrate of hovered active take
                    local takePlayrate = reaper.GetMediaItemTakeInfo_Value(activeTake, "D_PLAYRATE")
                    -- check midi cc (up or down indication) and adjust playrate accordingly
                    local is_new_value,filename,sectionID,cmdID,mode,resolution,val,contextstr = reaper.get_action_context()
                    local delta = val - 64
                    if delta ~= 0 then
                        local absoluteValue = math.abs(delta)
                        local rateStepValue = rateIncrement * absoluteValue
                        local goUp = delta > 0
                        local newItemRate = setNewRateValue(takePlayrate, rateStepValue, goUp)
                        reaper.SetMediaItemTakeInfo_Value(activeTake, "D_PLAYRATE", newItemRate)
                        reaper.UpdateItemInProject(item)
                    else
                        -- reaper.ShowConsoleMsg("no up or down value registered")
                    end
                else
                    -- reaper.ShowConsoleMsg("ignoring midi item")
                end
            end
        end
    end
end

function activateDeferLoop()
        -- check if script is already running
    local isRunning = (reaper.GetExtState("playrateScript", "isrunningBool") == "1")
    if isRunning then
        return
    end
    -- get correct numeric command ID
    local deferLoopCmdID = reaper.NamedCommandLookup(tostring(deferLoopActionId))
    -- set deferloop as running
    reaper.SetExtState("playrateScript", "isRunningBool", "1", false)
    reaper.Main_OnCommand(deferLoopCmdID, 0)
end

main()
activateDeferLoop()