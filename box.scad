include <BOSL2/std.scad>

// constants
BOX_BASE = "base";
BOX_LID = "lid";
BOX_BOTH = undef;

// state variables
$box_cut = false;
$in_box_part = false;
$in_box_inside = false;
$box_make_anchor = BOTTOM;
$box_make_orient = UP;

// define parts to be put in base or lid.
// half: BOX_BASE, BOTH_LID, or BOX_BOTH
// cut: if true, cuts instead of adds
module box_part(half, cut=false, hide=false) {
    $in_box_part = true;
    if((is_undef(half) || $box_half == half) && $box_cut==cut && !hide)
        children();
}

// allow positioning children relative box inside anchors
module box_inside() {
    sz = $parent_size - [$box_side*2,$box_side*2,$box_bot+$box_top];
    $in_box_inside = true;
    recolor($box_inside_color)
    position(BOTTOM)
    up($box_bot)
    attachable(BOTTOM,0,UP,size=sz) {
        //#cube(sz,anchor=CENTER);
        union() {}; // dummy
        children();
    }
}

// anchor: anchor of box. The corresponding axis of the anchor is replaced according to current side. (so it will include BOTTOM for base parts, TOP for lid parts, etc)
// side: override side of the box, defaults to TOP for lid and BOTTOM for base. Useful to attach parts to the left/right/front/back inside. Only used inside box_part() children.
// spin: override spin. By default we spin inside TOP and outside BOTTOM, so that the part is rotated around X axis only.

// NOTE: parts on the inside of the top or outside of bottom will be rotated around X axis, so FRONT/BACK anchors will be reversed as seen from above the box.
// if called from box_inside(), child anchors are as looking on the inside of the box from within.

module box_pos(anchor=LEFT+FRONT,side,spin) {
    // for any non-zero element b[i], return b[i] else a[i]
    function v_replace_nonzero(a,b) =
        assert( is_list(a) && is_list(b) && len(a)==len(b), "Incompatible input")
        [for (i = [0:1:len(a)-1]) b[i] != 0 ? b[i] : a[i]];

    if($in_box_part) {
        flip = $in_box_inside /*&& !$box_cut*/; // taking box_cut into account would make all cutouts viewed from outside box
        side = default(side, $box_half==BOX_BASE ? BOTTOM : TOP);
        spin = default(spin, (side == TOP && flip) || (side == BOTTOM && !flip) ? 180 : undef);
        $box_wall = side == BOTTOM ? $box_bot : side == TOP ? $box_top : $box_side;
        position(v_replace_nonzero(anchor,side))
            orient(flip ? -side : side, spin = spin)
                children();
    } else { // compound parts
        position(anchor)
            children();
    }
}

// half: which half to make. BOX_BASE, BOX_LID, BOX_BOTH
// pos: where to position the lid, TOP (default), LEFT, BACK, RIGHT, FRONT
// topsep: separation for TOP lid position
// sidesep: separation for the other lid positions
module box_make(half=BOX_BOTH,pos=TOP,topsep=0.1,sidesep=10) {
    module do_half(half,anchor=BOTTOM,orient=UP) {
        $box_half = half;
        $box_make_anchor = anchor;
        $box_make_orient = orient;
        children();
    }
    
    if(half==BOX_BASE)
        do_half(BOX_BASE) children();

    if(half==BOX_LID)
        do_half(BOX_LID,TOP,DOWN) children();

    if(half==BOX_BOTH) {
        a = pos != TOP ? (TOP + [pos.x,pos.y,0]) : BOTTOM;
        o = pos != TOP ? DOWN : UP;

        do_half(BOX_BASE,pos != TOP ? [pos.x,pos.y,BOTTOM.z] : BOTTOM) children();
        move((pos == TOP ? topsep : sidesep) * [pos.x,pos.y,pos.z])
        zrot(pos.y!=0?180:0)
        do_half(BOX_LID,a,o) children();
    }
}

// flip a part upside down, useful for compound parts such as screw_clamp() etc.
module box_flip() {
    half = $box_half == BOX_BASE ? BOX_LID : BOX_BASE;
    bot = $box_top;
    top = $box_bot;
    let($box_half = half, $box_top = top, $box_bot = bot) yrot(180) children();
}

// convenience wrappers around box_part()
module box_add_base()
    box_part(BOX_BASE, false) children();

module box_add_lid()
    box_part(BOX_LID, false) children();

module box_cut_base()
    box_part(BOX_BASE, true) children();

module box_cut_lid()
    box_part(BOX_LID, true) children();

module box_cut_both() // for side cutouts
    box_part(cut=true) children();
