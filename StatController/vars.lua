return {
	["Damage"] = {
		{"DamageType", "string", {"MaxHP", "HP"}},
		{"Math", "string"}, -- Can also be math expression
		{"TargetType", "string"},
	},

	["Heal"] = {
		{"HealType", "string", {"MaxHP", "HP"}},
		{"Math", "string"},
		{"TargetType", "string"},
	},

	["Spend"] = {
		{"Type", "string"}, -- Resource type
		{"Count", "number"},
	},

	["Gain"] = {
		{"Type", "string"},
		{"Count", "number"},
	},

	["Remove"] = {
		-- No parameters
	},

	["Effect"] = {
		{"effect_id", "string"},
		{"Potency", "number"},
		{"Duration", "number"},
		{"Target", "string"},
	},

	["Potency"] = {
		{"Count", "number"},
		{"Duration", "number"},
		{"Type", "string", {"Set", "Upd"}}, -- Optional, defaults to add/remove
	},

	["Potency_Count"] = {
		{"Attributes", "numberAddons"}, -- Array of {Potency_Range, Effects...}
	},

	["If_Potency"] = {
		{"Potency", "numberAddons"}, -- {Min, Max}
		{"Attributes", "attributeArray"},
	},

	["Coin"] = {
		{"Heads", "attributeArray"},
		{"Tails", "attributeArray"},
	},

	["Roll"] = {
		{"Dice", "number"},
		{"Attributes", "numberAddons"},
	},

	["Note"] = {
		{"Text", "string"},
	},
}
