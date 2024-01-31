include <jl_scad/utils.scad>
include <jl_scad/box.scad>
include <jl_scad/parts.scad>

$slop = 0.1;

$fs=$preview?0.5:0.125;
$fa = 1;

//cut_inspect(BACK)
box_make(BOX_BOTH,TOP,topsep=0.1)
//color("#55f7")
box_shell1([50,40,20],wall_bot=2.2,wall_top=1.2,wall_side=1.6,rim_gap=0,rbot=1,rbot_inside=2,rtop=1,rtop_inside=1,rsides=5,base_height=0,hide=false)
{
    //$box_cut_color = undef;

    // placing parts
    M(10,25) box_part(BOT) standoff(h=5); // default box anchor is left+front corner.
    Z(-1) Y(10) box_part(BOT+LEFT, CENTER) standoff(h=3);
    X(1) box_part(TOP, LEFT) standoff(h=2,anchor=BOTTOM+LEFT);

    // back bottom cut
    Z(0.001) box_part(BACK+BOT, BACK+BOT) box_cutout(rect([8,4]),depth=2,anchor=FRONT);

    // lid cuts
    M(1,-5) box_part(TOP, LEFT+BACK) box_cutout(rect([8,5],rounding=1),chamfer=0.5,depth=5,anchor=LEFT+FRONT);
    M(-5,10) box_part(TOP, RIGHT) box_hole(3,rounding=0.5);

    // vents
    box_part(TOP, BACK) xcopies(2,5) box_cut() cuboid([1,4,4],rounding=0.5,anchor=CENTER);

    // side cut
    box_part(LEFT, CENTER) box_cutout(rect([14,7],chamfer=0.5),chamfer=0.5);

    // compound parts, must not be called via box_part()
    position(CENTER) box_standoff_clamp(h=5,od=4,id=2,gap=1.7,pin_h=2);
    X(-10) position(RIGHT) box_flip() box_screw_clamp(rounding=0.5);

    // walls
    Y(10) {
        box_part(BOT, FRONT) box_wall(RIGHT,width=1,fillet=1.5,gap=1);
        box_part(TOP, FRONT) box_wall(RIGHT,width=1,fillet=1.5);
    }

    // outside cuts works as well
    Z(-4) Y(10) box_part(BOT+RIGHT, CENTER, inside=false) box_hole(2,chamfer=0.5);

    // outside text
    Z(-0.25) Y(2) box_part(TOP, CENTER, inside=false) box_cut() text3d("JL BOX", h=2, size=3, anchor=BOTTOM);

    Z(-3) Y(2) {
        box_part(TOP+RIGHT,TOP+RIGHT,inside=false) text3d("RIGHT", h=0.25, size=3, anchor=BOTTOM+LEFT+BACK);
        box_part(TOP+LEFT,TOP+LEFT,inside=false) text3d("LEFT", h=0.25, size=3, anchor=BOTTOM+RIGHT+BACK);
    }

    // inspect by cutting away corner
    box_part(CENTER,CENTER) box_cut("#58c") cube(30,anchor=LEFT+BACK); 
}
