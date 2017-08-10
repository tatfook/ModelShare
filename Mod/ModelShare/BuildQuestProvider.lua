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

local tasks            = {};
local themes           = {};
local themesDS         = {};
local block_wiki_tasks = {};
local myThemePath      = "worlds/DesignHouse/blocktemplates/";

local categoryPaths = {
	["template"]  = "worlds/DesignHouse/blocktemplates/",
	["tutorial"]  = "config/Aries/creator/blocktemplates/buildingtask/",
	["blockwiki"] = "config/Aries/creator/blocktemplates/blockwiki/",
};

local categoryDS = {
	["template"] = {
		themes = {},themesDS = {},themesType = {},beOfficial = false,
	},
	["tutorial"] = {
		themes = {},themesDS = {},themesType = {},beOfficial = true,
	},
	["blockwiki"] = {
		themes = {},themesDS = {},themesType = {},beOfficial = true,
	},
};

function ModelBuildQuestProvider:ctor()
end

function ModelBuildQuestProvider:Init()
	self:LoadFromFile();

	if(self.is_inited) then
		return
	end

	self.is_inited = true;
end

function ModelBuildQuestProvider:LoadFromFile(filename)
	if(not self.NeedRefreshDS) then
		return;
	end

	themes        = {};
	themesDS      = {};
	localthemesDS = {};

	for key, path in pairs(categoryPaths) do
		categoryDS[key]["themes"]     = {};
		categoryDS[key]["themesDS"]   = {};
		categoryDS[key]["themesType"] = {};

		self:LoadFromTemplate(key, path);
	end
end

function ModelBuildQuestProvider:LoadFromTemplate(themeKey, themePath)
	echo(themeKey)
	if(themeKey == "template") then
		categoryDS[themeKey]["themes"]   = themes;
		categoryDS[themeKey]["themesDS"] = themesDS;
	end
	
	local cur_themes     = categoryDS[themeKey]["themes"];
	local cur_themesDS   = categoryDS[themeKey]["themesDS"];
	local cur_themesType = categoryDS[themeKey]["themesType"];
	local beOfficial     = categoryDS[themeKey]["beOfficial"];

	--BuildQuestProvider.PrepareGlobalTemplateDir();
	--ֱ��ʹ�� worlds/DesignHouse/blocktemplates/

	local hasOldGlobalFiles;

	local output = self:GetFiles(themePath, function (msg)
		echo(msg, true);
		if(msg.filesize == 0 or string.match(msg.filename,"%.zip$")) then
			-- folder or zip file
			return true;
		elseif(string.match(msg.filename,"blocks%.xml$")) then
			-- never execute here
			hasOldGlobalFiles = true;
		end
	end, "*.*");

	echo("hasOldGlobalFiles");
	echo(hasOldGlobalFiles);

	if(hasOldGlobalFiles and themeKey == "template") then
		--compatible
		self:TranslateGlobalTemplateToBuildingTask();
	end

	echo("----------------")
	--echo(themeKey)
	--echo(output,true)
	echo("----------------")

	for key, themeitem in ipairs(output) do
		local theme_name     = string.match(themeitem, "^(.*).zip$");
		local isThemeZipFile = false;

		if(theme_name) then
			local filename = themePath .. themeitem;

			ParaAsset.OpenArchive(filename, true);

			isThemeZipFile = true;
		else
			theme_name = themeitem;
		end
		
		local theme_path      = themePath .. theme_name .. "/";
		local theme_name_utf8 = commonlib.Encoding.DefaultToUtf8(theme_name);
		local order           = 10;

		if(not isThemeZipFile) then
			local theme_info_file = theme_path .. "info.xml";
			local xmlRoot         = ParaXML.LuaXML_ParseFile(theme_info_file);

			if(xmlRoot) then
				for node in commonlib.XPath.eachNode(xmlRoot, "/Theme") do
					local attr = node.attr;

					if(attr and attr.name) then
						theme_name_utf8 = L(attr.name);

						if(attr.order) then
							order = tonumber(attr.order) or order;
						end

						break;
					end
				end
			end
		end

		local insert_index;

		for i=1, #cur_themesDS do
			local item = cur_themesDS[i];

			if( (item.order or 10 )>order) then
				insert_index = i;
				break;
			end
		end

		cur_themesDS[#cur_themesDS+1] = {
			name         = theme_name_utf8,
			foldername   = theme_name,
			order        = order,
			unlock_coins = "0",
			image        = "",
			icon         = "",
			official     = false,
		};

		local theme_index       = #cur_themes+1;

		cur_themes[theme_index] = ThemeClass:new({
			name         = theme_name_utf8,
			foldername   = theme_name,
			unlock_coins = "0",
			image        = "",
			icon         = "",
			official     = false,
			themeKey     = themeKey
		});

		localthemesDS[#localthemesDS + 1] = {value = theme_name_utf8};

		if(not isThemeZipFile) then
			local next_theme_type_index           = #cur_themesType + 1;
			cur_themesType[next_theme_type_index] = {text = theme_name_utf8, value = theme_name};
		end

		if(insert_index) then
			table.insert(cur_themesDS , insert_index, cur_themesDS[theme_index]);
			cur_themesDS[theme_index+1]  = nil;

			table.insert(cur_themes   , insert_index, cur_themes[theme_index]);
			cur_themes[theme_index+1]    = nil;

			table.insert(localthemesDS, insert_index, localthemesDS[theme_index]);
			localthemesDS[theme_index+1] = nil;

			theme_index = insert_index;
		end

		--local theme_path = themePath..theme_name.."/";
		local tasks_output;

		if(isThemeZipFile) then
			tasks_output = self:GetFiles(theme_path, "*.", "*.zip");
		else
			tasks_output = self:GetFiles(theme_path, function (msg)
				-- folder or zip
				return msg.filesize == 0 or string.match(msg.filename,".zip");
			end, "*.*");
		end

		--echo(tasks_output,true)

		local theme   = cur_themes[theme_index];
		local tasksDS = theme.tasksDS;
		local tasks   = theme.tasks;

		for _, taskitem in ipairs(tasks_output) do
			local taskname;

			if(isThemeZipFile) then
				taskname = string.match(taskitem, "^(.*)/$");
			else
				taskname = string.match(taskitem, "^(.*).zip$");

				if(taskname) then
					local filename = theme_path .. taskitem;
					ParaAsset.OpenArchive(filename, true);
				else
					taskname = taskitem;
				end
			end
			
			local taskpath    = theme_path .. taskname .. "/" .. taskname .. ".xml";
			local task_dir    = theme_path .. taskname .. "/";
			local taskXmlRoot = ParaXML.LuaXML_ParseFile(taskpath);

			for node in commonlib.XPath.eachNode(taskXmlRoot, "/Task") do
				node.attr.filepath  = taskpath;
				node.attr.dir       = task_dir;
				tasksDS[#tasksDS+1] = {};
				
				commonlib.partialcopy(tasksDS[#tasksDS], node.attr);
				tasksDS[#tasksDS].task_index = #tasksDS;

				local task_index  = #tasks+1;
				tasks[task_index] = TaskClass:new(node.attr):Init(node, theme, task_index, themeKey);
				
				if(themeKey == "blockwiki") then
					local block_id, task_name   = string.match(tasksDS[#tasksDS].name,"(%d*)_(.*)");
					tasksDS[#tasksDS].block_id  = tonumber(block_id);
					--tasksDS[#tasksDS].name = task_name;
				end

				--myTaskMap[node.attr.name] = {task_index = task_index, task_ds_index = #myTasksDS};
			end
		end
	end

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
			local c1 = string_byte(filename1, i);
			local c2 = string_byte(filename2, i);

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
	if(not next(themesDS)) then
		self:Init();
	end

	local ds;

	if(themeKey) then
		ds = categoryDS[themeKey]["themesDS"]
	else
		ds = themesDS;
	end

	return ds;
end

-- get the tasks information. 
function ModelBuildQuestProvider:GetTasks_DS(theme_id, category)
	self:Init();

	local theme = self:GetTheme(theme_id, category);

	if(not theme) then
		return;
	end

	return theme.tasksDS;
end

function ModelBuildQuestProvider:GetTheme(theme_id, category)
	local cur_themes;

	if(category) then
		cur_themes = categoryDS[category]["themes"];
	else
		cur_themes = themes;
	end

	return cur_themes[theme_id or 1];
end

-- to be compatible with old file structure. we will need to move from old template position. 
-- @param bDeleteOldFile: whether we will delete old files
function ModelBuildQuestProvider:TranslateGlobalTemplateToBuildingTask(bDeleteOldFile)
	--local allTemplate = BlockTemplatePage.GetAllTemplatesDS();
	local globalTemplate = self:GetFiles(myThemePath, function (msg)
		return string.match(msg.filename,"%.blocks%.xml$") ~= nil;
	end);

	LOG.std(nil, "info", "TranslateGlobalTemplateToBuildingTask", "%d files translated", #globalTemplate);
	
	for i = 1,#globalTemplate do
		--local file = globalTemplate[i];
		local filename = string.gsub(globalTemplate[i],".blocks.xml","");
		
		local srcpath = string.format("%s%s.blocks.xml",myThemePath,filename);
		local despath = string.format("%s/%s.blocks.xml",global_dir_default..filename,filename);

		if(not ParaIO.DoesFileExist(despath, false)) then
			ParaIO.CopyFile(srcpath, despath, true);
			local taskfilename   = string.format("%s/%s.xml",global_dir_default..filename,filename);
			local blocksfilename = string.format("%s/%s.blocks.xml",global_dir_utf8..commonlib.Encoding.DefaultToUtf8(filename),commonlib.Encoding.DefaultToUtf8(filename));

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
		ParaIO.DeleteFile(myThemePath.."*.jpg");
	end
end