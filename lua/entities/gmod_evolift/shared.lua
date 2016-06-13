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


LIFT_MOVE_DIR_UP = 1;
LIFT_MOVE_DIR_DOWN = -1;
LIFT_MOVE_DIR_STATIONARY = 0;

function ENT:Initialize()
	self:SetModel("models/props_junk/garbage_carboard002a.mdl");
	self:SetSolid(SOLID_OBB);
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS);
	self:SetMoveType(MOVETYPE_NONE);
	self:DrawShadow(false);
	if (SERVER) then
		self:SetUseType(SIMPLE_USE);
	end
end

function ENT:IsWaiting()
	return self:GetIsWaiting()
end

---
-- Checks if a particular floor has been requested
-- @param {number} floor
-- @return {bool}
function ENT:IsFloorRequested(floor)
	return self:GetDTBool(10 + floor);
end

MAX_ELEVATOR_FLOORS = 5;

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Lift");
	self:NetworkVar("Int", 0, "NumFloors");
	self:NetworkVar("Int", 1, "MoveDirection");
	self:NetworkVar("Int", 2, "TargetFloor");
	self:NetworkVar("Int", 3, "CurrentFloor");
	self:NetworkVar("Float", 0, "WaitEnd");
	self:NetworkVar("Bool", 0, "IsWaiting");
	self:NetworkVar("String", 0, "FloorNames");

	-- Set up a decent number of floors for the save system
	for i = 1, MAX_ELEVATOR_FLOORS do
		self:NetworkVar("Bool", 10 + i, "Floor" .. i .. "Requested");
	end

	-- TODO

	if (SERVER) then
		self:NetworkVarNotify("Lift", function(self, _, _, lift) self:SetParent(lift) end);
	end
end
