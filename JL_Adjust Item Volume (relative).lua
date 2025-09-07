-- Adjust volume of currently hovered Item. It needs to be an endless encoder set to relative mode,
-- that outputs cc value <= 63 for decreasing values, and cc value >= 65 for increasing values.

-- USER CONFIG AREA -----------------------------------------------------------

-- set the volume increment in dB (the value will either be added or subtracted depending on knob "scroll" direction)
local dbIncrement = 0.1

------------------------------------------------------- END OF USER CONFIG AREA

-- convert from db
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

function main()
    -- capture mouse cursor context
    reaper.BR_GetMouseCursorContext()
    -- get current item which cursor is hovering over
    local item = reaper.BR_GetMouseCursorContext_Item()
    if item then
        local itemVol = reaper.GetMediaItemInfo_Value(item, "D_VOL")
        -- check item type
        if item ~= nil then
            local activeTake = reaper.GetActiveTake(item)
            if activeTake ~= nil then
                local itemSource = reaper.GetMediaItemTake_Source(activeTake)
                local sourceType = reaper.GetMediaSourceType(itemSource)
                -- check if audio item
                if sourceType ~= "MIDI" then
                    -- check midi cc (up or down indication) and adjust volume accordingly
                    local is_new_value,filename,sectionID,cmdID,mode,resolution,val,contextstr = reaper.get_action_context()
                    local delta = val - 64
                    if delta ~= 0 then
                        local absoluteValue = math.abs(delta)
                        local dbStepValue = dbIncrement * absoluteValue
                        local goUp = delta > 0
                        local newItemVol = setNewVolValue(itemVol, dbStepValue, goUp)
                        reaper.SetMediaItemInfo_Value(item, "D_VOL", newItemVol)
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

main()