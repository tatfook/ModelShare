--[[
Title: ModelShare
Author(s):  BIG
Date: 2017.6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ModelShare/main.lua");
local ModelShare = commonlib.gettable("Mod.ModelShare");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua");
NPL.load("(gl)Mod/ModelShare/ShareWindow.lua");

local loginMain   = commonlib.gettable("Mod.WorldShare.login.loginMain");
local ShareWindow = commonlib.gettable("Mod.ModelShare.ShareWindow");

local ModelShare = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.ModelShare"));

function ModelShare:ctor()
end

function ModelShare:GetName()
	return "ModelShare"
end

function ModelShare:GetDesc()
	return "ModelShare Mod"
end

function ModelShare:init()
	GameLogic.GetFilters():add_filter("GetExporters",function(exporters)
		local title = L"分享模板到Keepwork";
		local desc  = L"将模板分享到keepwork并进行3D打印";
		local temp = exporters[3];
		exporters[3] = {id="ShareModel", title=title, desc=desc};
		exporters[#exporters+1] = temp;

		return exporters;
	end);

	GameLogic.GetFilters():add_filter("select_exporter", function(id)
		if(id == "ShareModel") then
			id = nil; -- prevent other exporters
			local curShareWindow = ShareWindow:new();
			curShareWindow:SetInstance();
			curShareWindow:ShowPage();
		end
		return id;
	end);
end

function ModelShare:OnLogin()
end

function ModelShare:OnWorldLoad()
	
end