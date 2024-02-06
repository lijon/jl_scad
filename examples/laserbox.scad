include <jl_scad/box.scad>
include <jl_scad/parts.scad>
include <jl_scad/utils.scad>

$fs = $preview?0.5:0.125;
$fa = 1;

$slop = 0.08;
 
laser_d = 9.1;
laser_l = 20;

switch_h = 8;
switch_d = 15;

bat_sz = [48,26,18]; // 9V max size
bat_clip = 6;
box_sz = [bat_sz.x+laser_l+bat_clip+switch_d+4,bat_sz.y+3,bat_sz.z+2];

$box_outside_color = "#fffb";
$box_inside_color = "#9a9b";
$box_cut_color = undef;

module toggle_switch(anchor=BOTTOM,spin) {
    cube([13,switch_h,9],anchor=anchor,spin=spin) {
        position(BOTTOM) cyl(d=6,l=7,anchor=TOP)
            position(BOTTOM) up(1) yrot(20) cyl(d1=3,d2=2,rounding1=1,rounding2=0,l=8,anchor=TOP);
        position(TOP) xcopies(5,3) cube([1,2,6],anchor=BOTTOM);
    }
}

//cut_inspect(LEFT,ofs=[-21.1,0,0]) // inspect only laser mount
//cut_inspect(BACK)
box_make(print=true)
box_shell_base_lid(box_sz,rsides=6,wall_sides=1.6,wall_top=2,base_height=3,rim_height=2,rbot_inside=1,rtop_inside=1)
{
    size = $parent_size;

    // laser
    box_half(TOP) box_pos(CENTER, LEFT) box_hole(5.5,chamfer=1);
    box_half([TOP,BOT]) {
        s = [laser_l+1,laser_d+2,size.z/2-1.5];
        box_pos(LEFT)
            X(0.5) diff() cuboid(s,anchor=LEFT+BOT,rounding=-1.5,edges=BOTTOM/*,except=LEFT*/)
                tag("remove") position(TOP) Z(0.001) {
                    cube([laser_l*0.4,s.y+5,s.z-2],anchor=TOP);
                    cube([s.x+5,laser_d*0.4,s.z-2],anchor=TOP);
                }
        box_pos(CENTER, LEFT) box_cut() cyl(d=laser_d,h=laser_l,anchor=BOT); // cut both base and lid
    }
    box_half(TOP) box_pos(CENTER, LEFT) box_preview("#f667") tag(BOX_KEEP_TAG) cyl(d=laser_d,h=laser_l,anchor=BOT);

    // switch
    box_half(TOP) box_pos(CENTER, RIGHT) {
        box_hole(7);
        box_preview("#6d67") toggle_switch(spin=90);
    }

    // screw holes
    for(a = [BACK+LEFT, FRONT+RIGHT, BACK+RIGHT, FRONT+LEFT])
        M(a * -0.5) position(a) box_screw_clamp(anchor=a,gap=0.1);

    // battery
    box_half(TOP) box_pos(LEFT)
        box_preview() X(laser_l+3) Z(-1) cuboid(bat_sz,rounding=2,anchor=BOTTOM+LEFT)
            position(RIGHT) X(1) cuboid([4,25,15],rounding=6,anchor=LEFT,edges="X");

    // text
    box_half(TOP, inside=false) box_pos()
        Z(-0.4) box_cut() text3d("LASER", h=2, size=10, atype="ycenter", anchor=BOTTOM);

    
    // vents
    box_half(TOP) X(11) box_cut() for(a = [BACK,FRONT])
         box_pos(a+LEFT) xcopies(3,4,sp=0) cuboid([1.5,8,8],rounding=0.75,anchor=CENTER);

}
