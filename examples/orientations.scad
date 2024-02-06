include <jl_scad/box.scad>

box_make(explode=0)
_box_shell(80, [0,0,0], repeat(10,6), true, BOX_ALL) {
    union() {};

    union() {
        box_half(BOX_ALL, inside=undef)
            box_pos() mytext(vector_name($box_half), $box_inside?"white":"orange");

        box_half(BOT, inside=undef)
            position(CENTER) wirecube($box_inside?"white":"orange");
    }
}

module mytext(txt,clr) color(clr) text3d(txt,h=0.5,size=5,anchor=BOTTOM,atype="ycenter",spacing=1.5);
module wirecube(clr) color(clr,0.5) tag("keep") edge_profile() square(0.5);
