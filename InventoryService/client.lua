--[[

This is the client sidded access version of the Inventory module.
This version prevents the client from accessesing risky functions, like "EquipItem" or "AddItem".
You can either call this via "Inventory", or directly by "Inventory.InventoryClient".

]]

local InventoryClient = { }
InventoryClient.__index = InventoryClient

-- Error codes
local NO_EQUIPS = "No equips are allowed in this inventory!"
local MAX_EQUIPS = "Max equips reached!"
local SAME_EQUIP = "Same equip used!"
local NO_INVS_EXIST = "No inventories exist yet!"
local MAX_INVENTORY = "Inventory is full!"
local NO_ITEM_EXISTS = "No item exists with requested params!"
local CANNOT_UNEQUIP_DEFAULT = "Cannot unequip the default equipped item!"

-- Debug warning helper function
function debugWarn(message)
	if script.Parent:GetAttribute("debugEnabled") then
		warn("[CLIENT] " .. message)
	end
end

if script.Parent:GetAttribute("debugEnabled") and script.Parent:GetAttribute("hasBeenWarned") == false then
	script.Parent:SetAttribute("hasBeenWarned", true)
	debugWarn("Debug mode for this module can cause tons of warnings or errors to pop up, and many of these are normal, only use if needed.")
end

function InventoryClient:GetItemAmount(item) -- Returns the items amount
	return item.Tags.Amount ~= nil and item.Tags.Amount or 1
end

function InventoryClient:IsFull(inv)
	local currentItemCount = 0
	for _, currentItem in pairs(inv.Items) do
		currentItemCount += inv:GetItemAmount(currentItem)
	end

	return currentItemCount >= inv.MaxItems
end

function InventoryClient:GetAmount(inv)
	local total = 0
	for _, item in inv.Items do
		total += inv:GetItemAmount(item)
	end
	return total
end

function InventoryClient:GetAmountMatchName(inv, name)
	local total = 0
	for _, item in inv.Items do
		if item.Name == name then
			total += inv:GetItemAmount(item)
		end
	end
	return total
end

function InventoryClient:GetAmountOfItemById(inv, itemId)
	local item = inv:GetItemById(itemId)
	return item ~= NO_ITEM_EXISTS and inv:GetItemAmount(itemId) or 0
end

function InventoryClient:IsItemEquipped(inv, itemId)
	if not inv.UsesEquips then
		debugWarn(NO_EQUIPS)
		return NO_EQUIPS
	end

	return table.find(inv.Equipped, itemId) ~= nil
end

function InventoryClient:GetItemById(inv, itemId)
	if not inv.Items[itemId] then debugWarn(NO_ITEM_EXISTS) end
	return inv.Items[itemId] or NO_ITEM_EXISTS
end

function InventoryClient:GetIdByName(inv, name)
	for key, item in inv.Items do
		if item.Name == name then
			return key
		end
	end

	debugWarn(NO_ITEM_EXISTS)
	return NO_ITEM_EXISTS
end

function InventoryClient:GetIdByNameAndTags(inv, name, tags)
	for key, item in inv.Items do
		if item.Name == name then
			local sameTags = true
			for key, value in pairs(tags) do
				if key ~= "Amount" and item.Tags[key] ~= value then
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

return InventoryClient
