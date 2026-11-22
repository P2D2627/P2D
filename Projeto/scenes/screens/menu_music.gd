class_name MenuMusic
extends AudioStreamPlayer

## The menus' music, the main menu's theme: it plays while one of the menus in Menus shows, the main
## menu or the pause, and fades out when none does. Faded out, it pauses where it was, and the next
## menu to show goes on from there: from the main menu to a level and its pause, the song carries
## on, not from the top. At its end it starts again from the top (with Loop on in the file's import,
## it loops by itself and this never happens). The menus never know it is there: it follows their
## visibility. It runs while the game is paused, as Main does, so it plays in the pause.

## The menus it plays for, each one a CanvasLayer, as the main menu and the pause are.
@export var menus: Array[CanvasLayer] = []
## The time the music takes to come up when a menu shows.
@export_range(0.0, 5.0, 0.05, "suffix:s") var fade_in_time: float = 1.5
## The time it takes to go quiet when the last menu hides, before it pauses.
@export_range(0.0, 5.0, 0.05, "suffix:s") var fade_out_time: float = 1.5
## The fades' curve. The ear hears loudness in decibels, not in gain: a straight ramp of the gain (Linear)
## brings most of the loudness at once and drops it all at the end. Cubic eases the gain in slowly and out
## quickly, closer to an even change of loudness, -18 dB halfway against the ramp's -6, with no -80 dB floor
## to wait through as a ramp in decibels would have (#284).
@export var fade_curve: Tween.TransitionType = Tween.TRANS_CUBIC

## The volume set in the Inspector, the one a fade-in comes up to, as a linear gain.
var _full_volume: float = 1.0
## True while a menu shows and the music is meant to play.
var _wanted: bool = false
var _fade: Tween


func _ready() -> void:
	_full_volume = volume_linear
	volume_linear = 0.0
	finished.connect(play)
	for index: int in menus.size():
		var menu: CanvasLayer = menus[index]
		if menu == null:
			push_warning("MenuMusic: entry %d of Menus has no menu." % index)
			continue
		# At the end of the frame, so a menu that hides as another shows, as the pause's Main Menu
		# does, leaves the music as it was.
		menu.visibility_changed.connect(_follow_the_menus, CONNECT_DEFERRED)
	_follow_the_menus()


## True while one of the menus shows.
func is_wanted() -> bool:
	return _wanted


## The volume a fade-in comes up to, the one set in the Inspector, as a linear gain.
func full_volume() -> float:
	return _full_volume


## Fades in when the first menu shows, from where the song was left, and fades out and pauses when
## the last one hides.
func _follow_the_menus() -> void:
	var wanted: bool = _a_menu_shows()
	if wanted == _wanted:
		return
	_wanted = wanted
	if _fade != null:
		_fade.kill()
	_fade = create_tween().set_trans(fade_curve)
	if wanted:
		stream_paused = false
		if not playing:
			play()
		_fade.tween_property(self, ^"volume_linear", _full_volume, fade_in_time).set_ease(Tween.EASE_IN)
	else:
		_fade.tween_property(self, ^"volume_linear", 0.0, fade_out_time).set_ease(Tween.EASE_OUT)
		_fade.tween_callback(_pause_the_song)


func _a_menu_shows() -> bool:
	for menu: CanvasLayer in menus:
		if menu != null and menu.visible:
			return true
	return false


## Silent by now: the song stops where it is, to go on from there.
func _pause_the_song() -> void:
	stream_paused = true
