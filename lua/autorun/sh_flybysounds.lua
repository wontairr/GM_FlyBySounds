CreateConVar("sv_flybysound_minspeed", 100, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Minimum speed required for sound to be heard.")
CreateConVar("sv_flybysound_maxspeed", 1000, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Volume does not increase after this speed is exceeded.")

CreateConVar("sv_flybysound_minshapevolume", 1, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Pitch does not increase when volume (area) falls below this amount.")
CreateConVar("sv_flybysound_maxshapevolume", 300, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Pitch does not decrease when volume (area) exceeds this amount.")

CreateConVar("sv_flybysound_minvol", 30, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Object must have at least this much volume (area) to produce fly by sounds.")

CreateConVar("sv_flybysound_playersounds", 0, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Script applies to players.")

CreateConVar("sv_flybysound_spinsounds",0,{FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY},"If set to 1, the sound will be heard when an entity is spinning.")

concommand.Add("sv_flybysound_resetconvars",function(ply)
	RunConsoleCommand("sv_flybysound_minspeed",	100)
	RunConsoleCommand("sv_flybysound_maxspeed",	1000)
	RunConsoleCommand("sv_flybysound_minshapevolume", 1)
	RunConsoleCommand("sv_flybysound_maxshapevolume", 300)
	RunConsoleCommand("sv_flybysound_minvol", 30)
	RunConsoleCommand("sv_flybysound_playersounds", 0)
	RunConsoleCommand("sv_flybysound_spinsounds", 0)
end)

FlyBySound_validClasses = {
	"prop_physics",
	"prop_physics_override",
	"prop_physics_multiplayer",
	"prop_ragdoll",

	"prop_vehicle_jeep",
	"prop_vehicle_airboat",
	"prop_vehicle_prisoner_pod",

	"npc_rollermine",
	"sent_ball",
	"player",

	"gmod_wheel",
}

-- Spawnmenu -> Options -> Fly By Sounds
if CLIENT then


	hook.Add("PopulateToolMenu", "FlyBySoundsMenu", function()
		spawnmenu.AddToolMenuOption("Options", "Fly By Sounds", "FlyBySoundsClientMenu", "Client Options", "", "", function(panel)
			panel:ClearControls()
			panel:Help("Fly By Sounds Client Options")
			panel:Help("(All number sliders have an effect on performance!)")

			panel:Help(" ")

			panel:NumSlider("Entity Scan Delay","cl_flybysound_scandelay",0.00,1.00,2)
			panel:NumSlider("Sound Update Delay","cl_flybysound_updatedelay",0.00,0.300,2)

			panel:NumSlider("Maximum Audible Distance","cl_flybysound_cutoffdist",0,10000,1)

			panel:CheckBox("Alternative Sound Effect","cl_flybysound_altsound")

			panel:Help(" ")

			panel:Button("Reset To Defaults","cl_flybysound_resetconvars",{})
		end)
		spawnmenu.AddToolMenuOption("Options", "Fly By Sounds", "FlyBySoundsServerMenu", "Server Options", "", "", function(panel)
			panel:ClearControls()
			panel:Help("Fly By Sounds Server Options")

			panel:Help(" ")

			panel:NumSlider("Minimum Speed", "sv_flybysound_minspeed", 0, 2000, 0)
			panel:NumSlider("Maximum Speed", "sv_flybysound_maxspeed", 1, 1000,0)

			panel:NumSlider("Minimum Shape Size", "sv_flybysound_minshapevolume", 0, 1000, 0)
			panel:NumSlider("Maximum Shape Size", "sv_flybysound_maxshapevolume", 1, 1000, 0)

			panel:Help(" ")

			panel:NumSlider("Minimum Volume", "sv_flybysound_minvol", 1, 100,2)

			panel:Help(" ")

			panel:CheckBox("Apply to Players", "sv_flybysound_playersounds")
			panel:CheckBox("Spinning Sounds", "sv_flybysound_spinsounds")

			panel:Help(" ")

			panel:Button("Reset To Defaults","sv_flybysound_resetconvars",{})
		end)
	end)
end