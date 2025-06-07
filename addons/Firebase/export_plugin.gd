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
	var _plugin_name: String = "Firebase"

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
				"androidx.core:core-ktx:1.12.0",
				"org.jetbrains.kotlin:kotlin-stdlib:2.0.20",
				"com.google.firebase:firebase-messaging-ktx:24.1.1",
				"com.google.firebase:firebase-inappmessaging-display-ktx:21.0.2",
				"com.google.firebase:firebase-analytics"
			])
		else:
			return PackedStringArray([
				"androidx.core:core-ktx:1.12.0",
				"org.jetbrains.kotlin:kotlin-stdlib:2.0.20",
				"com.google.firebase:firebase-messaging-ktx:24.1.1",
				"com.google.firebase:firebase-inappmessaging-display-ktx:21.0.2",
				"com.google.firebase:firebase-analytics"
			])

	func _get_name() -> String:
		return _plugin_name
