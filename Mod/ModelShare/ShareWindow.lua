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

local ShareWindow = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.ModelShare.ShareWindow"));

function ShareWindow:ctor()
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

function ShareWindow:init()
end

function ShareWindow:SetPage()
	ShareWindow.page = document.GetPageCtrl();
end

function ShareWindow:OnClose()
	if(ShareWindow.page) then
		ShareWindow.page:CloseWindow();
	end
end