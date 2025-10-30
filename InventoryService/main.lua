-- Services, Values, and More
local InventoryDefaults = require(script:WaitForChild("InventoryDefaults"))
local InventoryClient = require(script:WaitForChild("InventoryClient"))

-- Define the Inventory class
local Inventory : inventory = { }
Inventory.__index = Inventory

-- Error codes
local NO_EQUIPS = "No equips are allowed in this inventory!"
local MAX_EQUIPS = "Max equips reached!"
local SAME_EQUIP = "Same equip used!"
local NO_INVS_EXIST = "No inventories exist yet!"
local MAX_INVENTORY = "Inventory is full!"
local NO_ITEM_EXISTS = "No item exists with requested params!"
local CANNOT_UNEQUIP_DEFAULT = "Cannot unequip the default equipped item!"
local NO_AMOUNTS = "No amount tags are allowed in this inventory!"

-- Debug warning helper function
function debugWarn(message)
	if script:GetAttribute("debugEnabled") then
		warn("[SERVER] " .. message)
	end
end

if game:GetService("RunService"):IsClient() then
	debugWarn("Attempted loading of main inventory class on client; redirecting to client helper class!")
	return InventoryClient
end

if script:GetAttribute("debugEnabled") and script:GetAttribute("hasBeenWarned") == false then
	script:SetAttribute("hasBeenWarned", true)
	debugWarn("Debug mode for this module can cause tons of warnings or errors to pop up, and many of these are normal, only use if needed.")
end

--[[

Non-Object oriented functions.
Mainly just stuff to help you do things easier.

]]

function Inventory.generateItem(name, amount, tags)
	if tags == nil then tags = {} end
	tags["Amount"] = (amount ~= nil and tonumber(amount) or 1)

	return {
		Name = name,
		Tags = tags
	}
end

--[[

The most important function: Creating a new inventory to a player.

]]

function Inventory.new(player, inventoryName)
	local defaults = InventoryDefaults.getDefaults(inventoryName)

	local self = setmetatable({
		Player = player,
		Name = inventoryName,

		Items = defaults.DefaultItems,
		MaxItems = defaults.MaxItems,
		DontMergeItems = defaults.DontMergeItems,

		Equipped = {},
		MaxEquips = defaults.MaxEquips,
		UsesEquips = defaults.UsesEquips,

		DefaultEquip = defaults.DefaultEquip,
		UsesDefault = defaults.UsesDefault,

		DontUseAmounts = defaults.DontUseAmounts,

		OnEquipChangeConnections = {},
		OnItemsChangeConnections = {},
	}, Inventory)

	-- Check if 'UsesDefault' is true and 'DefaultEquip' exists in 'Items'
	if self.UsesDefault and #self.Equipped == 0 then
		local defaultItem = self:GetItemById(self.DefaultEquip)
		if defaultItem then
			debugWarn("Auto equipping default item(s).")
			-- Equip the default item
			self:EquipItem(self.DefaultEquip)
		end
	end

	return self
end

--[[

Secondary Inventory Functions.

]]

function Inventory:ResetToDefault()
	local defaults = InventoryDefaults.getDefaults(self.Name)
	
	self.Items = defaults.DefaultItems
	self.MaxItems = defaults.MaxItems
	self.DontMergeItems = defaults.DontMergeItems

	self.Equipped = {}
	self.MaxEquips = defaults.MaxEquips
	self.UsesEquips = defaults.UsesEquips

	self.DefaultEquip = defaults.DefaultEquip
	self.UsesDefault = defaults.UsesDefault

	self.DontUseAmounts = defaults.DontUseAmounts
	
	return true
end

function Inventory:PushInventoryChange(key, value) -- Force pushes an inventory base value, like "MaxItems"
	self[key] = value
	return true
end

function Inventory:AttemptSetAmount(item, amount) -- Attempts to set the items amount, based on the DontUseAmounts variable
	if not self.DontUseAmounts then
		item.Tags.Amount = amount
	else
		if item.Tags.Amount ~= nil then item.Tags.Amount = nil end
		if amount <= 0 then
			self:RemoveItemByNameAndTags(item.Name, item.Tags)
		end
	end
end

function Inventory:AttemptIncrementAmount(itemId, amount) -- Attemps to increment the items amount, based on the DontUseAmounts variable
	local item = self:GetItemById(itemId)

	if not self.DontUseAmounts then
		item.Tags.Amount += amount
		if item.Tags.Amount <= 0 then
			table.remove(self.Items, itemId)
		end
	else
		if item.Tags.Amount ~= nil then item.Tags.Amount = nil end
		if amount <= -1 then
			table.remove(self.Items, itemId)
		end
	end
end

function Inventory:GetItemAmount(item) -- Returns the items amount
	return item.Tags.Amount ~= nil and item.Tags.Amount or 1
end

--[[

Main Inventory Functions.

]]

function Inventory:AddItem(item)
	local currentItemCount = 0
	for _, currentItem in pairs(self.Items) do
		currentItemCount += self:GetItemAmount(currentItem)
	end

	local estimatedTotalAmount = currentItemCount + self:GetItemAmount(item)

	if estimatedTotalAmount >= self.MaxItems then
		if currentItemCount < self.MaxItems then
			debugWarn("Warning: Attempted AboveMax in Item.Tags.Amounts, Rounded to Max.")
			self:AttemptSetAmount(item, self.MaxItems - currentItemCount)
		else
			debugWarn(MAX_INVENTORY)
			return MAX_INVENTORY
		end
	end

	if self.DontUseAmounts then
		if item.Tags.Amount ~= nil then
			item.Tags.Amount = nil
		end
	end

	local existingId = self:GetIdByNameAndTags(item.Name, item.Tags)
	local existingItem = self:GetItemById(existingId)
	if existingItem ~= NO_ITEM_EXISTS and not self.DontMergeItems then
		self:AttemptIncrementAmount(existingId, self:GetItemAmount(item))
	else
		if self.DontMergeItems then
			for i = 1, self:GetItemAmount(item) do
				local clonedItem = table.clone(item)
				self:AttemptSetAmount(clonedItem, 1)
				table.insert(self.Items, clonedItem)
			end
		else
			table.insert(self.Items, item)
		end
	end

	self:TriggerOnItemsChangeCallbacks()

	return self:GetItemAmount(item)
end

function Inventory:EquipItem(itemId)
	if not self.UsesEquips then
		debugWarn(NO_EQUIPS)
		return NO_EQUIPS
	end

	if table.find(self.Equipped, itemId) then
		debugWarn(SAME_EQUIP)
		return SAME_EQUIP
	end

	if #self.Equipped >= self.MaxEquips then
		self.Equipped[1] = itemId
		self:TriggerOnEquipChangeCallbacks()
		debugWarn(MAX_EQUIPS .. "\nUnequipping first slot item to bypass.")
		return true
	end

	table.insert(self.Equipped, itemId)
	self:TriggerOnEquipChangeCallbacks()

	return true
end

function Inventory:UnequipItem(itemId)
	if not self.UsesEquips then
		debugWarn(NO_EQUIPS)
		return NO_EQUIPS
	end

	for i, equippedItemId in self.Equipped do
		if equippedItemId == itemId then
			table.remove(self.Equipped, i)

			self:TriggerOnEquipChangeCallbacks()

			return true
		end
	end

	debugWarn(NO_ITEM_EXISTS)
	return NO_ITEM_EXISTS
end

function Inventory:IsFull()
	local currentItemCount = 0
	for _, currentItem in pairs(self.Items) do
		currentItemCount += self:GetItemAmount(currentItem)
	end

	return currentItemCount >= self.MaxItems
end

function Inventory:GetAmount()
	local total = 0
	for _, item in self.Items do
		total += self:GetItemAmount(item)
	end
	return total
end

function Inventory:GetAmountMatchName(name)
	local total = 0
	for _, item in self.Items do
		if item.Name == name then
			total += self:GetItemAmount(item)
		end
	end
	return total
end

function Inventory:GetAmountOfItemById(itemId)
	local item = self:GetItemById(itemId)
	return item ~= NO_ITEM_EXISTS and self:GetItemAmount(itemId) or 0
end

function Inventory:IsItemEquipped(itemId)
	if not self.UsesEquips then
		debugWarn(NO_EQUIPS)
		return NO_EQUIPS
	end

	return table.find(self.Equipped, itemId) ~= nil
end

function Inventory:GetItemById(itemId)
	if not self.Items[itemId] then debugWarn(NO_ITEM_EXISTS) end
	return self.Items[itemId] or NO_ITEM_EXISTS
end

function Inventory:GetIdByName(name)
	for key, item in self.Items do
		if item.Name == name then
			return key
		end
	end

	debugWarn(NO_ITEM_EXISTS)
	return NO_ITEM_EXISTS
end

function Inventory:GetIdByNameAndTags(name, tags)
	for key, item in self.Items do
		if item.Name == name then
			local sameTags = true
			for key, value in pairs(item.Tags) do
				if key ~= "Amount" and tags[key] ~= value then
					sameTags = false
					break
				end
			end

			if sameTags then
				return key
			end
		end
	end

	debugWarn(NO_ITEM_EXISTS)
	return NO_ITEM_EXISTS
end

function Inventory:RemoveItemById(itemId, amount)
	if self.Items[itemId] then
		if self.UsesDefault and self.DefaultEquip == itemId then
			debugWarn(CANNOT_UNEQUIP_DEFAULT)
			return CANNOT_UNEQUIP_DEFAULT
		end

		for _, equipped in self.Equipped do
			self:UnequipItem(equipped)
		end
		if self.UsesDefault then
			self:EquipItem(self.DefaultEquip)
		end

		if amount ~= nil then
			local item = self.Items[itemId]
			self:AttemptIncrementAmount(itemId, -amount)
		else
			table.remove(self.Items, itemId)
		end

		self:TriggerOnItemsChangeCallbacks()
		return true
	end

	debugWarn(NO_ITEM_EXISTS)
	return NO_ITEM_EXISTS
end

function Inventory:RemoveItemByName(name, amount)
	for itemId, item in self.Items do
		if item.Name == name then
			if self.UsesDefault and self.DefaultEquip == itemId then
				debugWarn(CANNOT_UNEQUIP_DEFAULT)
				return CANNOT_UNEQUIP_DEFAULT
			end

			for _, equipped in self.Equipped do
				self:UnequipItem(equipped)
			end
			if self.UsesDefault then
				self:EquipItem(self.DefaultEquip)
			end

			if amount ~= nil then
				local item = self.Items[itemId]
				self:AttemptIncrementAmount(itemId, -amount)
			else
				table.remove(self.Items, itemId)
			end

			self:TriggerOnItemsChangeCallbacks()
			return true
		end
	end

	debugWarn(NO_ITEM_EXISTS)
	return NO_ITEM_EXISTS
end

function Inventory:RemoveItemByNameAndTags(name, tags, amount)
	for itemId, item in self.Items do
		if item.Name == name then
			local sameTags = true
			for key, value in pairs(tags) do
				if key ~= "Amount" and item.Tags[key] ~= value then
					sameTags = false
					break
				end
			end

			if sameTags then
				if self.UsesDefault and self.DefaultEquip == itemId then
					debugWarn(CANNOT_UNEQUIP_DEFAULT)
					return CANNOT_UNEQUIP_DEFAULT
				end

				for _, equipped in self.Equipped do
					self:UnequipItem(equipped)
				end
				if self.UsesDefault then
					self:EquipItem(self.DefaultEquip)
				end
				
				if amount ~= nil then
					local item = self.Items[itemId]
					self:AttemptIncrementAmount(itemId, -amount)
				else
					table.remove(self.Items, itemId)
				end

				self:TriggerOnItemsChangeCallbacks()
				return true
			end
		end
	end

	debugWarn(NO_ITEM_EXISTS)
	return NO_ITEM_EXISTS
end

function Inventory:OnEquipChange(callback)
	local connection = {}
	local funcSelf = self

	connection.Callback = callback

	function connection:Disconnect()
		for i, entry in funcSelf.OnEquipChangeConnections do
			if entry == connection then
				table.remove(funcSelf.OnEquipChangeConnections, i)
				break
			end
		end
	end

	table.insert(self.OnEquipChangeConnections, connection)
	return connection
end

function Inventory:OnItemsChange(callback)
	local connection = {}
	local funcSelf = self

	connection.Callback = callback

	function connection:Disconnect()
		for i, entry in funcSelf.OnItemsChangeConnections do
			if entry == connection then
				table.remove(funcSelf.OnItemsChangeConnections, i)
				break
			end
		end
	end

	table.insert(self.OnItemsChangeConnections, connection)
	return connection
end

function Inventory:TriggerOnEquipChangeCallbacks()
	for _, connection in self.OnEquipChangeConnections do
		connection.Callback(self.Equipped)
	end
end

function Inventory:TriggerOnItemsChangeCallbacks()
	for _, connection in self.OnItemsChangeConnections do
		connection.Callback(self.Items)
	end
end

--[[

Export, Import, and Release functions.

]]

function Inventory:Export()
	return {
		self.Name,
		self.Items,
		self.Equipped,
		self.MaxEquips,
		self.MaxItems
	}
end

function Inventory:Import(importedContent)
	local inventoryName, items, equipped, maxequips, maxitems = table.unpack(importedContent)

	self.Name = inventoryName
	self.Items = items or {}
	self.Equipped = equipped or {}

	self.MaxEquips = maxequips or self.MaxEquips
	self.MaxItems = maxitems or self.MaxItems
end

export type item = {["Name"]: string, ["Tags"]: {["Amount"]: number, [any]: any}}
export type inventory = {
	Player: Player,
	Name: string,

	Items: {[number]: item},
	MaxItems: number,
	DontMergeItems: boolean,

	Equipped: {number},
	MaxEquips: number,
	UsesEquips: boolean,

	DefaultEquip: number,
	UsesDefault: boolean,

	DontUseAmounts: boolean,

	generateItem: (name : string, amount : number, tags : {[any] : any}) -> item,

	AddItem: (self: inventory, item : item) -> number | string,
	EquipItem: (self: inventory, itemId : number) -> true | string,
	UnequipItem: (self: inventory, itemId : number) -> true | string,
	GetAmount: (self: inventory) -> number,
	GetAmountMatchName: (self: inventory, name : string) -> number,
	GetAmountOfItemById: (self: inventory, itemId : number) -> number,
	IsItemEquipped: (self: inventory, itemId : number) -> boolean,
	GetItemById: (self: inventory, itemId : number) -> item | string,
	GetIdByName: (self: inventory, name : string) -> item | string,
	GetIdByNameAndTags: (self: inventory, name : string, tags : {[any] : any}) -> item | string,
	RemoveItemById: (self: inventory, itemId : number, amount : number?) -> true | string,
	RemoveItemByName: (self: inventory, name : string, amount : number?) -> true | string,
	RemoveItemByNameAndTags: (self: inventory, name : string, tags : {[any] : any}, amount : number?) -> true | string,
	OnEquipChange: (self: inventory, callback : ({number}) -> nil) -> nil,
	OnItemsChange: (self: inventory, callback : ({[number] : item}) -> nil) -> nil,
}

return Inventory
