-- Inserts a new track that acts as a resampling track for 'live resampling' purposes.
-- Audio input based on currently selected track(s).
-- If you are familiar with abletons 'resampling input option' it is similar, with the main difference
-- being that you choose the specific tracks you wish to receive audio from.

-- USER CONFIG AREA -----------------------------------------------------------

-- Set Track Height A in pixels(default).
TrackHeight_A = 116

-- Set same track color. If several tracks selected the first selected track color is copied.
SetSameTrColor = true

------------------------------------------------------- END OF USER CONFIG AREA

local defsendvol = ({reaper.BR_Win32_GetPrivateProfileString('REAPER', 'defsendvol', '1',  reaper.get_ini_file() )})[2]
local defsendflag = ({reaper.BR_Win32_GetPrivateProfileString('REAPER', 'defsendflag', '0',  reaper.get_ini_file() )})[2]

function Print(param)
  reaper.ClearConsole()
  reaper.ShowConsoleMsg(tostring(param).."\n")
end

function Main()
  TrackSum = reaper.CountSelectedTracks(0)
  local maxTrackNumber = -math.huge
  local minTrackNumber = math.huge

    -- get first and last (of selected tracks) position
    for i = 1, TrackSum do
      local tr = reaper.GetSelectedTrack(0, i - 1)
      local trPosNumber = reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
      minTrackNumber = math.min(minTrackNumber, trPosNumber)
      maxTrackNumber = math.max(maxTrackNumber, trPosNumber)
    end
  
    FirstSelTr = reaper.GetTrack(0, minTrackNumber - 1)
    local retval, FirstSelTrName = reaper.GetTrackName(FirstSelTr)
  
  -- popup window to input new destination track name. Is populated with ReSmpl + first selected track name
  local returnValue, sname = reaper.GetUserInputs('Send name', 1, 'Resampling track name' ,'ReSmpl: ' .. FirstSelTrName)

  if returnValue then 

    NewDestTr = InsertTrackBelowSelTracks(maxTrackNumber)

    for i = 1, TrackSum do
      local trackID = reaper.GetSelectedTrack(0, i - 1)
      NewSendID = reaper.CreateTrackSend(trackID, NewDestTr)
      reaper.SetTrackSendInfo_Value(trackID, 0, NewSendID, 'D_VOL', defsendvol)
      reaper.SetTrackSendInfo_Value(trackID, 0, NewSendID, 'I_SENDMODE', defsendflag)
      SetOriginTrackRecState(trackID)
    end

    if NewSendID >= 0 then
      if NewDestTr then
        SetDestTrackColor(FirstSelTr, NewDestTr)

        -- select created track
        reaper.SetOnlyTrackSelected(NewDestTr)

        reaper.GetSetMediaTrackInfo_String(NewDestTr, 'P_NAME', sname ,true)
        reaper.SetMediaTrackInfo_Value(NewDestTr, "I_RECMODE_FLAGS", 2)
        reaper.SetMediaTrackInfo_Value(NewDestTr, "I_RECMODE", 1)
        reaper.SetMediaTrackInfo_Value(NewDestTr, "I_RECARM", 1)
        reaper.SetMediaTrackInfo_Value(NewDestTr, "B_MUTE", 1)

        -- set track height to custom track_height
        reaper.SetMediaTrackInfo_Value(NewDestTr, "I_HEIGHTOVERRIDE", TrackHeight_A)

        --  set to "Display gain reduction in track meters for plug-ins that support it
        reaper.Main_OnCommand(42705, 0)
      end
    end
    reaper.TrackList_AdjustWindows(false)
  end
end

-- insert track right below last selected track
function InsertTrackBelowSelTracks(lastSelTrackPos)
  reaper.InsertTrackAtIndex(lastSelTrackPos, true)
  local NewDestTr = reaper.GetTrack(0, lastSelTrackPos)
  return NewDestTr
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

Main()