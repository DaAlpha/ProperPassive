-- Created by DaAlpha
class 'Passive'

function Passive:__init()
	SQL:Execute("CREATE TABLE IF NOT EXISTS passive (steamid VARCHAR PRIMARY KEY)")

	Network:Subscribe("Toggle", self. self.Toggle)

	Events:Subscribe("PlayerChat", self, self.PlayerChat)
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
	local result = query:Execute()

	if result[1] then
		args.player:SetNetworkValue("Passive", true)
	end
end

function Passive:PlayerEnterVehicle(args)
	if args.player:GetValue("Passive") and args.is_driver then
		args.vehicle:SetInvulnerable(true)
	end
end

function Passive:PlayerExitVehicle(args)
	if args.vehicle:GetInvulnerable() and not args.vehicle:GetDriver() then
		args.vehicle:SetInvulnerable(false)
	end
end

local passive = Passive()
