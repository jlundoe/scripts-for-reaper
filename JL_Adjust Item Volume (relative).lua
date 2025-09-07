MidiCCplaceholder = 65
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
                -- check midi cc and adjust volume accordingly
                if MidiCCplaceholder == 63 then
                    -- calculate new volume
                    local newItemVol = setNewVolValue(itemVol, DBincr, false)
                    -- set new volume
                    reaper.SetMediaItemInfo_Value(item, "D_VOL", newItemVol)
                elseif MidiCCplaceholder == 65 then
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



-- if audio item
    -- check midi cc value
    -- if 65 turn up by "var-amount"
    -- if 63 turn down by "var-amount"



--     -- set audio items rnd volume change
--     -- loop through items in table
--     for key, value in pairs(selAudioItems) do
--         local currentItemVol
--         if relVolumeVariation then
--             -- get current item volume
--             currentItemVol = reaper.GetMediaItemInfo_Value(value, "D_VOL")
--         else
--             -- reset item volume to zero
--             currentItemVol = 1
--         end
--         -- generate new item volume (new value relative to it's previous volume)
--         local newItemVol = generateNewVolValue(currentItemVol, maxVolumeVariation)
--         -- set item to new random volume
--         reaper.SetMediaItemInfo_Value(value, "D_VOL", newItemVol)
    
--         -- set items to generated colorcode (as indicator)
--         reaper.SetMediaItemInfo_Value(value, "I_CUSTOMCOLOR", colorCode|0x1000000)
--     end
-- end

main()