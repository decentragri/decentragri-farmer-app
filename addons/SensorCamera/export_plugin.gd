@tool
extends EditorPlugin

# A class member to hold the editor export plugin during its lifecycle.
var export_plugin : AndroidExportPlugin

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	export_plugin = AndroidExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_export_plugin(export_plugin)
	export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	# TODO: Update to your plugin's name.
	var _plugin_name: String = "SensorCamera"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		if platform is EditorExportPlatformAndroid:
			return true
		return false

	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if debug:
			return PackedStringArray([_plugin_name + "/bin/debug/" + _plugin_name + "-debug.aar"])
		else:
			return PackedStringArray([_plugin_name + "/bin/release/" + _plugin_name + "-release.aar"])

	func _get_android_dependencies(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		# TODO: Add remote dependices here.
		if debug:
			return PackedStringArray([
				"org.jetbrains.kotlin:kotlin-stdlib:2.0.20",
				"androidx.appcompat:appcompat:1.7.0",
				"androidx.camera:camera-camera2:1.4.2",
				"androidx.camera:camera-lifecycle:1.4.2",
				"androidx.camera:camera-view:1.4.2",
				"com.google.mlkit:text-recognition:16.0.1",
				"androidx.lifecycle:lifecycle-runtime-ktx:2.6.2"
			])
		else:
			return PackedStringArray([
				"org.jetbrains.kotlin:kotlin-stdlib:2.0.20",
				"androidx.appcompat:appcompat:1.7.0",
				"androidx.camera:camera-camera2:1.4.2",
				"androidx.camera:camera-lifecycle:1.4.2",
				"androidx.camera:camera-view:1.4.2",
				"com.google.mlkit:text-recognition:16.0.1",
				"androidx.lifecycle:lifecycle-runtime-ktx:2.6.2"
			])

	func _get_name() -> String:
		return _plugin_name
