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

	return;
end

local wide = 120;
local high = 220;
local bsize = 70;
local bpos = { x = (wide - bsize) / 2; y = 125 };
local bwidth = 3;
local bipos = { x = bpos.x + bwidth; y = bpos.y + bwidth }
local bisize = bsize - bwidth * 2;

local on_colour = Color(255, 0, 0);
local off_colour = Color(70, 50, 50);
local bgcolour = Color(20, 20, 20);

local ah = 40;
local aut = 15;
local arr_up = {
	{ x = (wide / 4) + 5, y = aut + ah };
	{ x = wide / 2, y = aut };
	{ x = ((wide / 4) * 3) - 5, y = aut + ah };
}

local adt = 70;
local arr_dn = {
	{ x = ((wide / 4) * 3) - 5, y = adt };
	{ x = wide / 2, y = adt + ah };
	{ x = (wide / 4) + 5, y = adt };
}
function ENT:Draw()
	self:DrawModel();

	local pos = self:GetPos() + (self:GetRight() * -3) + (self:GetUp() * 5.5);
	local ang = self:GetAngles();

	ang:RotateAroundAxis(ang:Right(), 90);
	ang:RotateAroundAxis(ang:Up(),   -90);

	local lift = self:GetController();
	local liftDir = lift:GetMoveDirection();

	cam.Start3D2D(pos, ang, 0.05)
		draw.NoTexture();

		surface.SetDrawColor(bgcolour);
		surface.DrawRect(0, 0, wide, high);

		-- surface.SetTextColor(on_colour);
		-- surface.SetTextPos(wide, bpos.y);
		-- surface.DrawText("ACTIVE: " .. tostring(self:GetActive()));

		-- Button
		local bcol = self:GetActive() and on_colour or off_colour;
		draw.RoundedBox(8, bpos.x, bpos.y, bsize, bsize, bcol);
		draw.RoundedBox(8, bipos.x, bipos.y, bisize, bisize, bgcolour);

		-- Arras
		-- surface.SetTextPos(wide, aut);
		-- surface.DrawText("LIFTDIR: " .. tostring(liftDir) .. " UP: " ..tostring(liftDir == LIFT_MOVE_DIR_UP) .. " UM..." .. tostring(LIFT_MOVE_DIR_UP));
		local aucol = (liftDir == LIFT_MOVE_DIR_UP) and on_colour or off_colour;
		surface.SetDrawColor(aucol);
		surface.DrawPoly(arr_up);

		-- surface.SetTextPos(wide, adt);
		-- surface.DrawText("LIFTDIR: " .. tostring(liftDir) .. " DOWN: " ..tostring(liftDir == LIFT_MOVE_DIR_DOWN));
		local adcol = (liftDir == LIFT_MOVE_DIR_DOWN) and on_colour or off_colour;
		surface.SetDrawColor(adcol);
		surface.DrawPoly(arr_dn);
	cam.End3D2D();
end
