-- Created by DaAlpha
class 'Passive'

function Passive:__init()
	self.maxDistance	= 200			-- Maximum distance for the "Passive" tags in meters
	self.passiveText	= "Passive"		-- Text for the "Passive" tags
	self.textSize		= 14			-- Text size for the "Passive" tags

	self.firingActions	= {11, 12, 13, 14, 15, 137, 138, 139}

	Events:Subscribe("LocalPlayerInput", self, self.Input)
	Events:Subscribe("LocalPlayerBulletHit", self, self.Damage)
	Events:Subscribe("LocalPlayerExplosionHit", self, self.Damage)
	Events:Subscribe("LocalPlayerForcePulseHit", self, self.Damage)
	Events:Subscribe("PlayerNetworkValueChange", self, self.PlayerNetworkValueChange)
	Events:Subscribe("Render", self, self.Render)
    Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
    Events:Subscribe("ModulesLoad", self, self.ModuleLoad)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

function Passive:Input(args)
	if table.find(self.firingActions, args.input) and (LocalPlayer:GetValue("Passive")
			or (LocalPlayer:InVehicle() and LocalPlayer:GetVehicle():GetInvulnerable())) then
		return false
	end
end

function Passive:Damage(args)
	if LocalPlayer:GetValue("Passive") then
		return false
	elseif args.attacker then
		if args.attacker:GetValue("Passive") or
			args.attacker:InVehicle() and args.attacker:GetVehicle():GetInvulnerable() then
			return false
		end
	end
end

function Passive:PlayerNetworkValueChange(args)
	if args.player == LocalPlayer and args.key == "Passive" then
		self:FirePlayerEvent(args.value)
	end
end

function Passive:FirePlayerEvent(passive)
	if passive then
		Game:FireEvent("ply.invulnerable")
	else
		Game:FireEvent("ply.vulnerable")
	end
end

function Passive:Render()
	if Game:GetState() ~= GUIState.Game then return end

	for player in Client:GetStreamedPlayers() do
		if player:GetValue("Passive") then
			local tagpos	= player:GetBonePosition("ragdoll_Head") + Vector3(0, 0.5, 0)
			local distance	= tagpos:Distance(LocalPlayer:GetPosition())

			if distance < self.maxDistance then
				local pos, onscreen = Render:WorldToScreen(tagpos)

				if onscreen then
					local factor	= math.clamp(1 - distance / self.maxDistance, 0, 1)
					local width		= Render:GetTextWidth(self.passiveText, self.textSize)
					pos				= pos - Vector2(width / 2, math.clamp(300 * factor, 0, 26))
					local color		= Color(0, 255, 0, 255 * factor)
					local sColor	= Color(0, 0, 0, 200 * factor)

					Render:DrawText(pos + Vector2.One, self.passiveText, sColor, self.textSize)
					Render:DrawText(pos, self.passiveText, color, self.textSize)
				end
			end
		end
	end

	if LocalPlayer:GetValue("Passive") then
		local width = Render:GetTextWidth("Passive")
		local textpos = Vector2(Render.Width/2 - width/2, 5)

		Render:DrawText(textpos + Vector2.One, "Passive", Color.Black, 18)
		Render:DrawText(textpos, "Passive", Color.Lime, 18)
	end
end

function Passive:ModuleLoad()
	Events:Fire("HelpAddItem", {
		name = "Passive Mode",
		text = "Type /passive into the chat to the chat to toggle passive mode.\n" ..
				"\n" ..
				"If you are in passive mode, you cannot fire your weapons and you cannot kill others " ..
				"(except from roadkilling, that is pretty much impossible to code properly) " ..
				"and you are completely invincible. If a vehicle's driver is passive, " ..
				"the vehicle will become invulnerable until he exits the vehicle. " ..
				"If a vehicle is invulnerable, its mounted guns cannot be used, " ..
				"even if the person using it is not passive.\n" ..
				"\n" ..
				"Passive Mode (public version) by DaAlpha, coder of Nologam"})
end

function Passive:ModuleUnload()
	Events:Fire("HelpRemoveItem", {name = "Passive Mode"})
end

local passive = Passive()
