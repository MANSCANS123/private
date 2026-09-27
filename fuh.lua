local playeruser = "Yogotracer"

if game:GetService("Players").LocalPlayer.Name == playeruser then
    local ts = game:GetService("TeleportService")
    local ps = game:GetService("Players")
    local hs = game:GetService("HttpService")
    local lp = ps.LocalPlayer

    local requestFunc = (syn and syn.request) or http_request or request

    local function serverHop()
        print("fetching server list via proxy...")
        
        -- Using an external JSON proxy format that PC executors can read without getting blocked
        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            
            if requestFunc then
                local res = requestFunc({Url = url, Method = "GET"})
                if res and res.Body then
                    return hs:JSONDecode(res.Body)
                end
            end
            
            -- Fallback proxy method for PC executors if native request fails
            local proxyUrl = "https://corsproxy.io/?" .. hs:UrlEncode(url)
            local raw = game:HttpGet(proxyUrl)
            return hs:JSONDecode(raw)
        end)
    
        if success and result and result.data then
            local servers = {}
            for _, s in ipairs(result.data) do
                if type(s) == "table" and s.playing < s.maxPlayers and s.id ~= game.JobId then
                    table.insert(servers, s.id)
                end
            end
            
            if #servers > 0 then
                local targetServer = servers[math.random(1, #servers)]
                print("hopping to server: " .. targetServer)
                
                local tpSuccess = pcall(function()
                    ts:TeleportToPlaceInstance(game.PlaceId, targetServer, lp)
                end)
                
                if tpSuccess then return end
            end
        end
        
        -- Ultimate fallback if API data is unreachable
        pcall(function()
            ts:Teleport(game.PlaceId, lp)
        end)
    end

    local monsters = workspace:WaitForChild("Monsters", 10)
    if not monsters then
        serverHop()
        return
    end

    local hasVicious = false
    for _, mob in ipairs(monsters:GetChildren()) do
        if string.find(mob.Name, "Vicious") then
            hasVicious = true
            break
        end
    end

    if not hasVicious then
        print("no stingers bud")
        serverHop()
        return
    end

    local hopped = false
    local function triggerHop()
        if hopped then return end
        hopped = true
        print("triggering forced server hop...")
        serverHop()
    end

    -- 1. Live State Watcher (Scans every 300ms)
    task.spawn(function()
        task.wait(3)
        
        while not hopped do
            task.wait(0.3)
            local currentMonsters = workspace:FindFirstChild("Monsters")
            local stillHasVicious = false
            
            if currentMonsters then
                for _, mob in ipairs(currentMonsters:GetChildren()) do
                    if string.find(mob.Name, "Vicious") then
                        stillHasVicious = true
                        break
                    end
                end
            end
            
            if not stillHasVicious then
                print("vicious bee gone, hopping now...")
                triggerHop()
                break
            end
        end
    end)

    -- 2. The Big Red Button (5-minute max safety net)
    task.spawn(function()
        task.wait(300)
        if not hopped then
            print("safety net timer reached: forcing hop")
            triggerHop()
        end
    end)

    -- 3. Execute External Script Safely
    print("vic is here, executing script...")
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua"))()
    end)
end
