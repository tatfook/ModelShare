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
NPL.load("(gl)Mod/ModelShare/BuildQuestTask.lua");
NPL.load("(gl)Mod/ModelShare/BuildQuestProvider.lua");
NPL.load("(gl)Mod/ModelShare/ShareWindow.lua");

local loginMain               = commonlib.gettable("Mod.WorldShare.login.loginMain");
local ModelBuildQuest         = commonlib.gettable("Mod.ModelShare.BuildQuest");
local ModelBuildQuestProvider = commonlib.gettable("Mod.ModelShare.BuildQuestProvider");
local ShareWindow             = commonlib.gettable("Mod.ModelShare.ShareWindow");

local ModelManager = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.ModelManager"));

ModelManager.isEditing = false;

function ModelManager:ctor()
	ModelBuildQuest:new();

	self.ModelBuildQuestProvider = ModelBuildQuestProvider:new();
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

function ModelManager.GetPage()
	if(ModelManager.curInstance) then
		return ModelManager.curInstance.page;
	end
end

function ModelManager.Refresh()
	if(ModelManager.curInstance) then
		ModelManager.curInstance.page:Refresh(0.01);
	end
end

function ModelManager.RefreshList()
	if(ModelManager.curInstance) then
		self = ModelManager.curInstance;

		ModelBuildQuest:new();
		self.ModelBuildQuestProvider = ModelBuildQuestProvider:new();

		self.page:Refresh(0.01);
	end
end

function ModelManager:OnClose()
	if(self.page) then
		self.page:CloseWindow();
	end

	ModelManager.curInstance = nil;
end

function ModelManager.ClosePage()
	if(ModelManager.curInstance) then
		ModelManager.curInstance:OnClose();
	end
end

function ModelManager.GetTheme_DS(index)
	if(ModelManager.curInstance) then
		self = ModelManager.curInstance;
	end

    local themesDS = self.ModelBuildQuestProvider:GetThemes_DS();

    if(not index) then
        return #themesDS;
    else
        return themesDS[index];
    end
end

function ModelManager.GetTask_DS(index)
	if(ModelManager.curInstance) then
		self = ModelManager.curInstance;
	else
		return;
	end

    local tasksDS = self.ModelBuildQuestProvider:GetTasks_DS(ModelBuildQuest.template_theme_index);

    if(not index) then
        return #tasksDS;
    else
        return tasksDS[index];
    end
end

function ModelManager.GetTaskName()
	if(ModelManager.curInstance) then
		self = ModelManager.curInstance;
	else
		return;
	end

    local task = self.ModelBuildQuestProvider:GetTask(ModelBuildQuest.template_theme_index, ModelBuildQuest.cur_task_index);
	--echo(task, true);
    if(task) then
        return task.name or "";
    else
        return "";
    end
end

function ModelManager.GetTaskInfo()
	if(ModelManager.curInstance) then
		self = ModelManager.curInstance;
	else
		return;
	end

    local task = self.ModelBuildQuestProvider:GetTask(ModelBuildQuest.template_theme_index, ModelBuildQuest.cur_task_index);

	if(task) then
		return task;
	end
end

function ModelManager.TaskIsLocked(index)
    if(index > ModelBuildQuest.cur_task_index) then
        return true;
    else
        return false;
    end
end

--[[function ModelManager.CreateNewTheme()
    ModelBuildQuest.new_theme_category_dir = "worlds/DesignHouse/blocktemplates/";
    ModelBuildQuest:ShowCreateNewThemePage("template");
end]]

function ModelManager.vip()
	_guihelper.MessageBox(L"VIP功能正在开发中...");
end

function ModelManager.GetCurThemeIndex()
    return ModelBuildQuest.template_theme_index;
end

function ModelManager.ChangeTheme(name, mcmlNode)
    local index = mcmlNode:GetAttribute("param1");
    index       = tonumber(index);

	if(index == 3 and not loginMain.IsSignedIn()) then
		_guihelper.MessageBox(L"登陆后才能查看");
		return;
	end
   -- ModelBuildQuest.template_theme_index = index;
    --echo(ModelBuildQuest.template_theme_index)

	ModelBuildQuest:new({
		cur_theme_index      = index,
		template_theme_index = index, 
		cur_task_index       = 1,
	});

    --task_index = ModelBuildQuest.cur_task_index;
	
	if(ModelManager.curInstance) then
		ModelManager.curInstance.RestEditing();
	end

    ModelManager.Refresh();
end

function ModelManager.RestEditing()
	isEditing = false;
end

function ModelManager.TaskIsSelected(index)
    if(ModelBuildQuest.cur_task_index == index) then
        return true;
    else
        return false;
    end
end

function ModelManager.ChangeTask(name, mcmlNode)
    local index = mcmlNode:GetAttribute("param1");

    ModelBuildQuest.cur_task_index      = tonumber(index);
    ModelBuildQuest.template_task_index = tonumber(index);

	if(ModelManager.curInstance) then
		ModelManager.curInstance.RestEditing();
	end

	ModelManager.Refresh();
end

function ModelManager.CanEditing()
	local curTheme;
	
	if(true) then
		return true;
	end

	if(ModelManager.curInstance) then
		curTheme = ModelManager.curInstance.GetTheme_DS(ModelBuildQuest.template_theme_index);
	end
	--echo(curTheme);
    if(curTheme) then
        if(curTheme.official) then
            return false;
        else
            return true;
        end
    end

    return false;
end

function ModelManager.OnChangeTaskDesc()
    ModelManager.isEditing = true;
	ModelManager.Refresh();
end

function ModelManager.OnSaveTaskDesc()
    ModelManager.isEditing = false;

    local content = ModelManager.GetPage():GetValue("content", "");
    local desc    = string.gsub(content,"\r\n","<br />");

	--echo(desc, true);

    self.ModelBuildQuestProvider:OnSaveTaskDesc(theme_index, task_index,desc);
    ModelManager.Refresh();
end

function ModelManager.screenshot()
    return false;
end

function ModelManager.GetQuestTriggerText()
    local s        = "";
    local cur_task = ModelBuildQuest:GetCurrentQuest();

    if(ModelBuildQuest:IsTaskUnderway() and cur_task and cur_task.theme_id == ModelBuildQuest.template_theme_index) then
        s = L"放弃建造";
    else
        local task = self.ModelBuildQuestProvider:GetTask(ModelBuildQuest.template_theme_index, ModelBuildQuest.cur_task_index);

		if(task == nil) then
			return "";
		end

        if(task.type == "template" or type(task.IsClickOnceDeploy) == "function" and task:IsClickOnceDeploy()) then
            s = L"使用";
        else
            s = L"开始建造";
        end
    end

    return s;
end

function ModelManager.StartBuild()
	--echo(ModelBuildQuest.cur_theme_index);
	--echo(ModelBuildQuest.cur_task_index);

	if(ModelBuildQuest.cur_theme_index == 1) then
		local cur_task = ModelBuildQuest:GetCurrentQuest();

		if(ModelBuildQuest:IsTaskUnderway() and cur_task.theme_id == ModelBuildQuest.cur_theme_index) then
			ModelBuildQuest:EndEditing();
			return;
		end

		local UseAbsolutePos  = mouse_button == "right";
		local ClickOnceDeploy = UseAbsolutePos;

		local task = ModelBuildQuest:new({
						theme_id = ModelBuildQuest.cur_theme_index, 
						task_id  = ModelBuildQuest.cur_task_index, 
						step_id  = 1,
						UseAbsolutePos  = UseAbsolutePos,
						ClickOnceDeploy = ClickOnceDeploy});
	
		--echo(task, true);

		task:Run();
	elseif(ModelBuildQuest.cur_theme_index == 2) then
		local curTheme = ModelBuildQuestProvider.themes[ModelBuildQuest.cur_theme_index];

		ModelBuildQuest.CreateFromTemplate(curTheme.tasks[ModelBuildQuest.cur_task_index].filename);
	end

    ModelManager.ClosePage();
end

function ModelManager.DeleteTemplate()
	_guihelper.MessageBox(format(L"确定删除此模板:%s?", ""), function(res)
		if(res and res == _guihelper.DialogResult.Yes) then
			local curTheme = ModelBuildQuestProvider.themes[ModelBuildQuest.cur_theme_index];
			local curTask  = curTheme.tasks[ModelBuildQuest.cur_task_index];

			if(ModelBuildQuest.cur_task_index == #curTheme.tasks) then
				ModelBuildQuest.cur_task_index = ModelBuildQuest.cur_task_index - 1;
			end

			if (curTheme.themeKey == "globalTemplate") then
				if(ParaIO.DoesFileExist(curTask.filepath)) then
					ParaIO.DeleteFile(curTask.dir);
					ModelManager.RefreshList();
				else
					_guihelper.MessageBox(L"删除失败");
				end
			elseif(curTheme.themeKey == "worldTemplate") then
				if(ParaIO.DoesFileExist(curTask.filename)) then
					ParaIO.DeleteFile(curTask.filename);
					ModelManager.RefreshList();
				else
					_guihelper.MessageBox(L"删除失败");
				end
			end
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

function ModelManager.shareTemplate()
	local curShareWindow = ShareWindow:new();
	curShareWindow:SetInstance();
	curShareWindow:FolderToCloud();
end