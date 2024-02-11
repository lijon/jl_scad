include <jl_scad/box.scad>
include <jl_scad/parts.scad>
include <jl_scad/utils.scad>

$fs = $preview?0.5:0.25;
$fa = 1;

$slop = 0.1;

pcb_pad = 1;
sensor_ofs = -12;

vent_z = 15;
vent_y = 4;
vent_x = 1.5;

box_sz = [82,46,19];

middle_cut = 31;

//$box_show_previews = false;

//cut_inspect(LEFT)
//cut_inspect(LEFT,ofs=-28)
//cut_inspect(LEFT,ofs=-middle_cut/2,s=150) cut_inspect(RIGHT,ofs=-middle_cut/2,s=150) // middle cutout
box_make(print=true,explode=0.1,hide_box=false)
box_shell_base_lid(box_sz,rsides=4,rtop_inside=1,rbot_inside=1,rtop=1,wall_sides=1.6,base_height=4,rim_height=5)
{
    M(pcb_pad,pcb_pad) position(FRONT+LEFT) d1mini(anchor=FRONT+LEFT);
 
    X(sensor_ofs) {
        position(RIGHT) dht22();

        X(-8-3) { // isolating wall
            box_part(CENTER,RIGHT) box_wall(width=5,gap=0.1,anchor=BOTTOM+RIGHT);
            M(0.5,3,$box_half_height) box_part(BOT,RIGHT+FRONT) box_cut() cube([6,4,4],anchor=TOP+RIGHT+FRONT);
        }
    }

    position(CENTER) grove_oled_066();

    for(a = [BACK+LEFT, FRONT+RIGHT])
        M(a * -0.5) position(a) box_screw_clamp(anchor=a,gap=0.1);

    Y(-3) box_part(BOT,BACK) box_cutout(keyhole(3.5,7.5),anchor=BACK);

    box_cut()
        box_part(TOP,[BACK+LEFT,FRONT+LEFT,BACK+RIGHT,FRONT+RIGHT])
            X(sensor_ofs*$box_anchor.x) xcopies(3.5,5) cuboid([vent_x,vent_y,vent_z],rounding=vent_x/2,anchor=CENTER);

}



