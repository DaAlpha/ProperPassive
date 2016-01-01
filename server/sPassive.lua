-- Created by DaAlpha
class 'Passive'

function Passive:__init()
	-- Create DB table
	SQL:Execute("CREATE TABLE IF NOT EXISTS passive (steamid VARCHAR PRIMARY KEY)")

	-- Network
	Network:Subscribe("Toggle", self, self.Toggle)

	-- Events
	Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
	Events:Subscribe("PlayerEnterVehicle", self, self.PlayerEnterVehicle)
	Events:Subscribe("PlayerExitVehicle", self, self.PlayerExitVehicle)
end

function Passive:Toggle(state, sender)
	player:SetNetworkValue("Passive", state or nil)

	local vehicle = sender:GetVehicle()
	if IsValid(vehicle) and vehicle:GetDriver() == sender then
		vehicle:SetInvulnerable(state)
	end

	Chat:Send(player, "Passive mode " .. (state and "enabled." or "disabled."),
		state and Color.Lime or Color.Red)

	local command = SQL:Command(state
						and "INSERT OR REPLACE INTO passive VALUES (?)"
						or "DELETE FROM passive WHERE steamid = ?"
						)
	command:Bind(1, sender:GetSteamId().string)
	command:Execute()
end

function Passive:ClientModuleLoad(args)
	local query = SQL:Query("SELECT * FROM passive WHERE steamid = ?")
	query:Bind(1, args.player:GetSteamId().string)
	args.player:SetNetworkValue("Passive", query:Execute()[1] and true or nil)
end

function Passive:PlayerEnterVehicle(args)
	args.vehicle:SetInvulnerable(args.is_driver and args.player:GetValue("Passive"))
end

function Passive:PlayerExitVehicle(args)
	args.vehicle:SetInvulnerable(false)
end

local passive = Passive()
