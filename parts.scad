include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

module open_round_box(
    size=10,
    rsides=5,
    rbot=1,
    wall_side=2,
    wall_bot=2,
    rim_height=0,
    rim_wall=0,
    rim_inside=false,
    rsides_inside,
    rbot_inside,
    k=0.92,
//    steps=22,
    inside_color,
    outside_color,
) {
    rim_wall = rim_wall != 0 ? rim_wall : wall_side/2;

    inside_color = default(inside_color,outside_color);

    path = square(size,center=true);
    
    size = scalar_vec3(size);
    
    rsides = (rsides==rbot && rsides!=0) ? rsides+0.001 : rsides; // work around BOSL2 bug

    steps = round(max(rbot, rsides) * 2 / default($fs,1.0)); // FIXME: allow $fn etc as well?
    
    module baseshape(p,inset=0,flat_bottom=false) {
        p = offset(p,delta=-inset,closed=true);
        
        r1 = inset>0 && is_def(rsides_inside) ? rsides_inside : max(0, rsides - inset);
        r2 = flat_bottom ? 0 : inset>0 && is_def(rbot_inside) ? rbot_inside : max(0, rbot - inset);
        rounded_prism(p,height=size.z,joint_sides=r1,joint_bot=r2,splinesteps=steps,k=k,anchor=BOTTOM);
    }
    
    // TODO: this should also be an attachable
    
//    color("#888")
    difference() {
        recolor(outside_color)
        baseshape(path); // outside
        
        recolor(inside_color)
        up(wall_bot) baseshape(path,inset=wall_side); // inside
        
        recolor("#aaa")
        if(rim_height>0) up(size.z-rim_height) difference() {
            if(rim_inside)
                up(0.001) linear_sweep(offset(path,delta=1,closed=true),rim_height);
            baseshape(path,inset=rim_wall,flat_bottom=true);
        }
        
    }
}

module standoff(h=10,od=4,id=2,depth=0,fillet=1,iround=0,anchor=BOTTOM, spin=0, orient=UP) {
    d = depth == 0 ? h : depth;
    iround = min(id/2,iround);
    attachable(anchor,spin,orient,d=od,l=h - min(0,d)) {
        down(max(0,-d/2)) {
            difference() {
                cyl(h,d=od,rounding1=-fillet);
                if(d>0) up(h/2+0.001) cyl(d,d=id,rounding1=iround,anchor=TOP);
            }
            if(d<0) up(h/2) cyl(-d,d=id,rounding2=iround,anchor=BOTTOM);
        }
        children();
    }
}

// compound parts should have default anchor CENTER
module box_standoff_clamp(h=5,od=5,id=2.25,pin_h=2,gap=1.7,fillet=2,iround=0.5,anchor=CENTER,spin=0,orient=UP) {
// TODO: allow negative pin_h to have the pin in the lid?
    ph = $parent_size.z;
    attachable(anchor,spin,orient,d=od,l=ph,cp=[0,0,ph/2]) {
        union() {
            box_half(BOT) box_pos() standoff(h,od,id-get_slop()*2,-pin_h-gap,fillet,iround=iround);
            box_half(TOP) box_pos() standoff(ph-h-gap,od,id,pin_h+0.5,fillet,iround=iround);
        }
        children();
    }
}

module box_screw_clamp(h=2,od=8,od2,id=3,id2,head_d=6,head_depth=3,idepth=0,gap=0,fillet=1.5,iround=0,rounding,chamfer,anchor=CENTER,spin=0,orient=UP) {
    ph = $parent_size.z;
    id2 = default(id2,id-0.5);
    od2 = default(od2,od);
    wall_bot = $box_walls[BOX_WALL_BOT];
    h = h + head_depth - wall_bot;
    chamfer = is_def(chamfer) ? -chamfer : undef;
    rounding = is_def(rounding) ? -rounding : undef;
    // FIXME: we should rather have the bounding box so it's easier to position at corner!
    //attachable(anchor,spin,orient,d=od,l=ph,cp=[0,0,ph/2]) {
    attachable(anchor,spin,orient,size=[od,od,ph],cp=[0,0,ph/2]) {
        union() 
        {
            box_half(BOT) box_pos() standoff(h,od,id,h,fillet,iround=0);
            box_half(TOP) box_pos() standoff(ph-h-gap,od2,id2,idepth,fillet,iround=0);
            
        }
        union() {
            box_half(BOT) box_pos() box_cut() down(wall_bot+0.001) cyl(h=head_depth+0.001,d=head_d,rounding2=iround,chamfer1=chamfer,rounding1=rounding,anchor=BOTTOM) tag(BOX_KEEP_TAG) children();
        }
    }
}

// p: path of cutout
// rounding: roundover outer edge
// chamfer: chamfer outer edge
// depth: extra depth
// anchor: XY child anchor

module box_cutout(p, rounding, chamfer, depth=0, anchor=CENTER) {
    h = $box_wall + depth + 0.002;
    anchor = [anchor.x,anchor.y,BOTTOM.z];
    geom = attach_geom(region=force_region(p),h=h,cp="centroid"); // don't include top/bottom profiles in size
    down(0.001+$box_wall) box_cut()
        attachable(anchor,0,UP,geom=geom) {
            profile = is_def(rounding) ? os_circle(-rounding) : is_def(chamfer) ? os_chamfer(-chamfer) : [];
            // swap top/bottom profile depending on if inside/outside of box
            tprof = $box_inside ? [] : profile;
            bprof = $box_inside ? profile : [];

            position(BOTTOM)
                offset_sweep(p,h,top=tprof,bottom=bprof,anchor=BOTTOM);

            children();
        }
}

module box_hole(d=1, rounding, chamfer, depth=0, anchor=CENTER) {
    box_cutout(circle(d=d),rounding=rounding,chamfer=chamfer,depth=depth,anchor=anchor) children();
}

module box_wall(dir=BACK,height,length,gap=0,width=1,fillet=1.5,anchor=BOTTOM,spin=0,orient=UP) {
    edges = [BOTTOM+LEFT,BOTTOM+RIGHT];
    l = default(length,dir.y != 0 ? $parent_size.y : $parent_size.x);
    height = default(height, $box_half_height) - gap;
    zrot(dir.x != 0 ? 90 : 0)
        cuboid([width,l,height],rounding=-fillet,edges=edges,anchor=anchor,spin=spin,orient=orient);
}


module box_shell_rimmed(
    size,
    base_height,
    wall_sides=2,
    wall_top,
    wall_bot,
    walls_outside=true, // if true, walls are added outside the given size
    rim_height=3,
    rim_gap=0,
    k=0.92,
    rsides=1,
    rbot=1,
    rtop=1,
    rsides_inside,
    rbot_inside,
    rtop_inside,
){
    size = scalar_vec3(size);
    wall_top = default(wall_top, wall_sides);
    wall_bot = default(wall_bot, wall_top);

    base_height = default(base_height, size.z / 2 + (walls_outside ? wall_bot : 0));

    outer_base_height = base_height + rim_height;

    halves = [BOT, TOP];
    walls = [wall_sides,wall_sides,wall_sides,wall_sides,wall_bot,wall_top];

    module box_wrap(sz,wall_bot,rim_height,rim_inside,rim_wall,rbot,rbot_inside) {
        open_round_box(
            size=sz,
            rsides=rsides,
            wall_side=wall_sides,
            wall_bot=wall_bot,
            rim_height=rim_height,
            rim_inside=rim_inside,
            k=k,
            rbot=rbot,
            rim_wall=rim_wall,
            rbot_inside=rbot_inside,
            inside_color=$box_inside_color,
            outside_color=$box_outside_color);
    }

    _box_shell(size, outer_base_height, walls, walls_outside, halves) {
        // base        
        if(box_half(BOT)) let(rim_gap = min(0,rim_gap)) {
            box_wrap(
                [$box_size.x,$box_size.y,outer_base_height+rim_gap],
                wall_bot=wall_bot,
                rim_height=rim_height+rim_gap,
                rim_inside=true,
                rim_wall=wall_sides/2+get_slop(),
                rbot=rbot,
                rbot_inside=rbot_inside);
        }
        // lid
        else if(box_half(TOP)) let(rim_gap = max(0,rim_gap), h = $box_size.z - base_height) {
            up(base_height) zflip(z=h/2)
            box_wrap(
                [$box_size.x,$box_size.y,h-rim_gap],
                wall_bot=wall_top,
                rim_height=rim_height-rim_gap,
                rim_inside=false,
                rim_wall=wall_sides/2,
                rbot=rtop,
                rbot_inside=rtop_inside);
        }
        // parts
        children();
    }
}
