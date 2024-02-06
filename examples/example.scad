include <jl_scad/utils.scad>
include <jl_scad/box.scad>
include <jl_scad/parts.scad>

$slop = 0.1;

$fs=$preview?0.5:0.125;
$fa = 1;

//Y(1) X(-5)
//cut_inspect(BACK)
box_make(print=false,explode=10.1,hide_box=false,hide_parts=false)
box_shell_rimmed([50,40,20],wall_sides=2,wall_top=1,rim_gap=0,rbot=1,rbot_inside=2,rtop=1,rtop_inside=1,rsides=5,rim_height=2,walls_outside=true)
{
    //$box_cut_color = undef;

    // placing parts
    box_half(BOT) {
        M(10,25) box_pos(LEFT+FRONT) standoff(h=5);
        Z(-1) Y(10) box_pos(CENTER, LEFT) standoff(h=3);
    }
    box_half(TOP) X(1) box_pos(LEFT) standoff(h=2,anchor=BOTTOM+LEFT);

    // back bottom cut
    box_half(BOT) Z(0.001) box_pos(BACK+BOT, BACK) box_cutout(rect([8,4]),depth=2,anchor=FRONT);

    // lid cuts
    box_half(TOP) {
        M(1,-5) box_pos(LEFT+BACK) box_cutout(rect([8,5],rounding=1),chamfer=0.5,depth=5,anchor=LEFT+FRONT);
        M(-5,10) box_pos(RIGHT) box_hole(3,rounding=0.5);
    }

    // vents
    box_half(TOP) box_pos(BACK) xcopies(2,5) box_cut() cuboid([1,5,5],rounding=0.5,anchor=CENTER);

    // side cut, no box_half() argument means it will apply to all box pieces
    box_half() box_pos(CENTER, LEFT) box_cutout(rect([14,7],chamfer=0.5),chamfer=0.5);

    // compound parts, must not be called via box_half() and box_pos()
    position(CENTER) box_standoff_clamp(h=5,od=4,id=2,gap=1.7,pin_h=2);
    X(-10) position(RIGHT) box_flip() box_screw_clamp(rounding=0.5);

    // walls
    box_half() Y(10) box_pos(FRONT) box_wall(RIGHT,width=1,fillet=1.5,gap=0.5);

    // outside cuts works as well
    box_half(BOT,inside=false) Z(-4) Y(10) box_pos(CENTER, RIGHT) box_hole(2,chamfer=0.5);

    // outside text
    box_half(TOP,inside=false) Z(-0.25) Y(2) box_pos(CENTER) box_cut() text3d("JL BOX", h=2, size=3, anchor=BOTTOM);

    box_half(TOP,inside=false) Z(-3) Y(2) {
        box_pos(TOP+RIGHT,RIGHT) text3d("RIGHT", h=0.25, size=3, anchor=BOTTOM+LEFT+BACK);
        box_pos(TOP+LEFT,LEFT) text3d("LEFT", h=0.25, size=3, anchor=BOTTOM+RIGHT+BACK);
    }

    // inspect by cutting away corner
    box_half(BOX_ALL) position(CENTER) box_cut("#58c") cube(30,anchor=LEFT+BACK);
}
