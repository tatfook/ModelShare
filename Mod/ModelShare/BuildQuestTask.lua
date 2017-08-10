--[[
Title: BuildQuestTask
Author(s):  BIG
Date: 2017.8
Desc: BuildQuest for modelshare mod
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ModelShare/BuildQuestTask.lua");
local ModelBuildQuest = commonlib.gettable("Mod.ModelShare.BuildQuest");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestProvider.lua");
NPL.load("(gl)Mod/ModelShare/BuildQuestProvider.lua");

local BuildQuest              = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest");
local BuildQuestProvider      = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");
local ModelBuildQuestProvider = commonlib.gettable("Mod.ModelShare.BuildQuestProvider");

local ModelBuildQuest = commonlib.inhert(nil, commonlib.gettable("Mod.ModelShare.BuildQuest"));

function BuildQuest:ctor()

end

function BuildQuest:Init(theme_index, task_index)
	--echo("HELPHELPHELPHELPHELPHELPHELPHELPHELPHELP")
	echo("HelpPage.cur_category")
	echo(HelpPage.cur_category)
	--echo(HelpPage.task_index)
	if(HelpPage.cur_category and (HelpPage.cur_category == "command" or HelpPage.cur_category == "shortcutkey")) then
		return;
	end

	ModelBuildQuestProvider:Init(); --[[last work position]]
	BuildQuest.cur_theme_index = theme_index or BuildQuest.cur_theme_index or 1;

	local user = UserProfile.GetUser();
	--if(user) then
		--user:ResetBuildProgress(BuildQuest.cur_theme_index)
	--end

	if(HelpPage.cur_category and HelpPage.cur_category == "tutorial") then
		BuildQuest.cur_task_index = BuildQuest.GetCurrentFinishedTaskIndex(nil,HelpPage.cur_category);
	else
		BuildQuest.cur_task_index = 1;
	end
	
	if(task_index) then
		BuildQuest.cur_task_index = task_index;
	end
	
	local cur_theme_taskDS = BuildQuestProvider.GetTasks_DS(BuildQuest.cur_theme_index,HelpPage.cur_category);
	if(cur_theme_taskDS and BuildQuest.cur_task_index > #cur_theme_taskDS) then
		BuildQuest.cur_task_index = #cur_theme_taskDS;
	end
	HelpPage.cur_category = HelpPage.cur_category or "template";
	if(BuildQuest.inited) then
		return;
	end

	BuildQuest.inited = true;

	page = document:GetPageCtrl();
	BuildQuest.template_theme_index = BuildQuest.template_theme_index or 1;
	BuildQuest.template_task_index  = BuildQuest.template_task_index or 1;
end


