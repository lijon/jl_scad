include <jl_scad/box.scad>
include <jl_scad/parts.scad>

module my_box() {
    // a test box with one piece per side

    walls = [1,1,1];

    size = $box_make_size;

    base_height = size.z / 2;

    _box_shell(base_height, walls, true) {
        if(box_half(BOT)) {
            position(BOT) cube([size.x,size.y,walls[2]],anchor=BOT);
        }
        else if(box_half(TOP)) {
            position(TOP) cube([size.x,size.y,walls[1]],anchor=TOP);
        }
        else if(box_half(FRONT)) {
            position(FRONT) cube([size.x,walls[0],size.z],anchor=FRONT);
        }
        else if(box_half(BACK)) {
            position(BACK) cube([size.x,walls[0],size.z],anchor=BACK);
        }
        else if(box_half(LEFT)) {
            position(LEFT) cube([walls[0],size.y,size.z],anchor=LEFT);
        }
        else if(box_half(RIGHT)) {
            position(RIGHT) cube([walls[0],size.y,size.z],anchor=RIGHT);
        }
        // parts
        children();
    }
}

module txt(t) text3d(t, h=0.1, size=5, atype="ycenter", anchor=BOTTOM);

sz = [50,40,30];

box_make([BOT,TOP,LEFT,RIGHT,FRONT,BACK], sz, print=false, explode=20)
my_box()
{
    //box_half(BOT,$box_inside==true) show_anchors(5);

    for(v = BOX_ALL) box_half(v) {
        box_pos() txt(vector_name(v));
        box_pos() move([-10,7]) box_hole(3);
    }
}