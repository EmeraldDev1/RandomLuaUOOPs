return function(Process)
	local MathsModule = require(script.Parent.Maths)(Process)
	
	--[[
	
	Variables for Math/Stats
	
	]]--

	Process.newVariable("Walkspeed", "Walkspeed", 16) -- Walkspeed of player
	Process.newVariable("Jumppower", "Jumppower", 50) -- Jumppower of player

	Process.newVariable("Cut_Speed", "Cut Speed", 1) -- Speed mult of cutting
	Process.newVariable("Damage", "Damage", 1) -- Damage per click
	
	Process.newVariable("Ammo_Damage", "Ammo Damage", 1) -- Damage per Ammo

	Process.newVariable("Capacity", "Capacity", 1) -- Total paint capacity

	Process.newVariable("Bleed", "Bleed", 0) -- Damage per cut
	Process.newVariable("Poison", "Poison", 0) -- Damage per every 1s
	Process.newVariable("Regen", "Regen", 0) -- Heal per every 3s

	Process.newVariable("Explosive", "Explosive", 0) -- Chance of small explosion on cut
	Process.newVariable("Upgrading", "Upgrading", 0) -- Chance of upgrading paint on cut
	Process.newVariable("Duplication", "Duplication", 0) -- Chance of duplicating paint on cut
	Process.newVariable("Critical", "Critical", 0) -- Chance of double damage output on cut
	
	--[[
	
	Varibles for Triggers
	
	]]--
	
	-- Variables - Player
	Process.newVariable("PLAYER_DEATH", "[On Death]", 0, true)
	Process.newVariable("PLAYER_PAINT_CUT", "[On Cut]", 0, true)

	-- Variables - Paint
	Process.newVariable("ATTRIBUTE_PAINT_ADDED", "[On Add]", 0, true)
	Process.newVariable("PAINT_HIT", "[On Hit]", 0, true)
	Process.newVariable("PAINT_HEALTH_THRESHOLD", "[At {AMT}% Health]", 50, true)
	Process.newVariable("PAINT_EXPLODE_HIT", "[On Paint Explosion]", 0, true)
	Process.newVariable("PAINT_DEATH", "[On Destroy]", 0, true)

	Process.newVariable("AMMO_HIT", "[On Ammo Hit]", 0, true)

	-- Variables - All
	Process.newVariable("PASSIVE", "[Passive]", 0, true)
	
	--[[
	
	Attributes for Everyone
	
	]]--

	-- Damage
	local Damage = Process.newAttribute("Damage")
	Damage:onDisplayRequest(function(...)
		local DamageType, Math, TargetType = ...
		
		if typeof(Math) ~= "number" then
			return `Deal Damage equal to {MathsModule.getDisplayString(Math)} to {TargetType or "Self"}`
		else
			if string.lower(DamageType) == "maxhp" then
				return `Deal {math.round(Math * 100)}% Max HP Damage to {TargetType or "Self"}`
			else
				return `Deal {Math} Damage to {TargetType or "Self"}`
			end
		end
	end)
	
	Damage:onTriggerAttribute(function(Entity: any, TriggeredBy: any, effect_id, ...)
		local DamageType, Math, TargetType = ...
		local UpdateEntity = TargetType and TriggeredBy or Entity
		
		if typeof(UpdateEntity) == "Instance" then
			if UpdateEntity:IsA("Player") then
				local Humanoid = UpdateEntity.Character and UpdateEntity.Character:FindFirstChild("Humanoid")
				if Humanoid then
					local MaxHP = Humanoid.MaxHealth
					local DamageAmount = (typeof(Math) ~= "number" and MathsModule.evaluateMathExpression(Math, UpdateEntity))
						or (string.lower(DamageType) == "maxhp") and MaxHP * Math or Math
					Humanoid.Health = math.max(Humanoid.Health - DamageAmount, 0)
				end
			elseif UpdateEntity:IsA("BasePart") then
				local Health = UpdateEntity:GetAttribute("Health")
				if Health then
					local Total = UpdateEntity:GetAttribute("Total")
					local DamageAmount = (typeof(Math) ~= "number" and MathsModule.evaluateMathExpression(Math, UpdateEntity))
						or (string.lower(DamageType) == "maxhp") and Total * Math or Math
					UpdateEntity:SetAttribute("Health", math.max(Health - DamageAmount, 1))
				end
			end
		end
	end)

	-- Heal
	local Heal = Process.newAttribute("Heal")
	Heal:onDisplayRequest(function(...)
		local HealType, Math, TargetType = ...
		
		if typeof(Math) ~= "number" then
			return `Heal HP equal to {MathsModule.getDisplayString(Math)} to {TargetType or "Self"}`
		else
			if string.lower(HealType) == "maxhp" then
				return `Heal {math.round(Math * 100)}% Max HP to {TargetType or "Self"}`
			else
				return `Heal {Math} to {TargetType or "Self"}`
			end
		end
	end)
	
	Heal:onTriggerAttribute(function(Entity: any, TriggeredBy: any, effect_id, ...)
		local HealType, Math, TargetType = ...
		local UpdateEntity = TargetType and TriggeredBy or Entity
		
		if typeof(UpdateEntity) == "Instance" then
			if UpdateEntity:IsA("Player") then
				local Humanoid = UpdateEntity.Character and UpdateEntity.Character:FindFirstChild("Humanoid")
				if Humanoid then
					local MaxHP = Humanoid.MaxHealth
					local HealAmount = (typeof(Math) ~= "number" and MathsModule.evaluateMathExpression(Math, UpdateEntity))
						or (string.lower(HealType) == "maxhp") and MaxHP * Math or Math
					Humanoid.Health += HealAmount
				end
			elseif UpdateEntity:IsA("BasePart") then
				local Health = UpdateEntity:GetAttribute("Health")
				if Health then
					local Total = UpdateEntity:GetAttribute("Total")
					local HealAmount = (typeof(Math) ~= "number" and MathsModule.evaluateMathExpression(Math, UpdateEntity))
						or (string.lower(HealType) == "maxhp") and Total * Math or Math
					UpdateEntity:SetAttribute("Health", math.min(Health + HealAmount, Total))
				end
			end
		end
	end)

	-- Spend
	local Spend = Process.newAttribute("Spend")
	Spend:onDisplayRequest(function(...)
		local Type, Count = ...
		return "Spend " .. Count .. " " .. Type
	end)
	
	Spend:onTriggerAttribute(function(Entity: any, TriggeredBy: any, effect_id, ...)
		local Type, Count = ...
		if typeof(Entity) == "Instance" and Entity.Parent == game:GetService("Players") and _G.Players[Entity].Profile.Data[Type] ~= nil then
			_G.Players[Entity].Profile.Data[Type] -= Count
		end
	end)

	-- Gain
	local Gain = Process.newAttribute("Gain")
	Gain:onDisplayRequest(function(...)
		local Type, Count = ...
		return "Gain " .. Count .. " " .. Type
	end)
	
	Gain:onTriggerAttribute(function(Entity: any, TriggeredBy: any, effect_id, ...)
		local Type, Count = ...
		if typeof(Entity) == "Instance" and Entity.Parent == game:GetService("Players") and _G.Players[Entity].Profile.Data[Type] ~= nil then
			_G.Players[Entity].Profile.Data[Type] += Count
		end
	end)

	-- Remove
	local Remove = Process.newAttribute("Remove")
	Remove:onDisplayRequest(function(...)
		return "Remove this Effect"
	end)
	
	Remove:onTriggerAttribute(function(Entity: any, TriggeredBy: any, effect_id, ...)
		Process.pushEffect(effect_id, 0, 0, "Remove", Entity)
	end)

	-- Effect
	local Effect = Process.newAttribute("Effect")
	Effect:onDisplayRequest(function(...)
		local effect_id, Potency, Duration, Target = ...
		return "Inflict " .. Potency .. " [" .. Process.getEffect(effect_id).Name .. "] to " .. (Target or "Self")
	end)
	
	Effect:onTriggerAttribute(function(Entity: any, TriggeredBy: any, effect_id, ...)
		local effect_id, Potency, Duration, Target = ...
		Process.pushEffect(effect_id, Potency, Duration, nil, Target and TriggeredBy or Entity)
	end)

	-- Potency
	local Potency = Process.newAttribute("Potency")
	Potency:onDisplayRequest(function(...)
		local Count, Duration, Type = ...
		Duration = Duration or 0
		if Type == "Set" then
			return "Set Potency of this Effect to " .. Count
		else
			return (Count >= 0 and "Add " or "Remove ") .. Count .. " Potency to this Effect"
		end
	end)
	
	Potency:onTriggerAttribute(function(Entity: any, TriggeredBy: any, effect_id, ...)
		local Count, Duration, Type = ...
		Duration = Duration or 0
		Process.pushEffect(effect_id, Count, Duration, Type or nil, Entity)
	end)

	-- Potency_Count
	local Potency_Count = Process.newAttribute("Potency_Count")
	Potency_Count:onDisplayRequest(function(...)
		local Table = ...
		local str = `If potency is:\n`
		for i, Data in Table do
			local Potency, Effects = Data[1], (function()
				local effectsTable = table.clone(Data)
				table.remove(effectsTable, 1)
				return effectsTable
			end)()
			local potStr = Potency[1] ~= Potency[2] and Potency[2] ~= nil and Potency[1] .. "-" .. Potency[2] or Potency[1]
			for _, Effect in Effects do
				local effect_id = Effect.getAttributeId()
				local processString = Process.getAttributeText(effect_id, Effect.getVariables())
				str = str .. `[{potStr}]: {processString}{i ~= #Table and "\n" or ""}`
			end
		end
		return str
	end)
	
	Potency_Count:onTriggerAttribute(function(Entity: any, TriggeredBy: any, effect_id, ...)
		local Table = ...
		local EffData = Process.getEffectStats(effect_id, Entity)
		for _, Data in Table do
			local Dice, Effects = Data[1], (function()
				local effectsTable = table.clone(Data)
				table.remove(effectsTable, 1)
				return effectsTable
			end)()
			local Min, Max = table.unpack(Dice)
			if Min <= EffData.Potency and Max >= EffData.Potency then
				for _, Effect in Effects do
					Process.runCustomTrigger(effect_id, Effect, Entity)
				end
			end
		end
	end)
	
	-- If_Potency
	local If_Potency = Process.newAttribute("If_Potency")
	If_Potency:onDisplayRequest(function(...)
		local Potency, Attributes = ...
		local potStr = Potency[1] ~= Potency[2] and Potency[2] ~= nil and Potency[1] .. "-" .. Potency[2] or Potency[1]
		
		local str = `If potency is [{potStr}]:\n`
		for i, Effect in Attributes do
			local effect_id = Effect.getAttributeId()
			local processString = Process.getAttributeText(effect_id, Effect.getVariables())
			str = str .. `{processString}{i ~= #Attributes and "\n" or ""}`
		end
		return str
	end)

	If_Potency:onTriggerAttribute(function(Entity: any, TriggeredBy: any, effect_id, ...)
		local Potency, Attributes = ...
		local EffData = Process.getEffectStats(effect_id, Entity)
		local Min, Max = table.unpack(Potency)
		
		for _, Effect in Attributes do
			if Min <= EffData.Potency and Max >= EffData.Potency then
				Process.runCustomTrigger(effect_id, Effect, Entity)
			end
		end
	end)

	-- Coin
	local Coin = Process.newAttribute("Coin")
	Coin:onDisplayRequest(function(...)
		local Heads, Tails = table.unpack(...)
		local HeadsStr = Process.getAttributeText(Heads.getAttributeId(), Heads.getVariables())
		local TailsStr = Process.getAttributeText(Tails.getAttributeId(), Tails.getVariables())
		return `Flip a Coin:\nHeads: {HeadsStr}\nTails: {TailsStr}`
	end)
	
	Coin:onTriggerAttribute(function(Entity: any, TriggeredBy: any, effect_id, ...)
		local Table = ...
		Process.runCustomTrigger(effect_id, Table[math.random(1, 2)], Entity)
	end)

	-- Roll
	local Roll = Process.newAttribute("Roll")
	Roll:onDisplayRequest(function(...)
		local Dice, Table = ...
		local str = `Roll a D{Dice}:\n`
		for i, Data in Table do
			local Dice, Effects = Data[1], (function()
				local effectsTable = table.clone(Data)
				table.remove(effectsTable, 1)
				return effectsTable
			end)()
			local diceStr = Dice[1] ~= Dice[2] and Dice[2] ~= nil and Dice[1] .. "-" .. Dice[2] or Dice[1]
			for _, Effect in Effects do
				local effect_id = Effect.getAttributeId()
				local processString = Process.getAttributeText(effect_id, Effect.getVariables())
				str = str .. `[{diceStr}]: {processString}{i ~= #Table and "\n" or ""}`
			end
		end
		return str
	end)
	
	Roll:onTriggerAttribute(function(Entity: any, TriggeredBy: any, effect_id, ...)
		local Dice, Table = ...
		local rng = math.random(1, Dice)
		for _, Data in Table do
			local Dice, Effects = Data[1], (function()
				local effectsTable = table.clone(Data)
				table.remove(effectsTable, 1)
				return effectsTable
			end)()
			local Min, Max = table.unpack(Dice)
			if Min <= rng and Max >= rng then
				for _, Effect in Effects do
					Process.runCustomTrigger(effect_id, Effect, Entity)
				end
			end
		end
	end)

	-- Note
	local Note = Process.newAttribute("Note")
	Note:onDisplayRequest(function(...)
		return ... or "Nothing"
	end)
	
	Note:onTriggerAttribute(function()
		return
	end)
end
