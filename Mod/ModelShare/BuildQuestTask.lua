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
NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/HelpPage.lua");

local BuildQuest              = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest");
local BuildQuestProvider      = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");
local ModelBuildQuestProvider = commonlib.gettable("Mod.ModelShare.BuildQuestProvider");
local HelpPage                = commonlib.gettable("MyCompany.Aries.Game.Tasks.HelpPage");
local UserProfile             = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");

local ModelBuildQuest = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.BuildQuest"));

function ModelBuildQuest:ctor()
	ModelBuildQuestProvider = ModelBuildQuestProvider:new();
end

function ModelBuildQuest:Init(theme_index, task_index)
	echo("HelpPage.cur_category")
	echo(HelpPage.cur_category)
	--echo(HelpPage.task_index)

	if(HelpPage.cur_category and (HelpPage.cur_category == "command" or HelpPage.cur_category == "shortcutkey")) then
		return;
	end

	ModelBuildQuestProvider:Init(); --[[last work position]]
	self.cur_theme_index = theme_index or BuildQuest.cur_theme_index or 1;

	if(HelpPage.cur_category and HelpPage.cur_category == "tutorial") then
		self.cur_task_index = BuildQuest.GetCurrentFinishedTaskIndex(nil,HelpPage.cur_category);
	else
		self.cur_task_index = 1;
	end

	echo(self.cur_task_index);

	if(task_index) then
		self.cur_task_index = task_index;
	end
	
	local cur_theme_taskDS = ModelBuildQuestProvider:GetTasks_DS(self.cur_theme_index, HelpPage.cur_category);

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


