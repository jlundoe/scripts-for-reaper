-- Adjust playrate of currently hovered Item. It needs to be an endless encoder set to relative mode,
-- that outputs cc value <= 63 for decreasing values, and cc value >= 65 for increasing values.
-- NB.... -> This script works only together with the "Adjust Item Playrate (listener) script" -> paste in the command ID (of
-- the listener script) in the config area below.

-- USER CONFIG AREA -----------------------------------------------------------

-- set the rate increment as float (the value will either be added or subtracted depending on knob "scroll" direction)
local rateIncrement = 0.05

-- paste in the action ID from "Adjust Item Playrate (listener)". This is individual to all Reaper installs, so it needs to be done manually. Be sure to remember the quotes "" around the ID.
local deferLoopActionId = "_RSfcf5445c23df5bcdf72201db4838a13024834e04"

-- adjust time interval threshold between ticks in ms, which defines when the undo point is created (a low value might create several undo points during the same knob motion)
-- I recommend not to edit this value
local undoTimeThreshold = 0.25

------------------------------------------------------- END OF USER CONFIG AREA
local reaper = reaper

function setConfigValues()
    reaper.SetExtState("playrateScript", "rateIncrement", tostring(rateIncrement), false)
    reaper.SetExtState("playrateScript", "undoTimeThreshold", tostring(undoTimeThreshold), false)
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
    reaper.SetExtState("playrateScript", "ccValueBuffer", tostring(val), false)
    -- feed extstate variable to listener script
    reaper.SetExtState("playrateScript", "tickBuffer", "1", false)

    -- get precise time of when action is triggered
    local lastActivity = reaper.time_precise()
    reaper.SetExtState("playrateScript", "lastActivityTime", tostring(lastActivity), false)
end

local isStarting = reaper.GetExtState("playrateScript", "isStarting")
local isRunning = reaper.GetExtState("playrateScript", "isRunningBool")

if isStarting ~= "1" and isRunning ~= "1" then
    reaper.SetExtState("playrateScript", "isStarting", "1", false)
    setConfigValues()
    activateDeferLoop()
end
trigger()

reaper.defer(function() end)