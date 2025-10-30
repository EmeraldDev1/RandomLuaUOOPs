--[[

Name: Maths

Information: Helper-class module used for converting string tables to a mathmatical function.
Used normally for displays or for calculating stuff for effects

Last Revision 7/6/2025

]]--

return function(Process)
	local Maths = {}
	
	function Maths.resolveOperand(token: any, Entity: Instance): number
		if type(token) == "number" then
			return token
		elseif type(token) == "string" then
			if token:find("Count_") then
				local effect = string.sub(token, 7)
				local stats = Process.getEffectStats(effect, Entity)
				return stats and stats.Potency or 0

			elseif token:find("Stat_") then
				local stat = string.sub(token, 6)
				return Process.getVariableValue(stat, Entity)

			elseif token:find("Attribute_") then
				local attr = string.sub(token, 10)
				return Entity:GetAttribute(attr) or 0
			end
		end
		return 0
	end
	
	function Maths.evaluateMathExpression(mathTokens: {any}, Entity: Instance): number
		if not mathTokens or #mathTokens < 1 then return 0 end

		local result = Maths.resolveOperand(mathTokens[1], Entity)

		local i = 2
		while i <= #mathTokens do
			local operator = mathTokens[i]
			local nextOperand = Maths.resolveOperand(mathTokens[i + 1], Entity)

			if operator == "Add" then
				result += nextOperand
			elseif operator == "Subtract" then
				result -= nextOperand
			elseif operator == "Multiply" then
				result *= nextOperand
			elseif operator == "Divide" then
				result /= (nextOperand ~= 0 and nextOperand or 1)
			end

			i += 2
		end

		return result
	end
	
	function Maths.getDisplayString(mathTokens: {any}): string
		local parts = {}

		for i, token in ipairs(mathTokens) do
			if type(token) == "number" then
				table.insert(parts, tostring(token))
			elseif type(token) == "string" then
				if token:find("Count_") then
					table.insert(parts, string.sub(token, 7) .. " Count")
				elseif token:find("Stat_") then
					table.insert(parts, string.sub(token, 6))
				elseif token:find("Attribute_") then
					table.insert(parts, string.sub(token, 10))
				elseif token == "Add" then
					table.insert(parts, "+")
				elseif token == "Subtract" then
					table.insert(parts, "-")
				elseif token == "Multiply" then
					table.insert(parts, "×")
				elseif token == "Divide" then
					table.insert(parts, "÷")
				else
					table.insert(parts, token)
				end
			end
		end

		return table.concat(parts, " ")
	end

	return Maths
end

--{"Count_Bleed", "Multiply", "Stat_CritChance", "Divide", 8}
--Bleed Count x Crit Chance / 8
