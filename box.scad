include <BOSL2/std.scad>
include <reset_transform.scad>

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
//BOX_PREVIEW_TAG = "box_preview";

// global settings
$box_cut_color = "#977";
$box_outside_color = "#ccc";
$box_inside_color = "#a99";
$box_preview_color = "#77f8";
$box_inside_overlap = 0.0001;

$box_wall = undef;

// for any non-zero element b[i], return b[i] else a[i]
function v_replace_nonzero(a,b) =
    assert( is_list(a) && is_list(b) && len(a)==len(b), "Incompatible input")
    [for (i = [0:1:len(a)-1]) b[i] != 0 ? b[i] : a[i]];

function round_path(path, r, or, ir, closed=true) =
    let(
        or = get_radius(r1=or, r=r, dflt=0),
        ir = get_radius(r1=ir, r=r, dflt=0)
    ) or==0 && ir==0 ? path : offset(offset(offset(path,delta=ir,chamfer=true,closed=closed),-or-ir,closed=closed),or,closed=closed);

function chamfer_path(path, r, or, ir, closed=true) =
    let(
        or = get_radius(r1=or, r=r, dflt=0),
        ir = get_radius(r1=ir, r=r, dflt=0)
    ) or==0 && ir==0 ? path : offset(offset(offset(path,delta=ir,chamfer=true,closed=closed),delta=-or-ir,chamfer=true,closed=closed),delta=or,chamfer=true,closed=closed);

function lerp_index(v,x) = let(i=floor(x), a = v[i], b = v[min(i+1,len(v)-1)], f = x-i) lerp(a,b,f);

// takes a list of [x,y,R] or [x,y,z,R] points and returns a rounded/chamfered path.
// where R is positive for circular and negative for chamfer.
function rpath(points) =
    let(
        path = [for(p = points) slice(p,0,-2)],
        r = [for(p = points) last(p)]
    ) [
        for(i = idx(path)) each
            let(
                rr = r[i],
                ra = abs(rr),
                pt = select(path,i-1,i+1),
                angle = vector_angle(pt)/2,
                prev = unit(pt[0]-pt[1]),
                next = unit(pt[2]-pt[1])
            ) rr < 0 ? [pt[1]+prev*ra, pt[1]+next*ra]
            : rr > 0 ?
            let(
                d = ra/tan(angle),
                center = ra/sin(angle) * unit(prev+next)+pt[1],
                start = pt[1]+prev*d,
                end = pt[1]+next*d
            ) (approx(angle,90) ? [start,end] : arc(max(3,ceil((90-angle)/180*segs(ra))), cp=center, points=[start,end]))
            : [path[i]]
    ];

// like path_sweep2d for closed path, that fills the hole (bottom). for easy creation of boxes from side profile and top path.
// the profile is oriented so that X+ points outwards and Y+ points upwards.
module path_sweep2d_fill(profile, path, fill = true) {
    path_sweep2d(profile, path, closed = true) children();

    if(fill) {
        a = [for(p = [profile[0], last(profile)])
                path3d(offset(path, delta = p.x+0.001, closed = true), p.y)];
        vnf_polyhedron(vnf_vertex_array(a, caps = true, col_wrap = true));
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

// return val unless it's a, then return b
function unless(val, a, b) = val == a ? b : val;

// convenience module to make an attachable without a base shape
module component(
    anchor=CENTER,spin=0,orient=UP,
    size, size2, shift,
    r,r1,r2, d,d1,d2, l,h,
    vnf, path, region,
    extent=true,
    cp=[0,0,0],
    offset=[0,0,0],
    anchors=[],
    two_d=false,
    axis=UP,override,
    geom
) {
    attachable(
        anchor,spin,orient,
        size, size2, shift,
        r,r1,r2, d,d1,d2, l,h,
        vnf, path, region,
        extent,
        cp,
        offset,
        anchors,
        two_d,
        axis,override,
        geom
    ) {
        union() {} // invisible base shape
        children();
    }
}

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
    $box_inside_ofs = [for(i = [0:2:5]) walls[i]-$box_inside_overlap];

    size = scalar_vec3(size);

    sz = walls_outside ? (size + $box_walls_xyz) : size;

    $box_size = sz; // outside size
    $box_inside_size = sz - $box_walls_xyz + scalar_vec3($box_inside_overlap*2);

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

        //diff(BOX_CUT_TAG, str(BOX_KEEP_TAG," ",BOX_PREVIEW_TAG)) children();
        diff(BOX_CUT_TAG, BOX_KEEP_TAG) children();
    }

    top_pos = $box_make_top_pos;
    includes_top_pos = in_list(top_pos, halves) && in_list(top_pos, valid_halves);
    
    echo("BOX SIZE",$box_size); 

    for(h = halves) if(in_list(h,valid_halves)) {
        if($box_print) {
            spread = $box_make_spread;
            size = $box_size;

            ofs = h==TOP ? top_pos : (h*0.5);
            // FIXME: center if only two pieces?
            z = (h != TOP || includes_top_pos) ? size.z+spread*2 : spread;
            m = len(halves)==1 ? [0,0] : v_mul(ofs, [size.x+z, size.y+z, 0]);
            r = h == TOP && top_pos.y ? 180 : 0;
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

module box_make(halves=BOX_ALL, print=false, top_pos=BACK, explode=0.05, spread=5, hide_box=false, hide_parts=false, hide_previews=false) {
    halves = is_list(halves) && is_vector(halves[0]) ? halves : [halves];
    $box_make_halves = halves;
    $box_print = print || !$preview;
    $box_make_top_pos = top_pos;
    $box_make_explode = explode;
    $box_make_spread = spread;
    $box_hide_box = hide_box;
    $box_hide_parts = hide_parts;
    $box_explode = explode;
    $box_show_previews = !hide_previews;
    
    //hide($preview && $box_show_previews ? "" : BOX_PREVIEW_TAG) 
    children();
}

function box_half(half) =
    (is_undef(half) || is_undef($box_half)) ? true : let(half = is_list(half) && is_list(half[0]) ? half : [half]) in_list($box_half,half);

module box_half(half, inside=true, hide=false) {
    if(box_half(half) && (is_undef(inside) || is_undef($box_inside) || inside==$box_inside) && !hide) children();
}

// attach children on box, automatically anchoring it to the given side
module box_pos(anchor=CENTER, side, spin, auto_anchor=true, std_spin=false, hide=false) {    
    side = default(side, $box_half);

    anchors = is_list(anchor) && is_vector(anchor[0]) ? anchor : [anchor];

    checks = assert(num_true(side,function(x) x!=0) == 1, "side must contain exactly one non-zero element");

    orient = $box_inside ? -side : side;
    spin = default(spin, (orient == BOTTOM && !std_spin) ? 180 : undef);

    $box_side = side;
    $box_wall = _box_wall_for_side(side);

    if(!hide) {
        if(is_def(anchors[0])) for(i = idx(anchors)) {
            $box_idx = i;
            anchor = anchors[i];
            $box_anchor = anchor;
            position(auto_anchor ? v_replace_nonzero(anchor,side) : anchor)
                orient(orient, spin = spin)
                    children();
        } else {
            orient(orient, spin = spin)
                children();
        }
    }
}


module box_part(half_sides, anchor=CENTER, spin, inside=true, auto_anchor=true, std_spin=false, hide=false, debug=false) {
    half_sides = is_list(half_sides) && is_vector(half_sides[0]) ? half_sides : [half_sides];
    for(hs = half_sides) {
        matches = [for(half = $box_shell_halves) if(max(v_mul(half, hs))==1) half];
        // in $box_shell_halves, find the one(s) that is included in half_side.
        // so TOP is in TOP+LEFT but not in BOTTOM+FRONT.
        found = len(matches);
        halves = found ? matches:$box_shell_halves;

        for(half = halves) {
            // side = remove the half axis from hs, but only if hs has more than one axis.
            side = unless(num_true(hs)>1 && found ? hs-half : hs, CENTER, half);

            if(debug) echo(str(vector_name(hs)," -> half=",vector_name(half)," side=",vector_name(side)));

            box_half(half, inside=inside, hide=hide)
                box_pos(anchor, side, spin, auto_anchor, std_spin)
                    children();
        }
    }
}


// flip a part upside down, useful for compound parts such as screw_clamp() etc.
// Rotates around axis (default X) so BACK/FRONT will be swapped.
module box_flip(axis=RIGHT) {
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
    let($box_half = half, $box_walls = walls) rot(180,axis) children();
}

function box_cut_color(c) = default(c,default($box_cut_color,$box_inside_color));

// tag children for removal and color by $box_cut_color
module box_cut(c) tag(BOX_CUT_TAG) recolor(box_cut_color(c)) children();
module box_cut_force(c) force_tag(BOX_CUT_TAG) color(box_cut_color(c)) children();

module box_preview(c) {
    c = default(c, $box_preview_color);
    tag(BOX_KEEP_TAG)
    if($preview && $box_show_previews) {
        if(c) recolor(c) children();
        else children();
    }
}

// using tags for this made it harder to use other tags inside the preview shape.
// module box_preview_end() {
//     tag("") recolor($box_preview_save_color) children();
// }
// module box_preview(c) {
//     c = default(c, $box_preview_color);
//     $box_preview_save_color=default($color,"default");
//     tag(BOX_PREVIEW_TAG) recolor(c) children();
// }

// p: path of cutout
// rounding: roundover outer edge
// chamfer: chamfer outer edge
// depth: extra depth
// anchor: XY child anchor
module box_cutout(p, rounding, chamfer, depth=0, anchor=CENTER) {
    project = !any_defined([rounding, chamfer]);
    h = !project ? $box_wall + 0.002 : max($box_size);
    anchor = [anchor.x,anchor.y,TOP.z];
    //ofs = 0.001+$box_wall;
    box_cut() {
        profile = is_def(rounding) ? os_circle(-rounding) : is_def(chamfer) ? os_chamfer(-chamfer) : [];
        // swap top/bottom profile depending on if inside/outside of box
        tprof = $box_inside ? [] : profile;
        bprof = $box_inside ? profile : [];

        up(0.001+depth) offset_sweep(p,h,top=tprof,bottom=bprof,anchor=anchor,cp=[0,0])
            children(); // not sure if this is usable.
    }
}