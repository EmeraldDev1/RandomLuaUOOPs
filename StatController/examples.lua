return function(colorSchemes, Process)
	-- Effects
	-- Boots
	Process.newEffect("RUNNING_BOOTS", "Running Shoes", colorSchemes.Red, 1, {
		Process.addVariable("Cut_Speed", "Multi", 0.2),
		Process.addVariable("Walkspeed", "Add", 8),
		Process.addVariable("Jumppower", "Add", 12),
	})

	Process.newEffect("WORK_BOOTS", "Work Boots", colorSchemes.Yellow, 1, {
		Process.addVariable("Cut_Speed", "Multi", 0.5),
		Process.addVariable("Walkspeed", "Add", 4),
		Process.addVariable("Jumppower", "Add", -4),
		Process.addVariable("Explosive", "Add", 1, colorSchemes.Yellow),
	})

	-- Backpacks
	Process.newEffect("FOLDER_BACKPACK", "Folder", colorSchemes.Yellow, 1, {
		Process.addVariable("Capacity", "Add", 3),
		Process.addVariable("Cut_Speed", "Multi", -0.05),
	})

	Process.newEffect("BRIEFCASE_BACKPACK", "Briefcase", colorSchemes.Grey, 1, {
		Process.addVariable("Capacity", "Add", 15),
		Process.addVariable("Cut_Speed", "Multi", -0.1),
		Process.addVariable("Walkspeed", "Add", -4),
	})

	-- Tools
	Process.newEffect("EXACTO_KNIFE_TOOL", "Exacto Knife", colorSchemes.Red, 1, {
		Process.addVariable("Cut_Speed", "Multi", 0.2),
		Process.addVariable("Damage", "Add", 1),
		Process.addVariable("Bleed", "Add", 2, colorSchemes.Red),
	})

	Process.newEffect("SAW_TOOL", "Saw", colorSchemes.Red, 1, {
		Process.addVariable("Cut_Speed", "Multi", 0.6),
		Process.addVariable("Damage", "Add", 3),
		Process.addVariable("Critical", "Add", 0.5, colorSchemes.Yellow),
		Process.addVariable("Bleed", "Add", 4, colorSchemes.Red),
		Process.addTrigger("PLAYER_PAINT_CUT", colorSchemes.Yellow, {
			Process.addAttribute("Damage", "MaxHP", 0.15),
			Process.addAttribute("Roll", 10, {
				{{1,2}, Process.addAttribute("Heal", "HP", {"Count_Bleed", "Divide", 2})},
				{{3,4}, Process.addAttribute("Heal", "MaxHP", 0.15)},
				{{5,10}, Process.addAttribute("Spend", "Energy", 4)},
			})
		}),
	})

	Process.newEffect("ADRENALINE", "Adrenaline", colorSchemes.Blue, 10, {
		Process.addVariable("Cut_Speed", "Multi", 0.2),
		Process.addVariable("Walkspeed", "Multi", 0.2),
		Process.addVariable("Damage", "Multi", 0.2),
		Process.addTrigger("PLAYER_PAINT_CUT", colorSchemes.Red, {
			Process.addAttribute("Potency", -1, 0),
		}),
	})

	-- Other
	Process.newEffect("PAINT_STREAK", "Paint Streak", colorSchemes.Green, 100, {
		Process.addVariable("Cut_Speed", "Multi", 0.01),
		Process.addVariable("Eat_Speed", "Multi", 0.01),
		Process.addTrigger("PLAYER_PAINT_CUT", colorSchemes.Green, {
			Process.addAttribute("Potency", 1, 5),
		}),
	})

	Process.newEffect("ASBESTOS", "Asbestos Poisoning", colorSchemes.Yellow, 10, {
		Process.addVariable("Bleed", "Add", 2, colorSchemes.Red),
		Process.addVariable("Cut_Speed", "Multi", -0.02),
		Process.addVariable("Eat_Speed", "Multi", -0.02),
	})

	Process.newEffect("PLAIN_BULLET_AMMO", "Plain Bullet", colorSchemes.Grey, 1000, {
		Process.addTrigger("PASSIVE", colorSchemes.Passive, {
			Process.addAttribute("Note", "Ammo is unaffected by Damage buffs"),
		}),
		
		Process.addTrigger("AMMO_HIT", colorSchemes.Green, {
			Process.addAttribute("Coin", {
				Process.addAttribute("Damage", "HP", 2, "Paint Tile"),
				Process.addAttribute("Damage", "HP", 1, "Paint Tile"),
			}),
		}),
	})

	Process.newEffect("SHOTGUN_SLUG_AMMO", "Shotgun Slug", colorSchemes.Grey, 1000, {
		Process.addTrigger("PASSIVE", colorSchemes.Passive, {
			Process.addAttribute("Note", "Ammo is unaffected by Damage buffs"),
		}),
		
		Process.addTrigger("AMMO_HIT", colorSchemes.Green, {
			Process.addAttribute("Damage", "HP", 1, "Paint Tile"),
		}),
	})

	Process.newEffect("MAGIC_BULLET_AMMO", "Magic Bullet", colorSchemes.Blue, 7, {
		Process.addTrigger("PASSIVE", colorSchemes.Passive, {
			Process.addAttribute("Note", "Ammo is unaffected by Damage buffs"),
		}),
		
		Process.addTrigger("PASSIVE", colorSchemes.Passive, {
			Process.addAttribute("Note", "A Potency of 7 will kill the owner of this effect"),
		}),
		
		Process.addTrigger("AMMO_HIT", colorSchemes.Green, {
			Process.addAttribute("Potency_Count", {
				{{1, 2}, Process.addAttribute("Damage", "MaxHP", 0.05, "Paint Tile")},
				{{3, 4}, Process.addAttribute("Damage", "MaxHP", 0.15, "Paint Tile")},
				{{5, 5}, Process.addAttribute("Damage", "MaxHP", 0.25, "Paint Tile")},
				{{6, 6}, Process.addAttribute("Damage", "MaxHP", 0.5, "Paint Tile")},
				{{7, 7}, Process.addAttribute("Damage", "MaxHP", 1, "Paint Tile")},
			}),
			Process.addAttribute("Potency", 1),
		}),
	})
	
	Process.newEffect("CELESTIAL_RETRIBUTION", "Celestial Retribution", colorSchemes.Blue, 21, {
		Process.addTrigger("PASSIVE", colorSchemes.Passive, {
			Process.addAttribute("Note", "If this effect is removed, the holder will be killed"),
		}),
		
		Process.addTrigger("AMMO_HIT", colorSchemes.RED, {
			Process.addAttribute("Damage", "MaxHP", 0.05, "Paint Tile"),
			Process.addAttribute("Potency", -1),
		})
	})

	Process.newEffect("CELESTIAL_AMMO", "Ammo of the Celestial Front", colorSchemes.Blue, 9, {
		Process.addTrigger("PASSIVE", colorSchemes.Passive, {
			Process.addAttribute("Note", "Ammo is unaffected by Damage buffs"),
		}),
		
		Process.addTrigger("AMMO_HIT", colorSchemes.Green, {
			Process.addAttribute("Potency_Count", {
				{{1, 8}, Process.addAttribute("Damage", "MaxHP", 0.1, "Paint Tile")},
				{{9}, Process.addAttribute("Damage", "MaxHP", 0.15, "Paint Tile")},
			}),
			Process.addAttribute("Potency", 1),
		}),
		
		Process.addTrigger("PAINT_DEATH", colorSchemes.RED, {
			Process.addAttribute("Potency", 5),
		}),
		
		Process.addTrigger("AMMO_HIT", colorSchemes.Green, {
			Process.addAttribute("If_Potency", {9}, {
				Process.addAttribute("Potency", 1, nil, "Set"),
				Process.addAttribute("Effect", "CELESTIAL_RETRIBUTION", 7),
			}),
		}),
	})
end
