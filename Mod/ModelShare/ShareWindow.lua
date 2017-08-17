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
NPL.load("(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua");

local loginMain  = commonlib.gettable("Mod.WorldShare.login.loginMain");

local ShareWindow = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.ShareWindow"));

ShareWindow.SnapShotPath = "Screen Shots/block_template.jpg";

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

function ShareWindow.Refresh()
	if(ShareWindow.curInstance) then
		ShareWindow.curInstance:PageRefresh();
	end
end

function ShareWindow.login()
	loginMain.modalCall = function()
		if(ShareWindow.curInstance) then
			ShareWindow.curInstance:PageRefresh();
		end
	end;

	loginMain.showLoginModalImp();
end

function ShareWindow:OnClose()
	if(self.page) then
		self.page:CloseWindow();
	end

	ShareWindow.curInstance = nil; --destory instance
end

function ShareWindow.isSignedIn()
    return loginMain.IsSignedIn();
end

function ShareWindow.register()
    ParaGlobal.ShellExecute("open", loginMain.site .. "/wiki/home", "", "", 1);
end

function ShareWindow.screenshot()
    if(ShareWindow.curInstance.SnapShotPath) then
        ShareWindow.curInstance.page:SetUIValue("CurrentSnapshot", ShareWindow.SnapShotPath);
		return true;
    else
        return false;
    end
end

function ShareWindow.save()

end

function ShareWindow.OnClickTakeSnapshot()
	if(MyCompany.Apps.ScreenShot.SnapshotPage.TakeSnapshot(ShareWindow.SnapShotPath, 80, 80, false, false)) then
		-- refresh image
		ParaAsset.LoadTexture("", ShareWindow.SnapShotPath,1):UnloadAsset();
		echo(ShareWindow.SnapShotPath);
		ShareWindow.Refresh();
	else
		_guihelper.MessageBox(L"截图失败了, 请确定您有权限读写磁盘")
	end


end

function ShareWindow.closePage()
	if(ShareWindow.curInstance) then
		ShareWindow.curInstance:OnClose();
	end
end

function ShareWindow.setSavePath()
	local page = ShareWindow.curInstance.page;

	if(page) then
		ShareWindow.savePath = page:GetValue("savePath");

		page:Refresh(0.01);
	end
end

function ShareWindow.beLocal()
	local savePath = ShareWindow.savePath;

	if(savePath == "world" or savePath == "global") then
		return true;
	elseif(savePath == "cloud" or savePath =="cloudAndWorld" or savePath == "cloudAndGlobal") then
		return false;
	else
		return true;
	end
end

function ShareWindow.OnClickSave()
	if(not page) then
		return;
	end

	local template_dir = page:GetValue("template_dir");
	local isSaveInLocalWorld;

	if(template_dir == 0) then
		isSaveInLocalWorld = true;
		template_dir       = nil;
	elseif(template_dir == -1) then
		template_dir = "";
	end

	local template_base_dir = BlockTemplatePage.template_save_dir or default_template_dir;

    local name = page:GetUIValue("name") or page:GetUIValue("tl_name") or "";
	local desc = page:GetUIValue("template_desc") or page:GetUIValue("template_desc") or "";

    desc = string.gsub(desc,"\r?\n","<br/>")
	name = name:gsub("%s", "");

	if(name == "")  then
		_guihelper.MessageBox(L"名字不能为空~");
		return;
	end
	local name_normalized = commonlib.Encoding.Utf8ToDefault(name);

	local isThemedTemplate = template_dir and template_dir ~= "";
	local bSaveSnapshot    = false; -- not isThemedTemplate and not isSaveInLocalWorld;

    local filename,taskfilename;

	if(isSaveInLocalWorld) then
		filename = format("%s%s.blocks.xml", GameLogic.current_worlddir.."blocktemplates/", name_normalized);
	elseif(isThemedTemplate) then
		ParaIO.CreateDirectory(template_base_dir);

		local subdir = template_dir; -- commonlib.Encoding.Utf8ToDefault(template_dir);

		filename     = format("%s%s.blocks.xml", template_base_dir..subdir.."/"..name_normalized.."/", name_normalized);
		taskfilename = format("%s%s.xml", template_base_dir..subdir.."/"..name_normalized.."/", name_normalized);
	else
		filename = format("%s%s.blocks.xml", template_base_dir, name_normalized);
	end

	local function doSave_()
		local x, y, z    = ParaScene.GetPlayer():GetPosition();
		local bx, by, bz = BlockEngine:block(x,y,z)
		local player_pos = string.format("%d,%d,%d",bx,by,bz);

		local pivot = string.format("%d,%d,%d",BlockTemplatePage.pivot[1],BlockTemplatePage.pivot[2],BlockTemplatePage.pivot[3]);

		BlockTemplatePage.SaveToTemplate(filename, BlockTemplatePage.blocks, {
			name            = name,
			author_nid      = System.User.nid,
			creation_date   = ParaGlobal.GetDateFormat("yyyy-MM-dd").."_"..ParaGlobal.GetTimeFormat("HHmmss"),
			player_pos      = player_pos,
			pivot           = pivot,
			relative_motion = page:GetValue("checkboxRelativeMotion", false),
		},function ()
			if(isThemedTemplate) then
				BlockTemplatePage.CreateBuildingTaskFile(taskfilename, commonlib.Encoding.DefaultToUtf8(filename), name, BlockTemplatePage.blocks,desc);
				BuildQuestProvider.RefreshDataSource();
			end

			GameLogic.GetFilters():apply_filters("file_exported", "template", filename);
		end, bSaveSnapshot);
	end

	if(ParaIO.DoesFileExist(filename)) then
		_guihelper.MessageBox(format(L"模板文件%s已经存在, 是否要覆盖之前的文件?", commonlib.Encoding.DefaultToUtf8(filename)), function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				doSave_();
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	else
		doSave_();
	end
end