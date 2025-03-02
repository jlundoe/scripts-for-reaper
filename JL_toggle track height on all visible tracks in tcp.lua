-- Script functionality:
-- Toggles between two different heights for visible tracks in tcp.
-- It reads the all visible tracks height and if their height differs it sets all visible tracks to track_height_a.
-- If track heights match each other and match either track_height_a or track_height_b it toggles to the opposite track height.

-- USER CONFIG AREA -----------------------------------------------------------

-- Set Track Height A in pixels(default)
track_height_a = 102

-- Set Track Height B in pixels
track_height_b = 493

-- If set to true script affect master track as well
local setMasterTrack = true

------------------------------------------------------- END OF USER CONFIG AREA

function Print(param)
    -- reaper.ClearConsole()
    reaper.ShowConsoleMsg(tostring(param).."\n")
end

function CountVisibleTracks()
    local trackSum = reaper.CountTracks(0)
    visibleTrackTable = {}
    visibleTrackIDTable = {}

    local masterTrackVisible = reaper.GetMasterTrackVisibility()
    local masterTrackID = reaper.GetMasterTrack()
    Print(masterTrackVisible)
    Print(masterTrackID)
    if (masterTrackVisible == 1) then
        table.insert(visibleTrackTable, 0)
        table.insert(visibleTrackIDTable, masterTrackID)
    end

    for i = 1, trackSum do
        local trackID = reaper.GetTrack(0, i - 1)
        boolTest = reaper.IsTrackVisible(trackID, 0)
            if (boolTest == true) then
                table.insert(visibleTrackTable, i)
                table.insert(visibleTrackIDTable, trackID)
            end
    end
    visibleTrackSum = #visibleTrackTable
end

function GetTrackHeight()
    trackHeightTable = {}
    
    for i = 1, visibleTrackSum do
        trackHeight = reaper.GetMediaTrackInfo_Value(visibleTrackIDTable[i], "I_TCPH")
        table.insert(trackHeightTable, trackHeight)
    end
end

function TrackHeightMatch()
    firstTrackHeight = trackHeightTable[1]
    
      for i,v in ipairs(trackHeightTable) do
          if (firstTrackHeight ~= v) then
              trackHeightMatch = false
              break
          else
              trackHeightMatch = true
          end
      end
end

function SetTrackHeight()
    if (trackHeightMatch == true and firstTrackHeight == track_height_a) then
        for i = 1, visibleTrackSum do
            reaper.SetMediaTrackInfo_Value(visibleTrackIDTable[i], "I_HEIGHTOVERRIDE", track_height_b)
        end
    else
        for i = 1, visibleTrackSum do
            reaper.SetMediaTrackInfo_Value(visibleTrackIDTable[i], "I_HEIGHTOVERRIDE", track_height_a)
        end
    end
end

-- execute functions
CountVisibleTracks()
GetTrackHeight()
TrackHeightMatch()
SetTrackHeight()

-- update GUI
reaper.TrackList_AdjustWindows(0)
reaper.UpdateArrange()
reaper.UpdateTimeline()
