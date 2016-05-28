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

LIFT_MOVE_DIR_UP = 1;
LIFT_MOVE_DIR_DOWN = -1;
LIFT_MOVE_DIR_STATIONARY = 0;

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

---
-- Indicate that the elevator should go somewhere
-- @param floor {number} Which floor to go to. 1 <= x <= numfloors
function ENT:RequestStop(floor)
	if (floor < 1 or floor > self:GetNumFloors()) then
		error("Invalid floor #" .. floor .. " requested!");
	end
	MsgN("Floor #", floor, " has been requested!");
	self:SetDTBool(10 + floor, true);
	self:PokeElevator();
end

---
-- Make the elevator re-evaluate its priorities and move if necessary
function ENT:PokeElevator()
	local nfloor = self:GetCurrentFloor();
	local ye = false;
	for i = 1, self:GetNumFloors() do
		if (i ~= nfloor and self:GetDTBool(10 + i)) then
			ye = true;
			self:SetTargetFloor(i);
			break;
		end
	end
	-- TODO
	-- Ayyy lmao
	if (ye and not self:GetIsWaiting()) then
		self:GetLift():Fire('startforward');
	end
end

---
-- Only called at target floor tbh
-- @TODO This needs to fire for all floors
-- @param {number} num
function ENT:OnArriveAtFloor(num)
	local floor = self:GetStops()[num];
	if (not floor) then
		error("Invalid floor #" .. num .. "!");
	end
	self:SetCurrentFloor(num);
	-- Stop the lift at our target
	local lift = self:GetLift();
	lift:Fire("stop");
	-- Stop more
	self:SetIsWaiting(true);
	self:SetWaitEnd(CurTime() + 10);
	-- Reset the request
	self:SetDTBool(10 + num, false);
	-- Reset the elevator
	self:PokeElevator();
	-- TODO
end

ENT.lastPos = false;
function ENT:Think()
	local lift = self:GetLift();
	if (not IsValid(lift)) then
		return;
	end

	-- Waiting
	if (self:GetIsWaiting() and self:GetWaitEnd() < CurTime()) then
		self:SetIsWaiting(false);
		self:PokeElevator();
	end

	local pos = lift:GetPos();
	local lpos = self.lastPos;
	self.lastPos = pos;

	-- Startup anxiety
	if (not lpos) then
		lpos = pos;
	end

	-- Directional sanity
	if (pos == lpos) then
		self:SetMoveDirection(LIFT_MOVE_DIR_STATIONARY);
		return;
	end
	if (pos.z < lpos.z) then
		self:SetMoveDirection(LIFT_MOVE_DIR_DOWN);
	else
		self:SetMoveDirection(LIFT_MOVE_DIR_UP);
	end
	-- Stoppages
	local tfloor = self:GetTargetFloor();
	if (tfloor < 1) then
		-- Going nowhere
		return;
	end
	-- SuperSpeed
	self:NextThink(CurTime());

	local stops = self:GetStops();
	local stop = stops[tfloor];
	if (not stop) then
		error("Trying to go to " .. tfloor .. " but it doesn't exist!");
		self:SetTargetFloor(0);
		return;
	end
	local spos = stop.Pos;
	if (
		spos == pos or
		-- Detetct moving too fast
		-- Heading up
		(spos.z < pos.z and spos.z > lpos.z) or
		-- Heading down
		(spos.z > pos.z and spos.z < lpos.z)
	) then
		self:OnArriveAtFloor(tfloor);
	end
	return true;
end
