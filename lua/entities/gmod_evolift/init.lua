--[[
	Evocity Lift Control
	Copyright (c) 2016 Lex Robinson
	This code is freely available under the MIT License
--]]
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");

include("shared.lua");

DEFINE_BASECLASS(ENT.Base);

function ENT:SetStops(stops)
	for _, stop in pairs(stops) do
		local button = ents.Create("gmod_evolift_button");
		button:SetPos(stop.Pos);
		button:SetAngles(stop.Ang);
		button:SetController(self);
		button:Spawn();
		button:Activate();
		-- TODO
	end
	-- TODO
end

function ENT:Use(ply)
	print("Hello!");
end
