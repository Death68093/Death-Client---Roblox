# Death-Client - Roblox
A LocalScript client for Roblox games. All modules run locally and enhance movement, visuals, and utility for the player.  
**Version:** 1.0.0  
**Default Theme:** Red / Black    
### Load Newest Version with this:
[spoiler]
```
local HttpService = game:GetService("HttpService")
local url = "https://raw.githubusercontent.com/Death68093/Death-Client---Roblox/refs/heads/main/Newest.lua"

local success, code = pcall(function()
    return HttpService:GetAsync(url)
end)

if success then
    local func = loadstring(code)
    func()
else
    warn("Failed to fetch Death-Client code")
end
```
[/spoiler]

## Features

### Movement
- Fly (configurable speed, smooth movement)
- Noclip (walk through walls/objects)
- High Jump / Super Jump
- Speed Hack (walkspeed toggle)
- Infinite Jump
- Spider / Wall Climb
- Air Walk (locks to configured height)

### Combat / PvP
- Aimbot (configurable FOV and smoothing)
- ESP (player boxes, tracers, health bars)

### Utility
- Teleport GUI (to players)
- Anti-AFK
- Fake Player / Invisibility (real player frozen, fake player moves)
- Tool cloning & activation (fake player can use tools)
- ProximityPrompt instant activation (press **E** to trigger)

### Visual / Fun
- Rainbow Trails
- Camera Zoom Hack

### Safety / Stealth
- GUI toggle & minimization
- Keybinds reset when GUI closed (default toggle: **Z**)
