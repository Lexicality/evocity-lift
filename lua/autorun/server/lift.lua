local function loadMapData()
	local map = game.GetMap():lower();
	if (map ~= "rp_evocity_v2d") then
		MsgN("Elevatr doesn't know ", map, "!");
		return
	end

	return {
		SearchArea = { Vector(-7000, -9000, 2800), Vector(-7300, -9500, 60) };
		Stops = {
			{
				Pos = Vector(-7114, -9381,  134.0679);
				Ang = Angle(   0,  -90,    0);
			};
			{
				Pos = Vector(-7114, -9381,  902.4282);
				Ang = Angle(   0,  -90,    0);
			};
			{
				Pos = Vector(-7120, -9401, 1543.0226);
				Ang = Angle(   0,  180,    0);
			};
			{
				Pos = Vector(-7122.4150, -9401, 2680.1448);
				Ang = Angle(   0,  180,    0);
			};
		};
		Control = {
			Pos = Vector(81, -2.492188, -3.482422);
			Ang = Angle(90, 0, 180);
		};
	};
end

local function fuckWithTrackPoints(points)
	local top = -math.huge;
	local bottom = math.huge;
	local topEnt, bottomEnt;

	for _, ent in pairs(points) do
		local pos = ent:GetPos();
		if (pos.z > top) then
			topEnt = ent;
			top = pos.z;
		end
		if (pos.z < bottom) then
			bottomEnt = ent;
			bottom = pos.z;
		end
	end

	-- Cut out all the other stops
	topEnt:SetKeyValue("target", bottomEnt:GetName());
	bottomEnt:SetKeyValue("target", topEnt:GetName());
	-- Make them re-evaluate
	topEnt:Activate();
	bottomEnt:Activate();
end

-- Funny names make the code better
function DoYouEvenLiftBro()
	local mapdata = loadMapData();
	if (not mapdata) then
		return;
	end

	local points = {};
	local lift;
	for _, ent in pairs(ents.FindInBox(unpack(mapdata.SearchArea))) do
		local class = ent:GetClass();
		if (class == "path_track") then
			table.insert(points, ent);
		elseif (class == "func_tracktrain") then
			lift = ent;
		elseif (class == "func_button") then
			-- What could possibly go wrong
			-- TODO: Some way to get the outputs?
			ent:Remove();
		end
	end

	if (not IsValid(lift)) then
		error("Could not find lift!");
	elseif (#points < 3) then
		error("" .. #points .. " is not enough Vpoints!");
	end

	fuckWithTrackPoints(points);

	local controller = ents.Create("gmod_evolift");
	controller:SetPos(lift:LocalToWorld(mapdata.Control.Pos));
	controller:SetAngles(mapdata.Control.Ang);
	controller:SetLift(lift);
	controller:SetStops(mapdata.Stops);
	controller:Spawn();
	controller:Activate();
end
hook.Add("InitPostEntity", "Lift Spawner", DoYouEvenLiftBro);
hook.Add("PostCleanupMap", "Lift Spawner", DoYouEvenLiftBro);
