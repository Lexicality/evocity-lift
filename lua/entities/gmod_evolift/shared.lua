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
	self:SetModel("models/hunter/plates/plate05x1.mdl");
	self:SetSolid(SOLID_VPHYSICS);
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

---
-- Figures out if the player is looking at a button
-- This function makes me sad with the amount of magic it has
-- @param {Player} ply
-- @return {(bool|number)} The floor # they're aiming at or false if not
function ENT:GetFloorButtonBeingLookedAt(ply)
	local tr = ply:GetEyeTrace();
	if (tr.Entity ~= self) then
		return false;
	end

	local pos = self:WorldToLocal(tr.HitPos);
	-- magic
	local x = pos.x * -20 + 200;
	local y = pos.y * 20 + 480;

	-- :( more magic
	local margins = 40;
	local bsize = 70;

	if (x < margins or x > margins + bsize or y < margins) then
		return false;
	end

	local fnum = self:GetNumFloors();

	-- There's a lot of magic here
	for i = 1, fnum do
		local p1 = margins * i + bsize * (i - 1);
		local p2 = margins * i + bsize * i;
		if (y > p1 and y < p2) then
			return i;
		end
	end

	return false;
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
