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
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");

local BuildQuest              = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest");
local BuildQuestProvider      = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");
local ModelBuildQuestProvider = commonlib.gettable("Mod.ModelShare.BuildQuestProvider");
local HelpPage                = commonlib.gettable("MyCompany.Aries.Game.Tasks.HelpPage");
local UserProfile             = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");
local QuickSelectBar          = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");

local ModelBuildQuest = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.BuildQuest"));

ModelBuildQuest.cur_instance         = nil;
ModelBuildQuest.cur_task_index       = nil;
ModelBuildQuest.template_theme_index = nil;

function ModelBuildQuest:ctor()
end

function ModelBuildQuest:Init(theme_index, task_index)
	--echo("HelpPage.cur_category")
	--echo(HelpPage.cur_category)
	--echo(HelpPage.task_index)

--	if(HelpPage.cur_category and (HelpPage.cur_category == "command" or HelpPage.cur_category == "shortcutkey")) then
--		return;
--	end

	curModelBuildQuestProvider = ModelBuildQuestProvider:new();

	self.cur_theme_index = theme_index or self.cur_theme_index or 1;
	self.cur_task_index  = task_index  or self.cur_task_index  or 1;

--	if(HelpPage.cur_category and HelpPage.cur_category == "tutorial") then
--		self.cur_task_index = BuildQuest.GetCurrentFinishedTaskIndex(nil,HelpPage.cur_category);
--	else
--		self.cur_task_index = 1;
--	end

	local cur_theme_taskDS = curModelBuildQuestProvider:GetTasks_DS(self.cur_theme_index, HelpPage.cur_category);

	if(cur_theme_taskDS and BuildQuest.cur_task_index > #cur_theme_taskDS) then
		BuildQuest.cur_task_index = #cur_theme_taskDS;
	end

	HelpPage.cur_category = HelpPage.cur_category or "template";

	if(ModelBuildQuestProvider.inited) then
		return;
	end

	ModelBuildQuestProvider.inited = true;

	self.template_theme_index = self.template_theme_index or 1;
	self.template_task_index  = self.template_task_index  or 1;
end

function ModelBuildQuest.GetCurrentQuest()
	return ModelBuildQuest.cur_instance;
end

function ModelBuildQuest:ShowCreateNewThemePage(themeKey, callbcak)
	ModelBuildQuest.new_theme_key         = themeKey;
	ModelBuildQuest.create_theme_callback = callbcak;

	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "script/apps/Aries/Creator/Game/Tasks/BuildQuestTaskNewTheme.html", 
		name = "BuildQuestTask.CreateNewThemeShowPage", 
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		isShowTitleBar = false, 
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 1,
		allowDrag = true,
		click_through = false,
		directPosition = true,
			--align = "_lt",
			align = "_ct",
			x = -320/2,
			y = -130/2,
			width = 320,
			height = 130,
	});	
end

function ModelBuildQuest:IsTaskUnderway()
	if(ModelBuildQuest.cur_instance) then
		return true;
	else
		return false;
	end
end

-- @param bCommitChange: true to commit all changes made 
function ModelBuildQuest:EndEditing(bCommitChange)
	--BuildQuest.ClosePage()
	GameLogic.HideTipText("<player>");

	if(ModelBuildQuest.cur_instance) then
		local self = ModelBuildQuest.cur_instance;

		self:UnregisterHooks();
		self:ResetHints();

		self.finished = true;
		ModelBuildQuest.cur_instance = nil;

		local profile = UserProfile.GetUser();
		profile:GetEvents():DispatchEvent({type = "BuildProgressChanged" , status = "end",});
	end
end

function ModelBuildQuest:UnregisterHooks()
	GameLogic.events:RemoveEventListener("CreateBlockTask", BuildQuest.OnCreateBlockTask, self);
	self:GetEvents():RemoveEventListener("OnClickAccelerateProgress", BuildQuest.OnClickAccelerateProgress, self);

	if(not System.options.IsMobilePlatform) then
		QuickSelectBar.BindProgressBar(nil);
	end
end


