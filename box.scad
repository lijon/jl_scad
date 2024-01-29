include <BOSL2/std.scad>

BOX_BASE = "base";
BOX_LID = "lid";
BOX_BOTH = undef;

$box_cut = false;
$inside_box_part = false;
$inside_box_inside = false;
$box_make_anchor = BOTTOM;
$box_make_orient = UP;

module box_part(half, cut=false) {
    $inside_box_part = true;
    if((is_undef(half) || $box_half == half) && $box_cut==cut)
        children();
}

module box_inside() {
    sz = $parent_size - [$box_side*2,$box_side*2,$box_bot+$box_top];
    $inside_box_inside = true;
    recolor($box_inside_color)
    position(BOTTOM)
    up($box_bot)
    attachable(BOTTOM,0,UP,size=sz) {
        //#cube(sz,anchor=CENTER);
        union() {}; // dummy
        children();
    }
}


// side: optional side of the box, defaults to TOP for lid and BOTTOM for base. Useful to attach parts to the left/right/front/back inside.
// anchor: anchor children to box. The corresponding axis of the anchor is replaced according to current side. (so it will include BOTTOM for base parts, TOP for lid parts, etc)
/*
Currently child anchors (and sizes) are given from the POV of the children before they are rotated:
    - lid: Y 180
    - left: Y 90 CW
    - right: Y 90 CCW
    - back: X 90 CCW
    - font: X 90 CW

    (this is with spin=0 override in box_pos())
    Should we add helper func that gives us child anchor in global BOX coordinates? and always uses BOTTOM.z?
*/
module box_pos(anchor=LEFT+FRONT,side) {
    // for any non-zero element of b, replace the corresponding element in a[i] with -b[i]
    function v_invert_override(a,b) =
        assert( is_list(a) && is_list(b) && len(a)==len(b), "Incompatible input")
        [for (i = [0:1:len(a)-1]) b[i] != 0 ? -b[i] : a[i]];

    if($inside_box_part) {
        orient = -default(side,$box_half==BOX_LID ? TOP : BOTTOM);
        $box_wall = orient == UP ? $box_bot : orient == DOWN ? $box_top : $box_side;
        $box_spin = orient == UP ? 0 : 180; // ??
        position(v_invert_override(anchor,orient))
            orient($inside_box_inside ? orient : -orient,spin = 0)
                children();
    } else {
        position(anchor)
            children();
    }
}

module box_make(half=BOX_BOTH,pos=TOP,topsep=0.1,sidesep=10) {
    module do_half(half,anchor=BOTTOM,orient=UP) {
        $box_half = half;
        $box_make_anchor = anchor;
        $box_make_orient = orient;
        children();
    }
    
    a = pos != TOP ? (TOP + [pos.x,pos.y,0]) : BOTTOM;
    o = pos != TOP ? DOWN : UP;

    if(half==BOX_BASE)
        do_half(BOX_BASE) children();

    if(half==BOX_LID)
        do_half(BOX_LID,TOP,DOWN) children();

    if(half==BOX_BOTH) {
        do_half(BOX_BASE,pos != TOP ? [pos.x,pos.y,BOTTOM.z] : BOTTOM) children();
        move((pos == TOP ? topsep : sidesep) * [pos.x,pos.y,pos.z])
        zrot(pos.y!=0?180:0)
        do_half(BOX_LID,a,o) children();
    }
}

module box_flip() {
    half = $box_half == BOX_BASE ? BOX_LID : BOX_BASE;
    bot = $box_top;
    top = $box_bot;
    let($box_half = half, $box_top = top, $box_bot = bot) yrot(180) children();
}

module box_add_base() {
    box_part(BOX_BASE, false) children();
}

module box_add_lid() {
    box_part(BOX_LID, false) children();
}

module box_cut_base() {
    box_part(BOX_BASE, true) children();
}

module box_cut_lid() {
    box_part(BOX_LID, true) children();
}

module box_cut_both() { // for side cutouts
    box_part(cut=true) children();
}
