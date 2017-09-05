--[[
Title: ShareModel
Author(s):  BIG
Date: 2017.6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ModelShare/share/TemplateShare.lua");
local TemplateShare = commonlib.gettable("Mod.ModelShare.TemplateShare");
------------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
NPL.load("(gl)Mod/WorldShare/sync/SyncMain.lua");
NPL.load("(gl)Mod/WorldShare/service/LocalService.lua");
NPL.load("(gl)Mod/WorldSahre/service/HttpRequest.lua");

local loginMain       = commonlib.gettable("Mod.WorldShare.login.loginMain");
local BlockTemplate   = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
local BlockEngine     = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local SelectBlocks    = commonlib.gettable("MyCompany.Aries.Game.Tasks.SelectBlocks");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local SyncMain        = commonlib.gettable("Mod.WorldShare.sync.SyncMain");
local LocalService    = commonlib.gettable("Mod.WorldShare.service.LocalService");
local HttpRequest     = commonlib.gettable("Mod.WorldShare.service.HttpRequest");

local TemplateShare = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.share.TemplateShare"));

-- max number blocks in a template. 
TemplateShare.max_blocks_per_template = 5000000;
TemplateShare.SnapShotPath          = "Screen Shots/block_template.jpg";
TemplateShare.global_template_dir     = "worlds/DesignHouse/blocktemplates/"

function TemplateShare:ctor()
	TemplateShare.template_label = {};
	TemplateShare.savePath       = "world";
end

function TemplateShare:init()
end

function TemplateShare:ShowPage()
	if(TemplateShare.curInstance) then
		local selectBlocksInstance = SelectBlocks.GetCurrentInstance();

		local pivot_x, pivot_y, pivot_z = selectBlocksInstance:GetSelectionPivot();

		if(selectBlocksInstance.UsePlayerPivotY) then
			local x,y,z    = ParaScene.GetPlayer():GetPosition();
			local _, by, _ = BlockEngine:block(0, y + 0.1, 0);

			pivot_y = by;
		end

		TemplateShare.pivot  = {pivot_x, pivot_y, pivot_z};
		TemplateShare.blocks = selectBlocksInstance:GetCopyOfBlocks(pivot);

		--echo(TemplateShare.pivot);

		System.App.Commands.Call("File.MCMLWindowFrame", {
			url  = "Mod/ModelShare/share/TemplateShare.html", 
			name = "TemplateShare",
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

function TemplateShare:ManagerToCloud()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/ModelShare/share/TemplateShare.html", 
		name = "TemplateShare",
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

function TemplateShare:SetInstance()
	TemplateShare.curInstance = self;
end

function TemplateShare:SetPage()
	self.page = document.GetPageCtrl();
end

function TemplateShare.GetPage()
	if(not TemplateShare.curInstance.page) then
		return;
	end

	return TemplateShare.curInstance.page;
end

function TemplateShare:PageRefresh(sec)
	local templateName = self.page:GetValue("templateName");
	self.page:SetNodeValue("templateName", templateName);

	self.page:Refresh(sec or 0.01);
end

function TemplateShare.Refresh(sec)
	if(TemplateShare.curInstance) then
		TemplateShare.curInstance:PageRefresh(sec);
	end
end

function TemplateShare.login()
	loginMain.modalCall = function()
		if(TemplateShare.curInstance) then
			TemplateShare.curInstance:PageRefresh();
		end
	end;

	loginMain.showLoginModalImp();
end

function TemplateShare:OnClose()
	if(self.page) then
		self.page:CloseWindow();
	end

	TemplateShare.curInstance = nil; --destory instance
end

function TemplateShare.isSignedIn()
    return loginMain.IsSignedIn();
end

function TemplateShare.register()
    ParaGlobal.ShellExecute("open", loginMain.site .. "/wiki/home", "", "", 1);
end

function TemplateShare.screenshot()
    if(TemplateShare.curInstance.SnapShotPath) then
        TemplateShare.curInstance.page:SetUIValue("CurrentSnapshot", TemplateShare.SnapShotPath);
		return true;
    else
        return false;
    end
end

function TemplateShare.OnClickTakeSnapshot()
	if(MyCompany.Apps.ScreenShot.SnapshotPage.TakeSnapshot(TemplateShare.SnapShotPath, 80, 80, false, false)) then
		-- refresh image
		ParaAsset.LoadTexture("", TemplateShare.SnapShotPath,1):UnloadAsset();
		--echo(TemplateShare.SnapShotPath);
		TemplateShare.Refresh();
	else
		_guihelper.MessageBox(L"截图失败了, 请确定您有权限读写磁盘")
	end


end

function TemplateShare.ClosePage()
	if(TemplateShare.curInstance) then
		TemplateShare.curInstance:OnClose();
	end
end

function TemplateShare.SetSavePath()
	local page = TemplateShare.curInstance.page;

	if(page) then
		TemplateShare.savePath = page:GetValue("savePath");

		TemplateShare.Refresh();
	end
end

function TemplateShare.BeLocal()
	local savePath = TemplateShare.savePath;

	if(savePath == "world" or savePath == "global") then
		return true;
	end
end

function TemplateShare.BeShare()
	local savePath = TemplateShare.savePath;

	if(savePath == "cloud") then
		return true;
	end
end

function TemplateShare.BeBoth()
	local savePath = TemplateShare.savePath;

	if(savePath =="cloudAndWorld" or savePath == "cloudAndGlobal") then
		return true;
	end
end

function TemplateShare.IsShareButton()
	local savePath = TemplateShare.savePath;

	if(savePath == "world" or savePath == "global") then
		return true;
	elseif(savePath == "cloud" or savePath =="cloudAndWorld" or savePath == "cloudAndGlobal") then
		return false;
	else
		return true;
	end
end

function TemplateShare.LocalSave(template_dir, template_name, template_foldername)
	local page = TemplateShare.GetPage();

	local bSaveSnapshot;
	local isThemedTemplate;
	local isSaveInLocalWorld;

	if(not template_name.default) then
		template_name = nil;
	end

	if(not template_foldername or not template_foldername.default) then
		template_foldername = nil;
	end

	local template_base_dir = TemplateShare.global_template_dir;--TemplateShare.template_save_dir or TemplateShare.global_template_dir;

	if(not template_dir) then
		template_dir = page:GetValue("savePath");
	end

	if(template_dir == "world") then
		isSaveInLocalWorld = true;
	elseif(template_dir == "global") then
		isThemedTemplate = true;
	end

	if(not template_name) then
		template_name = {};

		template_name.utf8 = page:GetValue("templateName"); --or page:GetUIValue("tl_name") or "";
		template_name.utf8 = template_name.utf8:gsub("%s", "");

		template_name.default = commonlib.Encoding.Utf8ToDefault(template_name.utf8);
	end

	local desc = page:GetUIValue("template_desc"); --or page:GetUIValue("template_desc") or "";
    desc = string.gsub(desc,"\r?\n","<br/>");
	
	if(template_name.utf8 == "")  then
		_guihelper.MessageBox(L"名字不能为空~");
		return;
	end

	--isThemedTemplate = template_dir and template_dir ~= "";
	bSaveSnapshot = false; -- not isThemedTemplate and not isSaveInLocalWorld;

    local filename, taskfilename;

	if(isSaveInLocalWorld) then
		if(template_foldername) then
			filename = format("%s%s.blocks.xml", GameLogic.current_worlddir .. "blocktemplates/", template_foldername.default);
		else
			filename = format("%s%s.blocks.xml", GameLogic.current_worlddir .. "blocktemplates/", template_name.default);
		end
	elseif(isThemedTemplate) then
		ParaIO.CreateDirectory(template_base_dir);

		if(template_foldername) then
			filename     = format("%s%s.blocks.xml", template_base_dir .. template_foldername.default .. "/", template_foldername.default);
			taskfilename = format("%s%s.xml", template_base_dir .. template_foldername.default .. "/", template_foldername.default);
		else
			filename     = format("%s%s.blocks.xml", template_base_dir .. template_name.default .. "/", template_name.default);
			taskfilename = format("%s%s.xml", template_base_dir .. template_name.default .. "/", template_name.default);
		end
	else
		return;
	end

	local function doSave_()
		local x, y, z    = ParaScene.GetPlayer():GetPosition();
		local bx, by, bz = BlockEngine:block(x, y, z)
		local player_pos = string.format("%d,%d,%d", bx, by, bz);

		local pivot = string.format("%d,%d,%d", TemplateShare.pivot[1], TemplateShare.pivot[2], TemplateShare.pivot[3]);

		TemplateShare.SaveToTemplate(filename, TemplateShare.blocks, {
			name            = template_name.utf8,
			desc            = desc,
			author_nid      = System.User.nid,
			creation_date   = ParaGlobal.GetDateFormat("yyyy-MM-dd") .. "_" .. ParaGlobal.GetTimeFormat("HHmmss"),
			player_pos      = player_pos,
			pivot           = pivot,
			relative_motion = page:GetValue("checkboxRelativeMotion", false),
		},function ()
			if(isSaveInLocalWorld) then
				local imageFileName

				if(template_foldername) then
					imageFileName = format("%s%s.jpg", GameLogic.current_worlddir .. "blocktemplates/", template_foldername.default);
				else
					imageFileName = format("%s%s.jpg", GameLogic.current_worlddir .. "blocktemplates/", template_name.default);
				end
				
				ParaIO.CopyFile(TemplateShare.SnapShotPath, imageFileName, true);
			elseif(isThemedTemplate) then
				local imageFileName;

				if(template_foldername) then
					imageFileName = format("%s%s.jpg", template_base_dir .. template_foldername.default .. "/", template_foldername.default);
				else
					imageFileName = format("%s%s.jpg", template_base_dir .. template_name.default .. "/", template_name.default);
				end
				
				ParaIO.CopyFile(TemplateShare.SnapShotPath, imageFileName, true);
				TemplateShare.CreateBuildingTaskFile(taskfilename, commonlib.Encoding.DefaultToUtf8(filename), template_name.utf8, TemplateShare.blocks, desc);
			end
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

function TemplateShare.CloudApi()
	return loginMain.site .. "/api/mod/modelshare/models/modelshare/";
end

function TemplateShare.CloudSave(type)
	if(not type) then
		type = "cloud";
	end

	if(not loginMain.IsSignedIn()) then
		_guihelper.MessageBox(L"请登录之后再分享");
		return;
	end

	if(type == "cloud") then
		local template_base_dir = TemplateShare.global_template_dir;

		local isShare  = TemplateShare.GetPage():GetValue("isShare");

		local name   = {};
		name.utf8    = TemplateShare.GetPage():GetValue("templateName"); --or page:GetUIValue("tl_name") or "";

		if(name.utf8 == "")  then
			_guihelper.MessageBox(L"名字不能为空~");
			return;
		end

		name.utf8    = name.utf8:gsub("%s", "");
		name.default = commonlib.Encoding.Utf8ToDefault(name.utf8);

		local desc = TemplateShare.GetPage():GetValue("templateDesc");

		if(desc) then
			desc = string.gsub(desc,"\r?\n","<br/>");
		else
			desc = "";
		end

		local params = {
			templateName = name.utf8,
			blocks       = #TemplateShare.blocks,
			volume       = 0,
			isShare      = isShare and 1 or 0,
			desc         = desc,
		};

		HttpRequest:GetUrl({
			url     = TemplateShare.CloudApi() .. "add",
			json    = true,
			headers = {
				Authorization = "Bearer " .. loginMain.token,
			},
			form    = params,
		},function(data, err)
			--echo(data, true);

			local numberName = {};

			numberName.utf8    = data.data.modelsnumber;
			numberName.default = commonlib.Encoding.Utf8ToDefault(numberName.utf8);

			local filename = format("%s%s.blocks.xml", template_base_dir .. numberName.default .. "/", numberName.default);
			local infoCard = format("%s%s.info.xml", template_base_dir .. numberName.default .. "/", numberName.default);

			if(not ParaIO.DoesFileExist(filename)) then
				TemplateShare.LocalSave("global", name, numberName);

				local templateInfo = {
					{tostring(data.data.templateName), name = "templateName"},
					{tostring(data.data.modelsnumber), name = "sn"},
					{tostring(data.data.createDate)  , name = "createDate"},
					{tostring(data.data.username)    , name = "username"},
					{tostring(data.data.blocks)      , name = "blocks"},
					{tostring(data.data.volume)      , name = "volume"},
					{tostring(data.data.isShare)     , name = "isShare"},
					name = "template",
				};

				local templateInfoXml = commonlib.Lua2XmlString(templateInfo);

				local file = ParaIO.open(infoCard, "w");

				file:write(templateInfoXml,#templateInfoXml);
				file:close();
			end

			local curLocalService = LocalService:new();
			local path            = template_base_dir .. name.default .. "/";

			local files = curLocalService:LoadFiles(path);

			local file_index = 1;

			local function upload()
				if(file_index <= #files) then
					SyncMain:uploadService(
						loginMain.keepWorkDataSource,
						"templates/" .. name.utf8 .. "/" .. files[file_index].filename,
						files[file_index].file_content_t,
						function(bIsUpload, filename)
							if(bIsUpload) then
								file_index = file_index + 1;
								upload();
							end
						end,
						loginMain.keepWorkDataSourceId
					);
				else
					_guihelper.MessageBox(L"上传完成！");
				end
			end

			upload();
		end);
	elseif(type == "world") then
		echo("分享至世界存档");
	end
end

function TemplateShare.CloudAndLocalSave()
	local savePath = TemplateShare.GetPage():GetValue("savePath");
	--echo(savePath);
	if(savePath == "cloudAndWorld") then
		TemplateShare.LocalSave("world");
		TemplateShare.CloudSave("world")
	elseif(savePath == "cloudAndGlobal") then
		TemplateShare.LocalSave("global");
		TemplateShare.CloudSave("cloud");
	end
end

function TemplateShare.RefreshTemplateLabel()
	TemplateShare.GetTemplateLabel();
	TemplateShare.Refresh(3);
end

function TemplateShare.GetTemplateLabel()
	local templateLabel = TemplateShare.GetPage():GetValue("templateLabel");

	TemplateShare.GetPage():SetNodeValue("templateLabel", templateLabel);

	local templateLabelTabel = {};

	for item in string.gmatch(templateLabel,"[^;]+") do
		templateLabelTabel[#templateLabelTabel + 1] = {
			name = item,
		};
	end

	TemplateShare.template_label = templateLabelTabel;

	return TemplateShare.template_label;
end

function TemplateShare.SaveToTemplate(filename, blocks, params, callbackFunc, bSaveSnapshot)
	if( not GameLogic.IsOwner()) then
		--_guihelper.MessageBox(format("只有世界的作者, 才能保存模板. 请尊重别人的创意,不要盗版!", tostring(WorldCommon.GetWorldTag("nid"))));
		--return;
		GameLogic.AddBBS("copyright_respect", L"请尊重别人的创意,不要盗版!", 6000, "0 255 0");
	end

	if(not blocks or #blocks<1) then
		_guihelper.MessageBox(L"需要选中多块才能存为模板");
		return;
	end

	if(#blocks > TemplateShare.max_blocks_per_template) then
		_guihelper.MessageBox(format(L"模板最多能保存%d块", TemplateShare.max_blocks_per_template))
		return;
	end

	local task = BlockTemplate:new({
		operation = BlockTemplate.Operations.Save,
		filename  = filename,
		params    = params,
		blocks    = blocks
	});

	if(task:Run()) then
		BroadcastHelper.PushLabel({
			id="BlockTemplatePage",
			label = format(L"模板成功保存到:%s", commonlib.Encoding.DefaultToUtf8(filename)),
			max_duration=4000,
			color = "0 255 0",
			scaling=1.1,
			bold=true,
			shadow=true,
		});
		
		TemplateShare.ClosePage();

		if(type(callbackFunc) == "function") then
			callbackFunc();
		end

		if(bSaveSnapshot) then
			ParaIO.CopyFile(TemplateShare.SnapShotPath, filename:gsub("xml$", "jpg"), true);
		end

		_guihelper.MessageBox(L"保存成功！ 您可以从【建造】->【模板】中创建这个模板的实例了～");
	end
end

function TemplateShare.CreateBuildingTaskFile(filename, blocksfilename, taskname, _blocks, desc)
	--echo("filename");
	--echo(filename);
	local blocks = _blocks;
	local file   = ParaIO.open(filename, "w");

	if(file:IsValid()) then
		local o = {
			name="Task",
			attr = {
				name = taskname,
				click_once_deploy="true",
				icon = "",
				image = "",
				desc = desc or taskname,
				UseAbsolutePos = "false"
			},
		};

		o[1] = {
			name="Step",
			attr = {
				auto_create = "true",
				src = blocksfilename:gsub("(.*)[^\\/]+$", ""),
			},
		};

		local blocksNum;

		if(blocks) then
			blocksNum = #blocks;
		else
			local select_task = SelectBlocks.GetCurrentInstance();

			if(select_task) then
				local blocks = select_task:GetCopyOfBlocks();

				blocksNum = #blocks;
			else
				file:close();
				return;
			end
		end

		o[1][1] = {
				name = "tip",
				attr = {
				block = string.format("0-%d",blocksNum - 1)
			},
		};

		file:WriteString(commonlib.Lua2XmlString(o, true));
		file:close();

		return true;
	end
end