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
		themesDS = {}, themes = {}, themesType = {}, beOfficial = false,
	},
	["worldTemplate"] = {
		themesDS = {}, themes = {}, themesType = {}, beOfficial = false;
	},
	["cloudTemplate"] = {
		themesDS = {}, themes = {}, themesType = {}, beOfficial = false;
	}
};

BuildQuestProvider.themesDS = {};
BuildQuestProvider.themes   = {};

function BuildQuestProvider:ctor()
	BuildQuestProvider.themes   = {};
	BuildQuestProvider.themesDS = {};

	BuildQuestProvider.categoryPaths['worldTemplate'] = GameLogic.GetWorldDirectory():gsub("\\","/") .. "blocktemplates/";

	self:LoadFromLocal();

	BuildQuestProvider.themesDS[#BuildQuestProvider.themesDS + 1]  = BuildQuestProvider.categoryDS["globalTemplate"].themesDS;
	BuildQuestProvider.themesDS[#BuildQuestProvider.themesDS + 1]  = BuildQuestProvider.categoryDS["worldTemplate"].themesDS;

	BuildQuestProvider.themes[#BuildQuestProvider.themes + 1]  = BuildQuestProvider.categoryDS["globalTemplate"].themes;
	BuildQuestProvider.themes[#BuildQuestProvider.themes + 1]  = BuildQuestProvider.categoryDS["worldTemplate"].themes;

	if(loginMain.IsSignedIn()) then
		self:LoadFromCloud(function()
			BuildQuestProvider.themesDS[#BuildQuestProvider.themesDS + 1]  = BuildQuestProvider.categoryDS["cloudTemplate"].themesDS;
			BuildQuestProvider.themes[#BuildQuestProvider.themes + 1]      = BuildQuestProvider.categoryDS["cloudTemplate"].themes;

			for i=1, #BuildQuestProvider.themes do
				BuildQuestProvider.themes[i].id = i;
			end

			BuildQuestProvider.themesDS[#BuildQuestProvider.themesDS + 1] = {name = "empty", official = false};

			if(type(self.cloudLoadFinish) == "function") then
				self.cloudLoadFinish();
			end
		end);
	else
		self:LoadFromCloud();

		BuildQuestProvider.themesDS[#BuildQuestProvider.themesDS + 1]  = BuildQuestProvider.categoryDS["cloudTemplate"].themesDS;
		BuildQuestProvider.themes[#BuildQuestProvider.themes + 1]      = BuildQuestProvider.categoryDS["cloudTemplate"].themes;

		for i=1, #BuildQuestProvider.themes do
			BuildQuestProvider.themes[i].id = i;
		end

		BuildQuestProvider.themesDS[#BuildQuestProvider.themesDS + 1] = {name = "empty", official = false};
	end
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
	local cur_themesType = BuildQuestProvider.categoryDS[themeKey]["themesType"];
	local cur_themes     = BuildQuestProvider.categoryDS[themeKey]["themes"];
	
	if(themeKey == "globalTemplate") then
		local hasOldGlobalFiles;

		local output = BuildQuestProvider:GetFiles(themePath, function (msg)
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

	commonlib.partialcopy(cur_themesDS, {
		name         = theme_ds_name,
		foldername   = themeKey,
		order        = 10,
		unlock_coins = "0",
		image        = "",
		icon         = "",
		official     = BuildQuestProvider.categoryDS[themeKey]["beOfficial"],
	});

	cur_themes = ThemeClass:new({
		name         = themeKey,
		foldername   = themeKey,
		unlock_coins = "0",
		image        = "",
		icon         = "",
		official     = BuildQuestProvider.categoryDS[themeKey]["beOfficial"],
		themeKey     = themeKey
	});
	
	BuildQuestProvider.categoryDS[themeKey]["themes"] = cur_themes;

	cur_themes.tasksDS = {};
	cur_themes.tasks   = {};

	local tasksDS = cur_themes.tasksDS;
	local tasks   = cur_themes.tasks;

	local isThemeZipFile = false; --暂不考虑压缩情况

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

				tasks[task_index] = TaskClass:new(task_attr):Init(node, cur_themes, task_index, themeKey);

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
				task_index = #tasksDS + 1;

				tasksDS[task_index] = {};

				local file = {name = taskname};

				commonlib.partialcopy(tasksDS[task_index], file);
				tasksDS[task_index].task_index = task_index;

				tasks[task_index] = {
					name     = taskname,
					type     = "template",
					filename = BuildQuestProvider.categoryPaths['worldTemplate'] .. task_item,
				};
			end
		end
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
	local theme_name = "cloudTemplate";

	BuildQuestProvider.categoryDS[theme_name]['themes']     = {};
	BuildQuestProvider.categoryDS[theme_name]['themesDS']   = {};
	BuildQuestProvider.categoryDS[theme_name]['themesType'] = {};

	local cur_themes     = BuildQuestProvider.categoryDS[theme_name]['themes'];
	local cur_themesDS   = BuildQuestProvider.categoryDS[theme_name]['themesDS'];
	local cur_themesType = BuildQuestProvider.categoryDS[theme_name]['themesType'];

	commonlib.partialcopy(cur_themesDS, {
		order        = 10,
		foldername   = theme_name,
		official     = BuildQuestProvider.categoryDS[theme_name]["beOfficial"],
		icon         = "",
		unlock_coins = "0",
		name         = "云模板",
		image        = "",
		themeKey     = theme_name,
	});

	cur_themes = ThemeClass:new({
		name         = theme_name,
		foldername   = theme_name,
		unlock_coins = "0",
		image        = "",
		icon         = "",
		official     = BuildQuestProvider.categoryDS[theme_name]["beOfficial"],
		themeKey     = themeKey
	});

	BuildQuestProvider.categoryDS[theme_name]['themes'] = cur_themes;

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

			local globalThemes = BuildQuestProvider.categoryDS.globalTemplate.themes;
			
			local cur_tasksDS = cur_themes.tasksDS;
			local cur_tasks   = cur_themes.tasks;

			for key, item in ipairs(data.data) do
				local status = false;
				
				for Lkey,Litem in ipairs(globalThemes.tasks) do
					if(not Litem.infoCard or not Litem.infoCard.sn) then
						break;
					end

					if(tostring(item.modelsnumber) == tostring(Litem.infoCard.sn)) then
						status = true;
						break;
					end
				end

				local task_index = #cur_tasksDS + 1;

				cur_tasksDS[task_index] = {
					name   = item.templateName,
					status = status,
					sn     = item.modelsnumber,
				};
				
				cur_tasks[task_index] = {
					name     = item.templateName,
					infoCard = {
						sn         = item.modelsnumber,
						createDate = item.createDate,
						blocks     = item.blocks,
						volume     = item.volume,
						username   = item.username,
						isShare    = item.isShare,
					} 
				};

				if(status) then
					cur_tasks[task_index].dir = BuildQuestProvider.categoryPaths['globalTemplate'] .. item.modelsnumber .. "/";
				end
			end

			if(type(callback) == "function") then
				callback();
			end
		end)
	end
end

function BuildQuestProvider:DeleteCloudTemplate(sn, callback)
	if(sn) then
		HttpRequest:GetUrl({
			url     = self.CloudApi() .. "delete",
			json    = true,
			headers = {
				Authorization = "Bearer " .. loginMain.token,
			},
			form   = {
				modelsnumber = sn,
			},
		},function(data, err)
			local beSuccess = false;

			if(type(data) == "table" and data.error and data.error.id == 0) then
				beSuccess = true;
			end

			if(type(callback) == "function") then
				callback(beSuccess);
			end
		end);
	else
		return false;
	end
end

function BuildQuestProvider:GetThemes_DS(theme_id)
	if(not next(BuildQuestProvider.themesDS)) then
		return {};
	end

	if(theme_id) then
		if(BuildQuestProvider.themesDS[theme_id]) then
			return BuildQuestProvider.themesDS[theme_id];
		else
			return {};
		end
	end

	return BuildQuestProvider.themesDS;
end

-- get the tasks information. 
function BuildQuestProvider:GetTasks_DS(theme_id, task_id)
	if(not next(BuildQuestProvider.themes) and BuildQuestProvider.themes[theme_id]) then
		return {};
	end

	if(task_id) then
		if(BuildQuestProvider.themes[theme_id].tasksDS[task_id]) then
			return BuildQuestProvider.themes[theme_id].tasksDS[task_id]; 
		else
			return {};
		end
	end

	return BuildQuestProvider.themes[theme_id].tasksDS;
end

function BuildQuestProvider:GetTask(theme_id, task_id)
	if(not next(BuildQuestProvider.themes) and not BuildQuestProvider.themes[theme_id]) then
		return {};
	end

	--echo(theme_id);
	--echo(BuildQuestProvider.themes[theme_id], true);
	if(type(BuildQuestProvider.themes[theme_id].GetTask) == "function") then
		return BuildQuestProvider.themes[theme_id]:GetTask(task_id);
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