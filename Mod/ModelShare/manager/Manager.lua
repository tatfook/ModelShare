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

local loginMain          = commonlib.gettable("Mod.WorldShare.login.loginMain");
local BuildQuest         = commonlib.gettable("Mod.ModelShare.BuildQuest");
local BuildQuestProvider = commonlib.gettable("Mod.ModelShare.BuildQuestProvider");
local ShareWindow        = commonlib.gettable("Mod.ModelShare.ShareWindow");

local ModelManager = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.ModelManager"));

ModelManager.isEditing = false;

function ModelManager:ctor()
	BuildQuest:new();

	self.BuildQuestProvider = BuildQuestProvider:new();
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

		BuildQuest:new();
		self.BuildQuestProvider = BuildQuestProvider:new();

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

    local themesDS = self.BuildQuestProvider:GetThemes_DS();

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

    local tasksDS = self.BuildQuestProvider:GetTasks_DS(BuildQuest.template_theme_index);

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

    local task = self.BuildQuestProvider:GetTask(BuildQuest.template_theme_index, BuildQuest.template_task_index);

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

    local task = self.BuildQuestProvider:GetTask(BuildQuest.template_theme_index, BuildQuest.template_task_index);

	if(task) then
		return task;
	end
end

function ModelManager.TaskIsLocked(index)
    if(index > BuildQuest.template_task_index) then
        return true;
    else
        return false;
    end
end

function ModelManager.vip()
	_guihelper.MessageBox(L"VIP功能正在开发中...");
end

function ModelManager.GetCurThemeIndex()
    return BuildQuest.template_theme_index;
end

function ModelManager.ChangeTheme(name, mcmlNode)
    local index = mcmlNode:GetAttribute("param1");
    index       = tonumber(index);

	if(index == 3 and not loginMain.IsSignedIn()) then
		loginMain.modalCall = function()
			if(ModelManager.curInstance) then
				BuildQuest.template_theme_index = 3;
				BuildQuest.template_task_index  = 1;

				ModelManager.curInstance.BuildQuestProvider:LoadFromCloud(function()
					ModelManager.Refresh();
				end);
			end
		end;

		loginMain.showLoginModalImp();
		return;
	end

	BuildQuest:new({
		template_theme_index = index, 
		template_task_index  = 1,
	});
	
	if(ModelManager.curInstance) then
		ModelManager.curInstance.RestEditing();
	end

    ModelManager.Refresh();
end

function ModelManager.RestEditing()
	isEditing = false;
end

function ModelManager.TaskIsSelected(index)
    if(BuildQuest.template_task_index == index) then
        return true;
    else
        return false;
    end
end

function ModelManager.ChangeTask(name, mcmlNode)
    local index = mcmlNode:GetAttribute("param1");

    BuildQuest.template_task_index = tonumber(index);

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
		curTheme = ModelManager.curInstance.GetTheme_DS(BuildQuest.template_theme_index);
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

    self.BuildQuestProvider:OnSaveTaskDesc(theme_index, task_index,desc);
    ModelManager.Refresh();
end

function ModelManager.screenshot()
	local TaskInfo = ModelManager.GetTaskInfo();

	if(ModelManager.curInstance and TaskInfo and TaskInfo.infoCard) then
		local templateDir  = TaskInfo.dir;
		local templateSN   = TaskInfo.infoCard.sn; 

		ModelManager.curInstance.templateImageUrl = templateDir .. templateSN .. ".jpg";

		return true;
	end

	return false;
end

function ModelManager.GetQuestTriggerText()
    local s        = "";
    local cur_task = BuildQuest:GetCurrentQuest();

    if(BuildQuest:IsTaskUnderway() and cur_task and cur_task.theme_id == BuildQuest.template_theme_index) then
        s = L"放弃建造";
    else
        local task = self.BuildQuestProvider:GetTask(BuildQuest.template_theme_index, BuildQuest.template_task_index);

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
	if(BuildQuest.cur_theme_index == 1) then
		local cur_task = BuildQuest:GetCurrentQuest();

		if(BuildQuest:IsTaskUnderway() and cur_task.theme_id == BuildQuest.cur_theme_index) then
			BuildQuest:EndEditing();
			return;
		end

		local UseAbsolutePos  = mouse_button == "right";
		local ClickOnceDeploy = UseAbsolutePos;

		local task = BuildQuest:new({
						theme_id = BuildQuest.cur_theme_index, 
						task_id  = BuildQuest.template_task_index, 
						step_id  = 1,
						UseAbsolutePos  = UseAbsolutePos,
						ClickOnceDeploy = ClickOnceDeploy});
	
		--echo(task, true);

		task:Run();
	elseif(BuildQuest.cur_theme_index == 2) then
		local curTheme = BuildQuestProvider.themes[BuildQuest.cur_theme_index];

		BuildQuest.CreateFromTemplate(curTheme.tasks[BuildQuest.template_task_index].filename);
	end

    ModelManager.ClosePage();
end

function ModelManager.DeleteTemplate()
	_guihelper.MessageBox(format(L"确定删除此模板:%s?", ""), function(res)
		if(res and res == _guihelper.DialogResult.Yes) then

			local curTheme = BuildQuestProvider.themes[BuildQuest.template_theme_index];
			echo(curTheme);

			local curTask  = BuildQuestProvider.tasksDS[BuildQuest.template_task_index];

			if(BuildQuest.template_task_index ~= 1 and BuildQuest.template_task_index == #curTheme.tasks) then
				BuildQuest.template_task_index = BuildQuest.template_task_index - 1;
			end

			echo(curTask);

			if(true) then
				return;
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
			elseif(curTheme.themeKey == "cloudTemplate") then
				_guihelper.MessageBox("OKOKOK");
			end
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

function ModelManager.shareTemplate()
	local curShareWindow = ShareWindow:new();
	curShareWindow:SetInstance();
	curShareWindow:FolderToCloud();
end