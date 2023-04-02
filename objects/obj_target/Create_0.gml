/// @description 
// Feather ignore all

ps = part_system_create();
pt = part_type_create();

// set default emitter
pe = part_emitter_create(ps);

var _xmin = x, _ymin = y + (8*image_yscale);
var _xmax = x + (8*image_xscale), _ymax = y - (8*image_yscale)*2;
part_emitter_region(ps, pe, _xmin, _xmax, _ymin, _ymax, ps_shape_rectangle, ps_distr_linear);

// setup a default particle
part_type_blend(pt, false);
part_type_shape(pt, pt_shape_line);
part_type_size( pt, 0.05, 0.08, 0, 0.001);
part_type_orientation(pt, 88, 92, 0, 0, false);
part_type_scale(pt, 1.0, 1.0);
part_type_color3(pt, make_color_rgb(30, 200, 250), make_color_rgb(80, 80, 250), make_color_rgb(30, 30, 250) );
part_type_alpha3(pt, 0.8, 0.4, 0.0);
part_type_life(pt, 12, 24);
part_type_direction(pt, 260, 280, 0, 0.2);
part_type_gravity(pt, 0.2, 270);
part_type_speed(pt, 0.50, 0.70, 0.14, -0.92);

// Where 4 is the number of particles
var _burst = irandom_range(4, 8);
part_emitter_stream(ps, pe, pt, _burst);