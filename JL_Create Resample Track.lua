-- Inserts a new track that acts as a resampling track for 'live resampling' purposes.
-- Audio input based on currently selected track(s).
-- If you are familiar with abletons 'resampling input option' it is similar, with the main difference
-- being that you choose the specific tracks you wish to receive audio from.

-- USER CONFIG AREA -----------------------------------------------------------

-- Set Track Height A in pixels(default).
MinimizedHeight = 116

-- Set same track color. If several tracks selected the first selected track color is copied.
SetSameTrColor = true

------------------------------------------------------- END OF USER CONFIG AREA

local defsendvol = ({reaper.BR_Win32_GetPrivateProfileString('REAPER', 'defsendvol', '1',  reaper.get_ini_file() )})[2]
local defsendflag = ({reaper.BR_Win32_GetPrivateProfileString('REAPER', 'defsendflag', '0',  reaper.get_ini_file() )})[2]
local isFolderTrackSelected = false
local selectedTracksArr = {}
local maxTrackNumber = -math.huge
local minTrackNumber = math.huge

reaper.ClearConsole()
function Print(param)
  reaper.ShowConsoleMsg(tostring(param).."\n")
end

function Main()
  TrackSum = reaper.CountSelectedTracks(0)

  for i = 1, TrackSum do
    local tr = reaper.GetSelectedTrack(0, i - 1)
    -- insert selected tracks into array
    table.insert(selectedTracksArr, tr)
    --- check for folder tracks and set global bool
    if CheckFolderTracksSelected(tr) == 1 then
      if not isFolderTrackSelected then
        isFolderTrackSelected = true
      end
    end
    -- get first and last (of selected tracks) position
    local trPosNumber = reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
    minTrackNumber = math.min(minTrackNumber, trPosNumber)
    maxTrackNumber = math.max(maxTrackNumber, trPosNumber)
  end

  local returnvalue, trackname = setNewTrackName(minTrackNumber)
  -- if a folder track is selected
    -- put code here




  -- if no folder track is selected
  -- insert track (if script name isn't cancelled)
  if returnvalue then 
    local newDestTr = InsertTrackBelowSelTracks(maxTrackNumber)
    ConfigureNewTrack(newDestTr, trackname)
  end
end

function setNewTrackName(minTrackNumber)
  FirstSelTr = reaper.GetTrack(0, minTrackNumber - 1)
  local retval, FirstSelTrName = reaper.GetTrackName(FirstSelTr)
  if retval then
    -- popup window to input new destination track name. Is populated with ReSmpl + first selected track name
    returnvalue, strname = reaper.GetUserInputs('Send name', 1, 'Resampling track name' ,'ReSmpl: ' .. FirstSelTrName)
    return returnvalue, strname
  end
end

-- insert track right below last selected track
function InsertTrackBelowSelTracks(lastSelTrackPos)
  reaper.InsertTrackAtIndex(lastSelTrackPos, true)
  local newDestTr = reaper.GetTrack(0, lastSelTrackPos)
  return newDestTr
end

function ConfigureNewTrack(tr, trackname)
  for i = 1, TrackSum do
    local trackID = reaper.GetSelectedTrack(0, i - 1)
    NewSendID = reaper.CreateTrackSend(trackID, tr)
    reaper.SetTrackSendInfo_Value(trackID, 0, NewSendID, 'D_VOL', defsendvol)
    reaper.SetTrackSendInfo_Value(trackID, 0, NewSendID, 'I_SENDMODE', defsendflag)
    SetOriginTrackRecState(trackID)
  end

  if NewSendID >= 0 then
    if tr then
      SetDestTrackColor(FirstSelTr, tr)

      -- select created track
      reaper.SetOnlyTrackSelected(tr)

      reaper.GetSetMediaTrackInfo_String(tr, 'P_NAME', trackname ,true)
      reaper.SetMediaTrackInfo_Value(tr, "I_RECMODE_FLAGS", 2)
      reaper.SetMediaTrackInfo_Value(tr, "I_RECMODE", 1)
      reaper.SetMediaTrackInfo_Value(tr, "I_RECARM", 1)
      reaper.SetMediaTrackInfo_Value(tr, "B_MUTE", 1)

      -- set track height to custom track_height
      reaper.SetMediaTrackInfo_Value(tr, "I_HEIGHTOVERRIDE", MinimizedHeight)

      --  set to "Display gain reduction in track meters for plug-ins that support it
      reaper.Main_OnCommand(42705, 0)
    end
  end
  reaper.TrackList_AdjustWindows(false)
end

-- set track color of new destination track
function SetDestTrackColor(firstSelTrack, destinationTrack)
  if firstSelTrack and SetSameTrColor then 
    TrackColor = reaper.GetTrackColor(firstSelTrack)
    if TrackColor ~= 0 then
      reaper.SetTrackColor(destinationTrack, TrackColor)
    else
      do return end
    end
  end
end

-- set recording state on original track based on its input-setting
function SetOriginTrackRecState(originTrack)
  MidiInputIsEnabled = false;

  if originTrack then
    local inputStateData = reaper.GetMediaTrackInfo_Value(originTrack, "I_RECINPUT")
    if inputStateData >= 4096 then
      MidiInputIsEnabled = true;
    else
      MidiInputIsEnabled = false;
    end
  end

  if MidiInputIsEnabled then
    reaper.Main_OnCommand(40491, 0)
    reaper.SetMediaTrackInfo_Value(originTrack, "I_RECARM", 0)
    reaper.SetMediaTrackInfo_Value(originTrack, "I_RECMODE", 0)
  else
    reaper.Main_OnCommand(40491, 0)
    reaper.SetMediaTrackInfo_Value(originTrack, "I_RECARM", 0)
    reaper.SetMediaTrackInfo_Value(originTrack, "I_RECMODE", 0)
  end
end

function CheckFolderTracksSelected (tr)
  local checkFolder = reaper.GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH")
  return checkFolder
end

Main()