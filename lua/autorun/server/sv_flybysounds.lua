resource.AddSingleFile("sound/pink/flybysounds/fast_windloop1-louder.wav")

local nextThink = 0

-- the clientside func with the same name, but a special version for the server, a little hacky
local function isEntityRelevant(ent)
    if not IsValid(ent) or not IsValid(ent:GetPhysicsObject()) then return false end

    local physObj = ent:GetPhysicsObject()
    if physObj:IsAsleep() or not physObj:IsMotionEnabled() then return false end
  
    if ent:IsPlayer() then return false end

    if ent:WaterLevel() > 1 then return false end
    
  
    return true
end

-- Currently only used for spinning sounds
hook.Add("Think","FlyBySound_ServerThink",function()
    if GetConVar("sv_flybysounds_spinsounds"):GetBool() == false or CurTime() < nextThink then return end

    -- Maybe the think time should be changeable?
    nextThink = CurTime() + 0.27

    for _, vClass in ipairs(FlyBySound_validClasses) do
        for _, ent in ipairs(ents.FindByClass(vClass)) do
            if isEntityRelevant(ent) then
                local angVel = ent:GetPhysicsObject():GetAngleVelocity()
                if ent:GetNWVector("FlyBySound_AngularVelocity",vector_zero) != angVel then
                    ent:SetNWVector("FlyBySound_AngularVelocity",angVel)
                end
            end
        end
    end
end)

concommand.Add("flybysounds_test",function(ply)
    if SERVER then
        local tr = ply:GetEyeTrace()
        if IsValid(tr.Entity) then
            print(tr.Entity:GetClass())
        end
    end
end)

