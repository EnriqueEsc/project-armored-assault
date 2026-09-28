extends Attachment

var active: bool = false




func _process(delta: float) -> void:
	boosting(delta)
	calculate_charge(delta)

func calculate_charge(delta: float) -> void:
	#print(time_passed," | ",cooldown," | ",percent)
	if active:
		return
	if percent >= min_percent_to_use:
		return
	time_passed += delta
	if cooldown <= 0.0:
		percent = min_percent_to_use
		shoot_recharge.emit(percent)
		return
	
	
	percent = time_passed / cooldown
	percent = clampf(percent,0,1)
	percent *= 100
	shoot_recharge.emit(percent)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _use_attachment() -> void:
	
	if percent < min_percent_to_use:
		return
	#if master_vehicle:
	#	master_vehicle.boost(10)
	_attachment_function()

func _attachment_function() -> void:
	if active:
		return
	active = true

func boosting(delta: float) -> void:
	if not active:
		return
	
	percent -= delta * 100.0
	print(percent)
	master_vehicle.boost(1)
	if percent <= 0:
		time_passed = 0.0
		active = false
		return
