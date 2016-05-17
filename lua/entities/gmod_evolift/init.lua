--[[
	Evocity Lift Control
	Copyright (c) 2016 Lex Robinson
	This code is freely available under the MIT License
--]]
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");

include("shared.lua");

DEFINE_BASECLASS(ENT.Base);

AccessorFunc(ENT, "mt_stops", "Stops");

function ENT:SetStops(stops)
	local numstops = #stops;
	if (numstops > MAX_ELEVATOR_FLOORS) then
		error("Tried to add " .. numstops .. " stops to the lift but it only supports " .. MAX_ELEVATOR_FLOORS .. "!");
	end
	self:SetNumFloors(numstops);
	for i, stop in ipairs(stops) do
		local button = ents.Create("gmod_evolift_button");
		button:SetPos(stop.Pos);
		button:SetAngles(stop.Ang);
		button:SetController(self);
		button:SetFloor(i);
		button:Spawn();
		button:Activate();
		self:DeleteOnRemove(button);
		self:NetworkVarNotify("Floor" .. i .. "Requested", function(_, _, _, value) button:SetActive(value) end);
		stop.Button = button;
		-- TODO
	end
	self.mt_stops = stops;
	-- TODO
end

function ENT:Use(ply)
	print("Hello!");
end

function ENT:RequestStop(floor)
	MsgN("Floor #", floor, " has been requested!");
	-- TODO
end
