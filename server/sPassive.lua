-- Created by DaAlpha
class 'Passive'

function Passive:__init()
	-- Settings
	self.remTime	= 7		-- Days
	self.interval	= 1		-- Hours

	-- Globals
	self.passives	= {}
	self.timer		= Timer()

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
	local steamid = args.player:GetSteamId().string
	local state = self.passives[steamid]
	args.player:SetNetworkValue("Passive", state and true or false)
	self.passives[steamid] = state and os.time() or nil

	local vehicle = args.player:GetVehicle()
	if IsValid(vehicle) and vehicle:GetDriver() == args.player then
		vehicle:SetInvulnerable(state ~= nil)
	end
end

function Passive:PlayerEnterVehicle(args)
	if args.is_driver then args.vehicle:SetInvulnerable(args.player:GetValue("Passive") == true) end
end

function Passive:PostTick()
	if self.timer:GetHours() > self.interval then
		local threshold = os.time() - self.remTime * 86400
		for steamid, timestamp in pairs(self.passives) do
			if timestamp < threshold then
				self.passives[steamid] = nil
			end
		end
		self:ModuleUnload()
		self.timer:Restart()
	end
end

function Passive:ModuleUnload()
	local trans = SQL:Transaction()
	SQL:Execute("DELETE FROM passive")
	for steamid, _ in pairs(self.passives) do
		local command = SQL:Command("INSERT INTO passive VALUES (?)")
		command:Bind(1, steamid)
		command:Execute()
	end
	trans:Commit()
end

local passive = Passive()
