-- Adjust playrate of currently hovered Item. It needs to be an endless encoder set to relative mode,
-- that outputs cc value <= 63 for decreasing values, and cc value >= 65 for increasing values.

-- USER CONFIG AREA -----------------------------------------------------------

-- set the rate increment as float (the value will either be added or subtracted depending on knob "scroll" direction)
local volIncrement = 1

-- paste in the deferloop scripts action ID (this is individual to all Reaper installs, so it needs to be done manually). Be sure to remember the quotes "" around the ID.
local deferLoopActionId = "_RS1a5ecf7669b87c0c7276f23a07a1a12808526eaa"

-- adjust time interval threshold between ticks in ms, which defines when the undo point is created (a low value might create several undo points during the same knob motion)
-- I recommend not to edit this value
local undoTimeThreshold = 0.25

------------------------------------------------------- END OF USER CONFIG AREA
local reaper = reaper

function setConfigValues()
    reaper.SetExtState("itemVolumeScript", "volIncrement", tostring(volIncrement), false)
    reaper.SetExtState("itemVolumeScript", "undoTimeThreshold", tostring(undoTimeThreshold), false)
end

function activateDeferLoop()
    -- get correct numeric command ID
    local deferLoopCmdID = reaper.NamedCommandLookup(tostring(deferLoopActionId))
    reaper.Main_OnCommand(deferLoopCmdID, 0)
end

function trigger()
    -- check midi cc (up or down indication + acceleration)
    local is_new_value,filename,sectionID,cmdID,mode,resolution,val,contextstr = reaper.get_action_context()
    -- set midi ccValue extstate variable
    reaper.SetExtState("itemVolumeScript", "ccValueBuffer", tostring(val), false)
    -- feed extstate variable to listener script
    reaper.SetExtState("itemVolumeScript", "tickBuffer", "1", false)

    -- get precise time of when action is triggered
    local lastActivity = reaper.time_precise()
    reaper.SetExtState("itemVolumeScript", "lastActivityTime", tostring(lastActivity), false)
end

local isStarting = reaper.GetExtState("itemVolumeScript", "isStarting")
local isRunning = reaper.GetExtState("itemVolumeScript", "isRunningBool")

if isStarting ~= "1" and isRunning ~= "1" then
    reaper.SetExtState("itemVolumeScript", "isStarting", "1", false)
    setConfigValues()
    activateDeferLoop()
end

trigger()
reaper.defer(function() end)