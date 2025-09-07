DBincr = 1

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
    local itemVol = reaper.GetMediaItemInfo_Value(item, "D_VOL")
    -- reaper.ShowConsoleMsg(tostring(itemVol))
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
                reaper.ShowConsoleMsg(tostring(val))
                if val == 63 then
                    -- calculate new volume
                    local newItemVol = setNewVolValue(itemVol, DBincr, false)
                    -- set new volume
                    reaper.SetMediaItemInfo_Value(item, "D_VOL", newItemVol)
                elseif val == 65 then
                    -- calculate new volume
                    local newItemVol = setNewVolValue(itemVol, DBincr, true)
                    -- set new volume
                    reaper.SetMediaItemInfo_Value(item, "D_VOL", newItemVol)
                else
                    reaper.ShowConsoleMsg("do nothing")
                end
            else
                reaper.ShowConsoleMsg("ignoring midi item")
            end
        end
    end
end

main()