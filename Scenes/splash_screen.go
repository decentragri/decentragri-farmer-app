package scenes

import (
	"graphics.gd/classdb/Control"
	"graphics.gd/classdb/PackedScene"
	"graphics.gd/classdb/Resource"
	"graphics.gd/classdb/SceneTree"
)

type SplashScreen struct {
	Control.Extension[SplashScreen] `gd:"SplashScreen"`
}

func (s *SplashScreen) Ready() {
	// Start a timer to change scene after 2 seconds
	timer := SceneTree.Get(s.AsNode()).CreateTimer(2.0)
	timer.OnTimeout(func() {
		// For now, just go directly to auth screen
		s.ChangeToAuthScene()
	})
}

func (s *SplashScreen) ChangeToAuthScene() {
	scene := Resource.Load[PackedScene.Instance]("res://Scenes/auth_screen_new.tscn")
	SceneTree.Get(s.AsNode()).ChangeSceneToPacked(scene)
}

func (s *SplashScreen) ChangeToMainMenuScene() {
	scene := Resource.Load[PackedScene.Instance]("res://Scenes/main_menu_new.tscn")
	SceneTree.Get(s.AsNode()).ChangeSceneToPacked(scene)
}