-- Created by DaAlpha
class 'Passive'

function Passive:__init()
  -- Settings
  self.cooldown     = 60  -- seconds (Default: 60)
  self.tagOffset    = 20  -- px (Default: 20)
  self.textSize     = 14  -- pt (Default: 14) Text size for the tags
  self.passiveText  = "Passive" -- Text for the "Passive" tags
  self.passiveColor = Color(0, 222, 0) -- Color used for tags and info text

  -- Globals
  self.timer    = Timer()
  self.actions  = {
    [11] = true, [12] = true, [13] = true, [14] = true,
    [15] = true, [137] = true, [138] = true, [139] = true
    }

  -- Events
  Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
  Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
  Events:Subscribe("LocalPlayerBulletHit", self, self.LocalPlayerDamage)
  Events:Subscribe("LocalPlayerExplosionHit", self, self.LocalPlayerDamage)
  Events:Subscribe("LocalPlayerForcePulseHit", self, self.LocalPlayerDamage)
  Events:Subscribe("NetworkObjectValueChange", self, self.NetworkObjectValueChange)
  Events:Subscribe("Render", self, self.Render)
  Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
  Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

function Passive:LocalPlayerChat(args)
  if args.text:lower() ~= "/passive" then return end

  local seconds = self.timer:GetSeconds()
  if seconds < self.cooldown then
    Chat:Print("Cooling down. " .. math.ceil(self.cooldown - seconds) .. " seconds remaining.", Color.Red)
    return false
  end

  Network:Send("Toggle", not LocalPlayer:GetValue("Passive"))
  self.timer:Restart()
  return false
end

function Passive:LocalPlayerInput(args)
  if self.actions[args.input] and (LocalPlayer:GetValue("Passive")
      or LocalPlayer:InVehicle() and LocalPlayer:GetVehicle():GetInvulnerable()) then
    return false
  end
end

function Passive:LocalPlayerDamage(args)
  if LocalPlayer:GetValue("Passive") or args.attacker and (args.attacker:GetValue("Passive")
      or args.attacker:InVehicle() and args.attacker:GetVehicle():GetInvulnerable()) then
    return false
  end
end

function Passive:NetworkObjectValueChange(args)
  if args.key == "Passive" and args.object.__type == "LocalPlayer" then
    if args.value then
      Game:FireEvent("ply.invulnerable")
    else
      Game:FireEvent("ply.vulnerable")
    end
  end
end

function Passive:Render()
  if Game:GetState() ~= GUIState.Game then return end

  for player in Client:GetStreamedPlayers() do
    if player:GetValue("Passive") then
      local tagpos    = player:GetBonePosition("ragdoll_Head") + Vector3(0, 0.3, 0)
      local distance  = tagpos:Distance(LocalPlayer:GetPosition())
      local pos, onsc = Render:WorldToScreen(tagpos)

      if onsc then
        local scale   = math.clamp(1 - distance / 1000, 0.75, 1)
        local size    = Render:GetTextSize(self.passiveText, self.textSize, scale)
        pos           = pos - Vector2(size.x / 2, size.y + self.tagOffset * scale)
        local sColor  = Color(0, 0, 0, 180 * scale ^ 2)
        local color   = Copy(self.passiveColor)
        color.a       = 255 * scale

        Render:DrawText(pos + Vector2.One, self.passiveText, sColor, self.textSize, scale)
        Render:DrawText(pos, self.passiveText, color, self.textSize, scale)
      end
    end
  end

  if LocalPlayer:GetValue("Passive") then
    local width = Render:GetTextWidth("Passive")
    local textpos = Vector2(Render.Width/2 - width/2, 5)

    Render:DrawText(textpos + Vector2.One, "Passive", Color.Black, 18)
    Render:DrawText(textpos, "Passive", self.passiveColor, 18)
  end
end

function Passive:ModuleLoad()
  Events:Fire("HelpAddItem", {
    name = "Passive Mode",
    text =
      "Type /passive into the chat to the chat to toggle passive mode.\n \n" ..
      "If you are in passive mode, you cannot fire your weapons and you cannot kill others " ..
      "and you are completely invincible. If a vehicle's driver is passive, " ..
      "the vehicle will become invulnerable until he exits the vehicle. " ..
      "If a vehicle is invulnerable, its mounted guns cannot be used, " ..
      "even if the person using it is not passive.\n \n" ..
      "Passive Mode (public version) by DaAlpha, coder of Nologam"
      })
end

function Passive:ModuleUnload()
  Events:Fire("HelpRemoveItem", {name = "Passive Mode"})
end

local passive = Passive()
