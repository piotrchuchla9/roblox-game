local Players = game:GetService("Players")

local LeaderboardUI = {}

function LeaderboardUI.update(data)
	local player = Players.LocalPlayer
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local collection = leaderstats:FindFirstChild("Collection")
		if collection then
			collection.Value = data.collectionCount or 0
		end
	end
end

return LeaderboardUI
