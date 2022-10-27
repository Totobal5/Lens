// Feather ignore all
#macro __LENS_VERSION "1.1.3"
#macro __LENS_CREDITS "@TabularElf - https://tabelf.link/"
#macro __LENS_DEBUG true
show_debug_message("Lens " + __LENS_VERSION + " initalized! Created by " + __LENS_CREDITS);

#macro LENS_MOUSE_FOLLOW "MouseFollow"
#macro LENS_MOUSE_BORDER "MouseBorder"

/// @param {real} view
/// @param {real} x
/// @param {real} y
/// @param {real} width
/// @param {real} heigth
/// @param {real} [angle]
/// @return {Struct.Lens}
function Lens(_view, _x, _y, _w, _h, _angle=0) constructor {
	#region Variables
	view   = _view;
	camera = camera_create(); // Crear camara en startup
	
	// Tamaño y posicion
	w = _w;
	h = _h;
	relation = w / min(1, h);
	
	wscale = 1;
	hscale = 1;
	hPort = 0;
	wPort = 0;
	
	// Posicion de origen derecha
	xr = _x; // x right e y right
	yr = _y;

	// Posicion posicion de origen izquierda
	xl = _x - w; // x left and y left
	yl = _y - h;
	
	// Posicion de origen centro
	xc = xr - w*.5;
	yc = yr - h*.5;
	
	// Posicion con 
	
	// Posicion con el centro de la camara como origen
	x = xc; // posicion absolutas (se actualiza automaticamente)
	y = yc;
	xprev = x;
	yprev = y;

	angle = _angle; // Posiciones teniendo en cuenta el centro y angulo de la camara
	var _sin = dsin(angle), _cos = dcos(angle);
	xangle = x*_cos + y*_sin;
	yangle = x*_sin + y*_cos;

	// limites de la camara global, infinity no posee limites
	xLimitMin = infinity;
	xLimitMax = infinity;
	
	yLimitMin = infinity;
	yLimitMax = infinity;
	
	// Control
	deltaTime = 0;
	gameSpeed = game_get_speed(gamespeed_fps);
	step = time_source_create(time_source_game, 1, time_source_units_frames, function() {
		if (view_camera[view] != camera) {updateCamera(); }
		
		// Control
		deltaTime = (delta_time * 0.000001) * gameSpeed;
		
		// Tamaño
		var _w = max(1, (w * wscale) );
		var _h = max(1, (h * hscale) ); 
		camera_set_view_size(camera, _w, _h);

		// Posicion del centro
		x = (xl + _w*.5) + eventX();
		y = (yl + _h*.5) + eventY();
		
		// Limites global
		if (xLimitMin != infinity && xLimitMax != infinity) { // Limite x
			x = clamp(x, xLimitMin, xLimitMax); 
		}
		
		if (yLimitMin != infinity && yLimitMax != infinity) { // Limite y
			y = clamp(y, yLimitMin, yLimitMax); 
		}
		
		camera_set_view_pos (camera, x, y);
		
		// Angulo
		camera_set_view_angle(camera, angle);
		var _sin = dsin(angle), _cos = dcos(angle);
		xangle = x*_cos + y*_sin;
		yangle = x*_sin + y*_cos;
		
	}, [], -1);

	var _same = function() {} // Evitar crear tantas funciones
		#region Shake
	shakeX = 0; // X e Y que cambian respecto al shake
	shakeY = 0; //
	shakeTime = 0;
	shakeStep = time_source_create(step, 1, time_source_units_frames, _same);
	
	#endregion


		#region Follow
	followTargets = ds_list_create();
	followTime = [0, 0]; // Tiempo
	followTargetX = 0;
	followTargetY = 0;
	followX = 0; // X e Y que sigan a los objetivos
	followY = 0;
	
	followAfterX = noone; // Guardar posicion x e y anterior
	followAfterY = noone;
	
	followLimitX = infinity; // limites del follow, infinity no posee limites
	followLimitY = infinity;
	followStep  = time_source_create(step		, 1, time_source_units_frames, _same);
	followAfter = time_source_create(followStep , 1, time_source_units_frames, _same);
	
	#endregion


		#region Zoom
	zoomTime  = 0;
	zoomDelay = 0;
	zoomStep  = time_source_create(step, 1, time_source_units_frames, _same);
	zoomCallback = _same;
	
	zoomX = 0;
	zoomY = 0;
	
	#endregion


		#region Mouse
	mouseMode = "NoMode";
	mouseInstance = {
		id: "mouse", 
		x: 0, 
		y: 0,
		step: time_source_create(step, 1, time_source_units_frames, function() {} ), 
	};
		
	#endregion


	#region Methods

		#region Basic
	/// @param {real} view_index
	static setCamera = function(_view) {
		if (view_enabled != false) view_enabled = true;
		view = _view;
		view_set_camera (view, camera); // Establecer la camara a esta vista
		view_set_visible(view, true);	// Poner en true la camara
		
		return self;
	}
	
	
	/// @desc Actualiza la camara
	static updateCamera = function() {
		if (!view_enabled) view_enabled = true;
		view_set_camera (view, camera); // Establecer la camara a esta vista
		view_set_visible(view, true);	// Poner en true la camara
	}
	
	
	/// @param {real} x
	static setX = function(_x) {
		xr = _x;
		xl = xr - w;
		xc = xr - w*.5;
		return self;
	}
	
	
	/// @param {real} y
	static setY = function(_y) {
		yr = _y;
		yl = yr - h;
		yc = yr - h*.5;
		return self;
	}	
	
	
	/// @param {real} x
	/// @param {real} y
	static setXY = function(_x, _y) {
		setX(_x); setY(_y);
		return self;
	}
	
	
	/// @param {real} x
	static addX = function(_x) {
		xr = xr + _x;
		xl = xr -  w;
		xc = xr - w*.5;
		return self;
	}
	
	
	/// @param {real} y
	static addY = function(_y) {
		yr = yr + _y;
		yl = yr -  h;
		yc = yr - h*.5;
		return self;
	}	
	
	
	/// @param {real} x
	/// @param {real} y	
	static addXY = function(_x, _y) {
		addX(_x); addY(_y);
		return self;
	}
	
	
	/// @param {real} width
	static setW = function(_w) {
		w = _w;
		relation = w / min(1, h);
		xl = xr - w;
		xr = xl + w;
		xc = xr - w*.5;
		return self;
	}
	
	
	/// @param {real} height
	static setH = function(_h) {
		h = _h;
		relation = w / min(1, h);
		yl = yr - h;
		yr = yl + h;
		yc = yr - h*.5;
		return self;
	}
	
	
	/// @param {real} width
	/// @param {real} height
	static setWH = function(_w, _h) {
		w = _w;
		h = _h;
		relation = w / min(1, h);
		xl = xr - w;
		xr = xl + w;
		xc = xr - w*.5;
		
		yl = yr - h;
		yr = yl + h;
		yc = yr - h*.5;
		return self;
	}
	
	
	/// @param {real} angle
	static setAngle = function(_angle) {
		angle = _angle;
		return self;
	}
	
	
	/// @param {real} angle
	static addAngle = function(_angle) {
		angle = angle + _angle;
		return self;
	}
	
	#endregion
		
		
		#region Shake
	/// @param {real} duration
	/// @param {bool} timeUnit	false: frames true: seconds
	/// @param {real} forceX
	/// @param {real} forceY
	/// @param {Asset.GMAnimcurve} animcurve
	/// @param {Array<real>, Array<string>} channels name or index
	static shake  = function(_duration, _unit, _forceX, _forceY=_forceX, _animcurve=acLensShake, _channels=[0, 1], _callback) {
		static f=function() {};
		
		// Solo si esta detenido
		if (!isShake() ) { 
			var _chan = [
				animcurve_get_channel(_animcurve, _channels[0] ),
				animcurve_get_channel(_animcurve, _channels[1] )
			];
			// Segundos
			if (_unit) {_duration *= gameSpeed; }
			time_source_reconfigure(shakeStep, 1, time_source_units_frames, function(_duration, _forceX, _forceY, _channels, _callback) {
				shakeX = animcurve_channel_evaluate(_channels[0], shakeTime) * _forceX;
				shakeY = animcurve_channel_evaluate(_channels[1], shakeTime) * _forceY;
				var _s = (_duration * deltaTime);
				shakeTime = shakeTime + (1 / _s);
				// Detener shake event
				if (shakeTime >= 1) {
					_callback(); // Llamar callback
					
					// Reiniciar
					shakeX = 0;
					shakeY = 0;
					shakeTime = 0;
					time_source_stop(shakeStep);
				}
			}, [_duration, _forceX, _forceY, _chan, _callback ?? f], -1);
			time_source_start(shakeStep); // Iniciar time source
		}
	}
	
	
	/// @desc Si esta sacudiendo la camara
	static isShake = function() {
		return 	(time_source_get_state(shakeStep) == time_source_state_active);
	}


	#endregion
		
		
		#region Follow
	/// @param {real} speedX
	/// @param {real} speedY
	/// @param {real} resetTime	tiempo para comprobar si hay que reiniciar el proceso del animcurve
	/// @param {Asset.GMAnimcurve} animcurve
	/// @param {Array<real>, Array<string>} channels name or index
	static follow = function(_speedX, _speedY=_speedX, _resetTime=5, _animcurve=acLensFollow, _channels=[0, 1]) {
		if (!isFollow() ) {
			var _chan = [
				animcurve_get_channel(_animcurve, _channels[0] ),
				animcurve_get_channel(_animcurve, _channels[1] )
			];
			
			_speedX *= gameSpeed; _speedY *= gameSpeed;
			time_source_reconfigure(followStep , 1, time_source_units_frames, function(_speedX, _speedY, _channels) {
				var n = ds_list_size(followTargets);
				if (n > 0) {
					var _cx = animcurve_channel_evaluate(_channels[0], followTime[0] );
					var _cy = animcurve_channel_evaluate(_channels[1], followTime[1] );
					// Poner el origen en 0,0
					followTargetX = 0;
					followTargetY = 0;
					
					// Si se han movido los objetivos
					#region Obtener posiciones
					for (var i=0; i<n; i=i+1) {
						var _ins = followTargets[| i];
						if (is_struct(_ins) ) {
							followTargetX += _ins.x;
							followTargetY += _ins.y;
						}
						else if (instance_exists(_ins) ) {
							followTargetX += _ins.x;
							followTargetY += _ins.y;
						}
						else {
							ds_list_delete(followTargets, i);
							n = n - 1;
						}
					}

					#endregion
					
					
					#region Actualizar valores
					n = max(1, n);
					followTargetX = followTargetX / n;
					followTargetY = followTargetY / n;
					
					followTargetX = followTargetX - (xc + w*.5) + (zoomX / w*wscale);
					followTargetY = followTargetY - (yc + h*.5) + (zoomY / h*hscale);
					
					#endregion
					
					
					#region Limites
					if (followLimitX != infinity) followTargetX = clamp(followTargetX, 0, followLimitX);
					if (followLimitY != infinity) followTargetY = clamp(followTargetY, 0, followLimitY);
					
					#endregion
					
					
					#region Lerp y tiempo
					//lens_trace("targetX: ", followTargetX);
					followX = lerp(followX, followTargetX, _cx);
					followY = lerp(followY, followTargetY, _cy);

					followTime[0] = followTime[0] + (1 / _speedX * deltaTime);
					followTime[1] = followTime[1] + (1 / _speedY * deltaTime);
					
					#endregion
				// Si no hay elementos parar
				} else time_source_stop(followStep);
			}, [_speedX, _speedY, _chan], -1);
			time_source_reconfigure(followAfter, _resetTime, time_source_units_frames, function() {
				static start = false;
				
				if (followX == followAfterX && followY == followAfterY) {
					if (start) {
						followTime[0] = 0;
						followTime[1] = 0;
						followStop = true;
					}
					
					start = true;
				}
				else {
					followAfterX = followX;
					followAfterY = followY;
				}
			}, [], -1, time_source_expire_after);
			
			time_source_start(followStep);  // Iniciar time source
		}
	}
	
		
	/// @desc Deja de seguir a un objeto
	static stopFollow = function() {
		// No reiniciar posicion x e y de follow
		var _x = followX;
		var _y = followY;
		addXY(_x, _y);
		followX = 0;
		followY = 0;
		followTime = [0, 0];
		time_source_stop(followStep);
	}
	
	
	/// @desc Añade objetivos para seguir
	static addTarget  = function(_target) {
		if (is_array(_target) ) {
			array_foreach(_target, function(_v) {addTarget(_v); } );
		}
		else {
			ds_list_add(followTargets, _target);
		}
		return self;
	}


	/// @desc Si esta siguiendo a algun objetivo
	static isFollow = function() {
		return 	(time_source_get_state(followStep) == time_source_state_active);
	}
	
	
	#endregion


		#region Mouse
	/// @desc Añade un struct que sigue al mouse en la lista de follows
	static addMouseFollow = function() {
		if (mouseMode == "NoMode") {
			mouseMode = "MouseFollow";
			var _this = self;
			with (mouseInstance) {
				time_source_reconfigure(step, 1, time_source_units_frames, function(_this) {
					x = window_view_mouse_get_x(_this.view);
					y = window_view_mouse_get_y(_this.view);
				}, [_this], -1);
				time_source_start(step);
			}
			// Añadir al inicio
			ds_list_insert(followTargets, 0, mouseInstance);
		} 
		// Detener
		else if (mouseMode == "MouseFollow") {
			mouseMode = "NoMode";
			time_source_stop(mouseInstance.step); // Detener timesource
			var i = ds_list_find_index(followTargets, mouseInstance);
			ds_list_delete(followTargets, i); // Eliminar instancia
		}
	}
		
	#endregion
	
		
		#region Zoom
	
	/// @param {real} duration
	/// @param {real} delay
	/// @param {bool} unit?	frame: false seconds:true
	/// @param {Asset.GMAnimcurve} [animcurve]
	/// @param {Array<real>, Array<string>} [channels] name or index
	static zoomCenter = function(_duration, _delay, _unit, _animcurve=acLensZoomCenter, _channels=[0, 1]) {
		if (!isZoom() ) {
			#region Set Variables
			var _chan = [
				animcurve_get_channel(_animcurve, _channels[0] ),
				animcurve_get_channel(_animcurve, _channels[1] )
			];
			zoomDelay = _delay;
			if (_unit) {
				_duration *= gameSpeed; 
				zoomDelay *= gameSpeed;
			}
			
			#endregion
			
			time_source_reconfigure(zoomStep, 1, time_source_units_frames, function(_duration, _chan, _wprev, _hprev) {
				if (zoomTime < .5) {
					var _ws = animcurve_channel_evaluate(_chan[0], zoomTime);
					var _hs = animcurve_channel_evaluate(_chan[1], zoomTime);
					// Actualizar escala
					wscale = _ws;
					hscale = _hs;
					// Actualizar tiempo
					zoomTime += (1 / _duration * deltaTime);
				}
				else if (zoomTime > .5 && zoomTime < 1) {
					if (zoomDelay <= 0) {
						var _ws = animcurve_channel_evaluate(_chan[0], zoomTime);
						var _hs = animcurve_channel_evaluate(_chan[1], zoomTime);
						// Actualizar escala
						wscale = _ws;
						hscale = _hs;
						
						// Actualizar tiempo
						zoomTime += (1 / _duration * deltaTime);
					} else {
						zoomDelay--;
					}
				}
				else if (zoomTime >= 1) {
					zoomCallback(); // Ejecutar callback
					wscale = _wprev;
					hscale = _hprev;
					zoomTime = 0;
					time_source_stop(zoomStep); // Detener timesource
				}
			}, [_duration, _chan, wscale, hscale], -1);
			time_source_start(zoomStep); // Iniciar timesource
		}
	}
	
	
	/// @param {real} x
	/// @param {real} y
	/// @param {real} duration
	/// @param {real} delay
	/// @param {bool} unit?	frame: false seconds:true
	/// @param {Asset.GMAnimcurve} [animcurve]
	/// @param {Array<real>, Array<string>} [channels] name or index
	static zoomTo = function(_x, _y, _duration, _delay, _unit, _animcurve=acLensZoomCenter, _channels=[0, 1]) {
		if (!isZoom() ) {
			#region Set Variables
			var _chan = [
				animcurve_get_channel(_animcurve, _channels[0] ),
				animcurve_get_channel(_animcurve, _channels[1] )
			];
			zoomDelay = _delay;
			if (_unit) {
				_duration *= gameSpeed;
				zoomDelay *= gameSpeed;
			}
			#endregion
			lens_trace("START");
			time_source_reconfigure(zoomStep, 1, time_source_units_frames, function(_xTo, _yTo, _duration, _delay, _w, _h, _chan) {
				var _xr = xc	;// xc;
				var _yr = yc	;// yc;
				if (zoomTime < .5) {
					var _xAbs = (_xTo - w*.5) - _xr;
					var _yAbs = (_yTo - h*.5) - _yr;
					show_debug_message(string(_xAbs));
					var _px = _xAbs / w*wscale;
					var _py = _yAbs / h*hscale;
				
					var _ws = max(0.0001, animcurve_channel_evaluate(_chan[0], zoomTime) );
					var _hs = max(0.0001, animcurve_channel_evaluate(_chan[1], zoomTime) );
					wscale = _ws; hscale = _hs;
					var _wn = wscale * w, _hn = h * hscale;
				
					var _xn = _px * _wn;
					var _yn = _py * _hn;
	
					// Set the origin based on where the object should be.
					zoomX = _xTo - _xn - (xl + _wn);
					zoomY = _yTo - _yn - (yl + _hn);
					zoomTime += (1 / _duration * deltaTime);
				}
				else if (zoomTime > .5 && zoomTime < 1) {
					if (zoomDelay <= 0) {
						var _xAbs = (_xTo - w*.5) - _xr;
						var _yAbs = (_yTo - h*.5) - _yr;
						show_debug_message(string(_xAbs));
						var _px = _xAbs / w*wscale;
						var _py = _yAbs / h*hscale;
				
						var _ws = max(0.0001, animcurve_channel_evaluate(_chan[0], zoomTime) );
						var _hs = max(0.0001, animcurve_channel_evaluate(_chan[1], zoomTime) );
						wscale = _ws; hscale = _hs;
						var _wn = wscale * w, _hn = h * hscale;
				
						var _xn = _px * _wn;
						var _yn = _py * _hn;
	
						// Set the origin based on where the object should be.
						zoomX = _xTo - _xn - (xl + _wn);
						zoomY = _yTo - _yn - (yl + _hn);
						zoomTime += (1 / _duration * deltaTime);
					} else zoomDelay--;
				} else if (zoomTime >= 1) {
					zoomCallback(); // Ejecutar callback
					zoomTime = 0;
					wscale = _w;
					hscale = _h;
					zoomX = 0;
					zoomY = 0;

					time_source_stop(zoomStep); // Detener timesource
				}

			}, [_x, _y, _duration, _delay, wscale, hscale, _chan], -1);
			time_source_start(zoomStep);
		}
	}


	/// @desc Si esta acercandose hacia el centro de la pantalla
	static isZoom = function() {
		return (time_source_get_state(zoomStep) == time_source_state_active);
	}
	
	
	/// @desc Establece el callback para zoomCenter
	/// @param {function} callback
	static setZoomCallback = function(_callback) {
		zoomCallback = _callback ?? function() {};
		return self;
	}
	
	
	#endregion
		

		#region Utils
	/// @desc Para debug
	static toString = function() {
		static stateToString = function(_state) {
			switch (_state) {
				case time_source_state_active : return  "active"; break;
				case time_source_state_stopped: return "stopped"; break;
				case time_source_state_initial: return "initial"; break;
				case time_source_state_paused : return  "paused"; break;
			}
		}
		var _always =
		"DeltaTime: " + string(deltaTime) +
		"\ncamX: " + string(camera_get_view_x(camera) ) +
		"\ncamY: " + string(camera_get_view_x(camera) ) +
		"\nPositionsX: " + string(xl) + " - ["+ string(xc) + "] - " + string(xr) +
		"\nPositionsY: " + string(yl) + " - ["+ string(yc) + "] - " + string(yr) +
		"\nangle : " + string(angle) + 
		"\nxangle: " + string(xangle) +
		"\nyangle: " + string(yangle) +
		"\nwidth : " + string(w) + " - " + string(camera_get_view_width (camera) ) + " - *" + string(wscale) +
		"\nheight: " + string(h) + " - " + string(camera_get_view_height(camera) ) + " - *" + string(hscale) +
		"\nZoomState: "  + stateToString(time_source_get_state(zoomStep) ) +
		"\nZoomX: " + string(zoomX) +
		"\nZoomY: " + string(zoomY) +
		
		"\nShakeState: " + stateToString(time_source_get_state(shakeStep ) ) +
		"\nShakeX: " + string(shakeX) +
		"\nShakeY: " + string(shakeY) +
		
		"\nFollowState: " + stateToString(time_source_get_state(followStep) ) +
		"\nFollowX: " + string(followX) +
		"\nFollowY: " + string(followY);
		return _always;
	}
	
	
	/// @desc Regresa el valor x de todos los eventos
	static eventX = function() {
		return (shakeX + followX + zoomX );
	}
	
	
	/// @desc Regresa el valor y de todos los eventos
	static eventY = function() {
		return (shakeY + followY + zoomY );
	}


	#endregion
	
	
	#endregion
	
	
	#region init
	time_source_start(step);
	time_source_stop( shakeStep) ;  // Pasarlo a stop
	time_source_stop(followStep) ;  // Pasarlo a stop
	time_source_stop(zoomStep);
	
	#endregion
}
	
/// @ignore
/// @param {string} message
function lens_trace() {
	if (!__LENS_DEBUG) exit;
	var _msj="";
	var i=0;repeat(argument_count) {_msj += string(argument[i++]); }
	show_debug_message(_msj);
}