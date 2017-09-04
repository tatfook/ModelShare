--[[
Title: BuildQuestProvider
Author(s):  BIG
Date: 2017.8
Desc: BuildQuestProvider for modelshare mod
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ModelShare/build/BuildQuestProvider.lua");
local BuildQuestProvider = commonlib.gettable("Mod.ModelShare.build.BuildQuestProvider");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestProvider.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)Mod/ModelShare/build/class/ThemeClass.lua");
NPL.load("(gl)Mod/ModelShare/build/class/TaskClass.lua");
NPL.load("(gl)Mod/WorldSahre/service/HttpRequest.lua");

local BuildQuestMain          = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest");
local BuildQuestProviderMain  = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");
local BlockTemplatePageMain   = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
local ThemeClass              = commonlib.gettable("Mod.ModelShare.build.class.ThemeClass");
local TaskClass               = commonlib.gettable("Mod.ModelShare.build.class.TaskClass");
local HttpRequest             = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
local loginMain               = commonlib.gettable("Mod.WorldShare.login.loginMain");

local BuildQuestProvider = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.build.BuildQuestProvider"));

BuildQuestProvider.categoryPaths = {
	["globalTemplate"]  = "worlds/DesignHouse/blocktemplates/",
};

BuildQuestProvider.categoryDS = {
	["globalTemplate"] = {
		themesDS = {}, themes={}, themesType = {}, beOfficial = false,
	},
	["worldTemplate"] = {
		themesDS = {}, themes={}, themesType = {}, beOfficial = false;
	}
};

BuildQuestProvider.themesDS = {};
BuildQuestProvider.themes   = {};

function BuildQuestProvider:ctor()
	BuildQuestProvider.themes           = {};
	BuildQuestProvider.themesDS         = {};

	BuildQuestProvider.categoryPaths['worldTemplate'] = GameLogic.GetWorldDirectory():gsub("\\","/") .. "blocktemplates/";

	self:LoadFromLocal();
	self:LoadFromCloud();

	for key, value in ipairs(BuildQuestProvider.categoryDS["globalTemplate"]) do

	end

	for key, value in ipairs(BuildQuestProvider.categoryDS["globalTemplate"]) do

	end

	for key, value in ipairs(BuildQuestProvider.categoryDS["cloudTemplate"]) do

	end

	BuildQuestProvider.themesDS[#BuildQuestProvider.themesDS + 1] = {name = "empty", official = false};
end

function BuildQuestProvider:LoadFromLocal()
	for key, path in pairs(BuildQuestProvider.categoryPaths) do
		BuildQuestProvider.categoryDS[key]["themes"]     = {};
		BuildQuestProvider.categoryDS[key]["themesDS"]   = {};
		BuildQuestProvider.categoryDS[key]["themesType"] = {};

		self:LoadFromTemplate(key, path);
	end
end

function BuildQuestProvider:LoadFromTemplate(themeKey, themePath)
	local cur_themesDS   = BuildQuestProvider.categoryDS[themeKey]["themesDS"];
	local cur_themes     = BuildQuestProvider.categoryDS[themeKey]["themes"];
	local cur_themesType = BuildQuestProvider.categoryDS[themeKey]["themesType"];

	if(themeKey == "globalTemplate") then
		local hasOldGlobalFiles;

		local output = GetFiles(themePath, function (msg)
			if(msg.filesize == 0 or string.match(msg.filename,"%.zip$")) then
				-- folder or zip file
				return true;
			elseif(string.match(msg.filename,"blocks%.xml$")) then
				-- never execute here
				hasOldGlobalFiles = true;
			end
		end, "*.*");

		if(hasOldGlobalFiles) then
			self:TranslateGlobalTemplateToBuildingTask(true);
		end
	end

	local theme_ds_name;

	if(themeKey == "globalTemplate") then
		theme_ds_name = "本地全局模板";
	elseif(themeKey == "worldTemplate") then
		theme_ds_name = "本存档模板";
	end

	local theme_index = #cur_themesDS + 1;

	cur_themesDS[theme_index] = {
		name         = theme_ds_name,
		foldername   = themeKey,
		order        = 10,
		unlock_coins = "0",
		image        = "",
		icon         = "",
		official     = BuildQuestProvider.categoryDS[themeKey]["beOfficial"],
	};
	
	cur_themes[theme_index] = ThemeClass:new({
		--name         = theme_name_utf8,
		--foldername   = theme_name,
		unlock_coins = "0",
		image        = "",
		icon         = "",
		official     = BuildQuestProvider.categoryDS[themeKey]["beOfficial"],
		themeKey     = themeKey
	});

	local isThemeZipFile = false; --暂不考虑压缩情况

	local tasksDS = cur_themes[theme_index].tasksDS;
	local tasks   = cur_themes[theme_index].tasks;

	local tasks_output;

	if(not isThemeZipFile) then
		local next_theme_type_index           = #cur_themesType + 1;
		cur_themesType[next_theme_type_index] = {text = theme_name_utf8, value = theme_name};
	end

	if(isThemeZipFile) then
		tasks_output = self:GetFiles(themePath, "*.", "*.zip");
	else
		tasks_output = self:GetFiles(themePath, function (msg)
			return msg.filesize == 0 or string.match(msg.filename,".xml") or string.match(msg.filename,".zip");
		end, "*.*");
	end

	if(themeKey == "globalTemplate") then
		for _, task_item in ipairs(tasks_output) do
			local taskname;

			if(isThemeZipFile) then
				taskname = string.match(task_item, "^(.*)/$");
			else
				taskname = string.match(task_item, "^(.*).zip$"); --判断task item是否ZIP文件

				if(taskname) then
					local filename = theme_path .. task_item;
					ParaAsset.OpenArchive(filename, true);
				else
					taskname = task_item;
				end
			end

			local task_path = themePath .. taskname .. "/" .. taskname .. ".xml";
			local task_dir  = themePath .. taskname .. "/";
			local task_xml  = ParaXML.LuaXML_ParseFile(task_path);

			for node in commonlib.XPath.eachNode(task_xml, "/Task") do
				local task_attr = node.attr;

				task_attr.filepath  = task_path;
				task_attr.dir       = task_dir;

				local task_index  = #tasksDS + 1;
				tasksDS[task_index] = {};

				commonlib.partialcopy(tasksDS[task_index], task_attr);
				tasksDS[task_index].task_index = task_index;

				tasks[task_index] = TaskClass:new(task_attr):Init(node, cur_themes[theme_index], task_index, themeKey);

				local infoCard     = themePath .. taskname .. "/" .. taskname .. ".info.xml";
				local templateInfo = ParaXML.LuaXML_ParseFile(infoCard);

				if(templateInfo ~= nil) then
					tasks[task_index]['infoCard'] = {};

					for key, item in ipairs(templateInfo[1]) do
						tasks[task_index]['infoCard'][item.name] = item[1];
					end
				end
			end
		end
	end

	if(themeKey == "worldTemplate") then
		for _, task_item in ipairs(tasks_output) do 
			local taskname = task_item:match("([^/\\]+)%.blocks%.xml$");
			
			if(taskname) then
				task_index = #taskDS + 1;

				tasksDS[task_index] = {};

				local file = {name = taskname};

				commonlib.partialcopy(tasksDS[task_index], file);
				tasksDS[task_index].task_index = task_index;

				tasks[task_index] = {
					name     = name,
					type     = "template",
					filename = BuildQuestProvider.categoryPaths['worldTemplate'] .. task_item,
				};
			end
		end
	end

	for i=1, #cur_themes do
		cur_themes[i].id = i;
	end
end

function BuildQuestProvider:GetFiles(path, filter, zipfile)
	local output = commonlib.Files.Find({}, path,0, 10000, filter, zipfile);

	table.sort(output, function(a, b)
		-- sort by filename
		local filename1 = a.filename;
		local filename2 = b.filename;

		for i=1, math.min(#filename1, #filename2) do
			local c1 = string.byte(filename1, i);
			local c2 = string.byte(filename2, i);

			if(c1 < c2) then
				return true;
			elseif(c1 > c2) then
				return false;
			end
		end

		return (#filename1) < (#filename2);
	end);

	local out = {};

	for i = 1,#output do
		out[i] = output[i]["filename"];
	end

	return out or {};
end

function BuildQuestProvider.CloudApi()
	return loginMain.site .. "/api/mod/modelshare/models/modelshare/";
end

function BuildQuestProvider:LoadFromCloud(callback)
	local theme_index;
	local cur_themes = BuildQuestProvider.themes;

	if(not BuildQuestProvider.themesDS[3]) then
		local cloudTheme = {
			order        = 10,
			foldername   = "cloudTemplate",
			official     = false,
			icon         = "",
			unlock_coins = "0",
			name         = "云模板",
			image        = "",
		};

		BuildQuestProvider.themesDS[#BuildQuestProvider.themesDS + 1] = cloudTheme;

		theme_index = #cur_themes + 1; 

		cur_themes[theme_index] = {
			tasksDS = {},
			
		};
	else
		theme_index = 3;
	end

	if(loginMain.IsSignedIn()) then
		local params = {
			limit = 100,
			skip  = 0,
		};

		HttpRequest:GetUrl({
			url     = self.CloudApi() .. "getList",
			json    = true,
			headers = {
				Authorization = "Bearer " .. loginMain.token,
			},
			form   = params,
		},function(data, err)
			if(not data or not data.error or data.error.id ~= 0 or type(data.data) ~= "table") then
				return;
			end

			local cur_tasksDS = cur_themes[theme_index].tasksDS;
			
			for key, item in ipairs(data.data) do
				local status = false;

				for Lkey,Litem in ipairs(cur_themes[1].tasks) do
					if(not Litem.infoCard or not Litem.infoCard.sn) then
						break;
					end

					if(tostring(item.modelsnumber) == tostring(Litem.infoCard.sn)) then
						status = true;
						break;
					end
				end

				cur_tasksDS[#cur_tasksDS + 1] = {
					name   = item.templateName,
					status = status,
				};
			end

			if(type(callback) == "function") then
				callback();
			end

			--echo(cur_tasksDS);
		end)
	end
end

function BuildQuestProvider:GetThemes_DS(themeKey)
	if(not next(BuildQuestProvider.themesDS)) then
		return {};
	end

	local ds;

	if(themeKey) then
		ds = BuildQuestProvider.categoryDS[themeKey]["themesDS"]
	else
		ds = BuildQuestProvider.themesDS;
	end

	return ds;
end

-- get the tasks information. 
function BuildQuestProvider:GetTasks_DS(theme_id)
	local theme = self:GetTheme(theme_id);

	if(not theme) then
		return;
	end

	return theme.tasksDS;
end

function BuildQuestProvider:GetTheme(theme_id) --category
	local cur_themes = BuildQuestProvider.themes;

	return cur_themes[theme_id or 1];
end

function BuildQuestProvider:GetTask(theme_id, task_id)
	if(self == nil) then
		return;
	end

	local theme = self:GetTheme(theme_id);

	if(theme and type(theme.GetTask) == "function") then
		return theme:GetTask(task_id);
	end
end

-- to be compatible with old file structure. we will need to move from old template position. 
-- @param bDeleteOldFile: whether we will delete old files
function BuildQuestProvider:TranslateGlobalTemplateToBuildingTask(bDeleteOldFile)
	--local allTemplate = BlockTemplatePage.GetAllTemplatesDS();
	local globalThemePath = BuildQuestProvider.categoryPaths.globalTemplate;

	local globalTemplate = self:GetFiles(globalThemePath, function (msg)
		return string.match(msg.filename,"%.blocks%.xml$") ~= nil;
	end);

	LOG.std(nil, "info", "TranslateGlobalTemplateToBuildingTask", "%d files translated", #globalTemplate);

	for i = 1,#globalTemplate do
		local filename = string.gsub(globalTemplate[i],".blocks.xml","");

		local srcpath = string.format("%s%s.blocks.xml", globalThemePath, filename);
		local despath = string.format("%s/%s.blocks.xml", globalThemePath .. commonlib.Encoding.DefaultToUtf8(filename), commonlib.Encoding.DefaultToUtf8(filename));

		if(not ParaIO.DoesFileExist(despath, false)) then
			ParaIO.CopyFile(srcpath, despath, true);

			local taskfilename   = string.format("%s/%s.xml", globalThemePath .. filename, filename);
			local blocksfilename = despath;

			local xmlRoot = ParaXML.LuaXML_ParseFile(commonlib.Encoding.Utf8ToDefault(blocksfilename));

			if(xmlRoot) then
				local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");

				if(node and node[1]) then
					local blocks = NPL.LoadTableFromString(node[1]);

					if(blocks and #blocks > 0) then
						blocksNum = #blocks;
						BlockTemplatePage.CreateBuildingTaskFile(taskfilename, blocksfilename, commonlib.Encoding.DefaultToUtf8(filename), blocks)
					end
				end
			end
		end

		if(bDeleteOldFile) then
			ParaIO.DeleteFile(srcpath);
		end
	end

	if(bDeleteOldFile) then
		ParaIO.DeleteFile(globalThemePath .. "*.jpg");
	end
end

function BuildQuestProvider:OnSaveTaskDesc(theme_index, task_index,desc)
	--local task = self:GetTask(theme_index, task_index);

    if(task) then
        task.desc = desc;

		local step           = task:GetStep(1);
		local taskfilename   = task.filepath;
		local taskname       = task.name;
		local blocksfilename = step.src;

		local xmlRoot = ParaXML.LuaXML_ParseFile(commonlib.Encoding.Utf8ToDefault(blocksfilename));

		if(xmlRoot) then
			local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");

			if(node and node[1]) then
				local blocks = NPL.LoadTableFromString(node[1]);

				if(blocks and #blocks > 0) then
					blocksNum = #blocks;
					BlockTemplatePage.CreateBuildingTaskFile(taskfilename, blocksfilename, taskname, blocks, desc)
				end
			end
		end
    end
end