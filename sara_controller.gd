extends CharacterBody3D

## Velocidad de movimiento
@export var move_speed: float = 5.0
## Velocidad de rotación
@export var rotation_speed: float = 4.0
## Velocidad de la cámara (mouse)
@export var mouse_sensitivity: float = 0.003

## Referencia a la cámara
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	# Capturar el mouse para controlar la cámara
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	# Soltar el mouse con ESC
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Rotar cámara con el mouse
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	# Obtener la dirección del input
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Calcular la dirección del movimiento relative a la cámara
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Aplicar movimiento
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		# Fricción - detener gradualmente
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	
	# Mover el personaje
	move_and_slide()

	# Rotar el personaje hacia la dirección del movimiento
	if direction:
		var target_rotation: float = atan2(direction.x, direction.z)
		var current_rotation: float = rotation.y
		rotation.y = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)
