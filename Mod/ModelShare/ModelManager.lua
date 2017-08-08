--[[
Title: ModelManager
Author(s):  BIG
Date: 2017.7
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ModelShare/ModelManager.lua");
local ModelManager = commonlib.gettable("Mod.ModelShare.ModelManager");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/WorldShare/login/LoginMain.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestProvider.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/HelpPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");

local loginMain          = commonlib.gettable("Mod.WorldShare.login.loginMain");
local BuildQuest         = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest");
local BuildQuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");
local HelpPage           = commonlib.gettable("MyCompany.Aries.Game.Tasks.HelpPage");
local UserProfile        = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");

local ModelManager = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.ModelManager"));

local categoryPaths = {
	["template"]  = "worlds/DesignHouse/blocktemplates/",
	["tutorial"]  = "config/Aries/creator/blocktemplates/buildingtask/",
	["blockwiki"] = "config/Aries/creator/blocktemplates/blockwiki/",
}

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

function ModelManager:ctor()
	self.BuildQuestTaskInit();
	self.themesDS = BuildQuestProvider.GetThemes_DS();
	--echo(self.themesDS)
--	self.themesDS[1] = {order=1,foldername="global",official=false,icon="",unlock_coins="0",name="本地全局模板",image="",};
--	self.themesDS[2] = {order=2,foldername="local" ,official=false,icon="",unlock_coins="0",name="本地存档模板",image="",};
--	self.themesDS[3] = {order=3,foldername="cloud" ,official=false,icon="",unlock_coins="0",name="云模板",image="",};
end

function ModelManager:SetInstance()
	ModelManager.curInstance = self;
end

function ModelManager:ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/ModelShare/ModelManager.html", 
		name = "ModelManager",
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory / false will only hide window
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 0,
		allowDrag = true,
		bShow = bShow,
		directPosition = true,
			align = "_ct",
			x = -636/2,
			y = -450/2,
			width = 636,
			height = 450,
		cancelShowAnimation = true,
	});
end

function ModelManager:SetPage()
	self.page = document:GetPageCtrl();
end

function ModelManager:OnClose()
	if(self.page) then
		self.page:CloseWindow();
	end

	ModelManager.curInstance = nil;
end

function ModelManager.GetTheme_DS(index)
    local themesDS = BuildQuestProvider.GetThemes_DS();
	
    if(not index) then
        return #themesDS;
    else
        return themesDS[index];
    end
end

function ModelManager.BuildQuestTaskInit(theme_index,task_index)
	--echo("HELPHELPHELPHELPHELPHELPHELPHELPHELPHELP")
	--echo(HelpPage.cur_category)
	--echo(HelpPage.task_index)
	if(HelpPage.cur_category and (HelpPage.cur_category == "command" or HelpPage.cur_category == "shortcutkey")) then
		return;
	end

	BuildQuestProvider.Init();
	BuildQuest.cur_theme_index = theme_index or BuildQuest.cur_theme_index or 1;

	local user = UserProfile.GetUser();
	--if(user) then
		--user:ResetBuildProgress(BuildQuest.cur_theme_index)
	--end

	if(HelpPage.cur_category and HelpPage.cur_category == "tutorial") then
		BuildQuest.cur_task_index = BuildQuest.GetCurrentFinishedTaskIndex(nil,HelpPage.cur_category);
	else
		BuildQuest.cur_task_index = 1;
	end
	
	if(task_index) then
		BuildQuest.cur_task_index = task_index;
	end
	
	local cur_theme_taskDS = BuildQuestProvider.GetTasks_DS(BuildQuest.cur_theme_index,HelpPage.cur_category);
	if(cur_theme_taskDS and BuildQuest.cur_task_index > #cur_theme_taskDS) then
		BuildQuest.cur_task_index = #cur_theme_taskDS;
	end
	HelpPage.cur_category = HelpPage.cur_category or "template";
	if(BuildQuest.inited) then
		return;
	end

	BuildQuest.inited = true;

	page = document:GetPageCtrl();
	BuildQuest.template_theme_index = BuildQuest.template_theme_index or 1;
	BuildQuest.template_task_index  = BuildQuest.template_task_index or 1;
end

function ModelManager.BuildQuestProviderInit()
	self.LoadFromFile();

	if(self.is_inited) then
		return
	end

	self.is_inited = true;
end

function ModelManager.LoadFromFile(filename)
	if(not BuildQuestProvider.NeedRefreshDS) then
		return;
	end

	themesDS      = {};
	themes        = {};
	localthemesDS = {};

	for k,v in pairs(categoryPaths) do
		categoryDS[k]["themes"]     = {};
		categoryDS[k]["themesDS"]   = {};
		categoryDS[k]["themesType"] = {};

		self.LoadFromTemplate(k,v);
	end
end

function ModelManager.LoadFromTemplate(themeKey,themePath)
	if(themeKey == "template") then
		categoryDS[themeKey]["themes"]   = themes;
		categoryDS[themeKey]["themesDS"] = themesDS;
	end
	
	local cur_themes     = categoryDS[themeKey]["themes"];
	local cur_themesDS   = categoryDS[themeKey]["themesDS"];
	local cur_themesType = categoryDS[themeKey]["themesType"];
	local beOfficial     = categoryDS[themeKey]["beOfficial"];

	--BuildQuestProvider.PrepareGlobalTemplateDir(); 直接使用 worlds/DesignHouse/blocktemplates/

	local hasOldGlobalFiles;

	local output = GetFiles(themePath,function (msg)
		if(msg.filesize == 0 or string.match(msg.filename,"%.zip$")) then
			-- folder or zip file
			return true;
		elseif(string.match(msg.filename,"blocks%.xml$")) then
			-- never execute here
			hasOldGlobalFiles = true;
		end
	end, "*.*");

	if(hasOldGlobalFiles and themeKey == "template") then
		BuildQuestProvider.TranslateGlobalTemplateToBuildingTask();
	end
	echo("----------------")
	echo(themeKey)
	echo(output,true)
	echo("----------------")
	for i = 1,#output do
		local theme_name = string.match(output[i],"^(.*).zip$");
		local isThemeZipFile = false;
		if(theme_name) then
			local filename = themePath..output[i];
			ParaAsset.OpenArchive(filename, true);
			isThemeZipFile = true;
		else
			theme_name = output[i];
		end
		
		local theme_path = themePath..theme_name.."/";
		local theme_name_utf8 = commonlib.Encoding.DefaultToUtf8(theme_name);
		local order = 10;
		if(not isThemeZipFile) then
			local theme_info_file = theme_path.."info.xml";
			local xmlRoot = ParaXML.LuaXML_ParseFile(theme_info_file)
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
		cur_themesDS[#cur_themesDS+1] = {name = theme_name_utf8, foldername=theme_name, order = order, unlock_coins = "0",image = "",icon = "",official = false,};
		local theme_index =  #cur_themes+1;
		cur_themes[theme_index] = theme_class:new({name = theme_name_utf8, foldername=theme_name, unlock_coins = "0",image = "",icon = "",official = false, themeKey = themeKey});

		localthemesDS[#localthemesDS + 1] = {value = theme_name_utf8};
		if(not isThemeZipFile) then
			local next_theme_type_index = #cur_themesType + 1;
			cur_themesType[next_theme_type_index] = {text = theme_name_utf8, value = theme_name};
		end
		if(insert_index) then
			table.insert(cur_themesDS, insert_index, cur_themesDS[theme_index]); cur_themesDS[theme_index+1] = nil;
			table.insert(cur_themes, insert_index, cur_themes[theme_index]); cur_themes[theme_index+1] = nil;
			table.insert(localthemesDS, insert_index, localthemesDS[theme_index]); localthemesDS[theme_index+1] = nil;
			theme_index = insert_index;
		end

		--local theme_path = themePath..theme_name.."/";
		local tasks_output;
		if(isThemeZipFile) then
			tasks_output = GetFiles(theme_path,"*.","*.zip");
		else
			-- echo({"11111111111111", commonlib.Encoding.DefaultToUtf8(theme_path)})
			tasks_output = GetFiles(theme_path,function (msg)
				-- folder or zip
				return msg.filesize == 0 or string.match(msg.filename,".zip");
			end, "*.*");
			-- echo({"2222222222", #tasks_output});
		end
		echo(tasks_output,true)
		local theme = cur_themes[theme_index];
		local tasksDS = theme.tasksDS;
		local tasks = theme.tasks;
		for j = 1,#tasks_output do
			local taskname;
			if(isThemeZipFile) then
				taskname = string.match(tasks_output[j],"^(.*)/$")
			else
				taskname = string.match(tasks_output[j],"^(.*).zip$")
				if(taskname) then
					local filename = theme_path..tasks_output[j];
					ParaAsset.OpenArchive(filename, true);
				else
					taskname = tasks_output[j];
				end
			end
			
			local taskpath = theme_path..taskname.."/"..taskname..".xml";
			local task_dir = theme_path..taskname.."/";
			local taskXmlRoot = ParaXML.LuaXML_ParseFile(taskpath);
			for node in commonlib.XPath.eachNode(taskXmlRoot, "/Task") do
				node.attr.filepath = taskpath;
				node.attr.dir = task_dir;
				tasksDS[#tasksDS+1] = {};
				
				commonlib.partialcopy(tasksDS[#tasksDS],node.attr);
				tasksDS[#tasksDS].task_index = #tasksDS;
				local task_index = #tasks+1;
				tasks[task_index] = task_class:new(node.attr):Init(node, theme, task_index, themeKey);
				
				if(themeKey == "blockwiki") then
					local block_id,task_name = string.match(tasksDS[#tasksDS].name,"(%d*)_(.*)");
					tasksDS[#tasksDS].block_id = tonumber(block_id);
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
		cur_themesDS[#cur_themesDS+1] = {name = "empty",official = false};
	end
	BuildQuestProvider.NeedRefreshDS = false;
end
