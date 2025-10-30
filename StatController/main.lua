--[[

Name: StatController

Information: Manages entities effects, items, stats, and more.
Its also responsible for storing this information, and generating it.

Last Revision 7/8/2025

]]--

local Process = {}

Process.colorSchemes = {
	Passive = Color3.fromRGB(135, 253, 255),
	Green = Color3.fromRGB(135, 255, 135),
	Blue = Color3.fromRGB(135, 135, 255),
	Yellow = Color3.fromRGB(255, 255, 135),
	Red = Color3.fromRGB(255, 135, 135),
	Bad = Color3.fromRGB(66, 13, 13),

	Grey = Color3.fromRGB(135, 135, 135),
}

-- [key] = {DisplayString, DefaultValue}
-- Basic variable that effects certain statistics, x = y.
local Variables: {[string]: {any}} = {}

-- [key] = {DisplayString, MaxPotency, Variables, Color}
-- The top level of potion and item effects. Holds all the data.
local Effects: {[string]: {any}} = {}

-- [key] = {DisplayString, InvokeAttribute}
-- Functions to run when triggered, do x to x.
local Attributes: {[string]: {any}} = {}
Attributes.__index = Attributes

--[[

Entity Managment

]]--

local Entities = {}
local Callbacks = {}

function getEntityStorage(Entity: any)
	if Entities[Entity] == nil then
		Entities[Entity] = {}
		
		Entity.AncestryChanged:Connect(function(_, parent)
			if not parent then
				Entities[Entity] = nil
				Callbacks[Entity] = nil
			end
		end)
	end
	
	return Entities[Entity]
end

function processEntityStorage(Entity: any)
	getEntityStorage(Entity)
	
	local Folder = Entity:FindFirstChild("Effects")
	if not Folder then
		Folder = Instance.new("Folder", Entity)
		Folder.Name = "Effects"
	end

	for effectName, effectData in Entities[Entity] do
		local pot, dur = table.unpack(effectData)
		local eff = Folder:FindFirstChild(effectName)
		if not eff then
			eff = Instance.new("NumberValue")
		end

		eff.Name = effectName
		eff.Value = pot
		eff:SetAttribute("Duration", dur)
		eff.Parent = Folder
	end

	for _, instance in Folder:GetChildren() do
		if not Entities[Entity][instance.Name] then
			instance:Destroy()
		end
	end
end

--[[

Variable and Trigger Managment

]]--

function Process.newVariable(key: string, displayString: string, defaultValue: number, isTrigger: boolean)
	Variables[key] = {displayString, defaultValue, isTrigger or false}
end

function Process.getVariableDisplay(key: string)
	return Variables[key][1]
end

function Process.defaultValue(key: string)
	return Variables[key][2]
end

function Process.isTrigger(key: string)
	return Variables[key][3]
end

function Process.addVariable(key: string, operator: string, value: number)
	return {"Variable", key, operator, value}
end

function Process.addTrigger(key: string, attributes: {any})
	return {"Trigger", key, attributes}
end

function Process.runTrigger(variable_id: string, TriggeredFrom: any, TriggeredBy: any)
	if TriggeredBy == nil then TriggeredBy = TriggeredFrom end
	local entityStorage = getEntityStorage(TriggeredFrom)

	for effect_id, _ in entityStorage do
		local displayString, maxPotency, variables, color = table.unpack(Effects[effect_id])

		for _, variableData in variables do
			local _, variableKey, attributes = table.unpack(variableData)
			if variableKey == variable_id then
				for _, att in attributes do
					Attributes[att.getAttributeId()].triggerFunction(TriggeredFrom, TriggeredBy, effect_id, att.getVariables())
				end
			end
		end
	end
end

function Process.computeEntityStat(Entity: any, key: string)
	local entityData = getEntityStorage(Entity)
	local currentValue = tonumber(Variables[key][2])

	local mathList = {
		Add = 0,
		Multi = 0,
	}

	for effect_id, effectData in entityData do
		local _, _, variables = table.unpack(Effects[effect_id])
		
		for _, data in variables do
			if data[1] ~= "Trigger" and data[2] == key and typeof(data[3]) == "number" then
				if data[3] == "Add" then
					mathList.Add += (data[4] * effectData[1])
				elseif data[3] == "Multi" then
					mathList.Multi += (data[4] * effectData[1])
				end
			end
		end
	end

	currentValue += mathList.Add
	currentValue *= 1 + mathList.Multi

	return currentValue
end

--[[

Effect Managment

]]--

function Process.newEffect(key: string, displayString: string, maxPotency: number, variables: {}, color: string|Color3)
	Effects[key] = {displayString, maxPotency, variables, color}
end

function Process.getEffectDisplay(key: string)
	return Effects[key][1]
end

function Process.pushEffectEntity(Entity: any, key: string, potency: number, duration: number, specialTask: string)
	local _, maxPotency = table.unpack(Effects[key])
	local entityStorage = getEntityStorage(Entity)
	
	local function runPush()
		if specialTask and specialTask == "Delete" then
			entityStorage[key] = nil
			return "Removed", 0, 0
		end

		if entityStorage[key] then
			local currentPotency, currentDuration = table.unpack(entityStorage[key])
			if currentPotency + potency < 1 or (currentDuration + duration) - os.clock() < 1 then 
				entityStorage[key] = nil
				return "Removed", 0, 0
			end

			entityStorage[key] = {math.min(potency + currentPotency, maxPotency), currentDuration + duration}
			return "Updated", math.min(potency + currentPotency, maxPotency), (currentDuration + duration) - os.clock()
		else
			if potency == nil or potency < 1 then return end
			if duration == nil or duration < 1 then return end
			entityStorage[key] = {math.min(potency, maxPotency), os.clock() + duration}
			return "Added", potency, duration
		end
	end
	
	local updateReason, potency, duration = runPush()
	if Callbacks[Entity] then
		for _, callback in Callbacks[Entity] do
			callback(updateReason, key, potency, duration)
		end
	end
	
	processEntityStorage(Entity)
end

function Process.onEffectsChange(Entity: any, callback)
	if Callbacks[Entity] == nil then Callbacks[Entity] = {}; end
	table.insert(Callbacks[Entity], callback)
	
	return {Disconnect = function()
		table.remove(Callbacks[Entity], table.find(Callbacks[Entity], callback))
		if #Callbacks[Entity] == 0 then Callbacks[Entity] = nil end
	end,}
end

function Process.getEffect(key: string)
	return Effects[key]
end

--[[

Attribute Managment

]]--

function Process.newAttribute(key: string)
	if Attributes[key] then warn("Already existant attribute!" .. key) end

	local self = setmetatable({
		displayFunction = nil,
		triggerFunction = nil,
	}, Attributes)

	Attributes[key] = self
	return self
end

function Attributes:onDisplayRequest(callback)
	self.displayFunction = callback
end

function Attributes:onTriggerAttribute(callback)
	self.triggerFunction = callback
end

function Process.addAttribute(key: string, ...)
	return {"Attribute", key, ...}
end

function Process.getAttributeText(key: string, ...)
	if Attributes[key] == nil then
		warn("Not a valid attribute! " .. key)
		return ""
	end

	return Attributes[key].displayFunction(...)
end

function Process.runAttributeTrigger(key: string, triggerInfo: {any}, Entity: any, TriggeredBy: any)
	if TriggeredBy == nil then TriggeredBy = Entity end
	for _, att in triggerInfo do
		Attributes[att.getAttributeId()].triggerFunction(Entity, TriggeredBy, key, att.getVariables())
	end
end

task.spawn(function()
	require(script.Attributes)(Process)
	for _, v in script.Effs:GetChildren() do
		require(v)(Process.colorSchemes, Process)
	end

	game:GetService("RunService").Heartbeat:Connect(function()
		for Entity, Data in Entities do
			for effectKey, effectData in Data do
				local pot, dur = table.unpack(effectData)
				if dur - os.clock() <= 0 then
					Process.pushEffectEntity(Entity, effectKey, 0, 0, "Delete")
				end
			end
		end
	end)
end)

return Process
