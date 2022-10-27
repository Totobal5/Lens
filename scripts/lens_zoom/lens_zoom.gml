// Feather ignore all
/// @param	{Struct.Lens}							lens				Lens Struct
/// @param	{Real}									duration			Duration of the event in frames
/// @param	{Real}									x_target			Position to zoom in
/// @param	{Real}									y_target			Position to zoom in
/// @param	{Struct.AnimCurve,Asset.GMAnimCurve}	[animation_curve]	Animation_curve
/// @param	{Real, String}							[x_channel]			Channel index/name (recommended 1 -> 0 -> 1)
/// @param	{Real, String}							[y_channel]			Channel index/name (recommended 1 -> 0 -> 1)
function lens_zoom(_lens, _duration, _xTarget, _yTarget=_xTarget, _animcurve=an_lens_zoom, _xChannel=0, _yChannel=1) 
{
	with (_lens)
	{
		if (isZooming() ) return undefined;
		__zoomEvent = true;
		__zoomXChan = animcurve_get_channel(_animcurve, _xChannel);
		__zoomYChan = animcurve_get_channel(_animcurve, _yChannel);
		
		__zoomXTarget = _xTarget;
		__zoomYTarget = _yTarget;
		__zoomDuration = _duration;
		
		/*
		var _event = new __LensEvent(_lens, method(_lens, __eventZoom), [
			_animcurve,
			_xChannel, _yChannel,
			_xTarget , _yTarget,
			_duration
		]);
		array_push(global.__lensEvents, _event);
		
		return (_event);*/
	}
}