include <jl_scad/utils.scad>
include <jl_scad/box.scad>
include <jl_scad/parts.scad>

$slop = 0.1;

$fs=$preview?0.5:0.125;
$fa = 1;

cut_inspect(BACK)
box_make(BOX_BOTH,topsep=0.1)
//color("#55f7")
box_shell1([50,40,20],wall_bot=1.2,wall_top=1.2,wall_side=1.6,rim_gap=0,rbot=1,rbot_inside=2,rtop=1,rtop_inside=1,rsides=5,base_height=0,hide=false)
{

    // placing parts
    M(10,25) box_place(BOT) standoff(h=5); // default box anchor is left+front corner.
    Y(10) box_place(BOT+LEFT, CENTER) standoff(h=3);
    X(1) box_place(TOP, LEFT) standoff(h=2,anchor=BOTTOM+LEFT);

    // back bottom cut
    Z(0.001) box_place(BACK+BOT, BACK+BOT, BOX_CUT) box_cutout(rect([8,4]),depth=2,anchor=FRONT);

    // lid cuts
    M(1,10) box_place(TOP, LEFT, BOX_CUT) box_cutout(rect([8,5],rounding=1),chamfer=0.5,depth=5,anchor=LEFT);
    M(-5,10) box_place(TOP, RIGHT, BOX_CUT) box_hole(3,rounding=0.5);

    // vents
    box_place(TOP, BACK, BOX_CUT) xcopies(2,5) cuboid([1,4,4],rounding=0.5,anchor=CENTER);

    // side cut
    box_place(LEFT, CENTER, BOX_CUT) box_cutout(rect([14,7],chamfer=0.5),chamfer=0.5);

    // compound parts, must not be called via box_place()
    position(CENTER) box_standoff_clamp(h=5,od=4,id=2,gap=1.7,pin_h=2);
    X(-10) position(RIGHT) box_flip() box_screw_clamp(rounding=0.5);

    // walls
    X(17) {
        box_place(BOT, LEFT) box_wall(BACK,width=1,fillet=1.5,gap=1);
        box_place(TOP, LEFT) box_wall(BACK,width=1,fillet=1.5);
    }

    // outside cuts works as well
    Z(-4) Y(10) box_place(BOT+RIGHT, CENTER, BOX_CUT, inside=false) box_hole(2,chamfer=0.5);

    // outside text
    Z(-0.25) Y(2) box_place(TOP, CENTER, BOX_CUT, inside=false) text3d("JL BOX", h=2, size=3, anchor=BOTTOM);

    Z(-3) Y(2) {
        box_place(TOP+RIGHT,TOP+RIGHT,inside=false) text3d("RIGHT", h=0.25, size=3, anchor=BOTTOM+LEFT+BACK);
        box_place(TOP+LEFT,TOP+LEFT,inside=false) text3d("LEFT", h=0.25, size=3, anchor=BOTTOM+RIGHT+BACK);
    }
}
