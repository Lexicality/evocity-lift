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
	local fnames = {};
	for i, stop in ipairs(stops) do
		fnames[i] = stop.Name;
		local button = ents.Create("gmod_evolift_button");
		button:SetPos(stop.Pos);
		button:SetAngles(stop.Ang);
		button:SetController(self);
		button:SetFloor(i);
		button:Spawn();
		button:Activate();
		self:DeleteOnRemove(button);
		local NWName = "Floor" .. i .. "Requested"
		self:NetworkVarNotify(NWName, function(_, _, _, value)
			button:SetActive(value)
		end);
		stop.Button = button;
		stop.NWName = NWName;
		stop.SetFunc = function(value) self["Set" .. NWName](self, value) end;
		-- TODO
	end
	self.mt_stops = stops;
	self:SetFloorNames(util.TableToJSON(fnames));
	-- TODO
end

function ENT:Use(ply)
	print("Hello", ply);
	if (not (IsValid(ply) and ply:IsPlayer())) then
		return;
	end
	local floor = self:GetFloorButtonBeingLookedAt(ply);
	print("Floor requested: ", floor);
	if (floor) then
		self:RequestStop(floor);
	end
end

---
-- @param {number} floor
-- @return {table} stop
function ENT:GetStop(floor)
	local stops = self:GetStops();
	local stop = stops[floor];
	if (not stop) then
		error("Invalid floor #" .. floor .. "!");
	end
	return stop;
end

---
-- Indicate that the elevator should go somewhere
-- @param floor {number} Which floor to go to. 1 <= x <= numfloors
function ENT:RequestStop(floor)
	local stop = self:GetStop(floor);
	MsgN();
	MsgN("Floor #", floor, " has been requested!");
	MsgN();
	if (self:IsFloorRequested(floor)) then
		MsgN(" Ignoring since it's already requested");
		return;
	elseif (self:GetMoveDirection() == LIFT_MOVE_DIR_STATIONARY and self:GetCurrentFloor() == floor) then
		MsgN(" Ignoring since we're already on that floor!");
		return;
	end
	stop.SetFunc(true);
	self:PokeElevator();
end

function ENT:SearchUp()
	local cfloor = self:GetCurrentFloor();
	MsgN("  ", "Searching up from floor #", cfloor);
	for i = cfloor + 1, self:GetNumFloors() do
		Msg("   ", "#", i, ": ");
		if (self:IsFloorRequested(i)) then
			MsgN("Requested!");
			return i;
		else
			MsgN("nope");
		end
	end
	return nil;
end

function ENT:SearchDown()
	local cfloor = self:GetCurrentFloor();
	MsgN("  ", "Searching down from floor #", cfloor);
	for i = cfloor - 1, 1, -1 do
		Msg("   ", "#", i, ": ");
		if (self:IsFloorRequested(i)) then
			MsgN("Requested!");
			return i;
		else
			MsgN("nope");
		end
	end
	return nil;
end

---
-- Make the elevator re-evaluate its priorities and move if necessary
function ENT:PokeElevator()
	MsgN("Elevator poke!");
	if (self:GetIsWaiting()) then
		MsgN(" Doing nothing since we're waiting");
		return;
	end

	local target;
	if (self:GetMoveDirection() == LIFT_MOVE_DIR_DOWN) then
		target = self:SearchDown() or self:SearchUp();
	else
		target = self:SearchUp() or self:SearchDown();
	end


	if (not target) then
		MsgN(" No target!");
		return;
	end
	self:SetTargetFloor(target);

	local cfloor = self:GetCurrentFloor();
	local lift = self:GetLift();

	MsgN(" Heading to floor #", target, " from floor #", cfloor);
	if (target > cfloor) then
		lift:Fire('setspeeddir', LIFT_MOVE_DIR_UP);
	else
		lift:Fire('setspeeddir', LIFT_MOVE_DIR_DOWN);
	end
end

---
-- Halts the elevator and clears any state
-- @param {number} floor
function ENT:StopAtFloor(floor)
	MsgN(" Stopping at floor #", floor, "!");
	local stop = self:GetStop(floor);
	-- Stop the lift at our target
	local lift = self:GetLift();
	lift:Fire("stop");
	-- Hang around so people can get on/off
	self:SetIsWaiting(true);
	self:SetWaitEnd(CurTime() + 10);
	-- Reset the request
	stop.SetFunc(false);
	self:SetTargetFloor(0);
end

---
-- Called every time an elevator passes a floor
-- @TODO This needs to fire for all floors
-- @param {number} floor
function ENT:OnArriveAtFloor(floor)
	MsgN("Lift passed floor #", floor);
	self:SetCurrentFloor(floor);
	if (floor == self:GetTargetFloor()) then
		self:StopAtFloor(floor);
	end
end

ENT.lastPos = false;
function ENT:Think()
	local lift = self:GetLift();
	if (not IsValid(lift)) then
		return;
	end

	-- Waiting
	if (self:GetIsWaiting() and self:GetWaitEnd() < CurTime()) then
		MsgN("Wait timeout!");
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
	for floor, stop in pairs(stops) do
		local spos = stop.Pos;
		if (
			spos == pos or
			-- Detetct moving too fast
			-- Heading up
			(spos.z < pos.z and spos.z > lpos.z) or
			-- Heading down
			(spos.z > pos.z and spos.z < lpos.z)
		) then
			self:OnArriveAtFloor(floor);
			break;
		end
	end
end
