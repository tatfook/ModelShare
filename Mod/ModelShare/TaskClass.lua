--[[
Title: TaskClass
Author(s):  BIG
Date: 2017.8
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/ModelShare/TaskClass.lua");
local TaskClass = commonlib.gettable("Mod.ModelShare.TaskClass");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/ModelShare/StepClass.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");

local StepClass   = commonlib.gettable("Mod.ModelShare.StepClass");
local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");

local TaskClass = commonlib.inherit(nil, commonlib.gettable("Mod.ModelShare.TaskClass"));

local tasks   = {};
local next_id = 1;

function TaskClass:ctor()
	self.steps = self.steps or {};
end

function TaskClass:AddID()
	if(self.id) then
		tasks[tostring(self.id)] = self;
		next_id = math.max(tonumber(self.id) or 0, next_id + 1);
	else
		tasks[tostring(next_id)] = self;
		next_id = next_id + 1;
	end
end

function TaskClass:Init(xml_node, theme, task_index, category)
	self.UseAbsolutePos    = if_else(self.UseAbsolutePos == "true" or self.beAbsolutePos == "true",true,false);
	self.click_once_deploy = self.click_once_deploy == "true";

	self:AddID();

	self.task_index = task_index;
	self.category   =  category;

	--if(themeKey == "blockwiki") then
		--local task_name = string.match(self.name,"%d*_(.*)");
		--self.name = task_name;
	--end
	
	local steps = self.steps;

	local default_src, default_name, default_dir;

	for node in commonlib.XPath.eachNode(xml_node, "/Step") do
		--if(category == "blockwiki") then
			--local src = string.format("%s%s.blocks.xml",commonlib.Encoding.DefaultToUtf8(self.dir),self.name);
			--node.attr.src = src;
		--end
		steps[#steps+1] = StepClass:new(node.attr):Init(node, self);
	end

	self.theme = theme;
	return self;
end

-- @param step_id: if nil the current step is returned.
function TaskClass:GetStep(step_id)
	return self.steps[step_id or self.current_step or 1];
end

-- whether using absolute position. 
function TaskClass:IsUseAbsolutePos()
	return self.UseAbsolutePos;
end

function TaskClass:IsClickOnceDeploy()
	return self.click_once_deploy;
end

-- just create everything using the template. 
function TaskClass:ClickOnceDeploy(bUseAbsolutePos)
	bUseAbsolutePos = bUseAbsolutePos or self:IsUseAbsolutePos()
	for _, step in pairs(self.steps) do
		step:ClickOnceDeploy(bUseAbsolutePos);
	end
	local profile = UserProfile.GetUser();
	profile:FinishBuilding(self:GetThemeID(), self:GetIndex(),self.category or "template");
end

-- reset task
function TaskClass:Reset()
	for _, step in pairs(self.steps) do
		step:Reset();
	end
end

-- get description
function TaskClass:GetDesc()
	return self.desc;
end

-- get theam id
function TaskClass:GetThemeID()
	if(self.theme) then
		return self.theme.id or 1;
	else
		return 1;
	end
end

-- get shadow blocks on ground in x,z plane 
function TaskClass:GetProjectionBlocks()
	if(not self.proj_blocks ) then
		local blocks = {};
		self.proj_blocks = blocks;
		for _, step in pairs(self.steps) do
			for i, block in ipairs(step:GetBom():GetBlocks()) do
				local block_index = GetBlockIndex(block[1], 0, block[3]);
				local last_block = blocks[block_index];
				if(not last_block or last_block[2]>block[2]) then
					-- always store the lowest y. 
					blocks[block_index] = block;
				end
			end
		end
	end
	return self.proj_blocks;
end

-- get all blocks in cube 
function TaskClass:GetProjectionAllBlocksWithAbsolutePos()
	if(not self.all_proj_blocks ) then
		local blocks = {};
		self.all_proj_blocks = blocks;
		for _, step in pairs(self.steps) do
			for i, block in ipairs(step:GetBom():GetBlocks_AbsolutePos()) do
				local block_index = GetBlockIndex(block[1], block[2], block[3]);
				if(not blocks[block_index]) then
					blocks[block_index] = block;
				end
			end
		end
	end
	return self.all_proj_blocks;
end

-- reset projection scene when use absolute position
function TaskClass:ResetProjectionScene()
	local blocks = self:GetProjectionAllBlocksWithAbsolutePos();
	for k,v in pairs(blocks) do
		local block = v;
		local x,y,z = block[1],block[2],block[3];
		BlockEngine:SetBlockToAir(x,y,z);
	end
	for _, step in pairs(self.steps) do
		local bom = step:GetBom();
		bom.palyerGotoOriginPos = nil;
	end
end

function TaskClass:GetIndex()
	return self.task_index;
end

-- get all block types in this task
function TaskClass:GetBlockTypes()
	local function insertblock_type(blocks,block_type,min_index,max_index)
		--local min_index = 1;
		local min_block_type = blocks[min_index];
		--local max_index = #blocks;
		local max_block_type = blocks[max_index];
		if(max_index - min_index == 1) then
			table.insert(blocks,min_index,block_type);
		else
			local new_index = math.floor(max_index/2);
			local new_block_type = blocks[new_index];
			if(block_type < new_block_type) then
				insertblock_type(blocks,block_type,min_index,new_index);
			else
				insertblock_type(blocks,block_type,new_index,max_index);
			end
		end
	end

	if(not self.block_types ) then
		local appear_blocks = {};
		local blocks = {};
		self.block_types = blocks;

		for _, step in pairs(self.steps) do
			for i, block in ipairs(step:GetBom():GetBlocks()) do
				local block_type = tonumber(block[4]);
				if(not appear_blocks[block_type]) then
					appear_blocks[block_type] = true;
					table.insert(blocks,{block_id = block_type});
				end
				--if(not next(blocks)) then
					--table.insert(blocks,block_type);
				--else
					--local min_index = 1;
					--local min_block_type = blocks[1];
					--local max_index = #blocks;
					--local max_block_type = blocks[#blocks];
					--if(min_index == max_index) then
						--if(block_type < max_block_type) then
							--table.insert(blocks,max_index,block_type);
						--else
							--table.insert(blocks,(max_index + 1),block_type);
						--end
					--else
						--insertblock_type(blocks,block_type,min_index,max_index);
					--end
				--end
				--local block_index = GetBlockIndex(block[1], 0, block[3]);
				--local last_block = blocks[block_index];
				--if(not last_block or last_block[2]>block[2]) then
					---- always store the lowest y. 
					--blocks[block_index] = block;
				--end
			end
		end
	end
	return self.block_types;
end