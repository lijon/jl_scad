include <BOSL2/std.scad>

// all possible sides
BOX_ALL = [LEFT,RIGHT,FRONT,BACK,BOTTOM,TOP];

BOX_WALL_LEFT = 0;
BOX_WALL_RIGHT = 1;
BOX_WALL_FRONT = 2;
BOX_WALL_BACK = 3;
BOX_WALL_BOT = 4;
BOX_WALL_TOP = 5;

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

size:           inner or outer box size
splitpoint:     outer dimension where box is split
walls:          wall thickness for all 6 sides: [left,right,front,back,bottom,top].
walls_outside:  if true, size is inner, otherwise outer dimensions.
halves:         list of valid box halves

children:
    0: box
    1: parts (children())
*/
module _box_shell(size, splitpoint, walls, walls_outside, halves) {
    $box_shell_halves = halves;
    $box_walls = walls;
    $box_walls_xyz = [for(i = [0:2:5]) walls[i]+walls[i+1]]; // left+right, back+front, top+bot
    $box_inside_ofs = [for(i = [0:2:5]) walls[i]];

    size = scalar_vec3(size);

    sz = walls_outside ? (size + $box_walls_xyz) : size;

    $box_size = sz; // outside size
    $box_inside_size = sz - $box_walls_xyz;

    $box_splitpoint = splitpoint - $box_inside_ofs;

    _box_layout() attachable($box_layout_anchor, 0, $box_layout_orient, size=sz, cp=[0,0,sz.z/2]) {
        if(!$box_hide_box) children(0);
        
        if(!$box_hide_parts) {
            let($box_inside = true) _box_inside() children(1); // inside box
            let($box_inside = false) children(1); // outside box
        }
    }
}

function _box_wall_for_side(side) =
    let(r = [for(i = idx(BOX_ALL)) if(BOX_ALL[i]==side) $box_walls[i]])
    assert(len(r),"undefined box side")
    r[0];

module _box_inside() { // for positioning children relative to box inside anchors
    sz = $box_inside_size;

    position(BOT+LEFT+FRONT)
    move($box_inside_ofs)
    attachable(BOT+LEFT+FRONT,0,UP,size=sz) {
        //#cube(sz,anchor=CENTER);
        union() {}; // dummy
        recolor($box_inside_color) children();
    }
}

function _axis_index(v) =
    let(r = [for(i = idx(v)) if(v[i]!=0) i]) assert(len(r)==1) r[0];

module _box_layout() {
    valid_halves = $box_shell_halves;
    halves = $box_make_halves;

    module do_half(half,anchor=BOTTOM,orient=UP) {
        $box_half = half;
        $box_layout_anchor = anchor;
        $box_layout_orient = orient;

        i = _axis_index($box_half);

        $box_half_height = $box_half[i] < 0 ? $box_splitpoint[i] : $box_half[i] > 0 ? $box_inside_size[i] - $box_splitpoint[i] : $box_inside_size[i];

        children();
    }

    top_pos = $box_make_top_pos;
    includes_top_pos = in_list(top_pos, halves) && in_list(top_pos, valid_halves);
    
    echo("BOX SIZE",$box_size); 

    diff(BOX_CUT_TAG, BOX_KEEP_TAG) 
    for(h = halves) if(in_list(h,valid_halves)) {
        if($box_print) {
            spread = $box_make_spread;
            size = $box_size;

            ofs = h==TOP ? top_pos : (h*0.5);
            // FIXME: center if only two pieces?
            z = (h != TOP || includes_top_pos) ? size.z+spread*2 : spread;
            m = len(halves)==1 ? [0,0] : v_mul(ofs, [size.x+z, size.y+z, 0]);
            r = h == TOP ? 180 : 0;
            a = h;
            o = h.z != 0 ? -a : a;
            
            //echo(str("Doing box half: ", vector_name(h)));
            move(m) zrot(r) do_half(h,a,o) children();
        } else {
            e = $box_make_explode / 2;
            m = h * e;
            
            //echo(str("Doing box half: ", vector_name(h)));
            up(e) move(m) do_half(h) children();
        }
    }
}

module box_make(halves=BOX_ALL, print=false, top_pos=BACK, explode=0.1, spread=5, hide_box=false, hide_parts=false) {
    $box_make_halves = halves;
    $box_print = print;
    $box_make_top_pos = top_pos;
    $box_make_explode = explode;
    $box_make_spread = spread;
    $box_hide_box = hide_box;
    $box_hide_parts = hide_parts;
    
    children();
}

// for any non-zero element b[i], return b[i] else a[i]
function v_replace_nonzero(a,b) =
    assert( is_list(a) && is_list(b) && len(a)==len(b), "Incompatible input")
    [for (i = [0:1:len(a)-1]) b[i] != 0 ? b[i] : a[i]];


function box_half(half) =
    is_undef(half)? true : let(half = is_list(half) && is_list(half[0]) ? half : [half]) in_list($box_half,half);

module box_half(half, inside=true, hide=false) {
    if(box_half(half) && (is_undef(inside) || is_undef($box_inside) || inside==$box_inside) && !hide) children();
}

// attach children on box, automatically anchoring it to the given side
module box_pos(anchor=CENTER, side, spin, auto_anchor=true, std_spin=false, hide=false) {
    side = default(side, $box_half);
    checks = assert(num_true(side,function(x) x!=0) == 1, "side must contain exactly one non-zero element");

    if(!hide) {
        orient = $box_inside ? -side : side;
        spin = default(spin, (orient == BOTTOM && !std_spin) ? 180 : undef);

        $box_wall = _box_wall_for_side(side);

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


// flip a part upside down, useful for compound parts such as screw_clamp() etc.
// Rotates around x axis so BACK/FRONT will be swapped.
module box_flip() {
    half = -$box_half;
    walls = [
        $box_walls[0],
        $box_walls[1],
        $box_walls[2],
        $box_walls[3],
        // bot/top wall widths are swapped
        $box_walls[5],
        $box_walls[4],
    ];
    let($box_half = half, $box_walls = walls) xrot(180) children();
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

