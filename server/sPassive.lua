-- Created by DaAlpha
class 'Passive'

function Passive:__init()
  -- Settings
  self.interval = 3600 * 6 -- DB write interval in seconds (Default: 6h)

  -- Globals
  self.passives = {}
  self.diff     = {}

  -- Create DB table if it does not exist
  SQL:Execute("CREATE TABLE IF NOT EXISTS passive (steamid VARCHAR PRIMARY KEY)")

  -- Load all DB entries into the cache
  local i = 0
  local timer = Timer()
  for _, row in ipairs(SQL:Query("SELECT * FROM passive"):Execute()) do
    self.passives[row.steamid] = true
    i = i + 1
  end
  print(string.format("Loaded %d passives in %dms.", i, timer:GetMilliseconds()))

  -- Network
  Network:Subscribe("Toggle", self, self.Toggle)

  -- Events
  Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
  Events:Subscribe("PlayerEnterVehicle", self, self.PlayerEnterVehicle)
  Events:Subscribe("PostTick", self, self.PostTick)
  Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

  -- Console
  Console:Subscribe("savepassive", self, self.ModuleUnload)
end

function Passive:Toggle(state, sender)
  sender:SetNetworkValue("Passive", state or nil)

  local vehicle = sender:GetVehicle()
  if IsValid(vehicle) and vehicle:GetDriver() == sender then
    vehicle:SetInvulnerable(state == true)
  end

  Chat:Send(sender, "Passive mode " .. (state and "enabled." or "disabled."), Color.Lime)

  local steamid = sender:GetSteamId().string
  self.diff[steamid] = not self.diff[steamid] or nil
  self.passives[steamid] = state or nil
end

function Passive:ClientModuleLoad(args)
  local state = self.passives[args.player:GetSteamId().string]
  args.player:SetNetworkValue("Passive", state)
  local vehicle = args.player:GetVehicle()
  if IsValid(vehicle) and vehicle:GetDriver() == args.player then
    vehicle:SetInvulnerable(state ~= nil)
  end
end

function Passive:PlayerEnterVehicle(args)
  if args.is_driver then args.vehicle:SetInvulnerable(args.player:GetValue("Passive") == true) end
end

function Passive:PostTick()
  if math.floor(Server:GetElapsedSeconds()) % self.interval == 0 then
    self:ModuleUnload()
  end
end

function Passive:ModuleUnload()
  local i = 0
  local timer = Timer()
  local trans = SQL:Transaction()
  for steamid, _ in pairs(self.diff) do
    local state = self.passives[steamid]
    local command
    if state then
      command = SQL:Command("INSERT OR REPLACE INTO passive VALUES (?)")
    else
      command = SQL:Command("DELETE FROM passive WHERE steamid = ?")
    end
    command:Bind(1, steamid)
    command:Execute()
    i = i + 1
  end
  trans:Commit()
  self.diff = {}
  print(string.format("Saved %d passives in %dms.", i, timer:GetMilliseconds()))
end

local passive = Passive()
