// Feather ignore all
#macro __LENS_VERSION "1.1.3"
#macro __LENS_CREDITS "@TabularElf - https://tabelf.link/"
#macro __LENS_VERBOSE false
#macro __LENS_DEBUG   false

show_debug_message(
	"Lens {0} initalized! Created by {1} [verboseState: {2}]", 
	__LENS_VERSION, __LENS_CREDITS, __LENS_VERBOSE ? "True" : "False"
);

#macro LENS_MOUSE_FOLLOW "MouseFollow"
#macro LENS_MOUSE_BORDER "MouseBorder"

/// @param {real} view
/// @param {real} x
/// @param {real} y
/// @param {real} width
/// @param {real} heigth
/// @param {real} [angle]
/// @return {Struct.Lens}
function Lens(_view, _x, _y, _w, _h, _angle=0) constructor 
{
	#region Variables
	view   = _view;
	camera = camera_create(); // Crear camara en startup
	
	// Tamaño y posicion
	w = _w;
	h = _h;
	hPort = 0;
	wPort = 0;
	relation = w / min(1, h);
	
	wscale = 1;
	hscale = 1;
	x1 = _x - _w;   // left
	y1 = _y - _h;   // top
	x2 = _x;        // right
	y2 = _y;        // bottom 

	// Posicion final que se coloca la camara (es el centro de x1,y1 e x2,y2)
	x = _x - _w*.5;
	y = _x - _h*.5;
	
	xen = 0;
	yen = 0;
	
	// Camera
	camera_set_view_pos (camera, x, y);
	camera_set_view_size(camera, w, h);
	
	angle = _angle; // Posiciones teniendo en cuenta el centro y angulo de la camara
	var _sin = dsin(angle), _cos = dcos(angle);
	xangle = x1*_cos + y1*_sin;
	yangle = x1*_sin + y1*_cos;

	// limites de la camara global, infinity no posee limites
	xLimit = [-infinity, infinity];
	yLimit = [-infinity, infinity];
	
	// Control
	deltaTime = 0;
	gameSpeed = game_get_speed(gamespeed_fps);
	step = time_source_create(time_source_game, 1, time_source_units_frames, function() {
		if (view_camera[view] != camera) updateCamera();
		// Control
		deltaTime = (!__LENS_DEBUG ) ? 
			(delta_time * 0.000001) * gameSpeed : 1;
		
		xen = (x1 + targetX + shakeX);
		yen = (y1 + targetY + shakeY);
		
		var _x = (xen + w *.5), _y = (yen + h *.5);
		x = clamp(_x, xLimit[0], xLimit[1] );
		y = clamp(_y, yLimit[0], yLimit[1] );
		
		var _w = max(1, w * wscale), _h = max(1, h * hscale);
		camera_set_view_pos (camera, x, y);
		camera_set_view_size(camera, w, h);
	}, [], -1);

	var _same = function() {} // Evitar crear tantas funciones
	
	#region Shake
	shakeX = 0; // X e Y que cambian respecto al shake
	shakeY = 0; //
	shakeTime = 0;
	// Updadate - function
	shakeFnStep = _same;

	shakeStep = time_source_create(step, 1, time_source_units_frames, _same);
	
	#endregion

	#region Follow
	targetX = 0;
	targetY = 0;
	targetList = ds_list_create();
	
	targetTimeX = 0;
	targetTimeY = 0;
	targetXPrevious = 0;
	targetYPrevious = 0;
	
	targetLimitX = [-infinity, infinity];
	targetLimitY = [-infinity, infinity];
	
	getTargetLimitX = function() 
	{
		static array = [-infinity, infinity]
		return array;
	}
	
	getTargetLimitY = function() 
	{
		static array = [-infinity, infinity]
		return array;
	}
	
	targetStep = time_source_create(step      , 1, time_source_units_frames, _same);
	targetEnd  = time_source_create(targetStep, 1, time_source_units_frames, _same);
	
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
		step: time_source_create(step, 1, time_source_units_frames, _same), 
	};
		
	#endregion


	#region Methods

		#region Basic
	/// @param {real} view_index
	static setCamera = function(_view) 
	{
		if (view_enabled != false) view_enabled = true;
		view = _view;
		view_set_camera (view, camera); // Establecer la camara a esta vista
		view_set_visible(view, true);	// Poner en true la camara
		
		return self;
	}

	/// @desc Actualiza la camara
	static updateCamera = function() 
	{
		if (!view_enabled) view_enabled = true;
		view_set_camera (view, camera); // Establecer la camara a esta vista
		view_set_visible(view, true);	// Poner en true la camara
	}
	
	
	/// @return {real}
	static getX = function() 
	{
		return (camera_get_view_x(camera) ); 
	}
	
	/// @return {real}
	static getY = function() 
	{
		return (camera_get_view_y(camera) ); 
	}
	
	/// @param {real} x
	static setX = function(_x) 
	{
		var _w = getW();
		x1 = _x;
		x2 = _x + _w;
		return self;
	}
	
	/// @param {real} y
	static setY = function(_y) 
	{
		var _h = getH();
		y1 = _y;
		y2 = _y + _h;
		return self;
	}
	
	/// @param {real} x
	/// @param {real} y
	static setXY = function(_x, _y) 
	{
		setX(_x); setY(_y);
		return self;
	}
	
	
	/// @param {real} x
	static addX = function(_x)
	{
		return self;
	}
	
	/// @param {real} y
	static addY = function(_y) 
	{
		return self;
	}	
	
	/// @param {real} x
	/// @param {real} y	
	static addXY = function(_x, _y) 
	{
		addX(_x); addY(_y);
		return self;
	}
	
	
	static getW = function() 
	{
		return max(1, (w*wscale) ); 
	}
	
	static getH = function() 
	{
		return max(1, (h*hscale) ); 
	}
	
	/// @param {real} width
	static setW = function(_v) 
	{
		return self;
	}
	
	/// @param {real} height
	static setH = function(_v) 
	{
		return self;
	}
	
	/// @param {real} width
	/// @param {real} height
	static setWH = function(_w, _h) 
	{
		return self;
	}
	
	
	/// @param {real} width
	static addW = function(_w) 
	{
		return setW(w + _w);
	}
	
	/// @param {real} height
	static addH = function(_h) 
	{
		return setH(h + _h);
	}
	
	
	/// @param {real} angle
	static setAngle = function(_angle) 
	{
		angle = _angle;
		return self;
	}
	
	/// @param {real} angle
	static addAngle = function(_angle) 
	{
		angle = angle + _angle;
		return self;
	}
	
	#endregion
		
		
		#region Shake
	/// @desc Ejecutar una funcion cada actualizacion del shakeEvent
	/// @param {function} stepFunction
	static setShakeFnStep = function(_fn) 
	{
		shakeFnStep = method(self, _fn);
		return self;
	}
	
	/// @param {real} duration
	/// @param {bool} timeUnit	false: frames true: seconds
	/// @param {real} forceX
	/// @param {real} forceY
	/// @param {Asset.GMAnimcurve} animcurve
	/// @param {Array<real>, Array<string>} channels name or index
	static shake  = function(_time, _unit, _forceX, _forceY=_forceX, _animcurve=acLensShake, _channels=[0, 1], _fnEnd) {
		static fn = function() {};
		
		// Solo si esta detenido
		if (!isShake() ) {
			#region Setup
			// Es undefined
			_fnEnd ??= fn;
			if (_unit) _time *= gameSpeed;
			
			var _chan = [animcurve_get_channel(_animcurve, _channels[0]), animcurve_get_channel(_animcurve, _channels[1]) ];
			var _args = [_time, _forceX, _forceY, _chan, _fnEnd]
			
			#endregion

			time_source_reconfigure(shakeStep, 1, time_source_units_frames, function(_time, _forceX, _forceY, _channels, _fn) {
				// Ejecutar funcion
				shakeFnStep();
				
				// Obtener valores
				shakeX = animcurve_channel_evaluate(_channels[0], shakeTime) * _forceX;
				shakeY = animcurve_channel_evaluate(_channels[1], shakeTime) * _forceY;
				
				// Aumentar tiempo
				shakeTime = shakeTime + (1 / (_time * deltaTime) );
				
				// Detener shake event
				if (shakeTime >= 1) {
					// Ejecutar funcion de final
					_fn();
					
					// Reiniciar
					shakeX = 0;
					shakeY = 0;
					shakeTime = 0;
					// Detener time-source
					time_source_stop(shakeStep);
				}
			}, _args, -1);
			time_source_start(shakeStep); // Iniciar time source
		}
	}
	
	/// @desc Si esta sacudiendo la camara
	static isShake = function() 
	{
		return 	(time_source_get_state(shakeStep) == time_source_state_active);
	}
	
	
	#endregion
		
		#region Follow
	/// @param {real} speedX
	/// @param {real} speedY
	/// @param {real} resetTime	tiempo para comprobar si hay que reiniciar el proceso del animcurve
	/// @param {Asset.GMAnimcurve} animcurve
	/// @param {Array<real>, Array<string>} channels name or index
	static follow = function(_speedX, _speedY=_speedX, _resetTime=5, _animcurve=acLensFollow, _channels=[0, 1]) 
	{
		if (!isFollow() ) {
			#region Setup
			var _chan = [animcurve_get_channel(_animcurve, _channels[0]), animcurve_get_channel(_animcurve, _channels[1]) ];
			var _args = [_speedX*gameSpeed, _speedY * gameSpeed, _chan];
			
			#endregion
			
			time_source_reconfigure(targetStep, 1, time_source_units_frames, function(_speedX, _speedY, _channels) {
				var n = ds_list_size(targetList);
				if (n > 0) {
					// Poner el origen en 0,0
					var _xt=0, _yt=0;
					
					#region Obtener posiciones
					for (var i=0; i<n; i=i+1) {
						var _ins = targetList[| i];
						// Struct (solo si tienen x e y como variables)
						if (is_struct(_ins) ) {
							_xt += _ins[$ "x"] ?? 0;
							_yt += _ins[$ "y"] ?? 0;
						}
						// Instancia
						else if (instance_exists(_ins) ) {
							_xt += _ins.x;
							_yt += _ins.y;
						}
						// Eliminar si no
						else {
							ds_list_delete(targetList, i);
							n = n - 1;
						}
					}

					#endregion

					#region Actualizar valores
					var _lx = getTargetLimitX(self), _ly = getTargetLimitY(self);
					_xt = clamp(_xt, _lx[0], _lx[1]);
					_yt = clamp(_yt, _ly[0], _ly[1]);
					
					n = max(1, n);
					_xt = (_xt / n) - getW();
					_yt = (_yt / n) - getH();
					
					var _cx = animcurve_channel_evaluate(_channels[0], targetTimeX );
					var _cy = animcurve_channel_evaluate(_channels[1], targetTimeY );
					targetX = lerp(targetX, _xt, _cx);
					targetY = lerp(targetY, _yt, _cy);

					targetTimeX = min(1, targetTimeX + (1 / _speedX * deltaTime) );
					targetTimeY = min(1, targetTimeY + (1 / _speedY * deltaTime) );
					
					#endregion
					
				// Si no hay elementos parar
				} else time_source_stop(targetStep);
			}, [_speedX, _speedY, _chan], -1);
			if (_resetTime > 0) {
				time_source_reconfigure(targetEnd, _resetTime, time_source_units_frames, function(_x, _y) {
					if (targetX == targetXPrevious) && (targetY == targetYPrevious) {
						var _xt = targetTimeX*.5, _yt = targetTimeY*.5;
						followTime[0] = max(0, targetTimeX - _xt); 
						followTime[1] = max(0, targetTimeY - _yt); 
					}
				
					targetXPrevious = targetX;
					targetYPrevious = targetY;
					
				}, _args, -1, time_source_expire_after);
			}
			// Iniciar time source
			time_source_start(targetStep);
		}
	}
	
	
	/// @desc Deja de seguir a un objeto
	static stopFollow = function() 
	{
		// No reiniciar posicion x e y de follow
		targetX = 0;
		targetY = 0;
		time_source_stop(targetStep);
	}
	
	
	/// @desc Añade objetivos para seguir
	static addTarget  = function(_target) {
		if (is_array(_target) ) {
			array_foreach(_target, function(_v) {addTarget(_v); } );
		}
		else {
			ds_list_add(targetList, _target);
		}
		return self;
	}


	/// @desc Indica si existe ya esta agregado el objetivo a seguir
	static existsTarget = function(_target) 
	{
		return (ds_list_find_index(targetList, _target) );
	}
	
	
	/// @desc Elimina un objetivo de la lista
	static removeTarget = function(_target)
	{
		var _index = existsTarget(_target);
		if (_index != -1) {
			ds_list_delete(targetList, _index);
			return true;
		}
		
		return false;
	}


	/// @desc Si esta siguiendo a algun objetivo
	static isFollow = function() {
		return 	(time_source_get_state(targetStep) == time_source_state_active);
	}
	
	
	/// @param {function} limitX funcion() {return {array} }
	static setFollowLimitX = function(_x) 
	{
		getTargetLimitX = method(self, _x);
		return self;
	}
	
	
	/// @param {function} limitY funcion() {return {array} }
	static setFollowLimitY = function(_y) 
	{
		getTargetLimitY = method(self, _y);
		return self;
	}
	
	
	/// @param {function} limitX funcion() {return {array} }
	/// @param {function} limitY funcion() {return {array} }
	static setFollowLimitXY = function(_x, _y)
	{
		setFollowLimitX(_x);
		setFollowLimitY(_y);
		
		return self;
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
			lens_trace("START ZOOM");
			time_source_reconfigure(zoomStep, 1, time_source_units_frames, function(_xTo, _yTo, _duration, _delay, _w, _h, _chan) {
				var _xr = (x1 + w)// - followX/2;
				var _yr = (y1 + h)// - followY/2;
				if (zoomTime > .50 && zoomTime < 1.0) {
					if (zoomDelay > 0) {zoomDelay--; exit; }
				}

				var _xAbs = _xTo - _xr;// (_xTo - w*.5) - _xr;
				var _yAbs = _yTo - _yr;// (_yTo - h*.5) - _yr;

				var _px = _xAbs / w*wscale;
				var _py = _yAbs / h*hscale;
				
				var _ws = max(0.0001, animcurve_channel_evaluate(_chan[0], zoomTime) );
				var _hs = max(0.0001, animcurve_channel_evaluate(_chan[1], zoomTime) );
				wscale = _ws; hscale = _hs;
				var _wn = wscale * w, _hn = h * hscale;
				
				var _xn = _px * _wn;
				var _yn = _py * _hn;
	
				// Set the origin based on where the object should be.
				zoomX = _xTo - _xn - (x1 + _wn);
				zoomY = _yTo - _yn - (y1 + _hn);
				zoomTime = zoomTime + (1.001 / _duration * deltaTime);
				
				if (zoomTime >= 1.0) {
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
		"\nPositionsX: " + string(x1) + " - " + string(x2) +
		"\nPositionsY: " + string(y1) + " - " + string(y2) +
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
		"\nFollowX: " + string(followTime[0]) +
		"\nFollowY: " + string(followTime[1]);
		return _always;
	}


	#endregion
	
	
	#endregion
	
	
	#region init
	time_source_start(step);
	time_source_stop( shakeStep) ;  // Pasarlo a stop
	time_source_stop(targetStep) ;  // Pasarlo a stop
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