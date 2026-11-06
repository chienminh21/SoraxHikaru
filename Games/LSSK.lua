local function N(t)
    pcall(function()
        game.StarterGui:SetCore("SendNotification",{Title="PhiPhai v2",Text=t,Duration=5})
    end)
end

task.delay(2,function()
    N("Join Main Map To Use Script")
end)
