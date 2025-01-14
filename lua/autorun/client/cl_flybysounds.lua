local minspeed, maxspeed, minshapevolume, maxshapevolume, minvol, cutoffDist, scanDelay, updateDelay, spinSounds, playerSounds, windSound

local relevantEntities = {}

CreateClientConVar("cl_flybysound_scandelay", 0.5, true, false, "How often the script scans for relevant entities. Smaller values give faster feedback but are more CPU intensive.", 0.0, 1.0)
CreateClientConVar("cl_flybysound_updatedelay", 0.05, true, false, "How often the script updates sound effects (pitch, volume). Smaller values give smoother sound transitions but more CPU intensive.", 0.0, 0.3)
CreateClientConVar("cl_flybysound_cutoffdist", 3000, true, false, "Maximum distance at which sounds can be heard. Smaller values can give better performance in large maps.", 0, 10000)
CreateClientConVar("cl_flybysound_altsound", 0, true, false, "If set to 1 then an alternative wind sound will play. (Portal 2)")

concommand.Add("cl_flybysound_resetconvars",function()
  RunConsoleCommand("cl_flybysound_scandelay", 0.5)
  RunConsoleCommand("cl_flybysound_updatedelay", 0.05)
  RunConsoleCommand("cl_flybysound_cutoffdist", 3000)
  RunConsoleCommand("cl_flybysound_altsound", 0)
end)

local function updateCVars()
  minspeed        = GetConVar("sv_flybysound_minspeed"):GetInt()
  maxspeed        = GetConVar("sv_flybysound_maxspeed"):GetInt()
  minshapevolume  = GetConVar("sv_flybysound_minshapevolume"):GetInt()
  maxshapevolume  = GetConVar("sv_flybysound_maxshapevolume"):GetInt()
  minvol          = GetConVar("sv_flybysound_minvol"):GetInt()
  cutoffDist      = GetConVar("cl_flybysound_cutoffdist"):GetInt()
  scanDelay       = GetConVar("cl_flybysound_scandelay"):GetFloat()
  updateDelay     = GetConVar("cl_flybysound_updatedelay"):GetFloat()
  playerSounds    = GetConVar("sv_flybysound_playersounds"):GetBool()
  spinSounds      = GetConVar("sv_flybysound_spinsounds"):GetBool()

  windSound = "pink/flybysounds/fast_windloop1-louder.wav"
  if GetConVar("cl_flybysound_altsound"):GetBool() == true then
    windSound = "pink/flybysounds/portal2_wind.wav"
  end
end

updateCVars()

cvars.RemoveChangeCallback("cl_flybysound_altsound", "flybysounds_altsound_callback")

cvars.AddChangeCallback("cl_flybysound_altsound", function(convar, oldVal, newVal)
  updateCVars()

  for _, entity in ipairs(relevantEntities) do
    if not entity.FlyBySound then continue end

    entity.FlyBySound:Stop()
    entity.FlyBySoundPlaying = false
    entity.FlyBySound = CreateSound(entity, windSound)
  end

end, "flybysounds_altsound_callback")


local function isEntityRelevant(ent)
  if not IsValid(ent) then return false end
  if cutoffDist > 0 and EyePos():DistToSqr(ent:GetPos()) > cutoffDist * cutoffDist then return false end

  if ent:IsPlayer() then
    if ent:GetMoveType() == MOVETYPE_NOCLIP or not playerSounds or not ent:Alive() then return false end
  end

  if ent:WaterLevel() > 1 then return false end

  if LocalPlayer():GetVehicle() == ent then return false end

  return true
end

local function averageSpeed(ent)
  local vel = ent:GetVelocity()

  local angVel = 1.0
  if spinSounds then angVel = ent.FlyBySoundAngVel or 0.0 end

  local averageSpeed = (math.abs(vel.y) + math.abs(vel.x) + math.abs(vel.z)) / 3

  return math.Round(averageSpeed + angVel)
end

local function guessScale(ent)
  if not IsValid(ent) then return 0 end
  if ent:IsPlayer() then return 125 end
  local min, max = ent:GetCollisionBounds()

  if not min then min = 0 end
  if not max then max = 0 end

  local vecDiff = min - max
  local scaled = vecDiff * ent:GetModelScale()
  return math.Round((math.abs(scaled.x) + math.abs(scaled.y) + math.abs(scaled.z)) / 3)
end

local function scanForRelevantEntities()
  relevantEntities = {}

  for _, vClass in ipairs(FlyBySound_validClasses) do
    for _, ent in ipairs(ents.FindByClass(vClass)) do
      if ent == LocalPlayer() then continue end
      if isEntityRelevant(ent) then
        table.insert(relevantEntities, ent)
      elseif ent.FlyBySound and ent.FlyBySound:IsPlaying() then
        ent.FlyBySound:Stop()
        ent.FlyBySoundPlaying = false
      end
    end
  end
end



local function updateSound(entity)
  if not IsValid(entity) then return end

  local shapevolume = guessScale(entity)
  if shapevolume < minvol then return end

  -- Calculate cheap angular velocity length
  if spinSounds then
    local entAngles = entity:GetAngles()

    if entity.FlyBySoundLastAng then
      local angDiff = entAngles - entity.FlyBySoundLastAng

      angDiff.x = (angDiff.x + 180) % 360 - 180
      angDiff.y = (angDiff.y + 180) % 360 - 180
      angDiff.z = (angDiff.z + 180) % 360 - 180

      local angDiffLength = (math.abs(angDiff.x) + math.abs(angDiff.y) + math.abs(angDiff.z)) / 3

      entity.FlyBySoundAngVel = angDiffLength * 10
    end

    entity.FlyBySoundLastAng = entAngles
  end

  local speed = averageSpeed(entity)
  if speed <= minspeed then
    if entity.FlyBySoundPlaying then
      entity.FlyBySoundPlaying = false
      if entity.FlyBySound then entity.FlyBySound:FadeOut(0.5) end
    end
    return
  end

  if not entity.FlyBySound then
    entity.FlyBySound = CreateSound(entity, windSound)
  end

  local dist = math.Round(EyePos():Distance(entity:GetPos()))
  if entity == LocalPlayer() then dist = maxspeed - speed end
  if dist < 0 then dist = 0 end

  local volume = (math.Clamp(speed, minspeed, maxspeed) - minspeed) / (maxspeed - minspeed)
  if entity == LocalPlayer() then volume = volume / 3 end

  local pitch = ((1 - ((math.Clamp(shapevolume, minshapevolume, maxshapevolume) - minshapevolume) / (maxshapevolume - minshapevolume))) * 200) - (dist / 500) * 50
  pitch = math.max(pitch, 10)

  if entity.FlyBySoundPlaying then
    entity.FlyBySound:ChangeVolume(volume, 0)
    entity.FlyBySound:ChangePitch(pitch, 0)
  else
    entity.FlyBySoundPlaying = true
    entity.FlyBySound:PlayEx(volume, pitch)
  end
end

local lastScan = 0

-- this can run less often to save CPU time
hook.Add("Think", "FlyBySound_Scan", function()
  if scanDelay > 0 and CurTime() < lastScan + scanDelay then return end
  lastScan = CurTime()

  updateCVars()
  scanForRelevantEntities()
end)

local lastUpdate = 0

-- this must run more often to create smooth sound transitions
hook.Add("Think", "FlyBySound_Think", function()
  if updateDelay > 0 and CurTime() < lastUpdate + updateDelay then return end
  lastUpdate = CurTime()

  for _, entity in ipairs(relevantEntities) do
    updateSound(entity)
  end

  if (playerSounds and LocalPlayer():GetMoveType() != MOVETYPE_NOCLIP) then
    updateSound(LocalPlayer())
  elseif LocalPlayer().FlyBySound and LocalPlayer().FlyBySound:IsPlaying() then
    LocalPlayer().FlyBySound:Stop()
    LocalPlayer().FlyBySoundPlaying = false
  end
end)

hook.Add("EntityRemoved", "FlyBySound_EntityRemoved", function(ent)
  if ent.FlyBySound then
    ent.FlyBySound:Stop()
  end
end)
