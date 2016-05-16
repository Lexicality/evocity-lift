--[[
	Evocity Lift Control
	Copyright (c) 2016 Lex Robinson
	This code is freely available under the MIT License
--]]
DEFINE_BASECLASS "base_gmodentity";

ENT.Type      = "anim"
ENT.PrintName = "Evocity Lift Controller";
ENT.Author    = "Lexi";
ENT.Contact   = "lexi@lexi.org.uk";

ENT.Spawnable      = false;
ENT.AdminSpawnable = false;

ENT.PhysgunDisabled = true;
ENT.m_tblToolsAllowed = {};

function ENT:Initialize()
	self:SetModel("models/props_junk/garbage_carboard002a.mdl");
	self:SetSolid(SOLID_OBB);
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS);
	self:SetMoveType(MOVETYPE_NONE);
	if (SERVER) then
		self:SetUseType(SIMPLE_USE);
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Lift");
	-- TODO

	if (SERVER) then
		self:NetworkVarNotify("Lift", function(self, _, _, lift) self:SetParent(lift) end);
	end
end
