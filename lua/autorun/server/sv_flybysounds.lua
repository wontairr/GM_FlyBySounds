resource.AddSingleFile("sound/pink/flybysounds/fast_windloop1-louder.wav")
resource.AddSingleFile("sound/pink/flybysounds/portal2_wind.wav")

-- NOTE: Unused
hook.Add("Think","FlyBySound_ServerThink",function()
    return
end)

concommand.Add("flybysounds_testsight",function(ply)
    if SERVER and GetConVar("developer"):GetBool() then
        local tr = ply:GetEyeTrace()
        if IsValid(tr.Entity) then
            print(tr.Entity:GetClass())
        end
    end
end)