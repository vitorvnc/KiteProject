extends Node

const ICON_PATH = "res://Textures/Items/Upgrades/"
const WEAPON_PATH = "res://Textures/Items/Weapons/"

const UPGRADES = {
	"sphereatk1":{
		"icon": WEAPON_PATH + "ice_spear.png",
		"displayname": "Sonic Boom",
		"details": "A wind wave is thrown at a random enemy",
		"level": "Level: 1",
		"prerequisite":[],
		"type": "Weapon"
	},
	"sphereatk2":{
		"icon": WEAPON_PATH + "ice_spear.png",
		"displayname": "Sonic Boom",
		"details": "An additional wind wave is thrown",
		"level": "Level: 2",
		"prerequisite":["sphereatk"],
		"type": "Weapon"
	},
	"sphereatk3":{
		"icon": WEAPON_PATH + "ice_spear.png",
		"displayname": "Sonic Boom",
		"details": "An additional wind wave is thrown",
		"level": "Level: 3",
		"prerequisite":["sphereatk2"],
		"type": "Weapon"
	},
	"sphereatk4": {
		"icon": WEAPON_PATH + "ice_spear.png",
		"displayname": "Sonic Boom",
		"details": "An additional wind wave is thrown",
		"level": "Level: 4",
		"prerequisite": ["sphereatk3"],
		"type": "weapon"
	},
	"whipatk1": {
		"icon": WEAPON_PATH + "javelin_3_new_attack.png",
		"displayname": "Wind blow",
		"details": "A horizontal wind blow that pushes the enemies",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"whipatk2": {
		"icon": WEAPON_PATH + "javelin_3_new_attack.png",
		"displayname": "Wind blow",
		"details": "The wind will blow in two direction at once",
		"level": "Level: 2",
		"prerequisite": ["whipatk1"],
		"type": "weapon"
	},
	"whipatk3": {
		"icon": WEAPON_PATH + "javelin_3_new_attack.png",
		"displayname": "Wind blow",
		"details": "The wind blow triggers an additional time",
		"level": "Level: 3",
		"prerequisite": ["whipatk2"],
		"type": "weapon"
	},
	"whipatk4": {
		"icon": WEAPON_PATH + "javelin_3_new_attack.png",
		"displayname": "Wind blow",
		"details": "The wind blow triggers an additional time",
		"level": "Level: 4",
		"prerequisite": ["whipatk3"],
		"type": "weapon"
	},
	"waveatk1": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "PSY Wave",
		"details": "A psyonic wave that pushes enemies around",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"waveatk2": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "PSY Wave",
		"details": "Triggers an addiotional psy wave",
		"level": "Level: 2",
		"prerequisite": ["waveatk1"],
		"type": "weapon"
	},
	"tornado3": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "PSY Wave",
		"details": "Area increased",
		"level": "Level: 3",
		"prerequisite": ["waveatk2"],
		"type": "weapon"
	},
	"tornado4": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "PSY Wave",
		"details": "Knockback increased",
		"level": "Level: 4",
		"prerequisite": ["waveatk3"],
		"type": "weapon"
	},
	"armor1": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Armor",
		"details": "Reduces Damage By 1 point",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"armor2": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Armor",
		"details": "Reduces Damage By an additional 1 point",
		"level": "Level: 2",
		"prerequisite": ["armor1"],
		"type": "upgrade"
	},
	"armor3": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Armor",
		"details": "Reduces Damage By an additional 1 point",
		"level": "Level: 3",
		"prerequisite": ["armor2"],
		"type": "upgrade"
	},
	"armor4": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Armor",
		"details": "Reduces Damage By an additional 1 point",
		"level": "Level: 4",
		"prerequisite": ["armor3"],
		"type": "upgrade"
	},
	"speed1": {
		"icon": ICON_PATH + "boots_4_green.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased by 50% of base speed",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"speed2": {
		"icon": ICON_PATH + "boots_4_green.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased by an additional 50% of base speed",
		"level": "Level: 2",
		"prerequisite": ["speed1"],
		"type": "upgrade"
	},
	"speed3": {
		"icon": ICON_PATH + "boots_4_green.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased by an additional 50% of base speed",
		"level": "Level: 3",
		"prerequisite": ["speed2"],
		"type": "upgrade"
	},
	"speed4": {
		"icon": ICON_PATH + "boots_4_green.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased an additional 50% of base speed",
		"level": "Level: 4",
		"prerequisite": ["speed3"],
		"type": "upgrade"
	},
	"tome1": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"tome2": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 2",
		"prerequisite": ["tome1"],
		"type": "upgrade"
	},
	"tome3": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 3",
		"prerequisite": ["tome2"],
		"type": "upgrade"
	},
	"tome4": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 4",
		"prerequisite": ["tome3"],
		"type": "upgrade"
	},
	"scroll1": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"scroll2": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 2",
		"prerequisite": ["scroll1"],
		"type": "upgrade"
	},
	"scroll3": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 3",
		"prerequisite": ["scroll2"],
		"type": "upgrade"
	},
	"scroll4": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 4",
		"prerequisite": ["scroll3"],
		"type": "upgrade"
	},
	"ring1": {
		"icon": ICON_PATH + "urand_mage.png",
		"displayname": "Ring",
		"details": "Your spells now spawn 1 more additional attack",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"ring2": {
		"icon": ICON_PATH + "urand_mage.png",
		"displayname": "Ring",
		"details": "Your spells now spawn an additional attack",
		"level": "Level: 2",
		"prerequisite": ["ring1"],
		"type": "upgrade"
	},
	"food": {
		"icon": ICON_PATH + "chunk.png",
		"displayname": "Food",
		"details": "Heals you for 20 health",
		"level": "N/A",
		"prerequisite": [],
		"type": "item"
	}
}
