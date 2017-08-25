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
--NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.lua");
--NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestProvider.lua");
NPL.load("(gl)Mod/ModelShare/BuildQuestProvider.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/HelpPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");

--local BuildQuest              = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest");
--local BuildQuestProvider      = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");
local ModelBuildQuestProvider = commonlib.gettable("Mod.ModelShare.BuildQuestProvider");
local HelpPage                = commonlib.gettable("MyCompany.Aries.Game.Tasks.HelpPage");
local UserProfile             = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");
local QuickSelectBar          = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local TaskManager             = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local BlockTemplate           = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
local BlockEngine             = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");

local ModelBuildQuest = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("Mod.ModelShare.BuildQuest"));

ModelBuildQuest.cur_instance         = nil;
ModelBuildQuest.cur_task_index       = nil;
ModelBuildQuest.cur_theme_index      = nil;
ModelBuildQuest.template_theme_index = nil;

function ModelBuildQuest:ctor()
	ModelBuildQuest.cur_theme_index = self.cur_theme_index or ModelBuildQuest.cur_theme_index or 1;
	ModelBuildQuest.cur_task_index  = self.cur_task_index  or ModelBuildQuest.cur_task_index  or 1;

	ModelBuildQuest.template_theme_index = self.template_theme_index or ModelBuildQuest.template_theme_index or 1;
	ModelBuildQuest.template_task_index  = self.template_task_index  or ModelBuildQuest.template_task_index  or 1;
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

-- handle click once deploy via the template interface, instead of the task interface.  
-- return true if click once deploy is executed. 
function ModelBuildQuest:TryClickOnceDeploy()
	if(self.task) then
		if(self.ClickOnceDeploy or self.task:IsClickOnceDeploy()) then
			self.finished = true;
			self.task:ClickOnceDeploy(self.UseAbsolutePos);
			return true;
		end
	end
end

function ModelBuildQuest:RegisterHooks()
	GameLogic.events:AddEventListener("CreateBlockTask", BuildQuest.OnCreateBlockTask, self, "BuildQuest");
	self:GetEvents():AddEventListener("OnClickAccelerateProgress", BuildQuest.OnClickAccelerateProgress, self, "BuildQuest");

	if(not System.options.IsMobilePlatform) then
		QuickSelectBar.BindProgressBar(self);
	end
end

function ModelBuildQuest:StartEditing()
	local profile = UserProfile.GetUser();
	profile:GetEvents():DispatchEvent({type = "BuildProgressChanged" , status = "start",});
end

function ModelBuildQuest:Run()
	if(ModelBuildQuest.cur_instance) then
		-- stop last task of the same type
		ModelBuildQuest.EndEditing();
	end

	if(not TaskManager.AddTask(self)) then
		return;
	end
	
	--[[if(true) then
		return;
	end]]

	cur_instance = self;

	local curModelBuildQuestProvider = ModelBuildQuestProvider:new();
	-- current task
	self.task = self.task or curModelBuildQuestProvider:GetTask(self.theme_id, self.task_id, self.category or "template");
	--echo(self.task, true)

	if(not self.task) then
		ModelBuildQuest.EndEditing();
		return;
	end
	
	if(self:TryClickOnceDeploy()) then
		ModelBuildQuest.EndEditing();
		return;
	end

	-- current step
	self.step = self.task:GetStep(self.step_id);

	if(self.step) then
		self.bom = self.step:GetBom();
	end

	if(not self.bom) then
		self.finished = true;
		return;
	end
	
	local oldPosX, oldPosY, oldPosZ = ParaScene.GetPlayer():GetPosition();
	self.oldPosX, self.oldPosY, self.oldPosZ = oldPosX, oldPosY, oldPosZ;

	-- origin
	self.x,  self.y,  self.z  = self.x or oldPosX, self.y or oldPosY, self.z or oldPosZ;
	self.bx, self.by, self.bz = BlockEngine:block(self.x, self.y+0.1, self.z);
	
	self.finished = false;
	self:RegisterHooks();

	if(self.task.UseAbsolutePos) then
		self.task:ResetProjectionScene();
	end
	-- BuildQuest.ShowPage();

	self:StartEditing();
end

function ModelBuildQuest.CreateFromTemplate(filename, x, y, z)
	if(not x) then
		x, y, z = ParaScene.GetPlayer():GetPosition();
	end

	local bx, by, bz = BlockEngine:block(x, y+0.1, z);
	
	if(not ModelBuildQuest.LoadTemplate(filename, bx, by, bz, true)) then
		_guihelper.MessageBox(format(L"无法打开文件:%s", commonlib.Encoding.DefaultToUtf8(filename)))
	end
end

-- public function to load from a template to a given scene position.
-- @return true if created
function ModelBuildQuest.LoadTemplate(filename, bx, by, bz, bSelect)
	local task = BlockTemplate:new({
		operation = BlockTemplate.Operations.Load,
		filename = filename,
		blockX = bx,
		blockY = by,
		blockZ = bz,
		bSelect=bSelect
	});

	return task:Run();
end
