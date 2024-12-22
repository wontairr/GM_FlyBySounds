local minspeed, maxspeed, minshapevolume, maxshapevolume, minvol, cutoffDist, scanDelay, updateDelay, playerSounds
local validClasses = {"prop_physics", "prop_physics_multiplayer", "prop_ragdoll", "npc_rollermine", "sent_ball", "player"}

CreateClientConVar("cl_flybysound_scandelay", 0.5, true, false, "How often the script scans for relevant entities. Smaller values give faster feedback but are more CPU intensive.", 0.0, 1.0)
CreateClientConVar("cl_flybysound_updatedelay", 0.05, true, false, "How often the script updates sound effects (pitch, volume). Smaller values give smoother sound transitions but more CPU intensive.", 0.0, 0.3)
CreateClientConVar("cl_flybysound_cutoffdist", 3000, true, false, "Maximum distance at which sounds can be heard. Smaller values can give better performance in large maps.", 0, 10000)

local function updateCVars()
  minspeed = GetConVar("sv_flybysound_minspeed"):GetInt()
  maxspeed = GetConVar("sv_flybysound_maxspeed"):GetInt()
  minshapevolume = GetConVar("sv_flybysound_minshapevolume"):GetInt()
  maxshapevolume = GetConVar("sv_flybysound_maxshapevolume"):GetInt()
  minvol = GetConVar("sv_flybysound_minvol"):GetInt()
  cutoffDist = GetConVar("cl_flybysound_cutoffdist"):GetInt()
  scanDelay = GetConVar("cl_flybysound_scandelay"):GetFloat()
  updateDelay = GetConVar("cl_flybysound_updatedelay"):GetFloat()
  playerSounds = GetConVar("sv_flybysound_playersounds"):GetBool()
end

updateCVars()

local function isEntityRelevant(ent)
  if not IsValid(ent) then return false end
  if cutoffDist > 0 and EyePos():DistToSqr(ent:GetPos()) > cutoffDist * cutoffDist then return false end

  if ent:IsPlayer() then
    if ent:GetMoveType() == MOVETYPE_NOCLIP or not playerSounds or not ent:Alive() then return false end
  end

  if ent:WaterLevel() > 1 then return false end

  return true
end

local function averageSpeed(ent)
  local vel = ent:GetVelocity()
  return math.Round((math.abs(vel.y) + math.abs(vel.x) + math.abs(vel.z)) / 3)
end

local function guessScale(ent)
  if not IsValid(ent) then return 0 end
  if ent:IsPlayer() then return 125 end
  local min, max = ent:GetCollisionBounds()
  local vecdiff = min - max
  local scaled = vecdiff * ent:GetModelScale()
  return math.Round((math.abs(scaled.x) + math.abs(scaled.y) + math.abs(scaled.z)) / 3)
end

local function scanForRelevantEntities()
  relevantEntities = {}

  for _, vClass in ipairs(validClasses) do
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

  local speed = averageSpeed(entity)
  if speed <= minspeed then
    if entity.FlyBySoundPlaying then
      entity.FlyBySoundPlaying = false
      entity.FlyBySound:FadeOut(0.5)
    end
    return
  end

  if not entity.FlyBySound then
    entity.FlyBySound = CreateSound(entity, "pink/flybysounds/fast_windloop1-louder.wav")
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
