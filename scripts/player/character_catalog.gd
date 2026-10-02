class_name CharacterCatalog
extends RefCounted

# Character choice is cosmetic: movement, tools, capacity and progression are shared.
const DEFAULT_ID := "drainer"
const CHARACTERS := [
	{"id": "drainer", "name": "Drainer", "description": "The original swamp worker."},
	{"id": "humphrey", "name": "Humphrey", "description": "A bear with a sweet tooth."},
	{"id": "forg", "name": "Forg", "description": "A frog with excellent taste."},
	{"id": "piggy", "name": "Piggy", "description": "Small wings. Big ambitions."},
]
const ART := "res://assets/art/characters/"

static func valid_id(value: Variant) -> String:
	for character in CHARACTERS:
		if value == character.id:
			return character.id
	return DEFAULT_ID

static func texture_path(id: String, animation: String) -> String:
	return ART + id + "_" + animation + ".png"

static func preview(id: String) -> Texture2D:
	var atlas := AtlasTexture.new()
	if id == DEFAULT_ID:
		atlas.atlas = load("res://assets/art/drainsville/player_a_idle.png")
		atlas.region = Rect2(0, 0, atlas.atlas.get_width() / 5, atlas.atlas.get_height())
	else:
		atlas.atlas = load(texture_path(id, "idle"))
		atlas.region = Rect2(atlas.atlas.get_image().get_used_rect())
	return atlas
