extends CharacterBody3D
@onready var hands_cam = $CanvasLayer/SubViewportContainer/SubViewport/Hands_cam
@onready var main_camera = $head/Camera3D
@onready var hand = $head/Camera3D/Hands
@onready var ray =  $head/Camera3D/RayCast3D
var picked_item: RigidBody3D = null # Biến để lưu giữ vật đang cầm
var sens = 0.002
var SPEED = 4.0 # Giảm xuống tí cho game kinh dị
var smooth_speed = 100

# Thêm biến mốc xoay để làm mượt (dây chun)
var target_rot_y = 0.0
var target_rot_x = 0.0

func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    # Khởi tạo mốc bằng giá trị hiện tại để không bị khựng lúc đầu
    target_rot_y = rotation.y
    target_rot_x = $head/Camera3D.rotation.x

func xoay_chuot(event):
    if event is InputEventMouseMotion:
        # THAY ĐỔI: Chỉ cập nhật cái mốc nhìn, chưa xoay thật
        target_rot_y -= event.relative.x * sens
        target_rot_x -= event.relative.y * sens
        target_rot_x = clamp(target_rot_x, deg_to_rad(-85), deg_to_rad(85))

func _process(delta):
    hands_cam.global_transform = main_camera.global_transform
    # THAY ĐỔI: Đây là chỗ làm mượt bằng "dây chun" (lerp)
    rotation.y = lerp_angle(rotation.y, target_rot_y, smooth_speed * delta)
    $head/Camera3D.rotation.x = lerp_angle($head/Camera3D.rotation.x, target_rot_x, smooth_speed * delta)

func _physics_process(delta: float) -> void:
    # Trọng lực
    if not is_on_floor():
        velocity += get_gravity() * delta
    else:
        velocity.y = 0

    # ĐÃ BỎ PHẦN NHẢY (JUMP) theo ý bạn

    var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    if direction:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
    else:
        # Cách dừng lại "lười" nhưng mượt
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
    if ray.is_colliding():
        var target = ray.get_collider()
        
        if target and target.is_in_group("items"):
            picked_item = target 
            
            # 1. Đóng băng vật lý và tắt va chạm ngay lập tức
            picked_item.freeze = true
            picked_item.collision_layer = 0
            picked_item.collision_mask = 0
            
            # 2. Dùng reparent để đưa vào 'hand' (node con của hands_cam)
            # Dùng lệnh này nhanh và an toàn hơn remove_child/add_child
            picked_item.reparent(hand)
            
            # 3. Đưa về tâm của node 'hand'
            # Tú chỉ cần để 2 dòng này là ra ngoài Inspector xoay node 'hand' thoải mái
            picked_item.position = Vector3.ZERO
            picked_item.rotation = Vector3.ZERO
            picked_item.scale = Vector3(0.03, 0.03, 0.03)

            # 4. Chuyển Layer hiển thị (Gộp 2 vòng lặp của Tú thành 1 cho gọn)
            for child in picked_item.get_children():
                if child is VisualInstance3D:
                    child.set_layer_mask_value(1, false) # Tắt layer chính
                    child.set_layer_mask_value(2, true)  # Bật layer phụ
