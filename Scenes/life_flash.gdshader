shader_type canvas_item;
varying vec4 v_vertex_color;
uniform bool active = false;
uniform float Strength : hint_range(0,20) = 5;
uniform float RandomOffset = 5.0;

float random( float seed )
{
	return fract( 543.2543 * sin( dot( vec2( seed, seed ), vec2( 3525.46 + RandomOffset, -54.3415 ) ) ) );
}

void vertex(){
v_vertex_color = COLOR;

if(active==true) {  
	
	vec2 VERTEX_OFFSET = VERTEX;
	VERTEX_OFFSET.x += (
		random(
			( trunc( VERTEX_OFFSET.y))
		+	TIME
		) - 0.5
	) * Strength ;

	VERTEX_OFFSET.y += (
		random(
			( trunc( VERTEX_OFFSET.x))
		+	TIME
		) - 0.5
	) * Strength;
	
	VERTEX = VERTEX_OFFSET;	
}

}
void fragment() {

vec4 previous_color = v_vertex_color * texture(TEXTURE, UV);  
vec4 white_color = vec4(1.0,0.0,0.0, previous_color.a);  
vec4 new_color = previous_color;  
if(active==true) {  
	new_color = white_color;  
}  
COLOR = new_color;  
}




