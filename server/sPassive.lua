-- Created by DaAlpha
class 'Passive'

function Passive:__init()
  -- Settings
  self.interval = 3600 * 6 -- DB write interval in seconds (Default: 6h)

  -- Globals
  self.passives = {}
  self.diff     = {}
  self.nextSave = self.interval

  -- Note: self.nextSave defaults to self.interval instead of
  -- Server:GetElapsedSeconds() because the latter returns wrong and very
  -- high values when called during server startup which would result into
  -- self.nextSave never being reached during the module runtime

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
  Events:Subscribe("PostTick", self, self.PostTick)
  Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
  Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
  Events:Subscribe("PlayerEnterVehicle", self, self.PlayerEnterVehicle)

  -- Console
  Console:Subscribe("savepassive", self, self.ModuleUnload)
  Console:Subscribe("migratepassive", self, self.MigrateDatabase)
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

function Passive:PostTick()
  if Server:GetElapsedSeconds() > self.nextSave then
    self:ModuleUnload()
    self.nextSave = Server:GetElapsedSeconds() + self.interval
  end
end

function Passive:ModuleUnload()
  local i = 0
  local timer = Timer()
  local trans = SQL:Transaction()
  for steamid in pairs(self.diff) do
    local command
    if self.passives[steamid] then
      command = SQL:Command("INSERT INTO passive VALUES (?)")
    else
      command = SQL:Command("DELETE FROM passive WHERE steamid = ?")
    end
    command:Bind(1, steamid)
    command:Execute()
    i = i + 1
  end
  trans:Commit()
  self.diff = {}
  print(string.format("Saved %d changes in %dms.", i, timer:GetMilliseconds()))
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
  if args.is_driver then
    args.vehicle:SetInvulnerable(args.player:GetValue("Passive") == true)
  end
end

function Passive:MigrateDatabase()
  -- Abort if there is no table to migrate
  -- Note: This check for the table name is case sensitive but using a table in
  -- a statement is not (in SQLite). This is why the table has to be dropped
  -- before a new one is created.
  if not SQL:Query("SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'Passive'"):Execute()[1] then
    print("No table found to migrate.")
    return
  end

  -- Make sure all diff is written to the DB
  self:ModuleUnload()

  -- Get started
  print("Commencing database migration ...")
  local timer = Timer()

  -- Get old data
  local data = SQL:Query("SELECT * FROM Passive"):Execute()

  -- Re-create table
  local trans = SQL:Transaction()
  SQL:Execute("DROP TABLE Passive")
  SQL:Execute("CREATE TABLE passive (steamid VARCHAR PRIMARY KEY)")
  self.passives = {}

  -- Translate data
  for _, row in ipairs(data) do
    local steamid = SteamId(row.steamid).string
    local command = SQL:Command("INSERT INTO passive VALUES (?)")
    command:Bind(1, steamid)
    command:Execute()
    self.passives[steamid] = true
  end
  trans:Commit()

  -- Finish up
  print("Database migration done. " .. #data .. " entries written in " ..
    math.ceil(timer:GetMilliseconds()) .. "ms.")
end

Passive()
