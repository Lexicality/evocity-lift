--[[
	Evocity Lift Control
	Copyright (c) 2016 Lex Robinson
	This code is freely available under the MIT License
--]]
AddCSLuaFile();

DEFINE_BASECLASS "base_gmodentity";

ENT.Type      = "anim"
ENT.PrintName = "Evocity Lift Button";
ENT.Author    = "Lexi";
ENT.Contact   = "lexi@lexi.org.uk";

ENT.Spawnable      = false;
ENT.AdminSpawnable = false;

ENT.PhysgunDisabled = true;
ENT.m_tblToolsAllowed = {};

function ENT:Initialize()
	self:SetModel("models/props_lab/keypad.mdl");
	self:SetSolid(SOLID_OBB);
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS);
	self:SetMoveType(MOVETYPE_NONE);
	if (SERVER) then
		self:SetUseType(SIMPLE_USE);
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Controller");
	self:NetworkVar("Int", 0, "Floor");
	self:NetworkVar("Bool", 0, "Active");
end

if (SERVER) then
	function ENT:Use(ply)
		if (self:GetActive()) then
			return;
		end
		local c = self:GetController();
		if (not IsValid(c)) then
			ErrorNoHalt("Button without a valid controller!");
			return;
		end
		c:RequestStop(self:GetFloor());
	end
end
