extends Button

func _on_pressed() -> void:
	for worker in %WorkerHead.get_children():
		worker.abandon_job()
	
	SceneSwitcher.switch_to_space()
