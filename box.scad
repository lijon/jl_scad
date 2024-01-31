include <BOSL2/std.scad>

// constants
BOX_BASE = "base";
BOX_LID = "lid";
BOX_BOTH = undef;
// TODO: could also use BOX_BASE = BOTTOM, etc?

BOX_CUT_TAG = "remove";
BOX_KEEP_TAG = "keep";

// state variables
$box_make_anchor = BOTTOM;
$box_make_orient = UP;
$box_inside = false;

// global settings
$box_cut_color = "#977";
$box_outside_color = "#ccc";
$box_inside_color = "#a99";

// use for calling box children from box_shell
module _box_children() {
    module inside() { // for positioning children relative box inside anchors
        sz = $parent_size - [$box_side*2,$box_side*2,$box_bot+$box_top];

        position(BOTTOM)
        up($box_bot)
        attachable(BOTTOM,0,UP,size=sz) {
            //#cube(sz,anchor=CENTER);
            union() {}; // dummy
            let($box_inside = true) recolor($box_inside_color) children();
        }
    }

    let($box_inside = true) inside() children(); // inside box
    let($box_inside = false) children(); // outside box
}

// for any non-zero element b[i], return b[i] else a[i]
function v_replace_nonzero(a,b) =
    assert( is_list(a) && is_list(b) && len(a)==len(b), "Incompatible input")
    [for (i = [0:1:len(a)-1]) b[i] != 0 ? b[i] : a[i]];


// side: Which half and face of the box to attach the child. BOT (base), TOP (lid) or CENTER (both). Can also combine with one of LEFT,RIGHT,BACK,FRONT to attach to one of the sides.
// anchor: Anchor of the box to position child at.
// spin: override spin. By default we spin inside TOP and outside BOTTOM, so that the part is rotated around X axis only.
// cut: if true, cuts instead of adds
// cuttable: if true, part is merged with the box shell and can thus be cut
// NOTE: parts on the inside of the top or outside of bottom will be rotated around X axis, so FRONT/BACK anchors will be reversed as seen from above the box.
// if called from box_inside(), child anchors are as looking on the inside of the box from within.
module box_place(side=CENTER, anchor=LEFT+FRONT, auto_anchor=true, spin, std_spin=false, cut=false, cuttable=false, inside=true, hide=false) {
    checks = assert(side.x == 0 || side.y == 0, "side= can not be a side edge or corner")
             assert(is_vector(side,3));

    // derive half from side.z
    half = side.z == TOP.z ? BOX_LID : side.z == BOT.z ? BOX_BASE : BOX_BOTH;

    // single axis side
    side = side.x != 0 ? [side.x, 0, 0] : side.y != 0 ? [0, side.y, 0] : [0, 0, side.z];

    if((is_undef(half) || $box_half == half) && $box_inside == inside && !hide) {
        orient = inside ? -side : side;
        spin = default(spin, (orient == BOTTOM && !std_spin) ? 180 : undef);

        $box_half_height = $box_half == BOX_BASE ? $box_base_height : $box_half == BOX_LID ? $box_lid_height : $parent_size.z;
        $box_wall = side == BOTTOM ? $box_bot : side == TOP ? $box_top : $box_side; // used by box_cutout()

        if(is_def(anchor))
            position(auto_anchor ? v_replace_nonzero(anchor,side) : anchor)
                orient(orient, spin = spin)
                    children();
        else
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
        diff(BOX_CUT_TAG, BOX_KEEP_TAG) children();
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
    let($box_half = half, $box_top = top, $box_bot = bot) xrot(180) children();
}

// tag for removal and color by $box_cut_color
module box_cut(c) tag(BOX_CUT_TAG) color(default(c,default($box_cut_color,$box_inside_color))) children();
