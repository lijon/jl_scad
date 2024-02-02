include <BOSL2/std.scad>

// constants
BOX_BASE = -1;
BOX_LID = 1;
BOX_BOTH = 0;

BOX_CUT_TAG = "box_remove";
BOX_KEEP_TAG = "box_keep";

// state variables
$box_make_anchor = BOTTOM;
$box_make_orient = UP;
$box_inside = false;
$box_show_previews = true;

// global settings
$box_cut_color = "#977";
$box_outside_color = "#ccc";
$box_inside_color = "#a99";
$box_preview_color = "#77f8";

/*
parent module for making box shells. 

size: inner/outer dimensions.
base_height: outer base height.
walls: [sides, top, bottom].
walls_outside: if true, size is inner, otherwise outer dimensions.

children:
    0: box bottom
    1: box top
    2: parts (children())
*/
module _box_shell(size, base_height, walls, walls_outside) {
    wall_side = walls[0];
    wall_top = walls[1];
    wall_bot = walls[2];

    sz = _box_outer_size(size, walls, walls_outside);

    $box_bot = wall_bot;
    $box_top = wall_top;
    $box_side = wall_side;

    $box_size = sz;

// inside dimensions
    $box_base_height = base_height - wall_bot;
    $box_lid_height = sz.z - base_height - wall_top;
    $box_half_height = $box_half == BOX_BASE ? $box_base_height : $box_half == BOX_LID ? $box_lid_height : sz.z;

    anchor = default($box_make_anchor, BOTTOM);
    orient = default($box_make_orient, UP);

    attachable(anchor, 0, orient, size=sz, cp=[0,0,sz.z/2]) {
        echo("BOX SIZE",sz) if(!$box_hide_box) children($box_half == BOX_BASE ? 0 : 1);
        
        if(!$box_hide_parts) {
            let($box_inside = true) _box_inside() children(2); // inside box
            let($box_inside = false) children(2); // outside box
        }
    }
}

function _box_outer_size(size, walls, walls_outside) =
    size + (walls_outside ? [walls[0]*2,walls[0]*2,walls[1]+walls[2]] : [0,0,0]);

module _box_inside() { // for positioning children relative box inside anchors
    sz = $parent_size - [$box_side*2,$box_side*2,$box_bot+$box_top];

    position(BOTTOM)
    up($box_bot)
    attachable(BOTTOM,0,UP,size=sz) {
        //#cube(sz,anchor=CENTER);
        union() {}; // dummy
        recolor($box_inside_color) children();
    }
}

// for any non-zero element b[i], return b[i] else a[i]
function v_replace_nonzero(a,b) =
    assert( is_list(a) && is_list(b) && len(a)==len(b), "Incompatible input")
    [for (i = [0:1:len(a)-1]) b[i] != 0 ? b[i] : a[i]];

// box_part() - place children in the box
// side: Which half and face of the box to attach the child: BOT (base), TOP (lid) or CENTER (both). Can also combine with one of LEFT,RIGHT,BACK,FRONT to attach to one of the sides.
// anchor: Anchor of the box to position child at, if undefined then skip position and orient of part.
// spin: override spin. By default we spin inside TOP and outside BOTTOM, so that the part is rotated around X axis only.
// cut: if true, cuts instead of adds
// cuttable: if true, part is merged with the box shell and can thus be cut
// NOTE: parts on the inside of the top or outside of bottom will be rotated around X axis, so FRONT/BACK anchors will be reversed as seen from above the box.
// if called from box_inside(), child anchors are as looking on the inside of the box from within.
module box_part(side=CENTER, anchor=CENTER, auto_anchor=true, spin, std_spin=false, inside=true, hide=false) {
    checks = assert(side.x == 0 || side.y == 0, "side= can not be a side edge or corner")
             assert(is_vector(side,3));

    // derive half from side.z
    half = side.z;

    // single axis side
    side = side.x != 0 ? [side.x, 0, 0] : side.y != 0 ? [0, side.y, 0] : [0, 0, side.z];

    if((half == BOX_BOTH || $box_half == half) && $box_inside == inside && !hide) {
        orient = inside ? -side : side;
        spin = default(spin, (orient == BOTTOM && !std_spin) ? 180 : undef);

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
// pos: if BOTH, where to position the lid, TOP (default), LEFT, BACK, RIGHT, FRONT
// topsep: separation for TOP lid position
// sidesep: separation for the other lid positions
module box_make(half=BOX_BOTH, pos=TOP, topsep=0.1, sidesep=10, hide_box=false, hide_parts=false) {
    module do_half(half,anchor=BOTTOM,orient=UP) {
        $box_half = half;
        $box_make_anchor = anchor;
        $box_make_orient = orient;
        $box_hide_box = hide_box;
        $box_hide_parts = hide_parts;
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
// Rotates around x axis so BACK/FRONT will be swapped.
module box_flip() {
    half = -$box_half;
    bot = $box_top;
    top = $box_bot;
    let($box_half = half, $box_top = top, $box_bot = bot) xrot(180) children();
}

function box_cut_color(c) = default(c,default($box_cut_color,$box_inside_color));

// tag children for removal and color by $box_cut_color
module box_cut(c) tag(BOX_CUT_TAG) recolor(box_cut_color(c)) children();
module box_cut_force(c) force_tag(BOX_CUT_TAG) color(box_cut_color(c)) children();

module box_preview(c) {
    c = default(c, $box_preview_color);
    if($preview && $box_show_previews) {
        if(c) recolor(c) children();
        else children();
    }
}

