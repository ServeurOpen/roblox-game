local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.GameConfig)
local PlayerData = require(ServerScriptService.PlayerData)

-- Maps a Developer Product id to how much cash it grants.
local CASH_PRODUCTS = {
	[GameConfig.DevProducts.Cash_100] = 100,
	[GameConfig.DevProducts.Cash_500] = 500,
	[GameConfig.DevProducts.Cash_2000] = 2000,
}

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = PlayerData.Get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local grant = CASH_PRODUCTS[receiptInfo.ProductId]
	if grant then
		data.Cash += grant
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

PlayerData.DataLoaded:Connect(function(player, data)
	-- Apply Game Pass ownership once, on join, so repeated UserOwnsGamePassAsync
	-- calls during play aren't needed.
	local okDouble, ownsDouble = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConfig.GamePasses.DoubleCash)
	end)
	data.OwnsDoubleCash = okDouble and ownsDouble or data.OwnsDoubleCash

	local okVip, ownsVip = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GameConfig.GamePasses.VIP)
	end)
	data.OwnsVIP = okVip and ownsVip or data.OwnsVIP
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if not wasPurchased then
		return
	end

	local data = PlayerData.Get(player)
	if not data then
		return
	end

	if gamePassId == GameConfig.GamePasses.DoubleCash then
		data.OwnsDoubleCash = true
	elseif gamePassId == GameConfig.GamePasses.VIP then
		data.OwnsVIP = true
	end
end)
