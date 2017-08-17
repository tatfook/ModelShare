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
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");

local loginMain     = commonlib.gettable("Mod.WorldShare.login.loginMain");
local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
local BlockEngine   = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local SelectBlocks  = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");

local ShareWindow = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.ShareWindow"));

ShareWindow.SnapShotPath         = "Screen Shots/block_template.jpg";
ShareWindow.global_template_dir  = "worlds/DesignHouse/blocktemplates/"
ShareWindow.default_template_dir = "worlds/DesignHouse/blocktemplates/";

function ShareWindow:ctor()
end

function ShareWindow:init()
end

function ShareWindow:ShowPage()
	if(ShareWindow.curInstance) then
		local selectBlocksInstance = SelectBlocks.GetCurrentInstance();

		local pivot_x, pivot_y, pivot_z = selectBlocksInstance:GetSelectionPivot();

		if(selectBlocksInstance.UsePlayerPivotY) then
			local x,y,z    = ParaScene.GetPlayer():GetPosition();
			local _, by, _ = BlockEngine:block(0, y+0.1, 0);

			pivot_y = by;
		end

		ShareWindow.pivot  = {pivot_x, pivot_y, pivot_z};
		ShareWindow.blocks = selectBlocksInstance:GetCopyOfBlocks(pivot);

		--echo(ShareWindow.pivot);

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

function ShareWindow.OnClickTakeSnapshot()
	if(MyCompany.Apps.ScreenShot.SnapshotPage.TakeSnapshot(ShareWindow.SnapShotPath, 80, 80, false, false)) then
		-- refresh image
		ParaAsset.LoadTexture("", ShareWindow.SnapShotPath,1):UnloadAsset();
		echo(ShareWindow.SnapShotPath);
		ShareWindow.Refresh();
	else
		_guihelper.MessageBox(L"��ͼʧ����, ��ȷ������Ȩ�޶�д����")
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

function ShareWindow.localSave()
	if(not ShareWindow.curInstance.page) then
		return;
	end

	local bSaveSnapshot;
	local isThemedTemplate;
	local isSaveInLocalWorld;

	local template_base_dir = ShareWindow.default_template_dir;--ShareWindow.template_save_dir or ShareWindow.default_template_dir;

	local template_dir      = page:GetValue("savePath");

	if(template_dir == "world") then
		isSaveInLocalWorld = true;
	elseif(template_dir == "global") then
		isThemedTemplate = true;
	end

	--[[if(template_dir == 0) then
		isSaveInLocalWorld = true;
		template_dir       = nil;
	elseif(template_dir == -1) then
		template_dir = "";
	end]]

	local name = {};

    name.utf8 = page:GetUIValue("templateName"); --or page:GetUIValue("tl_name") or "";
	name.utf8 = name:gsub("%s", "");

	local desc = page:GetUIValue("templateDesc"); --or page:GetUIValue("template_desc") or "";

    desc = string.gsub(desc,"\r?\n","<br/>")

	if(name.utf8 == "")  then
		_guihelper.MessageBox(L"���ֲ���Ϊ��~");
		return;
	end

	name.default = commonlib.Encoding.Utf8ToDefault(name.utf8);

	--isThemedTemplate = template_dir and template_dir ~= "";
	bSaveSnapshot = false; -- not isThemedTemplate and not isSaveInLocalWorld;

    local filename, taskfilename;

	if(isSaveInLocalWorld) then
		filename = format("%s%s.blocks.xml", GameLogic.current_worlddir .. "blocktemplates/", name.default);
	elseif(isThemedTemplate) then
		ParaIO.CreateDirectory(template_base_dir);

		--local subdir = template_dir; -- commonlib.Encoding.Utf8ToDefault(template_dir);

		filename     = format("%s%s.blocks.xml", template_base_dir .. "/" .. name.default .. "/", name.default);
		taskfilename = format("%s%s.xml", template_base_dir .. "/" .. name.default .. "/", name.default);
	else
		return;
		--filename = format("%s%s.blocks.xml", template_base_dir, name_normalized);
	end

	local function doSave_()
		local x, y, z    = ParaScene.GetPlayer():GetPosition();
		local bx, by, bz = BlockEngine:block(x, y, z)
		local player_pos = string.format("%d,%d,%d", bx, by, bz);

		local pivot = string.format("%d,%d,%d", ShareWindow.pivot[1], ShareWindow.pivot[2], ShareWindow.pivot[3]);

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
		_guihelper.MessageBox(format(L"ģ���ļ�%s�Ѿ�����, �Ƿ�Ҫ����֮ǰ���ļ�?", commonlib.Encoding.DefaultToUtf8(filename)), function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				doSave_();
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	else
		doSave_();
	end
end

function ShareWindow.cloudAndLocalSave()

end

function ShareWindow.SaveToTemplate(filename, blocks, params, callbackFunc, bSaveSnapshot)
	if( not GameLogic.IsOwner()) then
		--_guihelper.MessageBox(format("ֻ�����������, ���ܱ���ģ��. �����ر��˵Ĵ���,��Ҫ����!", tostring(WorldCommon.GetWorldTag("nid"))));
		--return;
		GameLogic.AddBBS("copyright_respect", L"�����ر��˵Ĵ���,��Ҫ����!", 6000, "0 255 0");
	end

	if(not blocks or #blocks<1) then
		_guihelper.MessageBox(L"��Ҫѡ�ж����ܴ�Ϊģ��");
		return;
	end
	if(#blocks > BlockTemplatePage.max_blocks_per_template) then
		_guihelper.MessageBox(format(L"ģ������ܱ���%d��", BlockTemplatePage.max_blocks_per_template))
		return;
	end

	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Save, filename = filename, params = params, blocks = blocks})

	if(task:Run()) then
		BroadcastHelper.PushLabel({id="BlockTemplatePage", label = format(L"ģ��ɹ����浽:%s", commonlib.Encoding.DefaultToUtf8(filename)), max_duration=4000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
		page:CloseWindow();
		callbackFunc();
		if(bSaveSnapshot) then
			ParaIO.CopyFile(BlockTemplatePage.DefaultSnapShot, filename:gsub("xml$", "jpg"), true);	
		end
		_guihelper.MessageBox(L"����ɹ��� �����Դӡ����졿->��ģ�塿�д������ģ���ʵ���ˡ�");
	end
end