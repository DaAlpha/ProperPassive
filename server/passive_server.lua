class 'Passive'

function Passive:__init()
	self.passives = {}

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

		if passive then
			player:SetNetworkValue("Passive", nil)
			self.passives[steamid] = nil
			if player:InVehicle() and player == player:GetVehicle():GetDriver() then
				player:GetVehicle():SetInvulnerable(false)
			end
			Chat:Send(player, "Passive mode disabled.", Color.Yellow)
		else
			player:SetNetworkValue("Passive", true)
			self.passives[steamid] = true
			if player:InVehicle() and player == player:GetVehicle():GetDriver() then
				player:GetVehicle():SetInvulnerable(true)
			end
			Chat:Send(player, "Passive mode enabled.", Color.Yellow)
		end
		return false
	end
end

function Passive:PlayerJoin(args)
	if self.passives[args.player:GetSteamId().id] then
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
