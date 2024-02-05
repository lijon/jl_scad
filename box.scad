include <BOSL2/std.scad>

// all possible sides
BOX_ALL = [LEFT,RIGHT,FRONT,BACK,BOTTOM,TOP];

BOX_CUT_TAG = "box_remove";
BOX_KEEP_TAG = "box_keep";

// global settings
$box_cut_color = "#977";
$box_outside_color = "#ccc";
$box_inside_color = "#a99";
$box_preview_color = "#77f8";
$box_show_previews = true;

/*
parent module for making box shells. 

base_height: outer base height.
walls: [sides, top, bottom].
walls_outside: if true, size is inner, otherwise outer dimensions.

children:
    0: box bottom
    1: box top
    2: parts (children())
*/
module _box_shell(base_height, walls, walls_outside) {
    wall_side = walls[0];
    wall_top = walls[1];
    wall_bot = walls[2];

    sz = _box_outer_size($box_make_size, walls, walls_outside);

    $box_size = sz;

// FIXME: we need a more generic way to handle this. export wall thickness for all 6 sides, or for all sides for each half in case for example base and lid can have different side walls?
    $box_bot = wall_bot;
    $box_top = wall_top;
    $box_side = wall_side;
    // inside dimensions
    $box_base_height = base_height - wall_bot;
    $box_lid_height = sz.z - base_height - wall_top;
    $box_half_height = $box_half == BOT ? $box_base_height : $box_half == TOP ? $box_lid_height : sz.z;

    attachable($box_make_anchor, 0, $box_make_orient, size=sz, cp=[0,0,sz.z/2]) {
        echo("BOX SIZE",sz) if(!$box_hide_box) children(0);
        
        if(!$box_hide_parts) {
            let($box_inside = true) _box_inside() children(1); // inside box
            let($box_inside = false) children(1); // outside box
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


function box_half(half) =
    let(half = is_list(half) && is_list(half[0]) ? half : [half]) in_list($box_half,half);

module box_half(half, hide=false) {
    if(box_half(half) && !hide) children();
}

module box_pos(anchor=CENTER, side, spin, auto_anchor=true, std_spin=false, inside=true, hide=false) {
    side = default(side, $box_half);
    checks = assert(num_true(side,function(x) x!=0) == 1, "side must contain exactly one non-zero element");

    if($box_inside == inside && !hide) {
        orient = inside ? -side : side;
        spin = default(spin, (orient == BOTTOM && !std_spin) ? 180 : undef);

        $box_wall = side == BOTTOM ? $box_bot : side == TOP ? $box_top : $box_side; // used by box_cutout(). FIXME: retrieve this from exported box side -> wall table.

        position(auto_anchor ? v_replace_nonzero(anchor,side) : anchor)
            orient(orient, spin = spin)
                children();
    }
}

function vector_name(v) =
    assert(is_vector(v))
    let(
        a = ["LEFT","FRONT","BOTTOM"],
        b = ["RIGHT","BACK","TOP"],
        l = [for(i = idx(v)) if(v[i]!=0) v[i] < 0 ? a[i] : b[i]]
    )
    len(l) ? str_join(l, "+") : "CENTER";

module box_make(halves, size, print=false, top_pos=BACK, explode=0.1, spread=10, hide_box=false, hide_parts=false) {
    size = scalar_vec3(size);

    module do_half(half,anchor=BOTTOM,orient=UP) {
        $box_half = half;
        $box_make_anchor = anchor;
        $box_make_orient = orient;
        $box_make_size = size;
        $box_hide_box = hide_box;
        $box_hide_parts = hide_parts;
        $box_print = print;
        diff(BOX_CUT_TAG, BOX_KEEP_TAG) children();
    }

    if(print) {
        for(h = halves) {
            ofs = h==TOP ? top_pos : (h*0.5);
            
            z = (h != TOP || in_list(top_pos, halves) ? size.z+spread*2 : spread);
            m = v_mul(ofs, [size.x+z, size.y+z, 0]);
            r = h == TOP ? 180 : 0;
            a = h;
            o = h.z != 0 ? -a : a;
            
            echo(str("Doing box half: ", vector_name(h)));
            move(m) zrot(r) do_half(h,a,o) children();
        }
    } else {
        for(h = halves) {
            e = explode / 2;
            m = h * e;
            
            echo(str("Doing box half: ", vector_name(h)));
            up(e) move(m) do_half(h,BOTTOM) children();
        }
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

