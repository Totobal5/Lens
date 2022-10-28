// Feather ignore all
if keyboard_check(ord("Q") ) {lensCamera.addX( 1); }
if keyboard_check(ord("W") ) {lensCamera.addX(-1); }

if keyboard_check(ord("A") ) {lensCamera.addW( 1); }
if keyboard_check(ord("S") ) {lensCamera.addW(-1); }

if keyboard_check_pressed(ord("P") ) {
	lensCamera.shake(1, true, irandom(64), irandom(64) ); // 1 segundo
	//call_later(1, time_source_units_seconds, function() {show_debug_message("Un Segundo!"); } );
}

if keyboard_check_pressed(ord("O") ) {
	if (!lensCamera.isFollow()) {
		lensCamera.follow(4, 4, 8);
	}
	else {
		lensCamera.stopFollow ();
	}
}

if (keyboard_check_pressed(ord("I")) ) {
	lensCamera.zoomTo(obj_target.x, obj_target.y, 1, 0, true);
}