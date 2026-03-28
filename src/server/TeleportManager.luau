-- TeleportManager: Cross-server player search and teleportation
local TeleportService = game:GetService("TeleportService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")

local TeleportManager = {}

local SEARCH_TOPIC = "PlayerSearch"
local RESPONSE_TOPIC = "PlayerSearchResponse"
local homeJobIds: { [number]: string } = {} -- userId -> original JobId

function TeleportManager.init()
	-- Save home server for each player
	Players.PlayerAdded:Connect(function(player)
		homeJobIds[player.UserId] = game.JobId
	end)

	Players.PlayerRemoving:Connect(function(player)
		homeJobIds[player.UserId] = nil
	end)

	-- Listen for player search requests from other servers
	local success, err = pcall(function()
		MessagingService:SubscribeAsync(SEARCH_TOPIC, function(message)
			local data = message.Data
			local targetName = data.targetName
			local requesterJobId = data.requesterJobId

			-- Check if target player is on this server
			for _, player in Players:GetPlayers() do
				if string.lower(player.Name) == string.lower(targetName)
					or string.lower(player.DisplayName) == string.lower(targetName) then
					-- Found! Send response
					pcall(function()
						MessagingService:PublishAsync(RESPONSE_TOPIC, {
							targetName = player.Name,
							targetDisplayName = player.DisplayName,
							jobId = game.JobId,
							placeId = game.PlaceId,
							requesterJobId = requesterJobId,
						})
					end)
					return
				end
			end
		end)
	end)

	if not success then
		warn("[TeleportManager] Failed to subscribe to search topic: " .. tostring(err))
	end
end

function TeleportManager.searchPlayer(requester: Player, targetName: string, callback: (result: any?) -> ())
	local found = false

	-- First check local server
	for _, player in Players:GetPlayers() do
		if player ~= requester and (string.lower(player.Name) == string.lower(targetName)
			or string.lower(player.DisplayName) == string.lower(targetName)) then
			callback({
				targetName = player.Name,
				targetDisplayName = player.DisplayName,
				jobId = game.JobId,
				placeId = game.PlaceId,
				isLocal = true,
			})
			return
		end
	end

	-- Subscribe to responses temporarily
	local connection
	local success, err = pcall(function()
		connection = MessagingService:SubscribeAsync(RESPONSE_TOPIC, function(message)
			local data = message.Data
			if data.requesterJobId == game.JobId and not found then
				found = true
				data.isLocal = false
				callback(data)
				if connection then
					connection:Disconnect()
				end
			end
		end)
	end)

	if not success then
		warn("[TeleportManager] Failed to subscribe to response: " .. tostring(err))
		callback(nil)
		return
	end

	-- Publish search request
	pcall(function()
		MessagingService:PublishAsync(SEARCH_TOPIC, {
			targetName = targetName,
			requesterJobId = game.JobId,
		})
	end)

	-- Timeout after 5 seconds
	task.delay(5, function()
		if not found then
			found = true
			callback(nil)
			if connection then
				connection:Disconnect()
			end
		end
	end)
end

function TeleportManager.teleportToServer(player: Player, placeId: number, jobId: string)
	-- Save home before leaving
	homeJobIds[player.UserId] = game.JobId

	pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
	end)
end

function TeleportManager.teleportHome(player: Player)
	local homeJobId = homeJobIds[player.UserId]
	if homeJobId and homeJobId ~= game.JobId then
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, homeJobId, player)
		end)
	end
end

return TeleportManager
