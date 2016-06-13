--[[
	Evocity Lift Control
	Copyright (c) 2016 Lex Robinson
	This code is freely available under the MIT License
--]]
include("shared.lua");

DEFINE_BASECLASS(ENT.Base);

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT;

ENT.Floors = false;

function ENT:Think()
	if (not self.Floors) then
		local fnames = self:GetFloorNames();
		if (fnames) then
			self.Floors = util.JSONToTable(fnames);
		end
	end
end

local on_colour = Color(255, 0, 0);
local off_colour = Color(70, 50, 50);
local bgcolour = Color(200, 200, 200);

local txtbgcolour = Color(125, 125, 125);
local txtcolour = color_black;--Color(50, 50, 50);

local wide = 400;
local high = 470;

local margins = 40;

local bsize = 70;
local bwidth = 3;
local bisize = bsize - bwidth * 2;


local function button(y, colour)
	draw.RoundedBox(8, margins, y, bsize, bsize, colour);
	draw.RoundedBox(8, margins + bwidth, y + bwidth, bisize, bisize, bgcolour)
end

local function text(y, words)
	surface.SetDrawColor(txtbgcolour);
	local x = margins + bsize + margins;
	local tx = x + 20;
	local ty = y + 10;
	surface.DrawRect(x, y, wide - margins - x, bsize);
	surface.SetTextPos(tx, ty);
	surface.DrawText(words);
end

local fontName = "ElevatorButtons"
surface.CreateFont(fontName, {
	font = "Roboto Lt";
	size = 48;
	weight = 300;
});

function ENT:Draw()
	-- self:DrawModel();
	local fnames = self.Floors;
	if (not fnames) then
		return;
	end

	local nfloors = #fnames;
	local high = (nfloors * bsize) + (margins * (nfloors + 1));

	local pos = self:GetPos() +
		(self:GetForward() * 10) +
		(self:GetRight()   * 24) +
		(self:GetUp()      * -1.59);
	local ang = self:GetAngles();


	-- ang:RotateAroundAxis(ang:Right(), -90);
	ang:RotateAroundAxis(ang:Up(),      180);
	ang:RotateAroundAxis(ang:Forward(), 180);

	cam.Start3D2D(pos, ang, 0.05)
		draw.NoTexture();
		surface.SetDrawColor(bgcolour);
		surface.DrawRect(0, 0, wide, -high);

		surface.SetFont(fontName);
		surface.SetTextColor(txtcolour);

		for i, name in ipairs(fnames) do
			local j = -i;
			local p = margins * j + bsize * j
			local c = off_colour;
			if (self:IsFloorRequested(i)) then
				c = on_colour;
			end
			button(p, c);
			text(p, name);
		end

	cam.End3D2D();
end
