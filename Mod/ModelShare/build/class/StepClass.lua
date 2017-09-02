--[[
Title: StepClass
Author(s):  BIG
Date: 2017.8
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ModelShare/StepClass.lua");
local StepClass = commonlib.gettable("Mod.ModelShare.StepClass");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");

local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local StepClass = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.StepClass"));

function StepClass:ctor()
	self.tips = self.tips or {};
end

function StepClass:Init(xml_node, parent)
	local tips = self.tips;
	self.parent = parent;
	-- whether auto delete block
	self.auto_delete = xml_node.attr.auto_delete ~= "false";
	self.auto_create = xml_node.attr.auto_create == "true";
	self.invert_create = xml_node.attr.invert_create == "true";
	if(xml_node.attr.auto_sort_blocks) then
		self.auto_sort_blocks = xml_node.attr.auto_sort_blocks == "true";
	end
	if(self.invert_create) then
		self.auto_delete = false;
	end

	self.player_offset_x = tonumber(xml_node.attr.player_offset_x);
	self.player_offset_y = tonumber(xml_node.attr.player_offset_y);
	self.player_offset_z = tonumber(xml_node.attr.player_offset_z);

	self.offset_x = tonumber(xml_node.attr.offset_x);
	self.offset_y = tonumber(xml_node.attr.offset_y);
	self.offset_z = tonumber(xml_node.attr.offset_z);

	if(type(xml_node.attr.auto_prebuild_blocks) == "string") then
		local auto_prebuild_blocks = {};
		for id in string.gmatch(xml_node.attr.auto_prebuild_blocks, "%d+") do
			auto_prebuild_blocks[tonumber(id)] = true;
		end
		self.auto_prebuild_blocks = auto_prebuild_blocks;
		if(self.auto_sort_blocks == nil) then
			self.auto_sort_blocks = true;
		end
	end

	local last_to = 0;
	for node in commonlib.XPath.eachNode(xml_node, "/tip") do
		tips[#tips+1] = node;
		local from, to = node.attr.block:match("^(%d+)%-(%d+)$");
		if(to) then
			to = tonumber(to);
			from = tonumber(from);
		else
			from = node.attr.block:match("^(%d+)$");
			if(from) then
				from = tonumber(from);
			end
		end
		from = math.max(from or 0, last_to);
		to = math.max(from, to or 0);
		node.attr.block_from = from;
		node.attr.block_to = to;
		last_to = to + 1;
	end
	return self;
end

function StepClass:IsAutoPrebuildBlock(block_id)
	if(self.auto_prebuild_blocks) then
		return self.auto_prebuild_blocks[block_id];
	end
end

function StepClass:Reset()
	self.is_accelerating = nil;
	if(self.template) then
		self.template:Reset();
	end
end

-- @param nCount: if nil, we will be accelerating to the end. otherwise it will only accelerate up to the block count specified. 
function StepClass:SetAccelerating(nCount)
	self.is_accelerating = true;
	self.acceleration_count = nCount;
end

-- whether to auto delete blocks.
function StepClass:isAutoDelete()
	return self.auto_delete;
end

-- get bom offset. only used internally when loading bom from file. 
function StepClass:GetOffset()
	return self.offset_x, self.offset_y, self.offset_z;
end

-- get offset relative to 0,0,0 of the bom. nil maybe returned for any of the component. 
function StepClass:GetPlayerOffset()
	return self.player_offset_x,self.player_offset_y, self.player_offset_z;
end

-- whether to auto create blocks.
-- @param bAutoDecreaseCount: if true, it will decrease acceleration_count if any. 
function StepClass:isAutoCreate(bAutoDecreaseCount)
	if(self.auto_create) then
		return true;
	elseif(self.is_accelerating) then
		if(bAutoDecreaseCount and self.acceleration_count) then
			self.acceleration_count = self.acceleration_count - 1;
			if(self.acceleration_count <= 0) then
				self.is_accelerating = nil;
				self.acceleration_count = nil;
			end
		end
		return true;
	end
end

-- whether to invert create.
function StepClass:isInvertCreate()
	return self.invert_create;
end

function StepClass:GetBom()
	if(not self.template) then
		self.template = bom_class:new():Init(self:GetTemplateFilename(), self);
	end
	return self.template;
end

-- get disk file regardless of file encoding. 
-- just in case default encoding differs when deploying task files to a foreign operating system (Utf8ToDefault failed), 
-- we will guest it according to parent task filename
function StepClass:GetTemplateFilename()
	if(not self.src_disk and self.parent) then
		local task = self.parent;
		local default_src  = commonlib.Encoding.Utf8ToDefault(self.src);
		local default_name = commonlib.Encoding.Utf8ToDefault(task.name);
		local default_dir  = task.dir;
		if(not ParaIO.DoesFileExist(default_src, false)) then
			default_src = string.format("%s%s",default_dir,default_src);
			if(not ParaIO.DoesFileExist(default_src, false)) then
				default_src = task.filepath:gsub("%.xml$", ".blocks.xml");
				LOG.std(nil, "info", "task_class", "try fixing filename encoding for %s", default_src);
			end
		end
		self.src_disk = default_src;
	end
	return self.src_disk;
end
	
function StepClass:ClickOnceDeploy(bUseAbsolutePos)
	local TeleportPlayer;
	local bx, by, bz;
	if(bUseAbsolutePos) then
		TeleportPlayer = true;
	else
		local x, y, z = ParaScene.GetPlayer():GetPosition();
		bx, by, bz = BlockEngine:block(x, y+0.1, z);
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Load, filename = self:GetTemplateFilename(),
		blockX=bx,blockY=by, blockZ=bz, bSelect=false,TeleportPlayer=TeleportPlayer, UseAbsolutePos=bUseAbsolutePos,
		})
	task:Run();
end

-- get tip inner text
function StepClass:GetTipText(i)
	i = i or 0;
	for k= 1, #(self.tips) do
		local tip = self.tips[k];
		if(tip.attr.block_from<=i and i<=tip.attr.block_to) then
			return tip[1];
		end
	end
end