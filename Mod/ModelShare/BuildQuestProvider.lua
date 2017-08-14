--[[
Title: BuildQuestProvider
Author(s):  BIG
Date: 2017.8
Desc: BuildQuestProvider for modelshare mod
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ModelShare/BuildQuestProvider.lua");
local ModelBuildQuestProvider = commonlib.gettable("Mod.ModelShare.BuildQuestProvider");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestProvider.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
NPL.load("(gl)Mod/ModelShare/ThemeClass.lua");
NPL.load("(gl)Mod/ModelShare/TaskClass.lua");

local BuildQuest              = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest");
local BuildQuestProvider      = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");
local BlockTemplatePage       = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
local ThemeClass              = commonlib.gettable("Mod.ModelShare.ThemeClass");
local TaskClass               = commonlib.gettable("Mod.ModelShare.TaskClass");

local ModelBuildQuestProvider = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.BuildQuestProvider"));

ModelBuildQuestProvider.tasks            = {};
ModelBuildQuestProvider.themes           = {};
ModelBuildQuestProvider.themesDS         = {};
ModelBuildQuestProvider.localthemesDS    = {};
ModelBuildQuestProvider.block_wiki_tasks = {};
ModelBuildQuestProvider.globalThemePath  = "worlds/DesignHouse/blocktemplates/";

ModelBuildQuestProvider.categoryPaths = {
	["globalTemplate"]  = "worlds/DesignHouse/blocktemplates/",
};

ModelBuildQuestProvider.categoryDS = {
	["globalTemplate"] = {
		themes = {}, themesDS = {}, themesType = {}, beOfficial = false,
	},
	['worldTemplate'] = {
		themes = {}, themesDS = {}, themesType = {}, beOfficial = false;
	}
};

function ModelBuildQuestProvider:ctor()
	echo("Init BuildQuestProvider");
	local currentWorldPath = GameLogic.GetWorldDirectory():gsub("\\","/");

	ModelBuildQuestProvider.categoryPaths['worldTemplate'] = currentWorldPath .. "blocktemplates/";

	self:LoadFromFile();
end

function ModelBuildQuestProvider:LoadFromFile(filename)
	ModelBuildQuestProvider.themes           = {};
	ModelBuildQuestProvider.themesDS         = {};
	ModelBuildQuestProvider.localthemesDS    = {};

	for key, path in pairs(ModelBuildQuestProvider.categoryPaths) do
		ModelBuildQuestProvider.categoryDS[key]["themes"]     = {};
		ModelBuildQuestProvider.categoryDS[key]["themesDS"]   = {};
		ModelBuildQuestProvider.categoryDS[key]["themesType"] = {};

		self:LoadFromTemplate(key, path);
	end
end

function ModelBuildQuestProvider:LoadFromTemplate(themeKey, themePath)
	--[[if(themeKey == "globalTemplate") then
		ModelBuildQuestProvider.categoryDS[themeKey]["themes"]   = ModelBuildQuestProvider.themes;
		ModelBuildQuestProvider.categoryDS[themeKey]["themesDS"] = ModelBuildQuestProvider.themesDS;
	end]]
	
	local cur_themes     = ModelBuildQuestProvider.categoryDS[themeKey]["themes"];
	local cur_themesDS   = ModelBuildQuestProvider.themesDS;--ModelBuildQuestProvider.categoryDS[themeKey]["themesDS"];
	local cur_themesType = ModelBuildQuestProvider.categoryDS[themeKey]["themesType"];
	local beOfficial     = ModelBuildQuestProvider.categoryDS[themeKey]["beOfficial"];

	--BuildQuestProvider.PrepareGlobalTemplateDir();
	--直接使用 worlds/DesignHouse/blocktemplates/

	--[[local output = self:GetFiles(themePath, function (msg)
		if(msg.filesize == 0 or string.match(msg.filename,"%.zip$")) then
			-- folder or zip file
			return true;
		elseif(string.match(msg.filename,"blocks%.xml$")) then
			-- never execute here
			hasOldGlobalFiles = true;
		end
	end, "*.*");]]

	local hasOldGlobalFiles;

	if(hasOldGlobalFiles and themeKey == "globalTemplate") then
		--compatible
		self:TranslateGlobalTemplateToBuildingTask(true);
	end

	--[[for _, theme_item in ipairs(output) do --取消获取子目录
	end]]

	--local theme_name     = string.match(theme_item, "^(.*).zip$");
	--local isThemeZipFile = false;

	--[[if(theme_name) then
		local filename = themePath .. theme_item;

		ParaAsset.OpenArchive(filename, true);

		isThemeZipFile = true;
	else
		theme_name = theme_item;
	end]]
	
	--local theme_path      = themePath .. theme_name .. "/";
	--local theme_name_utf8 = commonlib.Encoding.DefaultToUtf8(theme_name);
	local order = 10;

	--[[if(not isThemeZipFile) then
		local theme_info_file = theme_path .. "info.xml";
		local xmlRoot         = ParaXML.LuaXML_ParseFile(theme_info_file);

		if(xmlRoot) then
			for node in commonlib.XPath.eachNode(xmlRoot, "/Theme") do
				local attr = node.attr;

				if(attr and attr.name) then
					theme_name_utf8 = L(attr.name); --set info,xml theme_name

					if(attr.order) then
						order = tonumber(attr.order) or order;
					end

					break;
				end
			end
		end
	end

	local insert_index;

	for _, item in ipairs(cur_themesDS) do
		if((item.order or 10 ) > order) then
			insert_index = i;
			break;
		end
	end]]
	
	local theme_ds_name;

	if(themeKey == "globalTemplate") then
		theme_ds_name    = "本地全局模板";
		--theme_ds_name.default = commonlib.Encoding.Utf8ToDefault(themeKey); 
	elseif(themeKey == "worldTemplate") then
		theme_ds_name    = "本存档模板";
		--theme_ds_name.default = commonlib.Encoding.Utf8ToDefault(themeKey); 
	end

	cur_themesDS[#cur_themesDS + 1] = {
		name         = theme_ds_name,
		foldername   = themeKey,
		order        = order,
		unlock_coins = "0",
		image        = "",
		icon         = "",
		official     = false,
	};
	
	local theme_index = #cur_themes + 1;

	cur_themes[theme_index] = ThemeClass:new({
		--name         = theme_name_utf8,
		--foldername   = theme_name,
		unlock_coins = "0",
		image        = "",
		icon         = "",
		official     = false,
		themeKey     = themeKey
	});

	echo(cur_themes, true);

	--ModelBuildQuestProvider.localthemesDS[#ModelBuildQuestProvider.localthemesDS + 1] = {value = theme_name_utf8};
	
	if(not isThemeZipFile) then
		local next_theme_type_index           = #cur_themesType + 1;
		cur_themesType[next_theme_type_index] = {text = theme_name_utf8, value = theme_name};
	end
	
	--[[if(insert_index) then
		table.insert(cur_themesDS , insert_index, cur_themesDS[theme_index]);
		cur_themesDS[theme_index + 1]   = nil;

		table.insert(cur_themes   , insert_index, cur_themes[theme_index]);
		cur_themes[theme_index + 1]    = nil;

		table.insert(localthemesDS, insert_index, localthemesDS[theme_index]);
		localthemesDS[theme_index + 1] = nil;

		theme_index = insert_index;
	end]]

	--local theme_path = themePath..theme_name.."/";
	local tasks_output;

	if(isThemeZipFile) then
		tasks_output = self:GetFiles(themePath, "*.", "*.zip");
	else
		tasks_output = self:GetFiles(themePath, function (msg)
			-- folder or zip
			return msg.filesize == 0 or string.match(msg.filename,".xml") or string.match(msg.filename,".zip");
		end, "*.*");
	end

	echo(tasks_output,true)
	
	local tasksDS = cur_themes[theme_index].tasksDS;
	local tasks   = cur_themes[theme_index].tasks;
	
	for _, task_item in ipairs(tasks_output) do
		local taskname;

		if(isThemeZipFile) then
			taskname = string.match(task_item, "^(.*)/$");
		else
			--判断task item是否ZIP文件
			taskname = string.match(task_item, "^(.*).zip$");

			if(taskname) then
				local filename = theme_path .. task_item;
				ParaAsset.OpenArchive(filename, true);
			else
				taskname = task_item;
			end
		end

		local taskpath    = themePath .. taskname .. "/" .. taskname .. ".xml";
		local task_dir    = themePath .. taskname .. "/";
		local taskXmlRoot = ParaXML.LuaXML_ParseFile(taskpath);

		for node in commonlib.XPath.eachNode(taskXmlRoot, "/Task") do
			node.attr.filepath  = taskpath;
			node.attr.dir       = task_dir;
			echo(node, true);
			tasksDS[#tasksDS+1] = {};

			commonlib.partialcopy(tasksDS[#tasksDS], node.attr);
			tasksDS[#tasksDS].task_index = #tasksDS;

			local task_index  = #tasks + 1;
			tasks[task_index] = TaskClass:new(node.attr):Init(node, cur_themes[theme_index], task_index, themeKey);
			
			--[[if(themeKey == "blockwiki") then
				local block_id, task_name   = string.match(tasksDS[#tasksDS].name,"(%d*)_(.*)");
				tasksDS[#tasksDS].block_id  = tonumber(block_id);
				--tasksDS[#tasksDS].name = task_name;
			end]]

			--myTaskMap[node.attr.name] = {task_index = task_index, task_ds_index = #myTasksDS};
		end
	end
	echo(cur_themes[theme_index], true);
	if(true) then
		return;
	end
	---------------------------------------------------------------------------------------------------
	for i=1, #cur_themes do
		cur_themes[i].id = i;
	end

	if (#localthemesDS == 0) then
		localthemesDS[#localthemesDS + 1] = {value = global_template_name_utf8};
	end

	if(not beOfficial) then
		cur_themesDS[#cur_themesDS+1] = {name = "empty", official = false};
	end

	self.NeedRefreshDS = false;
end

function ModelBuildQuestProvider:GetFiles(path, filter, zipfile)
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

function ModelBuildQuestProvider:GetThemes_DS(themeKey)
	if(not next(ModelBuildQuestProvider.themesDS)) then
		return {};
	end

	local ds;

	if(themeKey) then
		ds = ModelBuildQuestProvider.categoryDS[themeKey]["themesDS"]
	else
		ds = ModelBuildQuestProvider.themesDS;
	end

	return ds;
end

-- get the tasks information. 
function ModelBuildQuestProvider:GetTasks_DS(theme_id, category)
	local theme = self:GetTheme(theme_id, category);

	if(not theme) then
		return;
	end

	return theme.tasksDS;
end

function ModelBuildQuestProvider:GetTheme(theme_id, category)
	local cur_themes;

	if(category) then
		cur_themes = ModelBuildQuestProvider.categoryDS[category]["themes"];
	else
		cur_themes = ModelBuildQuestProvider.themes;
	end

	return cur_themes[theme_id or 1];
end

function ModelBuildQuestProvider:GetTask(theme_id, task_id, category)
	if(self == nil) then
		echo("GetTask NIL");
		return;
	end

	local theme = self:GetTheme(theme_id, category);

	if(theme) then
		return theme:GetTask(task_id);
	end
end

-- to be compatible with old file structure. we will need to move from old template position. 
-- @param bDeleteOldFile: whether we will delete old files
function ModelBuildQuestProvider:TranslateGlobalTemplateToBuildingTask(bDeleteOldFile)
	--local allTemplate = BlockTemplatePage.GetAllTemplatesDS();
	local globalThemePath = ModelBuildQuestProvider.globalThemePath;

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

function ModelBuildQuestProvider:OnSaveTaskDesc(theme_index, task_index,desc)
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