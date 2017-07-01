--[[
Title: ModelManager
Author(s):  BIG
Date: 2017.7
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ModelShare/ModelManager.lua");
local ModelManager = commonlib.gettable("Mod.ModelShare.ModelManager");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestProvider.lua");

local loginMain          = commonlib.gettable("Mod.WorldShare.login.loginMain");
local BuildQuest         = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest");
local BuildQuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");

local ModelManager = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.ModelManager"));

function ModelManager:ctor()
	BuildQuest.OnInit(BuildQuest.template_theme_index,BuildQuest.template_task_index);

	self.themesDS = BuildQuestProvider.GetThemes_DS();
	self.themesDS[#self.themesDS + 1] = {order=10,foldername="bendi",official=false,icon="",unlock_coins="0",name="本地全局模板",image="",};
	self.themesDS[#self.themesDS + 1] = {order=10,foldername="bendi",official=false,icon="",unlock_coins="0",name="本地存档模板",image="",};
	self.themesDS[#self.themesDS + 1] = {order=10,foldername="bendi",official=false,icon="",unlock_coins="0",name="云模板",image="",};
end

function ModelManager:SetInstance()
	ModelManager.curInstance = self;
end

function ModelManager:ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/ModelShare/ModelManager.html", 
		name = "ModelManager",
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory / false will only hide window
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 0,
		allowDrag = true,
		bShow = bShow,
		directPosition = true,
			align = "_ct",
			x = -636/2,
			y = -450/2,
			width = 636,
			height = 450,
		cancelShowAnimation = true,
	});
end

function ModelManager:SetPage()
	self.page = document:GetPageCtrl();
end

function ModelManager:OnClose()
	if(self.page) then
		self.page:CloseWindow();
	end

	ModelManager.curInstance = nil;
end

function ModelManager.GetTheme_DS(index)
    local themesDS = BuildQuestProvider.GetThemes_DS();
	
    if(not index) then
        return #themesDS;
    else
        return themesDS[index];
    end
end