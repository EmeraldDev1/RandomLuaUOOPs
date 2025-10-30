--[[

This is how inventorydefaults are generated, its a subclass that should only be accessed from the Inventory module only.
You should only change this if you understand what your doing, but realistically leave the default values alone.

]]

local InventoryDefaults = {}
InventoryDefaults.__index = InventoryDefaults

local Defaults = {}

function InventoryDefaults.new(inventoryName, maxItems, dontMergeItems, maxEquips, usesEquips, defaultItems, defaultEquip, usesDefault, dontUseAmounts)
	local self = setmetatable({
		MaxItems = maxItems ~= nil and maxItems or math.huge,
		DontMergeItems = dontMergeItems ~= nil and dontMergeItems or false,
		MaxEquips = maxEquips ~= nil and maxEquips or 1,
		UsesEquips = usesEquips ~= nil and usesEquips or false,
		DefaultItems = defaultItems ~= nil and defaultItems or {},
		DefaultEquip = defaultEquip ~= nil and defaultEquip or 1,
		UsesDefault = usesDefault ~= nil and usesDefault or false,
		DontUseAmounts = dontUseAmounts ~= nil and dontUseAmounts or false,
	}, InventoryDefaults)
	
	Defaults[inventoryName] = self

	return self
end

function InventoryDefaults.getDefaults(inventoryName)
	if not Defaults[inventoryName] then
		warn("That doesnt exist for an InventoryDefault!")
		return nil
	end
	
	return Defaults[inventoryName]
end

return InventoryDefaults
