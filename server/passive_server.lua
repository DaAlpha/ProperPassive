-- Created by DaAlpha
class 'Passive'

function Passive:__init()
	SQL:Execute("CREATE TABLE IF NOT EXISTS Passive (steamid INTEGER(20) UNIQUE)")

	Events:Subscribe("PlayerChat", self, self.PlayerChat)
	Events:Subscribe("PlayerJoin", self, self.PlayerJoin)
	Events:Subscribe("PlayerEnterVehicle", self, self.PlayerEnterVehicle)
	Events:Subscribe("PlayerExitVehicle", self, self.PlayerExitVehicle)
end

function Passive:PlayerChat(args)
	if args.text == "/passive" then
		local player = args.player
		local passive = player:GetValue("Passive")
		local steamid = player:GetSteamId().id
		local command

		if passive then
			player:SetNetworkValue("Passive", nil)
			if player:InVehicle() and player == player:GetVehicle():GetDriver() then
				player:GetVehicle():SetInvulnerable(false)
			end
			Chat:Send(player, "Passive mode disabled.", Color.Yellow)

			command = SQL:Command("DELETE FROM Passive WHERE steamid = ?")
		else
			player:SetNetworkValue("Passive", true)
			if player:InVehicle() and player == player:GetVehicle():GetDriver() then
				player:GetVehicle():SetInvulnerable(true)
			end

			command = SQL:Command("INSERT OR ABORT INTO Passive (steamid) VALUES (?)")

			Chat:Send(player, "Passive mode enabled.", Color.Yellow)
		end

		command:Bind(1, player:GetSteamId().id)
		command:Execute()
		return false
	end
end

function Passive:PlayerJoin(args)
	local query = SQL:Query("SELECT * FROM Passive WHERE steamid = ?")
	query:Bind(1, args.player:GetSteamId().id)
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
