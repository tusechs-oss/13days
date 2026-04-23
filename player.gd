extends CharacterBody3D
@onready var hands_cam = $CanvasLayer/SubViewportContainer/SubViewport/Hands_cam
@onready var main_camera = $head/Camera3D
@onready var hand = $head/Camera3D/Hands
@onready var ray =  $head/Camera3D/RayCast3D
var picked_item: RigidBody3D = null # Biến để lưu giữ vật đang cầm
var SPEED = 4.0 # Tốc độ di chuyển
var sens = 0.0015 # Độ nhạy chuột (giảm xuống một chút cho an toàn)

func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func xoay_chuot(event):
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        # Xoay ngang (Body)
        rotate_y(-event.relative.x * sens)
        
        # Xoay dọc (Camera)
        var camera = $head/Camera3D
        camera.rotation.x -= event.relative.y * sens
        camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))

func _process(delta):
    hands_cam.global_transform = main_camera.global_transform

func _physics_process(delta: float) -> void:
    # Trọng lực
    if not is_on_floor():
        velocity += get_gravity() * delta
    else:
        velocity.y = 0

    var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    if direction:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.z = move_toward(velocity.z, 0, SPEED)

    move_and_slide()

func _unhandled_input(event):
    xoay_chuot(event)

func _input(event):
    # Nhấn chuột trái để nhặt hoặc ném
    if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
        if picked_item == null:
            check_pickup()
            
func check_pickup():
    if is_instance_valid(ray) and ray.is_colliding():
        var target = ray.get_collider()
        if is_instance_valid(target) and target.is_in_group("items"):
            picked_item = target
            
            picked_item.freeze = true
            picked_item.collision_layer = 0
            picked_item.collision_mask = 0
            
            # Nhấc thẳng vật gốc lên tay
            if is_instance_valid(hand):
                picked_item.reparent(hand)
                if picked_item.has_node("GripPoint"):
                        var grip = picked_item.get_node("GripPoint") # Lấy grip từ chính món đồ
                        picked_item.position = -grip.position
                        picked_item.rotation = -grip.rotation
                picked_item.scale = Vector3(0.03, 0.03, 0.03)

                for child in picked_item.get_children():
                    if child is VisualInstance3D:
                        child.set_layer_mask_value(1, false)
                        child.set_layer_mask_value(2, true)
