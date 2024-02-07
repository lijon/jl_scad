include <jl_scad/utils.scad>
include <jl_scad/box.scad>
include <jl_scad/parts.scad>

$slop = 0.1;

$fs=$preview?0.5:0.125;
$fa = 1;

//Y(1) X(-5)
//cut_inspect(BACK)
box_make(print=false,explode=10.1,hide_box=false,hide_parts=false)
box_shell_base_lid([50,40,20],wall_sides=2,wall_top=1,rim_gap=0,rbot=1,rbot_inside=2,rtop=1,rtop_inside=1,rsides=5,rim_height=2,walls_outside=true)
{
    //$box_cut_color = undef;

    // placing parts
    M(10,25) box_part(BOT, LEFT+FRONT) standoff(h=5);
    Z(-1) Y(10) box_part(BOT+LEFT) standoff(h=3);

    X(1) box_part(TOP, LEFT) standoff(h=2,anchor=BOTTOM+LEFT);

    // back bottom cut
    Z(0.001) box_part(BACK+BOT, BOT) box_cutout(rect([8,4]),depth=2,anchor=FRONT);

    // lid cuts
    M(1,-5) box_part(TOP, LEFT+BACK) box_cutout(rect([8,5],rounding=1),chamfer=0.75,depth=5,anchor=LEFT+FRONT);
    M(-5,10) box_part(TOP, RIGHT) box_hole(3,rounding=0.5);

    // vents
    box_part(TOP, BACK) xcopies(2,5) box_cut() cuboid([1,5,5],rounding=0.5,anchor=CENTER);

    // side cut, LEFT matches both TOP and BOT and will be applied to both
    box_part(LEFT) box_cutout(rect([14,7],chamfer=0.5),chamfer=0.5);

    // compound parts, must not be called via box_half() and box_pos()
    position(CENTER) box_standoff_clamp(h=5,od=4,id=2,gap=1.7,pin_h=2);
    X(-10) position(RIGHT) box_flip() box_screw_clamp(rounding=0.5);

    // walls on both top and bottom
    Y(10) box_part([TOP,BOT],FRONT) box_wall(RIGHT,width=1,fillet=1.5,gap=0.5);

    // outside cuts works as well
    Z(-4) Y(10) box_part(BOT+RIGHT,inside=false) box_hole(2,chamfer=0.5);

    // outside text
    Z(-0.25) Y(2) box_part(TOP,inside=false) box_cut() text3d("JL BOX", h=2, size=3, anchor=BOTTOM);

    //box_half(TOP,inside=false) 
    Z(-3) Y(2) {
        box_part(TOP+RIGHT,TOP,inside=false) text3d("RIGHT", h=0.25, size=3, anchor=BOTTOM+LEFT+BACK);
        box_part(TOP+LEFT,TOP,inside=false) text3d("LEFT", h=0.25, size=3, anchor=BOTTOM+RIGHT+BACK);
    }

    // inspect by cutting away corner, we don't use box_part() or box_pos(), but manually position the cube.
    box_half(BOX_ALL) position(CENTER) box_cut("#58c") cube(30,anchor=LEFT+BACK);

    Y(-3) box_part(BOT,BACK) box_cutout(keyhole(),anchor=BACK);
}