CreateConVar("sv_flybysound_minspeed", 100, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Minimum speed required for sound to be heard.")
CreateConVar("sv_flybysound_maxspeed", 1000, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Volume does not increase after this speed is exceeded.")

CreateConVar("sv_flybysound_minshapevolume", 1, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Pitch does not increase when volume (area) falls below this amount.")
CreateConVar("sv_flybysound_maxshapevolume", 300, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Pitch does not decrease when volume (area) exceeds this amount.")

CreateConVar("sv_flybysound_minvol", 30, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Object must have at least this much volume (area) to produce fly by sounds.")

CreateConVar("sv_flybysound_playersounds", 0, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Script applies to players.")

local windsound = "pink/flybysounds/fast_windloop1-louder.wav"

if (SERVER) then

	AddCSLuaFile()
	resource.AddSingleFile("sound/" .. windsound)

else

	CreateClientConVar("cl_flybysound_updatedelay", 0.1, true, false, "How often the script updates. Smaller values are more accurate but more CPU intensive.", 0.0, 0.3)

	local function averageSpeed(ent)
		local vel = ent:GetVelocity()
		return math.Round((math.abs(vel.y) + math.abs(vel.x) + math.abs(vel.z))/3)
	end

	local function guessScale(ent)
		if (!IsValid(ent)) then return 0 end
		if (ent:IsPlayer()) then return 125 end
		local min, max = ent:GetCollisionBounds()
		local vecdiff = min - max
		local scaled = vecdiff*ent:GetModelScale()
		return math.Round((math.abs(scaled.x) + math.abs(scaled.y) + math.abs(scaled.z))/3)
	end

	local validClasses = {"prop_physics", "prop_physics_multiplayer", "prop_ragdoll", "npc_rollermine", "sent_ball"}

	local lastUpdate = 0

	hook.Add("Think", "FlyBySound_Think", function()
		local updateDelay = GetConVar("cl_flybysound_updatedelay"):GetFloat()

		if (updateDelay > 0) then
			if (CurTime() < lastUpdate + updateDelay) then return end
			lastUpdate = CurTime()
		end

		local minspeed = GetConVar("sv_flybysound_minspeed"):GetInt()
		local maxspeed = GetConVar("sv_flybysound_maxspeed"):GetInt()
		local minshapevolume = GetConVar("sv_flybysound_minshapevolume"):GetInt()
		local maxshapevolume = GetConVar("sv_flybysound_maxshapevolume"):GetInt()
		local minvol = GetConVar("sv_flybysound_minvol"):GetInt()

		for k, v in pairs (ents.GetAll()) do

			if (v == LocalPlayer()) then
				if (v:GetMoveType() == MOVETYPE_NOCLIP) then
					if (v.FlyBySound) then
						v.FlyBySound:Stop()
					end
					continue
				end
			end

			if (!table.HasValue(validClasses, v:GetClass())) then
				if (!(v:IsPlayer() && GetConVar("sv_flybysound_playersounds"):GetBool())) then
					if (v.FlyBySound) then
						v.FlyBySound:Stop()
					end
					continue
				end
			end

			local speed = averageSpeed(v)
			local shapevolume = guessScale(v)

			if (shapevolume < minvol) then continue end

			if (!v.FlyBySound) then
				v.FlyBySound = CreateSound(v, windsound)
			end

			if (v:WaterLevel() > 1) then
				v.FlyBySound:FadeOut(0.5)
				continue
			end

			if (speed > minspeed) then

				local dist = math.Round(EyePos():Distance(v:GetPos()))
				if (v == LocalPlayer()) then dist = maxspeed - speed end
				if (dist < 0) then dist = 0 end
				local volume = (math.Clamp(speed, minspeed, maxspeed)-minspeed)/(maxspeed-minspeed)
				if (v == LocalPlayer()) then volume = volume/3 end
				local pitch = ((1-((math.Clamp(shapevolume, minshapevolume, maxshapevolume)-minshapevolume)/(maxshapevolume-minshapevolume)))*200)-(dist/500)*50

				if (pitch < 10) then
					pitch = 10
				end

				if (v.FlyBySoundPlaying) then
					v.FlyBySound:ChangeVolume(volume, 0)
					v.FlyBySound:ChangePitch(pitch, 0)
					continue
				end

				v.FlyBySoundPlaying = true

				v.FlyBySound:PlayEx(volume, pitch)

			else

				if (!v.FlyBySoundPlaying) then continue end
				v.FlyBySoundPlaying = false
				v.FlyBySound:FadeOut(0.5)

			end

		end
	end)

	hook.Add("EntityRemoved", "FlyBySound_EntityRemoved", function(ent)
		if (ent.FlyBySound) then
			ent.FlyBySound:Stop()
		end
	end)

end
