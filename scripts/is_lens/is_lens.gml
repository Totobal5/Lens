/// @desc Checks if the value is a Lens constructor
/// @param	{Struct.Lens} lens
/// @return {Bool}
function is_lens(_lens)
{
	return (is_struct(_lens) && instanceof(_lens) == "Lens");
}