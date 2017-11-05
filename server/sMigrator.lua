-- Created by DaAlpha

Console:Subscribe("migratepassive", function()
  local timer = Timer()

  print("Commencing passive database migration ...")

  if not SQL:Query("SELECT name FROM sqlite_master WHERE type ='table' AND name='Passive'"):Execute()[1] then
    SQL:Execute("CREATE TABLE IF NOT EXISTS passive (steamid VARCHAR PRIMARY KEY)")
    print("Old passive table did not exist. Created an empty new one of none existed.")
    return
  end

  -- Save entries temporarily
  print("Loading DB entries ...")
  local entries = {}
  for rowNr, row in ipairs(SQL:Query("SELECT * FROM Passive"):Execute()) do
    table.insert(entries, SteamId(row.steamid))
  end
  print("Done.")

  -- Drop old table and create new
  SQL:Execute("DROP TABLE Passive")
  SQL:Execute("CREATE TABLE passive (steamid VARCHAR PRIMARY KEY)")

  -- Write to table
  print("Writing to new table ...")
  for _, steamid in  ipairs(entries) do
    local command = SQL:Command("INSERT INTO passive VALUES (?)")
    command:Bind(1, steamid.string)
    command:Execute()
  end
  print("Done.")

  -- Report
  print("Database migration done. " .. #entries .. " entries written in " ..
    math.ceil(timer:GetSeconds()) .. " seconds.")
end)
