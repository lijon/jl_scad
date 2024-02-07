include <jl_scad/box.scad>
include <jl_scad/parts.scad>

// $fa = 1;
// $fn = 48;

$fs=$preview?0.5:0.125;
$fa = 1;

module my_box(size) {
    // a test box with one piece per side
    size = scalar_vec3(size);

    // left, right, front, back, bot, top
    //walls = [0.5,0.5,1,1,3,2];
    walls = [1,1,1,1,2,2];
    split = size / 2;
    halves = BOX_ALL;

    _box_shell(size, split, walls, false, halves) {
        for(i = idx(halves)) { // implicit union
            h = halves[i];
            w = walls[i];
            sz = [h.x!=0?w:size.x, h.y!=0?w:size.y, h.z!=0?w:size.z];
            box_half(h) position(h) color("#fff7") cube(sz, anchor=h);
        }
        // parts
        children();
    }
}

module txt(t) text3d(t, h=0.5, size=5, atype="ycenter", anchor=BOTTOM);

sz = [50,40,30];

$box_inside_color = "orange";

//halves = [BOT,TOP,LEFT,RIGHT,BACK];
halves = BOX_ALL;
box_make(halves, print=true, top_pos=BACK)
my_box(sz)
{

    box_part(BOX_ALL) txt(vector_name($box_half));
    // box_part(BOX_ALL) move([0,8]) box_hole(5, chamfer=0.5);

    // box_cut()
    //     box_half(BOX_ALL, inside=false) // we use box_half to skip the side position and anchor
    //         position(LEFT+FRONT)
    //             cube([15,15,sz.z*0.75],anchor=CENTER,spin=45);
}

// p = keyhole(r=0);
// !union() {
//     region(p);
//     move_copies(p) color("red",0.5) circle(d=0.2,$fn=8);
// }