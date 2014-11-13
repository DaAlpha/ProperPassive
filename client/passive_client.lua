-- Created by DaAlpha
class 'Passive'

function Passive:__init()
	self.max_distance	= 200			-- Maximum distance for the "Passive" tags in meters
	self.passive_text	= "Passive"		-- Text for the "Passive" tags
	self.text_size		= 14

	self.firing_actions = {11, 12, 13, 14, 15, 137, 138, 139}

	Events:Subscribe("LocalPlayerInput", self, self.Input)
	Events:Subscribe("LocalPlayerBulletHit", self, self.Damage)
	Events:Subscribe("LocalPlayerExplosionHit", self, self.Damage)
	Events:Subscribe("LocalPlayerForcePulseHit", self, self.Damage)
	Events:Subscribe("Render", self, self.Render)
end

function Passive:Input(args)
	if table.find(self.firing_actions, args.input) then
		if LocalPlayer:GetValue("Passive")
			or LocalPlayer:InVehicle() and LocalPlayer:GetVehicle():GetInvulnerable() then
			return false
		end
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

function Passive:Render()
	if Game:GetState() ~= GUIState.Game then return end

	for player in Client:GetStreamedPlayers() do
		if player:GetValue("Passive") then
			local tagpos	= player:GetBonePosition("ragdoll_Head") + Vector3(0, 0.5, 0)
			local distance	= tagpos:Distance(LocalPlayer:GetPosition())

			if distance <= self.max_distance then
				local pos, onscreen = Render:WorldToScreen(tagpos)

				if onscreen then
					local factor	= math.clamp(distance/self.max_distance, 0, 1)
					local width		= Render:GetTextWidth(self.passive_text, self.text_size)
					pos				= pos - Vector2(width/2, math.clamp(300 * factor, 0, 26))
					local alpha		= math.lerp(255, 0, factor)
					local color		= Color(0, 255, 0, alpha)
					local s_color	= Color(0, 0, 0, alpha)

					Render:DrawText(pos + Vector2.One, self.passive_text, s_color, self.text_size)
					Render:DrawText(pos, self.passive_text, color, self.text_size)
				end
			end
		end
	end

	if LocalPlayer:GetValue("Passive") then
		local width = Render:GetTextWidth("Passive")
		local textpos = Vector2(Render.Width/2 - width/2, 5)

		Render:DrawText(textpos + Vector2.One, "Passive", Color.Black)
		Render:DrawText(textpos, "Passive", Color.Lime)
	end
end

local passive = Passive()
