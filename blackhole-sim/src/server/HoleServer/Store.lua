-- Store (ModuleScript, HoleServer 아래)
-- 로벅스 상점: 게임패스(한 번 사면 영원히)와 개발자 상품(살 때마다 효과).
-- Config.GamePasses / Config.Products의 id에 로블록스 웹사이트에서 만든 번호를 넣으면 진짜 결제가 된다.
-- 번호가 0이면 아직 만들지 않은 것: 테스트 계정은 누르면 산 것으로 처리하고, 일반 계정에는 "준비 중"을 띄운다.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local Store = {}

export type Hooks = {
	isTester: (Player) -> boolean,
	-- 게임패스를 가진 것으로 표시하고 효과를 켠다
	grantPass: (Player, string) -> (),
	-- 상품 효과를 준다. 그 사람의 기록을 아직 못 불러왔으면 false
	grantProduct: (Player, string, string) -> boolean,
	-- 이미 처리한 영수증인지
	hasReceipt: (Player, string) -> boolean,
	toast: (Player, string) -> (),
	save: (Player) -> (),
}

local hooks: Hooks? = nil
local passById: { [number]: any } = {}
local productById: { [number]: any } = {}

-- 들어올 때 가진 게임패스 확인
function Store.ownedPasses(player: Player): { [string]: boolean }
	local owned = {}
	for _, pass in ipairs(Config.GamePasses) do
		if pass.id > 0 then
			local ok, has = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if ok and has then
				owned[pass.key] = true
			end
		end
	end
	return owned
end

function Store.buyPass(player: Player, key: any)
	local h = hooks
	local pass = type(key) == "string" and Config.PASS_BY_KEY[key]
	if not h or not pass then
		return
	end
	if pass.id > 0 then
		MarketplaceService:PromptGamePassPurchase(player, pass.id)
	elseif h.isTester(player) then
		h.grantPass(player, pass.key)
		h.toast(player, "🧪 테스트 구매: " .. pass.name .. " (번호가 없어서 무료로 처리했어요)")
	else
		h.toast(player, pass.name .. "은(는) 아직 준비 중이에요")
	end
end

function Store.buyProduct(player: Player, key: any)
	local h = hooks
	local product = type(key) == "string" and Config.PRODUCT_BY_KEY[key]
	if not h or not product then
		return
	end
	if product.id > 0 then
		MarketplaceService:PromptProductPurchase(player, product.id)
	elseif h.isTester(player) then
		h.grantProduct(player, product.key, "test_" .. os.clock())
		h.toast(player, "🧪 테스트 구매: " .. product.name)
	else
		h.toast(player, product.name .. "은(는) 아직 준비 중이에요")
	end
end

function Store.init(h: Hooks)
	hooks = h
	for _, pass in ipairs(Config.GamePasses) do
		if pass.id > 0 then
			passById[pass.id] = pass
		end
	end
	for _, product in ipairs(Config.Products) do
		if product.id > 0 then
			productById[product.id] = product
		end
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
		local pass = passById[passId]
		if purchased and pass then
			h.grantPass(player, pass.key)
			h.toast(player, "💎 " .. pass.name .. " 구매 완료! 고마워요")
			h.save(player)
		end
	end)

	-- 개발자 상품 영수증. 같은 영수증은 한 번만 처리한다
	MarketplaceService.ProcessReceipt = function(receipt: any)
		local product = productById[receipt.ProductId]
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not product then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local id = tostring(receipt.PurchaseId)
		if h.hasReceipt(player, id) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		local ok, granted = pcall(h.grantProduct, player, product.key, id)
		if not ok or not granted then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		h.toast(player, "💎 " .. product.name .. " 구매 완료! 고마워요")
		h.save(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return Store
