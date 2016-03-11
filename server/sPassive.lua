-- Created by DaAlpha
class 'Passive'

function Passive:__init()
	-- Globals
	self.passives	= {}
	self.timer		= Timer()
	self.interval	= 1		-- Hours
	self.remTime	= 14	-- Days

	-- Create DB table if it does not exist
	SQL:Execute("CREATE TABLE IF NOT EXISTS passive (steamid VARCHAR PRIMARY KEY)")

	-- Load SQL entries to the cache initialls
	local timestamp = os.time()
	for _, entry in ipairs(SQL:Query("SELECT * FROM passive"):Execute()) do
		self.passives[entry.steamid] = timestamp
	end

	-- Network
	Network:Subscribe("Toggle", self, self.Toggle)

	-- Events
	Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
	Events:Subscribe("PlayerEnterVehicle", self, self.PlayerEnterVehicle)
	Events:Subscribe("PostTick", self, self.PostTick)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

function Passive:Toggle(state, sender)
	sender:SetNetworkValue("Passive", state or nil)

	local vehicle = sender:GetVehicle()
	if IsValid(vehicle) and vehicle:GetDriver() == sender then
		vehicle:SetInvulnerable(state)
	end

	Chat:Send(sender, "Passive mode " .. (state and "enabled." or "disabled."), Color.Lime)

	self.passives[sender:GetSteamId().string] = state and os.time() or nil
end

function Passive:ClientModuleLoad(args)
	args.player:SetNetworkValue("Passive", self.passives[args.player:GetSteamId().string] and true or nil)
end

function Passive:PlayerEnterVehicle(args)
	args.vehicle:SetInvulnerable(args.is_driver and args.player:GetValue("Passive") == true)
end

function Passive:PostTick()
	if self.timer:GetHours() > self.interval then
		local threshold = os.time() - self.remTime * 86400
		for steamid, timestamp in pairs(self.passives) do
			if timestamp < threshold then
				self.passives[steamid] = nil
			end
		end
		self.timer:Restart()
	end
end

function Passive:ModuleUnload()
	SQL:Execute("DELETE FROM passive")

	local trans = SQL:Transaction()
	for steamid, _ in pairs(self.passives) do
		local command = SQL:Command("INSERT INTO passive VALUES (?)")
		command:Bind(1, steamid)
		command:Execute()
	end
	trans:Commit()
end

local passive = Passive()
