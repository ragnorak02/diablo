class_name DungeonMeshLoader
extends RefCounted
## Loads dungeon meshes from .glb files or generates improved procedural fallbacks.
## Caches mesh+material pairs by tile type for reuse across the dungeon.

const TILE_SIZE := 3.0
const MESH_DIR := "res://resources/meshes/"

enum TileMesh { FLOOR, WALL, STAIRS, EXTRACTION, WALL_CAP, TORCH }

# Cache: TileMesh -> { "mesh": Mesh, "material": StandardMaterial3D }
var _cache: Dictionary = {}


func get_mesh(tile: TileMesh) -> Mesh:
	_ensure_loaded(tile)
	return _cache[tile]["mesh"]


func get_material(tile: TileMesh) -> StandardMaterial3D:
	_ensure_loaded(tile)
	return _cache[tile]["material"]


func _ensure_loaded(tile: TileMesh) -> void:
	if _cache.has(tile):
		return

	var glb_name := _glb_name_for(tile)
	var glb_path := MESH_DIR + glb_name

	if ResourceLoader.exists(glb_path):
		var scene: PackedScene = load(glb_path)
		var instance := scene.instantiate()
		# Extract first MeshInstance3D from the loaded scene
		var mesh_instance := _find_mesh_instance(instance)
		if mesh_instance:
			_cache[tile] = {
				"mesh": mesh_instance.mesh,
				"material": mesh_instance.material_override if mesh_instance.material_override else _create_procedural_material(tile),
			}
			instance.queue_free()
			return
		instance.queue_free()

	# Fallback: improved procedural mesh + textured material
	_cache[tile] = {
		"mesh": _create_procedural_mesh(tile),
		"material": _create_procedural_material(tile),
	}


func _glb_name_for(tile: TileMesh) -> String:
	match tile:
		TileMesh.FLOOR: return "floor_tile.glb"
		TileMesh.WALL: return "wall_tile.glb"
		TileMesh.STAIRS: return "stairs_tile.glb"
		TileMesh.WALL_CAP: return "wall_cap.glb"
		TileMesh.TORCH: return "torch.glb"
		_: return ""


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _find_mesh_instance(child)
		if found:
			return found
	return null


func _create_procedural_mesh(tile: TileMesh) -> Mesh:
	match tile:
		TileMesh.FLOOR, TileMesh.STAIRS, TileMesh.EXTRACTION:
			var box := BoxMesh.new()
			box.size = Vector3(TILE_SIZE, 0.2, TILE_SIZE)
			return box
		TileMesh.WALL:
			var box := BoxMesh.new()
			box.size = Vector3(TILE_SIZE, 3.0, TILE_SIZE)
			return box
		TileMesh.WALL_CAP:
			var box := BoxMesh.new()
			box.size = Vector3(TILE_SIZE + 0.1, 0.15, TILE_SIZE + 0.1)
			return box
		TileMesh.TORCH:
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.06
			cyl.bottom_radius = 0.08
			cyl.height = 0.6
			return cyl
		_:
			return BoxMesh.new()


func _create_procedural_material(tile: TileMesh) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.9

	# Create noise texture for stone/brick look
	var noise_tex := _create_noise_texture(tile)
	if noise_tex:
		mat.albedo_texture = noise_tex
		# Use the same noise for a subtle normal map effect
		mat.normal_enabled = true
		mat.normal_texture = noise_tex
		mat.normal_scale = 0.4

	match tile:
		TileMesh.FLOOR:
			mat.albedo_color = Color(0.35, 0.28, 0.22)
			mat.emission_enabled = true
			mat.emission = Color(0.12, 0.08, 0.05)
			mat.emission_energy_multiplier = 0.15
		TileMesh.WALL:
			mat.albedo_color = Color(0.45, 0.35, 0.28)
			mat.roughness = 0.85
			mat.emission_enabled = true
			mat.emission = Color(0.15, 0.1, 0.06)
			mat.emission_energy_multiplier = 0.15
		TileMesh.STAIRS:
			mat.albedo_color = Color(0.4, 0.35, 0.15)
			mat.emission_enabled = true
			mat.emission = Color(0.4, 0.35, 0.1)
			mat.emission_energy_multiplier = 0.3
		TileMesh.EXTRACTION:
			mat.albedo_color = Color(0.1, 0.5, 0.2)
			mat.emission_enabled = true
			mat.emission = Color(0.1, 0.8, 0.3)
			mat.emission_energy_multiplier = 0.8
		TileMesh.WALL_CAP:
			mat.albedo_color = Color(0.55, 0.45, 0.35)
			mat.emission_enabled = true
			mat.emission = Color(0.3, 0.22, 0.12)
			mat.emission_energy_multiplier = 0.4
			mat.normal_enabled = false
		TileMesh.TORCH:
			mat.albedo_color = Color(0.35, 0.2, 0.1)
			mat.emission_enabled = true
			mat.emission = Color(0.9, 0.5, 0.15)
			mat.emission_energy_multiplier = 1.5
			mat.normal_enabled = false

	return mat


func _create_noise_texture(tile: TileMesh) -> NoiseTexture2D:
	if tile == TileMesh.TORCH:
		return null

	var noise := FastNoiseLite.new()

	match tile:
		TileMesh.FLOOR, TileMesh.STAIRS, TileMesh.EXTRACTION:
			noise.noise_type = FastNoiseLite.TYPE_CELLULAR
			noise.frequency = 0.08
			noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
			noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
		TileMesh.WALL, TileMesh.WALL_CAP:
			noise.noise_type = FastNoiseLite.TYPE_CELLULAR
			noise.frequency = 0.05
			noise.cellular_distance_function = FastNoiseLite.DISTANCE_MANHATTAN
			noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
		_:
			return null

	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	return tex


## Creates a torch prop (handle mesh + flame sphere + light). Returns a Node3D.
func create_torch_prop() -> Node3D:
	var torch := Node3D.new()
	torch.name = "Torch"

	# Handle
	var handle := MeshInstance3D.new()
	handle.mesh = get_mesh(TileMesh.TORCH)
	handle.material_override = get_material(TileMesh.TORCH)
	handle.position = Vector3(0, 0.3, 0)
	torch.add_child(handle)

	# Flame sphere
	var flame := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	flame.mesh = sphere

	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_color = Color(1.0, 0.7, 0.2, 0.9)
	flame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.6, 0.15)
	flame_mat.emission_energy_multiplier = 3.0
	flame.material_override = flame_mat
	flame.position = Vector3(0, 0.7, 0)
	torch.add_child(flame)

	# Point light
	var light := OmniLight3D.new()
	light.position = Vector3(0, 0.8, 0)
	light.light_color = Color(1.0, 0.7, 0.3)
	light.light_energy = 1.5
	light.omni_range = 6.0
	light.omni_attenuation = 1.2
	light.shadow_enabled = false  # cheaper
	torch.add_child(light)

	return torch
