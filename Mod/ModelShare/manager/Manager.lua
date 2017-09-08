--[[
Title: Manager
Author(s):  BIG
Date: 2017.7
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ModelShare/Manager.lua");
local Manager = commonlib.gettable("Mod.ModelShare.manager.Manager");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/ModelShare/build/BuildQuestTask.lua");
NPL.load("(gl)Mod/ModelShare/build/BuildQuestProvider.lua");
NPL.load("(gl)Mod/ModelShare/share/TemplateShare.lua");

local loginMain          = commonlib.gettable("Mod.WorldShare.login.loginMain");
local BuildQuest         = commonlib.gettable("Mod.ModelShare.build.BuildQuest");
local BuildQuestProvider = commonlib.gettable("Mod.ModelShare.build.BuildQuestProvider");
local TemplateShare      = commonlib.gettable("Mod.ModelShare.share.TemplateShare");

local Manager = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.manager.Manager"));

Manager.isEditing = false;

function Manager:ctor()
	BuildQuest:new();

	self.BuildQuestProvider = BuildQuestProvider:new({
		cloudLoadFinish = function()
			Manager.Refresh();
		end
	});
end

function Manager:SetInstance()
	Manager.curInstance = self;
end

function Manager:ShowPage()
	BuildQuest.template_theme_index = 1;
	BuildQuest.template_task_index  = 1;

	System.App.Commands.Call("File.MCMLWindowFrame", {
		url  = "Mod/ModelShare/manager/Manager.html", 
		name = "Manager",
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

function Manager:SetPage()
	self.page = document:GetPageCtrl();
end

function Manager.GetPage()
	if(Manager.curInstance) then
		return Manager.curInstance.page;
	end
end

function Manager.Refresh()
	if(Manager.curInstance) then
		Manager.curInstance.page:Refresh(0.01);
	end
end

function Manager.RefreshList()
	if(Manager.curInstance) then
		self = Manager.curInstance;

		BuildQuest:new();
		self.BuildQuestProvider = BuildQuestProvider:new();

		self.page:Refresh(0.01);
	end
end

function Manager:OnClose()
	if(self.page) then
		self.page:CloseWindow();
	end

	Manager.curInstance = nil;
end

function Manager.ClosePage()
	if(Manager.curInstance) then
		Manager.curInstance:OnClose();
	end
end

function Manager.GetTheme_DS(index)
	if(not Manager.curInstance) then
		return;
	end

    local themesDS = Manager.curInstance.BuildQuestProvider:GetThemes_DS();

    if(not index) then
        return #themesDS;
    else
        return themesDS[index];
    end
end

function Manager.GetTask_DS(index)
	if(not Manager.curInstance) then
		return;
	end

    local tasksDS = Manager.curInstance.BuildQuestProvider:GetTasks_DS(BuildQuest.template_theme_index);

    if(not index) then
        return #tasksDS;
    else
        return tasksDS[index];
    end
end

function Manager.GetTaskName()
	if(not Manager.curInstance) then
		return;
	end

    local task = Manager.curInstance.BuildQuestProvider:GetTask(BuildQuest.template_theme_index, BuildQuest.template_task_index);

    if(task) then
        return task.name or "";
    else
        return "";
    end
end

function Manager.GetTaskInfo()
	if(not Manager.curInstance) then
		return;
	end

    local task = Manager.curInstance.BuildQuestProvider:GetTask(BuildQuest.template_theme_index, BuildQuest.template_task_index);

	if(task) then
		return task;
	else
		return {};
	end
end

function Manager.TaskIsLocked(index)
    if(index > BuildQuest.template_task_index) then
        return true;
    else
        return false;
    end
end

function Manager.vip()
	_guihelper.MessageBox(L"VIP功能正在开发中...");
end

function Manager.GetCurThemeIndex()
    return BuildQuest.template_theme_index;
end

function Manager.ChangeTheme(name, mcmlNode)
    local index = mcmlNode:GetAttribute("param1");
    index       = tonumber(index);

	if(index == 3 and not loginMain.IsSignedIn()) then
		loginMain.modalCall = function()
			if(Manager.curInstance) then
				BuildQuest.template_theme_index = 3;
				BuildQuest.template_task_index  = 1;

				Manager.curInstance.BuildQuestProvider = BuildQuestProvider:new({
					cloudLoadFinish = function()
						Manager.Refresh();
					end
				});
			end
		end;

		loginMain.showLoginModalImp();
		return;
	end

	BuildQuest:new({
		template_theme_index = index, 
		template_task_index  = 1,
	});
	
	if(Manager.curInstance) then
		Manager.curInstance.RestEditing();
	end

    Manager.Refresh();
end

function Manager.RestEditing()
	isEditing = false;
end

function Manager.TaskIsSelected(index)
    if(BuildQuest.template_task_index == index) then
        return true;
    else
        return false;
    end
end

function Manager.ChangeTask(name, mcmlNode)
    local index = mcmlNode:GetAttribute("param1");

    BuildQuest.template_task_index = tonumber(index);

	if(Manager.curInstance) then
		Manager.curInstance.RestEditing();
	end

	Manager.Refresh();
end

function Manager.CanEditing()
	local curTheme;
	
	if(true) then
		return true;
	end

	if(Manager.curInstance) then
		curTheme = Manager.GetTheme_DS(BuildQuest.template_theme_index);
	end

    if(curTheme) then
        if(curTheme.official) then
            return false;
        else
            return true;
        end
    end

    return false;
end

function Manager.OnChangeTaskDesc()
    Manager.isEditing = true;
	Manager.Refresh();
end

function Manager.OnSaveTaskDesc()
	if(not Manager.curInstance) then
		return;
	end

    Manager.isEditing = false;

    local desc = string.gsub(Manager.GetPage():GetValue("content", ""), "\r\n","<br />");

    Manager.curInstance.BuildQuestProvider:OnSaveTaskDesc(BuildQuest.template_theme_index, BuildQuest.template_task_index, desc);
    Manager.Refresh();
end

function Manager.screenshot()
	local TaskInfo = Manager.GetTaskInfo();

	if(Manager.curInstance and TaskInfo and TaskInfo.infoCard) then
		
		local templateDir  = TaskInfo.dir;
		local templateSN   = TaskInfo.infoCard.sn; 

		if(not templateDir) then
			return false;
		end

		Manager.curInstance.templateImageUrl = templateDir .. templateSN .. ".jpg";
		return true;
	end

	return false;
end

function Manager.GetQuestTriggerText()
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

function Manager.StartBuild()
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

    Manager.ClosePage();
end

function Manager.DeleteTemplate()
	_guihelper.MessageBox(format(L"确定删除此模板:%s?", ""), function(res)
		if(res and res == _guihelper.DialogResult.Yes) then
			local curTheme  = Manager.curInstance.BuildQuestProvider:GetThemes_DS(BuildQuest.template_theme_index);
			local curTaskDS = Manager.curInstance.BuildQuestProvider:GetTasks_DS(BuildQuest.template_theme_index, BuildQuest.template_task_index);

			if(BuildQuest.template_task_index ~= 1 and BuildQuest.template_task_index == #curTaskDS) then
				BuildQuest.template_task_index = BuildQuest.template_task_index - 1;
			end

			if (curTheme.foldername == "globalTemplate") then
				if(ParaIO.DoesFileExist(curTaskDS.filepath)) then
					ParaIO.DeleteFile(curTaskDS.dir);
					Manager.RefreshList();
				else
					_guihelper.MessageBox(L"删除失败");
				end
			elseif(curTheme.foldername == "worldTemplate") then				
				if(ParaIO.DoesFileExist(curTaskDS.filename)) then
					ParaIO.DeleteFile(curTaskDS.filename);
					Manager.RefreshList();
				else
					_guihelper.MessageBox(L"删除失败");
				end
			elseif(curTheme.foldername == "cloudTemplate") then
				Manager.curInstance.BuildQuestProvider:DeleteCloudTemplate(curTaskDS.sn,function(beSuccess)
					if(beSuccess) then
						Manager.curInstance.BuildQuestProvider = BuildQuestProvider:new({
							cloudLoadFinish = function()
								Manager.Refresh();
							end
						});
					else
						_guihelper.MessageBox(L"删除失败");
					end
				end);
			end
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

function Manager.shareTemplate()
	local curTheme = Manager.curInstance.BuildQuestProvider:GetThemes_DS(BuildQuest.template_theme_index);
	local curTask  = Manager.curInstance.BuildQuestProvider:GetTasks_DS(BuildQuest.template_theme_index, BuildQuest.template_task_index);

	if(curTheme.foldername == "globalTemplate") then
		if(curTask.infoCard) then
			_guihelper.MessageBox(L"此模板已上传至数据源，无法再次上传");
			return;
		end

		echo(curTask, true);
--		if(not TemplateShare.CloudSave("cloud", 1, curTask.name, curTask.desc)) then
--			loginMain.modalCall = function()
--				if(Manager.curInstance) then
--					Manager.BuildQuestProvider = BuildQuestProvider:new({
--						cloudLoadFinish = function()
--							Manager.Refresh();
--							Manager.shareTemplate();
--						end
--					});
--				end
--			end
--
--			loginMain.showLoginModalImp();
--		end
	elseif(curTheme.foldername == "worldTemplate") then
		echo(222);
		echo(curTask, true);
	elseif(curTheme.foldername == "cloudTemplate") then
		echo(333)
	end
end