--[[
Title: ThemeClass
Author(s):  BIG
Date: 2017.8
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ModelShare/ThemeClass.lua");
local ThemeClass = commonlib.gettable("Mod.ModelShare.ThemeClass");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/ModelShare/TaskClass.lua");

local TaskClass = commonlib.gettable("Mod.ModelShare.TaskClass");

local ThemeClass = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.ThemeClass"));

function ThemeClass:ctor()
	self.tasks   = self.tasks   or {};
	self.tasksDS = self.tasksDS or {};
end

-- load from xml node
function ThemeClass:Init(xml_node, theme_index, themeKey)
	self.id = theme_index;

	local tasks   = self.tasks;
	local tasksDS = self.tasksDS;

	for node in commonlib.XPath.eachNode(xml_node, "/Task") do
		tasksDS[#tasksDS+1] = {};

		commonlib.partialcopy(tasksDS[#tasksDS],node.attr);

		local task_index  = #tasks + 1;
		tasks[task_index] = TaskClass:new(node.attr):Init(node, self, task_index, themeKey);
	end

	return self;
end

function ThemeClass:GetTask(task_id)
	return self.tasks[task_id or 1];
end