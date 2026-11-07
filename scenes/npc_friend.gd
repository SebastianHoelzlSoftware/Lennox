@tool
extends CharacterBody2D
# Compañero o habitante NPC que puede seguir a un objetivo (el jugador o a otro compañero)
# o permanecer estacionario en su lugar del mundo (`can_follow = false`).
#
# Es un `@tool` script para que al cambiar `character_style` en el Inspector de Godot
# se actualicen inmediatamente los `SpriteFrames` en el editor 2D sin tener que configurar
# animaciones a mano. Soporta todos los estilos de personaje de `res://assets/common/characters/`
# además de `"custom"` (que respeta los `SpriteFrames` asignados manualmente en el editor).

@export_enum(
	"archer",
	"archer_lvl2",
	"archer_lvl3",
	"archer_lvl4",
	"archer_lvl5",
	"archer_lvl6",
	"archer_lvl7",
	"archer_lvl8",
	"archer_lvl9",
	"mage",
	"mage_lvl2",
	"mage_lvl3",
	"mage_lvl4",
	"mage_lvl5",
	"mage_lvl6",
	"mage_lvl7",
	"mage_lvl8",
	"mage_lvl9",
	"base_male",
	"base_male_sword",
	"dino",
	"polar_bear",
	"beholder_lvl1",
	"beholder_lvl2",
	"beholder_lvl3",
	"demon_lvl1",
	"demon_lvl2",
	"demon_lvl3",
	"ent_lvl1",
	"ent_lvl2",
	"ent_lvl3",
	"ghost_lvl1",
	"ghost_lvl2",
	"ghost_lvl3",
	"goblin_lvl1",
	"goblin_lvl2",
	"goblin_lvl3",
	"golem_lvl1",
	"golem_lvl2",
	"golem_lvl3",
	"imp_lvl1",
	"imp_lvl2",
	"imp_lvl3",
	"lich_lvl1",
	"lich_lvl2",
	"lich_lvl3",
	"lizardman_lvl1",
	"lizardman_lvl2",
	"lizardman_lvl3",
	"orc_lvl1",
	"orc_lvl2",
	"orc_lvl3",
	"plant_lvl1",
	"plant_lvl2",
	"plant_lvl3",
	"rat_lvl1",
	"rat_lvl2",
	"rat_lvl3",
	"skeleton_lvl1",
	"skeleton_lvl2",
	"skeleton_lvl3",
	"slime_lvl1",
	"slime_lvl2",
	"slime_lvl3",
	"slime_boss_lvl1",
	"slime_boss_lvl2",
	"slime_boss_lvl3",
	"vampire_lvl1",
	"vampire_lvl2",
	"vampire_lvl3",
	"zombie_lvl1",
	"zombie_lvl2",
	"zombie_lvl3",
	"custom"
)
var character_style: String = "archer":
	set(value):
		character_style = value
		if is_inside_tree():
			_apply_character_style()

@export var can_follow: bool = true
@export var target_path: NodePath
@export var follow_distance: float = 28.0
@export var run_catchup_distance: float = 58.0
@export var teleport_distance: float = 360.0
@export var breadcrumb_spacing: float = 12.0
@export var interaction_radius: float = 64.0
@export var dialog_auto_hide_seconds: float = 3.5
@export var dialog_word: String = "LOVE":
	set(value):
		dialog_word = value
		if dialog_bubble != null:
			dialog_bubble.set("word_text", dialog_word)
@export var dialog_icon: Texture2D = null:
	set(value):
		dialog_icon = value
		if dialog_bubble != null and dialog_icon != null:
			dialog_bubble.set("icon_texture", dialog_icon)

const DialogBubbleScript = preload("res://scenes/npc_dialog_bubble.gd")

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
var dialog_bubble: Node2D = null

const WALK_SPEED := 105.0
const RUN_SPEED := 152.0
const ACCELERATION := 650.0
const FRICTION := 800.0
const STOP_SPEED_THRESHOLD := 8.0
const RUN_SPEED_THRESHOLD := 125.0
const FRAME_SIZE := Vector2i(64, 64)
const ENT_FRAME_SIZE := Vector2i(128, 128)
const DIRECTION_ROWS := {
	&"down": 0,
	&"left": 1,
	&"right": 2,
	&"up": 3,
}
const ENT_DIRECTION_ROWS := {
	&"down": 0,
	&"up": 1,
	&"left": 2,
	&"right": 3,
}

const CHARACTER_STYLE_SHEETS := {
	# === Grupo A: Humanoides y animales (DIRECTION_ROWS = down:0, left:1, right:2, up:3; idle_up = 4 frames) ===
	"archer": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Archer_Lvl1/Archer_lvl1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Archer_Lvl1/Archer_lvl1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Archer_Lvl1/Archer_lvl1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Archer_Lvl1/Archer_lvl1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Archer_Lvl1/Archer_lvl1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Archer_Lvl1/Archer_lvl1_Death_without_shadow.png",
	},
	"archer_lvl2": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Archer_Lvl2/Archer_lvl2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Archer_Lvl2/Archer_lvl2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Archer_Lvl2/Archer_lvl2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Archer_Lvl2/Archer_lvl2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Archer_Lvl2/Archer_lvl2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Archer_Lvl2/Archer_lvl2_Death_without_shadow.png",
	},
	"archer_lvl3": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Archer_Lvl3/Archer_lvl3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Archer_Lvl3/Archer_lvl3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Archer_Lvl3/Archer_lvl3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Archer_Lvl3/Archer_lvl3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Archer_Lvl3/Archer_lvl3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Archer_Lvl3/Archer_lvl3_Death_without_shadow.png",
	},
	"archer_lvl4": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Archer_Lvl4/Without_shadow/lvl4_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Archer_Lvl4/Without_shadow/lvl4_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Archer_Lvl4/Without_shadow/lvl4_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Archer_Lvl4/Without_shadow/lvl4_Attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Archer_Lvl4/Without_shadow/lvl4_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Archer_Lvl4/Without_shadow/lvl4_Death_full_without_shadow.png",
	},
	"archer_lvl5": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Archer_Lvl5/Without_shadow/lvl5_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Archer_Lvl5/Without_shadow/lvl5_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Archer_Lvl5/Without_shadow/lvl5_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Archer_Lvl5/Without_shadow/lvl5_Attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Archer_Lvl5/Without_shadow/lvl5_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Archer_Lvl5/Without_shadow/lvl5_Death_full_without_shadow.png",
	},
	"archer_lvl6": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Archer_Lvl6/Without_shadow/Archer_lvl6_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Archer_Lvl6/Without_shadow/Archer_lvl6_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Archer_Lvl6/Without_shadow/Archer_lvl6_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Archer_Lvl6/Without_shadow/Archer_lvl6_Attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Archer_Lvl6/Without_shadow/Archer_lvl6_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Archer_Lvl6/Without_shadow/Archer_lvl6_Death_full_without_shadow.png",
	},
	"archer_lvl7": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Archer_Lvl7/Without_shadow/Archer_lvl7_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Archer_Lvl7/Without_shadow/Archer_lvl7_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Archer_Lvl7/Without_shadow/Archer_lvl7_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Archer_Lvl7/Without_shadow/Archer_lvl7_Attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Archer_Lvl7/Without_shadow/Archer_lvl7_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Archer_Lvl7/Without_shadow/Archer_lvl7_Death_full_without_shadow.png",
	},
	"archer_lvl8": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Archer_Lvl8/Without_shadow/Archer_lvl8_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Archer_Lvl8/Without_shadow/Archer_lvl8_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Archer_Lvl8/Without_shadow/Archer_lvl8_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Archer_Lvl8/Without_shadow/Archer_lvl8_Attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Archer_Lvl8/Without_shadow/Archer_lvl8_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Archer_Lvl8/Without_shadow/Archer_lvl8_Death_full_without_shadow.png",
	},
	"archer_lvl9": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Archer_Lvl9/Without_shadow/Archer_lvl9_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Archer_Lvl9/Without_shadow/Archer_lvl9_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Archer_Lvl9/Without_shadow/Archer_lvl9_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Archer_Lvl9/Without_shadow/Archer_lvl9_Attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Archer_Lvl9/Without_shadow/Archer_lvl9_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Archer_Lvl9/Without_shadow/Archer_lvl9_Death_full_without_shadow.png",
	},
	"mage": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Mage_1lvl/Without_shadow/Mage_lvl1_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Mage_1lvl/Without_shadow/Mage_lvl1_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Mage_1lvl/Without_shadow/Mage_lvl1_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Mage_1lvl/Without_shadow/Mage_lvl1_attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Mage_1lvl/Without_shadow/Mage_lvl1_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Mage_1lvl/Without_shadow/Mage_lvl1_Death_full_without_shadow.png",
	},
	"mage_lvl2": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Mage_2lvl/Without_shadow/Mage_lvl2_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Mage_2lvl/Without_shadow/Mage_lvl2_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Mage_2lvl/Without_shadow/Mage_lvl2_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Mage_2lvl/Without_shadow/Mage_lvl2_attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Mage_2lvl/Without_shadow/Mage_lvl2_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Mage_2lvl/Without_shadow/Mage_lvl2_Death_full_without_shadow.png",
	},
	"mage_lvl3": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Mage_3lvl/Without_shadow/Mage_lvl3_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Mage_3lvl/Without_shadow/Mage_lvl3_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Mage_3lvl/Without_shadow/Mage_lvl3_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Mage_3lvl/Without_shadow/Mage_lvl3_attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Mage_3lvl/Without_shadow/Mage_lvl3_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Mage_3lvl/Without_shadow/Mage_lvl3_Death_full_without_shadow.png",
	},
	"mage_lvl4": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Mage_4lvl/Without_shadow/Mage_lvl4_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Mage_4lvl/Without_shadow/Mage_lvl4_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Mage_4lvl/Without_shadow/Mage_lvl4_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Mage_4lvl/Without_shadow/Mage_lvl4_attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Mage_4lvl/Without_shadow/Mage_lvl4_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Mage_4lvl/Without_shadow/Mage_lvl4_Death_full_without_shadow.png",
	},
	"mage_lvl5": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Mage_5lvl/Without_shadow/Mage_lvl5_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Mage_5lvl/Without_shadow/Mage_lvl5_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Mage_5lvl/Without_shadow/Mage_lvl5_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Mage_5lvl/Without_shadow/Mage_lvl5_attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Mage_5lvl/Without_shadow/Mage_lvl5_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Mage_5lvl/Without_shadow/Mage_lvl5_Death_full_without_shadow.png",
	},
	"mage_lvl6": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Mage_6lvl/Without_shadow/Mage_lvl6_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Mage_6lvl/Without_shadow/Mage_lvl6_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Mage_6lvl/Without_shadow/Mage_lvl6_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Mage_6lvl/Without_shadow/Mage_lvl6_attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Mage_6lvl/Without_shadow/Mage_lvl6_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Mage_6lvl/Without_shadow/Mage_lvl6_Death_full_without_shadow.png",
	},
	"mage_lvl7": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Mage_7lvl/Without_shadow/Mage7_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Mage_7lvl/Without_shadow/Mage7_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Mage_7lvl/Without_shadow/Mage7_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Mage_7lvl/Without_shadow/Mage7_attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Mage_7lvl/Without_shadow/Mage7_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Mage_7lvl/Without_shadow/Mage7_Death_full_without_shadow.png",
	},
	"mage_lvl8": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Mage_8lvl/Without_shadow/Mage8_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Mage_8lvl/Without_shadow/Mage8_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Mage_8lvl/Without_shadow/Mage8_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Mage_8lvl/Without_shadow/Mage8_attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Mage_8lvl/Without_shadow/Mage8_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Mage_8lvl/Without_shadow/Mage8_Death_full_without_shadow.png",
	},
	"mage_lvl9": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Mage_9lvl/Without_shadow/Mage9_Idle_full_without_shadow.png",
		"walk": "res://assets/common/characters/Mage_9lvl/Without_shadow/Mage9_Walk_full_without_shadow.png",
		"run": "res://assets/common/characters/Mage_9lvl/Without_shadow/Mage9_Run_full_without_shadow.png",
		"attack": "res://assets/common/characters/Mage_9lvl/Without_shadow/Mage9_attack_full_without_shadow.png",
		"hurt": "res://assets/common/characters/Mage_9lvl/Without_shadow/Mage9_Hurt_full_without_shadow.png",
		"death": "res://assets/common/characters/Mage_9lvl/Without_shadow/Mage9_Death_full_without_shadow.png",
	},
	"base_male": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/BaseMale/Unarmed/Without_shadow/Unarmed_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/BaseMale/Unarmed/Without_shadow/Unarmed_Walk_without_shadow.png",
		"run": "res://assets/common/characters/BaseMale/Unarmed/Without_shadow/Unarmed_Run_without_shadow.png",
		"hurt": "res://assets/common/characters/BaseMale/Unarmed/Without_shadow/Unarmed_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/BaseMale/Unarmed/Without_shadow/Unarmed_Death_without_shadow.png",
	},
	"base_male_sword": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/BaseMale/Sword/Without_shadow/Sword_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/BaseMale/Sword/Without_shadow/Sword_Walk_without_shadow.png",
		"run": "res://assets/common/characters/BaseMale/Sword/Without_shadow/Sword_Run_without_shadow.png",
		"attack": "res://assets/common/characters/BaseMale/Sword/Without_shadow/Sword_attack_without_shadow.png",
		"hurt": "res://assets/common/characters/BaseMale/Sword/Without_shadow/Sword_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/BaseMale/Sword/Without_shadow/Sword_Death_without_shadow.png",
	},
	"dino": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/Dino/Dino_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Dino/Dino_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Dino/Dino_Run_without_shadow.png",
	},
	"polar_bear": {
		"layout": "humanoid",
		"idle": "res://assets/common/characters/PolarBear/PolarBear_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/PolarBear/PolarBear_Walk_without_shadow.png",
		"run": "res://assets/common/characters/PolarBear/PolarBear_Run_without_shadow.png",
	},
	# === Grupo B: Criaturas y monstruos (ENT_DIRECTION_ROWS = down:0, up:1, left:2, right:3; 4 filas completas) ===
	"beholder_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Beholder1/Without_shadow/Beholder1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Beholder1/Without_shadow/Beholder1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Beholder1/Without_shadow/Beholder1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Beholder1/Without_shadow/Beholder1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Beholder1/Without_shadow/Beholder1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Beholder1/Without_shadow/Beholder1_Death_without_shadow.png",
	},
	"beholder_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Beholder2/Without_shadow/Beholder2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Beholder2/Without_shadow/Beholder2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Beholder2/Without_shadow/Beholder2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Beholder2/Without_shadow/Beholder2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Beholder2/Without_shadow/Beholder2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Beholder2/Without_shadow/Beholder2_Death_without_shadow.png",
	},
	"beholder_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Beholder3/Without_shadow/Beholder3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Beholder3/Without_shadow/Beholder3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Beholder3/Without_shadow/Beholder3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Beholder3/Without_shadow/Beholder3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Beholder3/Without_shadow/Beholder3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Beholder3/Without_shadow/Beholder3_Death_without_shadow.png",
	},
	"demon_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Demon1/Without_shadow/Demon1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Demon1/Without_shadow/Demon1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Demon1/Without_shadow/Demon1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Demon1/Without_shadow/Demon1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Demon1/Without_shadow/Demon1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Demon1/Without_shadow/Demon1_Death_without_shadow.png",
	},
	"demon_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Demon2/Without_shadow/Demon2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Demon2/Without_shadow/Demon2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Demon2/Without_shadow/Demon2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Demon2/Without_shadow/Demon2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Demon2/Without_shadow/Demon2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Demon2/Without_shadow/Demon2_Death_without_shadow.png",
	},
	"demon_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Demon3/Without_shadow/Demon3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Demon3/Without_shadow/Demon3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Demon3/Without_shadow/Demon3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Demon3/Without_shadow/Demon3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Demon3/Without_shadow/Demon3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Demon3/Without_shadow/Demon3_Death_without_shadow.png",
	},
	"ent_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Ent1/Without_shadow/Ent1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Ent1/Without_shadow/Ent1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Ent1/Without_shadow/Ent1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Ent1/Without_shadow/Ent1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Ent1/Without_shadow/Ent1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Ent1/Without_shadow/Ent1_Death_without_shadow.png",
	},
	"ent_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Ent2/Without_shadow/Ent2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Ent2/Without_shadow/Ent2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Ent2/Without_shadow/Ent2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Ent2/Without_shadow/Ent2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Ent2/Without_shadow/Ent2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Ent2/Without_shadow/Ent2_Death_without_shadow.png",
	},
	"ent_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Ent3/Without_shadow/Ent3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Ent3/Without_shadow/Ent3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Ent3/Without_shadow/Ent3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Ent3/Without_shadow/Ent3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Ent3/Without_shadow/Ent3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Ent3/Without_shadow/Ent3_Death_without_shadow.png",
	},
	"ghost_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Ghost1/Without_shadow/Ghost1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Ghost1/Without_shadow/Ghost1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Ghost1/Without_shadow/Ghost1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Ghost1/Without_shadow/Ghost1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Ghost1/Without_shadow/Ghost1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Ghost1/Without_shadow/Ghost1_Death_without_shadow.png",
	},
	"ghost_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Ghost2/Without_shadow/Ghost2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Ghost2/Without_shadow/Ghost2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Ghost2/Without_shadow/Ghost2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Ghost2/Without_shadow/Ghost2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Ghost2/Without_shadow/Ghost2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Ghost2/Without_shadow/Ghost2_Death_without_shadow.png",
	},
	"ghost_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Ghost3/Without_shadow/Ghost3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Ghost3/Without_shadow/Ghost3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Ghost3/Without_shadow/Ghost3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Ghost3/Without_shadow/Ghost3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Ghost3/Without_shadow/Ghost3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Ghost3/Without_shadow/Ghost3_Death_without_shadow.png",
	},
	"goblin_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Goblin1/Without_shadow/Idle0_without_shadow.png",
		"walk": "res://assets/common/characters/Goblin1/Without_shadow/Walk0_without_shadow.png",
		"run": "res://assets/common/characters/Goblin1/Without_shadow/Run0_without_shadow.png",
		"attack": "res://assets/common/characters/Goblin1/Without_shadow/Attack0_without_shadow.png",
		"hurt": "res://assets/common/characters/Goblin1/Without_shadow/Hurt0_without_shadow.png",
		"death": "res://assets/common/characters/Goblin1/Without_shadow/Death0_without_shadow.png",
	},
	"goblin_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Goblin2/Without_shadow/Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Goblin2/Without_shadow/Walk_without_shadow.png",
		"run": "res://assets/common/characters/Goblin2/Without_shadow/Run_without_shadow.png",
		"attack": "res://assets/common/characters/Goblin2/Without_shadow/Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Goblin2/Without_shadow/Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Goblin2/Without_shadow/Death_without_shadow.png",
	},
	"goblin_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Goblin3/Without_shadow/Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Goblin3/Without_shadow/Walk_without_shadow.png",
		"run": "res://assets/common/characters/Goblin3/Without_shadow/Run_without_shadow.png",
		"attack": "res://assets/common/characters/Goblin3/Without_shadow/Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Goblin3/Without_shadow/Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Goblin3/Without_shadow/Death_without_shadow.png",
	},
	"golem_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Golem1/Without_shadow/Golem1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Golem1/Without_shadow/Golem1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Golem1/Without_shadow/Golem1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Golem1/Without_shadow/Golem1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Golem1/Without_shadow/Golem1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Golem1/Without_shadow/Golem1_Death_without_shadow.png",
	},
	"golem_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Golem2/Without_shadow/Golem2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Golem2/Without_shadow/Golem2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Golem2/Without_shadow/Golem2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Golem2/Without_shadow/Golem2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Golem2/Without_shadow/Golem2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Golem2/Without_shadow/Golem2_Death_without_shadow.png",
	},
	"golem_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Golem3/Without_shadow/Golem3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Golem3/Without_shadow/Golem3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Golem3/Without_shadow/Golem3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Golem3/Without_shadow/Golem3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Golem3/Without_shadow/Golem3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Golem3/Without_shadow/Golem3_Death_without_shadow.png",
	},
	"imp_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Imp1/Without_shadow/Imp1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Imp1/Without_shadow/Imp1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Imp1/Without_shadow/Imp1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Imp1/Without_shadow/Imp1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Imp1/Without_shadow/Imp1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Imp1/Without_shadow/Imp1_Death_without_shadow.png",
	},
	"imp_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Imp2/Without_shadow/Imp2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Imp2/Without_shadow/Imp2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Imp2/Without_shadow/Imp2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Imp2/Without_shadow/Imp2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Imp2/Without_shadow/Imp2_Hurt__without_shadow.png",
		"death": "res://assets/common/characters/Imp2/Without_shadow/Imp2_Death_without_shadow.png",
	},
	"imp_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Imp3/Without_shadow/Imp3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Imp3/Without_shadow/Imp3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Imp3/Without_shadow/Imp3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Imp3/Without_shadow/Imp3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Imp3/Without_shadow/Imp3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Imp3/Without_shadow/Imp3_Death_without_shadow.png",
	},
	"lich_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Lich1/Without_shadow/Lich1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Lich1/Without_shadow/Lich1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Lich1/Without_shadow/Lich1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Lich1/Without_shadow/Lich1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Lich1/Without_shadow/Lich1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Lich1/Without_shadow/Lich1_Death_without_shadow.png",
	},
	"lich_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Lich2/Without_shadow/Lich2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Lich2/Without_shadow/Lich2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Lich2/Without_shadow/Lich2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Lich2/Without_shadow/Lich2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Lich2/Without_shadow/Lich2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Lich2/Without_shadow/Lich2_Death_without_shadow.png",
	},
	"lich_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Lich3/Without_shadow/Lich3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Lich3/Without_shadow/Lich3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Lich3/Without_shadow/Lich3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Lich3/Without_shadow/Lich3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Lich3/Without_shadow/Lich3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Lich3/Without_shadow/Lich3_Death_without_shadow.png",
	},
	"lizardman_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Lizardman1/Without_shadow/Lizardman1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Lizardman1/Without_shadow/Lizardman1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Lizardman1/Without_shadow/Lizardman1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Lizardman1/Without_shadow/Lizardman1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Lizardman1/Without_shadow/Lizardman1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Lizardman1/Without_shadow/Lizardman1_Death_without_shadow.png",
	},
	"lizardman_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Lizardman2/Without_shadow/Lizardman2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Lizardman2/Without_shadow/Lizardman2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Lizardman2/Without_shadow/Lizardman2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Lizardman2/Without_shadow/Lizardman2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Lizardman2/Without_shadow/Lizardman2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Lizardman2/Without_shadow/Lizardman2_Death_without_shadow.png",
	},
	"lizardman_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Lizardman3/Without_shadow/Lizardman3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Lizardman3/Without_shadow/Lizardman3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Lizardman3/Without_shadow/Lizardman3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Lizardman3/Without_shadow/Lizardman3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Lizardman3/Without_shadow/Lizardman3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Lizardman3/Without_shadow/Lizardman3_Death_without_shadow.png",
	},
	"orc_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Orc1/Without_shadow/orc1_idle_without_shadow.png",
		"walk": "res://assets/common/characters/Orc1/Without_shadow/orc1_walk_without_shadow.png",
		"run": "res://assets/common/characters/Orc1/Without_shadow/orc1_run_without_shadow.png",
		"attack": "res://assets/common/characters/Orc1/Without_shadow/orc1_attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Orc1/Without_shadow/orc1_hurt_without_shadow.png",
		"death": "res://assets/common/characters/Orc1/Without_shadow/orc1_death_without_shadow.png",
	},
	"orc_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Orc2/Without_shadow/orc2_idle_without_shadow.png",
		"walk": "res://assets/common/characters/Orc2/Without_shadow/orc2_walk_without_shadow.png",
		"run": "res://assets/common/characters/Orc2/Without_shadow/orc2_run_without_shadow.png",
		"attack": "res://assets/common/characters/Orc2/Without_shadow/orc2_attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Orc2/Without_shadow/orc2_hurt_without_shadow.png",
		"death": "res://assets/common/characters/Orc2/Without_shadow/orc2_death_without_shadow.png",
	},
	"orc_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Orc3/Without_shadow/orc3_idle_without_shadow.png",
		"walk": "res://assets/common/characters/Orc3/Without_shadow/orc3_walk_without_shadow.png",
		"run": "res://assets/common/characters/Orc3/Without_shadow/orc3_run_without_shadow.png",
		"attack": "res://assets/common/characters/Orc3/Without_shadow/orc3_attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Orc3/Without_shadow/orc3_hurt_without_shadow.png",
		"death": "res://assets/common/characters/Orc3/Without_shadow/orc3_death_without_shadow.png",
	},
	"plant_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Plant1/Without_shadow/Plant1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Plant1/Without_shadow/Plant1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Plant1/Without_shadow/Plant1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Plant1/Without_shadow/Plant1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Plant1/Without_shadow/Plant1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Plant1/Without_shadow/Plant1_Death_without_shadow.png",
	},
	"plant_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Plant2/Without_shadow/Plant2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Plant2/Without_shadow/Plant2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Plant2/Without_shadow/Plant2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Plant2/Without_shadow/Plant2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Plant2/Without_shadow/Plant2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Plant2/Without_shadow/Plant2_Death_without_shadow.png",
	},
	"plant_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Plant3/Without_shadow/Plant3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Plant3/Without_shadow/Plant3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Plant3/Without_shadow/Plant3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Plant3/Without_shadow/Plant3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Plant3/Without_shadow/Plant3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Plant3/Without_shadow/Plant3_Death_without_shadow.png",
	},
	"rat_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Rat1/Without_shadow/Rat1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Rat1/Without_shadow/Rat1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Rat1/Without_shadow/Rat1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Rat1/Without_shadow/Rat1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Rat1/Without_shadow/Rat1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Rat1/Without_shadow/Rat1_Death_without_shadow.png",
	},
	"rat_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Rat2/Without_shadow/Rat2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Rat2/Without_shadow/Rat2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Rat2/Without_shadow/Rat2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Rat2/Without_shadow/Rat2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Rat2/Without_shadow/Rat2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Rat2/Without_shadow/Rat2_Death_without_shadow.png",
	},
	"rat_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Rat3/Without_shadow/Rat3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Rat3/Without_shadow/Rat3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Rat3/Without_shadow/Rat3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Rat3/Without_shadow/Rat3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Rat3/Without_shadow/Rat3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Rat3/Without_shadow/Rat3_Death_without_shadow.png",
	},
	"skeleton_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Skeleton1/Without_shadow/Skeleton1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Skeleton1/Without_shadow/Skeleton1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Skeleton1/Without_shadow/Skeleton1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Skeleton1/Without_shadow/Skeleton1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Skeleton1/Without_shadow/Skeleton1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Skeleton1/Without_shadow/Skeleton1_Death_without_shadow.png",
	},
	"skeleton_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Skeleton2/Without_shadow/Skeleton2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Skeleton2/Without_shadow/Skeleton2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Skeleton2/Without_shadow/Skeleton2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Skeleton2/Without_shadow/Skeleton2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Skeleton2/Without_shadow/Skeleton2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Skeleton2/Without_shadow/Skeleton2_Death_without_shadow.png",
	},
	"skeleton_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Skeleton3/Without_shadow/Skeleton3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Skeleton3/Without_shadow/Skeleton3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Skeleton3/Without_shadow/Skeleton3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Skeleton3/Without_shadow/Skeleton3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Skeleton3/Without_shadow/Skeleton3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Skeleton3/Without_shadow/Skeleton3_Death_without_shadow.png",
	},
	"slime_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Slime1/Without_shadow/Slime1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Slime1/Without_shadow/Slime1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Slime1/Without_shadow/Slime1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Slime1/Without_shadow/Slime1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Slime1/Without_shadow/Slime1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Slime1/Without_shadow/Slime1_Death_without_shadow.png",
	},
	"slime_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Slime2/Without_shadow/Slime2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Slime2/Without_shadow/Slime2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Slime2/Without_shadow/Slime2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Slime2/Without_shadow/Slime2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Slime2/Without_shadow/Slime2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Slime2/Without_shadow/Slime2_Death_without_shadow.png",
	},
	"slime_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Slime3/Without_shadow/Slime3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Slime3/Without_shadow/Slime3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Slime3/Without_shadow/Slime3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Slime3/Without_shadow/Slime3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Slime3/Without_shadow/Slime3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Slime3/Without_shadow/Slime3_Death_without_shadow.png",
	},
	"slime_boss_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Slime_boss1/Without_shadow/Slime_boss1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Slime_boss1/Without_shadow/Slime_boss1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Slime_boss1/Without_shadow/Slime_boss1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Slime_boss1/Without_shadow/Slime_boss1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Slime_boss1/Without_shadow/Slime_boss1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Slime_boss1/Without_shadow/Slime_boss1_Death_without_shadow.png",
	},
	"slime_boss_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Slime_boss2/Without_shadow/Slime_boss2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Slime_boss2/Without_shadow/Slime_boss2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Slime_boss2/Without_shadow/Slime_boss2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Slime_boss2/Without_shadow/Slime_boss2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Slime_boss2/Without_shadow/Slime_boss2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Slime_boss2/Without_shadow/Slime_boss2_Death_without_shadow.png",
	},
	"slime_boss_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Slime_boss3/Without_shadow/Slime_boss3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Slime_boss3/Without_shadow/Slime_boss3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Slime_boss3/Without_shadow/Slime_boss3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Slime_boss3/Without_shadow/Slime_boss3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Slime_boss3/Without_shadow/Slime_boss3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Slime_boss3/Without_shadow/Slime_boss3_Death_without_shadow.png",
	},
	"vampire_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Vampires1/Without_shadow/Vampires1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Vampires1/Without_shadow/Vampires1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Vampires1/Without_shadow/Vampires1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Vampires1/Without_shadow/Vampires1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Vampires1/Without_shadow/Vampires1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Vampires1/Without_shadow/Vampires1_Death_without_shadow.png",
	},
	"vampire_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Vampires2/Without_shadow/Vampires2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Vampires2/Without_shadow/Vampires2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Vampires2/Without_shadow/Vampires2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Vampires2/Without_shadow/Vampires2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Vampires2/Without_shadow/Vampires2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Vampires2/Without_shadow/Vampires2_Death_without_shadow.png",
	},
	"vampire_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Vampires3/Without_shadow/Vampires3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Vampires3/Without_shadow/Vampires3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Vampires3/Without_shadow/Vampires3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Vampires3/Without_shadow/Vampires3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Vampires3/Without_shadow/Vampires3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Vampires3/Without_shadow/Vampires3_Death_without_shadow.png",
	},
	"zombie_lvl1": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Zombie1/Without_shadow/Zombie1_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Zombie1/Without_shadow/Zombie1_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Zombie1/Without_shadow/Zombie1_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Zombie1/Without_shadow/Zombie1_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Zombie1/Without_shadow/Zombie1_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Zombie1/Without_shadow/Zombie1_Death_without_shadow.png",
	},
	"zombie_lvl2": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Zombie2/Without_shadow/Zombie2_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Zombie2/Without_shadow/Zombie2_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Zombie2/Without_shadow/Zombie2_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Zombie2/Without_shadow/Zombie2_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Zombie2/Without_shadow/Zombie2_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Zombie2/Without_shadow/Zombie2_Death_without_shadow.png",
	},
	"zombie_lvl3": {
		"layout": "monster",
		"idle": "res://assets/common/characters/Zombie3/Without_shadow/Zombie3_Idle_without_shadow.png",
		"walk": "res://assets/common/characters/Zombie3/Without_shadow/Zombie3_Walk_without_shadow.png",
		"run": "res://assets/common/characters/Zombie3/Without_shadow/Zombie3_Run_without_shadow.png",
		"attack": "res://assets/common/characters/Zombie3/Without_shadow/Zombie3_Attack_without_shadow.png",
		"hurt": "res://assets/common/characters/Zombie3/Without_shadow/Zombie3_Hurt_without_shadow.png",
		"death": "res://assets/common/characters/Zombie3/Without_shadow/Zombie3_Death_without_shadow.png",
	},
}


var target: Node2D = null
var _facing_direction: StringName = &"down"
var _breadcrumbs: Array[Vector2] = []
var _is_catching_up: bool = false
var _idle_glance_timer: float = 2.5
var _dialog_timer: float = 0.0


func _ready() -> void:
	# Evitar empujar al jugador al caminar a su lado
	collision_layer = 0
	collision_mask = 0
	add_to_group(&"npc_companions")

	_ensure_animated_sprite()
	_apply_character_style()

	if Engine.is_editor_hint():
		set_physics_process(false)
		return

	dialog_bubble = get_node_or_null("DialogBubble") as Node2D
	if dialog_bubble == null:
		dialog_bubble = DialogBubbleScript.new()
		dialog_bubble.name = "DialogBubble"
		dialog_bubble.position = Vector2(0.0, -14.0)
		dialog_bubble.visible = false
		add_child(dialog_bubble)
	dialog_bubble.set("word_text", dialog_word)
	if dialog_icon != null:
		dialog_bubble.set("icon_texture", dialog_icon)

	if not target_path.is_empty():
		target = get_node_or_null(target_path) as Node2D
	if target == null and get_parent() != null:
		target = get_parent().get_node_or_null("CharacterBody2D") as Node2D


func _notification(what: int) -> void:
	if not Engine.is_editor_hint() or character_style == "custom":
		return
	if animated_sprite == null:
		animated_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite == null:
		return
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		animated_sprite.sprite_frames = null
		animated_sprite.animation = &""
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_apply_character_style()


func _ensure_animated_sprite() -> void:
	if animated_sprite == null:
		animated_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite == null:
		animated_sprite = AnimatedSprite2D.new()
		animated_sprite.name = "AnimatedSprite2D"
		animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(animated_sprite)


func _apply_character_style() -> void:
	_ensure_animated_sprite()
	if character_style == "custom":
		if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(&"idle_down"):
			animated_sprite.play(&"idle_down")
		return
	animated_sprite.sprite_frames = _create_sprite_frames()
	var start_anim := StringName("idle_%s" % _facing_direction)
	if not animated_sprite.sprite_frames.has_animation(start_anim):
		start_anim = &"idle_down"
	animated_sprite.play(start_anim)


func interact(interactor: Node2D = null, custom_icon: Texture2D = null, custom_word: String = "") -> void:
	if interactor != null:
		var to_interactor := interactor.global_position - global_position
		if to_interactor.length() > 1.0:
			_facing_direction = direction_name_from_vector(to_interactor)
			_update_animation(Vector2.ZERO)

	if dialog_bubble == null:
		return

	if dialog_bubble.visible and custom_icon == null and custom_word.is_empty():
		dialog_bubble.call("hide_bubble")
		_dialog_timer = 0.0
	else:
		var word_to_show := custom_word if not custom_word.is_empty() else dialog_word
		var icon_to_show := custom_icon if custom_icon != null else dialog_icon
		if icon_to_show != null:
			dialog_bubble.call("show_symbol_and_word", icon_to_show, word_to_show)
		else:
			dialog_bubble.call("show_heart", word_to_show)
		_dialog_timer = dialog_auto_hide_seconds


func is_dialog_visible() -> bool:
	return dialog_bubble != null and dialog_bubble.visible


func set_follow_target(p_target: Node2D, p_snap: bool = false) -> void:
	target = p_target
	_breadcrumbs.clear()
	if target != null and p_snap:
		global_position = target.global_position + Vector2(-follow_distance, 6.0)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if _dialog_timer > 0.0:
		_dialog_timer -= delta
		if _dialog_timer <= 0.0 and dialog_bubble != null:
			dialog_bubble.call("hide_bubble")

	if target == null or not is_instance_valid(target):
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		_update_animation(velocity)
		move_and_slide()
		return

	if not can_follow:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		if velocity.length() < STOP_SPEED_THRESHOLD:
			velocity = Vector2.ZERO
			_update_idle_glance(delta)
		_update_animation(velocity)
		move_and_slide()
		return

	_record_breadcrumbs()
	var desired_velocity := _compute_follow_velocity(delta)
	var accel := ACCELERATION if not desired_velocity.is_zero_approx() else FRICTION
	velocity = velocity.move_toward(desired_velocity, accel * delta)

	if velocity.length() < STOP_SPEED_THRESHOLD and desired_velocity.is_zero_approx():
		velocity = Vector2.ZERO
		_update_idle_glance(delta)

	_update_animation(velocity)
	move_and_slide()


func _record_breadcrumbs() -> void:
	var target_pos := target.global_position
	if _breadcrumbs.is_empty():
		if global_position.distance_to(target_pos) > follow_distance:
			_breadcrumbs.append(target_pos)
		return

	var last_point: Vector2 = _breadcrumbs[_breadcrumbs.size() - 1]
	if last_point.distance_to(target_pos) >= breadcrumb_spacing:
		_breadcrumbs.append(target_pos)
		if _breadcrumbs.size() > 32:
			_breadcrumbs.pop_front()


func _compute_follow_velocity(_delta: float) -> Vector2:
	var to_target := target.global_position - global_position
	var dist_to_target := to_target.length()

	# Si se queda demasiado lejos, se acerca rapidamente al jugador
	if dist_to_target > teleport_distance:
		global_position = target.global_position - to_target.normalized() * (follow_distance * 1.2)
		_breadcrumbs.clear()
		return Vector2.ZERO

	# Histeresis para empezar/parar de caminar con naturalidad (sin vibrar en el borde)
	var start_dist := follow_distance + 8.0
	var stop_dist := follow_distance - 3.0
	if dist_to_target <= stop_dist:
		_is_catching_up = false
		_breadcrumbs.clear()
		return Vector2.ZERO
	if not _is_catching_up and dist_to_target < start_dist:
		return Vector2.ZERO

	_is_catching_up = true

	# Consumir puntos intermedios del rastro que ya hemos alcanzado
	while _breadcrumbs.size() > 1 and global_position.distance_to(_breadcrumbs[0]) <= breadcrumb_spacing:
		_breadcrumbs.pop_front()

	var steer_point := target.global_position
	if not _breadcrumbs.is_empty():
		steer_point = _breadcrumbs[0]

	var dir := (steer_point - global_position).normalized()
	if dir.is_zero_approx():
		dir = to_target.normalized()

	# Ajustar velocidad: corre si esta lejos o si el jugador va corriendo; frena suave al llegar
	var target_vel := Vector2.ZERO
	if target is CharacterBody2D:
		target_vel = (target as CharacterBody2D).velocity

	var max_speed := WALK_SPEED
	if dist_to_target > run_catchup_distance or target_vel.length() > WALK_SPEED + 20.0:
		max_speed = RUN_SPEED

	var slow_radius := follow_distance + 22.0
	var arrival_factor := clampf((dist_to_target - stop_dist) / maxf(slow_radius - stop_dist, 1.0), 0.35, 1.0)
	return dir * (max_speed * arrival_factor)


func _update_idle_glance(delta: float) -> void:
	_idle_glance_timer -= delta
	if _idle_glance_timer > 0.0:
		return
	_idle_glance_timer = randf_range(2.4, 4.8)
	# De vez en cuando mira hacia el jugador cuando estan parados cerca
	var to_player := target.global_position - global_position
	var max_glance_dist := interaction_radius * 2.5 if not can_follow else teleport_distance
	if to_player.length() > 4.0 and to_player.length() <= max_glance_dist:
		_facing_direction = direction_name_from_vector(to_player)


static func direction_name_from_vector(vec: Vector2) -> StringName:
	if absf(vec.x) > absf(vec.y):
		return &"right" if vec.x > 0.0 else &"left"
	return &"down" if vec.y > 0.0 else &"up"


func _update_animation(move_vec: Vector2) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	var speed := move_vec.length()
	if speed >= STOP_SPEED_THRESHOLD:
		_facing_direction = direction_name_from_vector(move_vec)

	var movement_animation: StringName = &"idle"
	if speed >= RUN_SPEED_THRESHOLD:
		movement_animation = &"run"
	elif speed >= STOP_SPEED_THRESHOLD:
		movement_animation = &"walk"

	var animation_name := StringName("%s_%s" % [movement_animation, _facing_direction])
	if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
		animated_sprite.play(animation_name)


const ANIMATION_SPECS := [
	{"prefix": &"idle", "key": "idle", "fps": 6.0, "loop": true},
	{"prefix": &"walk", "key": "walk", "fps": 9.5, "loop": true},
	{"prefix": &"run", "key": "run", "fps": 13.5, "loop": true},
	{"prefix": &"attack", "key": "attack", "fps": 12.0, "loop": false},
	{"prefix": &"hurt", "key": "hurt", "fps": 10.0, "loop": false},
	{"prefix": &"death", "key": "death", "fps": 8.0, "loop": false},
]


func _create_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var config: Dictionary = CHARACTER_STYLE_SHEETS.get(
		character_style,
		CHARACTER_STYLE_SHEETS["base_male"]
	)
	var is_monster := str(config.get("layout", "humanoid")) == "monster"
	var direction_rows: Dictionary = ENT_DIRECTION_ROWS if is_monster else DIRECTION_ROWS

	for spec: Dictionary in ANIMATION_SPECS:
		var sheet_key: String = spec["key"]
		if not config.has(sheet_key):
			continue
		var texture := load(str(config[sheet_key])) as Texture2D
		if texture == null:
			continue
		@warning_ignore("INTEGER_DIVISION")
		var cell_px := maxi(int(texture.get_height() / 4), 1)
		var detected_frame_size := Vector2i(cell_px, cell_px)
		@warning_ignore("INTEGER_DIVISION")
		var detected_frame_count := maxi(int(texture.get_width() / cell_px), 1)
		var overrides: Dictionary = {}
		if not is_monster and sheet_key == "idle":
			overrides = {&"up": 4}
		_add_sheet(
			frames,
			spec["prefix"],
			texture,
			detected_frame_count,
			float(spec["fps"]),
			bool(spec["loop"]),
			overrides,
			direction_rows,
			detected_frame_size
		)
	return frames


func _add_sheet(
	frames: SpriteFrames,
	animation_prefix: StringName,
	texture: Texture2D,
	frame_count: int,
	fps: float,
	loop_animation: bool,
	direction_frame_overrides: Dictionary = {},
	direction_rows: Dictionary = DIRECTION_ROWS,
	frame_size: Vector2i = FRAME_SIZE
) -> void:
	for direction: StringName in direction_rows:
		var animation_name := StringName("%s_%s" % [animation_prefix, direction])
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, fps)
		frames.set_animation_loop(animation_name, loop_animation)
		var row: int = direction_rows[direction]
		var count: int = direction_frame_overrides.get(direction, frame_count)
		for frame_index in range(count):
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = texture
			atlas_frame.region = Rect2(
				Vector2(frame_index * frame_size.x, row * frame_size.y),
				Vector2(frame_size)
			)
			frames.add_frame(animation_name, atlas_frame)
