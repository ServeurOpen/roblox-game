local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.GameConfig)

local player = Players.LocalPlayer

-- Call BoosterShop.PromptDoubleCash() / PromptVIP() / PromptCash(amount)
-- from your shop UI buttons once they exist.
local BoosterShop = {}

function BoosterShop.PromptDoubleCash()
	MarketplaceService:PromptGamePassPurchase(player, GameConfig.GamePasses.DoubleCash)
end

function BoosterShop.PromptVIP()
	MarketplaceService:PromptGamePassPurchase(player, GameConfig.GamePasses.VIP)
end

function BoosterShop.PromptCash(amount)
	local productId = GameConfig.DevProducts["Cash_" .. tostring(amount)]
	if productId then
		MarketplaceService:PromptProductPurchase(player, productId)
	end
end

_G.BoosterShop = BoosterShop
return BoosterShop
