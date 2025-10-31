#UILayerManager
extends Node

var ui_layer_scene = preload("res://scenes/ui/UILayer.tscn")
var ui_layer_instance: CanvasLayer = null

func init_ui_layer():
	if not ui_layer_instance or not is_instance_valid(ui_layer_instance):
		ui_layer_instance = ui_layer_scene.instantiate()
		get_tree().root.call_deferred("add_child", ui_layer_instance)

func show_hud():
	if ui_layer_instance:
		ui_layer_instance.call_deferred("show_hud")

func show_message(msg: String):
	if ui_layer_instance:
		ui_layer_instance.call_deferred("show_message", msg)

func hide_message():
	if ui_layer_instance:
		ui_layer_instance.call_deferred("hide_message")
