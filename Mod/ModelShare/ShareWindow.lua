--[[
Title: ShareModel
Author(s):  BIG
Date: 2017.6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ModelShare/ShareWindow.lua");
local ShareWindow = commonlib.gettable("Mod.ModelShare.ShareWindow");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua");

local loginMain  = commonlib.gettable("Mod.WorldShare.login.loginMain");

local ShareWindow = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.ShareWindow"));

function ShareWindow:ctor()
end

function ShareWindow:init()
end

function ShareWindow:ShowPage()
	if(ShareWindow.curInstance) then
		System.App.Commands.Call("File.MCMLWindowFrame", {
			url  = "Mod/ModelShare/ShareWindow.html", 
			name = "ShareWindow",
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory / false will only hide window
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 0,
			allowDrag = true,
			bShow = bShow,
			directPosition = true,
				align = "_ct",
				x = -450/2,
				y = -500/2,
				width = 450,
				height = 500,
			cancelShowAnimation = true,
		});
	end
end

function ShareWindow:SetInstance()
	ShareWindow.curInstance = self;
end

function ShareWindow:SetPage()
	self.page = document.GetPageCtrl();
end

function ShareWindow:PageRefresh()
	self.page:Refresh(0.01);
end

function ShareWindow:Login()
	loginMain.modalCall = function()
		self:PageRefresh();
	end;

	loginMain.showLoginModalImp();
end

function ShareWindow:OnClose()
	if(self.page) then
		self.page:CloseWindow();
	end

	ShareWindow.curInstance = nil; --destory instance
end