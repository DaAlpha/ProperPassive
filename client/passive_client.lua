class 'Passive'

function Passive:__init()
	self.max_distance = 150 -- Maximum distance for the "Passive" tags in meters
	self.passive_text = "Passive" -- Text for the "Passive" tags

	Events:Subscribe("LocalPlayerBulletHit", self, self.Damage)
	Events:Subscribe("LocalPlayerExplosionHit", self, self.Damage)
	Events:Subscribe("LocalPlayerForcePulseHit", self, self.Damage)
	Events:Subscribe("Render", self, self.Render)
end

function Passive:Damage(args)
	if args.attacker then
		if args.attacker:GetValue("Passive") or LocalPlayer:GetValue("Passive") or
			args.attacker:InVehicle() and args.attacker:GetVehicle():GetInvulnerable() then
			return false
		end
	end
end

function Passive:Render()
	if Game:GetState() ~= GUIState.Game then return end

	for player in Client:GetStreamedPlayers() do
		if player:GetValue("Passive") then
			local tagpos = player:GetBonePosition("ragdoll_Head") + Vector3(0, 1, 0)
			local distance = tagpos:Distance(LocalPlayer:GetPosition())

			if distance <= self.max_distance then
				local pos, onscreen = Render:WorldToScreen(tagpos)

				if onscreen then
					local size = Render:GetTextSize(self.passive_text)
					pos = pos - Vector2(size.x/2, size.y/2 + 0.075 * distance)

					Render:DrawText(pos + Vector2.One, self.passive_text, Color.Black)
					Render:DrawText(pos, self.passive_text, Color.Lime)
				end
			end
		end
	end

	if LocalPlayer:GetValue("Passive") then
		local width = Render:GetTextWidth("Passive")
		local textpos = Vector2(Render.Width - width - 5, 112)
		Render:DrawText(textpos, "Passive", Color.Lime)
	end
end

local passive = Passive()
