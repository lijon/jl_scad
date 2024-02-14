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
    rim_snap=false,
    rim_snap_ofs=0.6,
    rim_snap_depth=0.4,
    rim_snap_height=0.2,
    inside_color,
    outside_color,
) {
    rim_wall = rim_wall != 0 ? rim_wall : wall_side/2;

    inside_color = default(inside_color,outside_color);

    path = square(size,center=true);
    
    size = scalar_vec3(size);

    steps = get_fn(max(rbot, rsides)/2);
    
    module baseshape(p,inset=0,flat_bottom=false,height=size.z) {
        p = offset(p,delta=-inset,closed=true);
        
        r1 = inset>0 && is_def(rsides_inside) ? rsides_inside : max(0, rsides - inset);
        r2 = flat_bottom ? 0 : inset>0 && is_def(rbot_inside) ? rbot_inside : max(0, rbot - inset);
        rounded_prism(p,height=height,joint_sides=r1,joint_bot=r2,splinesteps=steps,k=k,anchor=BOTTOM);
    }
    
    // TODO: this should also be an attachable
    
//    color("#888")
    difference() {
        recolor(outside_color)
        baseshape(path); // outside
        
        recolor(inside_color)
        up(wall_bot) baseshape(path,inset=wall_side); // inside
        
        color("#aaa")
        if(rim_height>0) up(size.z-rim_height) difference() {
            if(rim_inside)
                up(0.001) linear_sweep(offset(path,delta=1,closed=true),rim_height);
            
            union() {
                baseshape(path,inset=rim_wall,flat_bottom=true);

                if(rim_snap) up(rim_snap_ofs-rim_snap_depth) hull() {
                    baseshape(path,inset=rim_wall,flat_bottom=true,height=rim_snap_depth*2+rim_snap_height);
                    up(rim_snap_depth) baseshape(path,inset=rim_wall-rim_snap_depth,flat_bottom=true,height=rim_snap_height);
                }
            }
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
    pin = pin_h == false ? 0 : -pin_h-gap;
    hole = pin_h == false ? 0 : pin_h+0.5;
    attachable(anchor,spin,orient,d=od,l=ph,cp=[0,0,ph/2]) {
        union() {
            box_half(BOT) box_pos() standoff(h,od,id,pin,fillet,iround=iround);
            box_half(TOP) box_pos() standoff(ph-h-gap,od,id+0.5,hole,fillet,iround=iround);
        }
        children();
    }
}

module box_screw_clamp(h=2,od=8,od2,id=3,id2,head_d=6,head_depth=3,idepth=0,gap=0.1,fillet=1.5,iround=0,rounding,chamfer,anchor=CENTER,spin=0,orient=UP) {
    ph = $parent_size.z;
    id2 = default(id2,id-0.5);
    od2 = default(od2,od);
    wall_bot = $box_walls[BOX_WALL_BOT];
    h = h + head_depth - wall_bot;
    chamfer = is_def(chamfer) ? -chamfer : undef;
    rounding = is_def(rounding) ? -rounding : undef;
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

function keyhole(d1=3,d2=6,l,r) =
    let(r=default(r,d1/2),l=d2,$fn=get_fn(d2/2,4)) // fn must be even by 4 for this to work!
    assert(r<d1)
    force_path(round_path(union([
        circle(d=d1),
        rect([d1,l],anchor=TOP),
        move([0,-l],circle(d=d2)),
    ]),r));

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

module box_snap_fit(size=[3,2],depth=0.5,thickness,thru_hole=false,spring_len=3,spring_dir=FRONT,spring_slot=0.5,spring_slot2,gap=0.1,anchor=BOT+BACK,spin=0,orient=DOWN) {
    checks = assert(depth<=size.y/2);
    
    thickness = is_def(thickness) ? thickness : is_def($box_wall) ? $box_wall/2 : 1;
    s = (spring_dir.y != 0 ? size : [size.y, size.x]) + [0,spring_len];
    spring_slot2 = default(spring_slot2, spring_slot);

    module snap_shape(slop=0,thru=false) {
        sz = size + [slop,slop];
        up(thickness) if(thru) cube([sz.x,sz.y,$box_wall],anchor=BOT); else prismoid(size1=sz,h=depth+slop,yang=45,xang=80);
        ofs = spring_dir.y != 0 ? sz.y : sz.x;
        move(-spring_dir*ofs/2) rot(from=FRONT,to=spring_dir) cuboid([s.x,s.y,thickness],anchor=BOT+BACK) children();
    }

    asz = [size.x,size.y,thickness+depth];
    component(anchor,spin,orient,size=asz,cp=[0,0,asz.z/2]) {
        box_half(BOT) {
            tag(BOX_KEEP_TAG) snap_shape()
            if(spring_len) box_cut() {
                position(FRONT) back(0.001) cuboid([s.x+spring_slot*2,s.y+spring_slot2,thickness+1],rounding=spring_slot/2,edges="Z",anchor=FRONT);
            }
        }

        box_half(TOP)
            box_cut() down(0.001) fwd(gap) snap_shape(spring_len /*&& !thru_hole*/ ? 0 : get_slop(), thru=thru_hole);

        children();
    }
}

module d1mini(pcb_zofs = 3,anchor=CENTER,spin=0,orient=UP) {
    h = $parent_size.z;
    pcb = [25.85,34.2,1.3];
    usb = [7.5,6.5,2.3];
    hole_pos = [[3.4,pcb.y-3.2],[pcb.x-3.2,2.9]];
    module d1_preview() {
        box_preview("#44ba")
        diff() cuboid(pcb,rounding=3.4,edges=[BACK+LEFT,BACK+RIGHT],anchor=FRONT+BOTTOM+LEFT) {
            up(0.001) recolor("#aaba") tag("keep") {
                position(FRONT+RIGHT+TOP) right(-8.3) cube(usb,anchor=BOT+RIGHT+FRONT);
                position(FRONT+LEFT+TOP) move([4.8,1.4]) cube([2.5,4.7,2],anchor=BOT+RIGHT+FRONT);
            }
            tag("remove") {
                position(FRONT+LEFT+BOT) move([-0.1,-0.1,-0.1]) cube([2.5,7,pcb.z*2],anchor=BOT+FRONT+LEFT);
                position(FRONT+BOT+RIGHT) move([-7.8,-0.1,-0.1]) cube([9,1,pcb.z*2],anchor=BOT+FRONT+RIGHT);
                for(p = hole_pos)
                    move(p) position(FRONT+LEFT) cyl(d=2.3,h=pcb.z*2);

            }
        }
    }

    module d1_standoff(pin=true) box_standoff_clamp(h=pcb_zofs,id=2,od=4,pin_h=pin?3:false,fillet=1.5,gap=pcb.z) children();

    sz = [pcb.x,pcb.y,h];
    attachable(anchor,spin,orient,size=sz,cp=[sz.x/2,sz.y/2,0]) {
        union() {
            for(p = hole_pos)
                move(p) d1_standoff();
            
            move([7,2.9]) d1_standoff(false);
            move([pcb.x-3.2,pcb.y-3.2]) d1_standoff(false);
        }

        union() {
            up(pcb_zofs+0.001) box_part(BOT,FRONT+LEFT) d1_preview();

            move([13.75,-0.002,pcb_zofs+usb.z/2+pcb.z]) position(BOT+FRONT+LEFT) box_part(FRONT,undef) box_cutout(rect([12,8],rounding=0.7));

            children();
        }
    }
}

module grove_oled_066(anchor=CENTER,spin=0,orient=UP) {
    gap=4;
    h = $parent_size.z;
    h2 = h-gap;
    scr_sz = [15.5,12];
    ofs = -3;

    module oled_preview() {
        box_preview("#44ba")
        back(ofs) up(h2) diff() cube([20.2,20.2,1.6],anchor=BOTTOM) {
            for(x = [-10,10]) right(x) {
                cyl(h=1.6-0.001,d=4.3);
                tag("remove") cyl(h=2,d=2.1);
            }

            up(1) position(TOP+BACK)
                recolor("#0007") cube([18.6,18.2,1.5],anchor=BOTTOM+BACK)
                back(-2) up(0.001) position(TOP+BACK) recolor("#000a") cube([14,10,0.1],anchor=BOTTOM+BACK);
            
            back(1) recolor("#ffda") position(FRONT+BOT) cube([12,5,8],anchor=TOP+FRONT);
        }
    }

    component(anchor,spin,orient,size=[scr_sz.x,scr_sz.y,h]) {
        box_half(BOT)
            back(ofs)
                for(x = [-10,10])
                    right(x) box_pos() standoff(h=h2,od=4,id=1.8,depth = -2, iround=0.25, fillet=2);


        box_part(TOP) box_cutout(rect(scr_sz,rounding=1),chamfer=0.75);

        box_part(BOT) up(0.001) oled_preview();
        children();
    }
}

module dht22(depth=3,anchor=CENTER,spin=0,orient=UP) {
    cut_sz = [16,20.5];
    gap = 1.8;
    h = $parent_size.z-gap-depth;

    module dht22_preview() {
        box_preview("#fffa")
        cube([15.4,20.3,7.7],anchor=BOTTOM)
            position(BACK+BOT) diff()
            prismoid([15.4,1.6],[10,1.6],5,anchor=BOT+BACK,orient=BACK)
            tag("remove") Z(-1.55+1.45) cyl(d=2.9,h=gap*2,orient=FRONT);
    }

    component(anchor,spin,orient,size=[cut_sz.x,cut_sz.y,$parent_size.z]) {
        box_part(BOT)
            standoff(h=h,od=7,id=5,fillet=1.5) up(0.1) position(TOP) dht22_preview();

        back(12.5) box_standoff_clamp(h=h,od=4.5,id=2.6,pin_h = 1,gap=gap,iround=0.5,fillet=1.5);

        box_part(TOP) box_cutout(rect(cut_sz),depth=2);
        children();
    }
}

module box_shell_base_lid(
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
    rim_snap=false, // do a snap ridge around the rim
    rim_snap_ofs=1, // offset along rim Z
    rim_snap_depth=0.2, // how much the snap ridge should protrude
    rim_snap_gap=0.1, // offset the snap rim in base and lid so they match before the lid is fully closed
    rim_snap_height=0.2, // extra snap height
){
    size = scalar_vec3(size);
    wall_top = default(wall_top, wall_sides);
    wall_bot = default(wall_bot, wall_top);

    base_height = default(base_height, size.z / 2 + (walls_outside ? wall_bot : 0));

    outer_base_height = base_height + rim_height;

    halves = [BOT, TOP];
    walls = [wall_sides,wall_sides,wall_sides,wall_sides,wall_bot,wall_top];
    splitpoint = [0,0,outer_base_height];

    $box_rim_height = rim_height;

    module box_wrap(sz,wall_bot,rim_height,rim_inside,rim_wall,rbot,rbot_inside,rim_snap_ofs) {
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
            outside_color=$box_outside_color,
            rim_snap=rim_snap,rim_snap_ofs=rim_snap_ofs,rim_snap_depth=rim_snap_depth,rim_snap_height=rim_snap_height);
    }

    _box_shell(size, splitpoint, walls, walls_outside, halves) {
        // base        
        if(box_half(BOT)) let(rim_gap = min(0,rim_gap)) {
            box_wrap(
                [$box_size.x,$box_size.y,outer_base_height+rim_gap],
                wall_bot=wall_bot,
                rim_height=rim_height+rim_gap,
                rim_inside=true,
                rim_wall=wall_sides/2,
                rbot=rbot,
                rbot_inside=rbot_inside,
                rim_snap_ofs=rim_snap_ofs+rim_snap_gap);
        }
        // lid
        else if(box_half(TOP)) let(rim_gap = max(0,rim_gap), h = $box_size.z - base_height) {
            up(base_height) zflip(z=h/2)
            box_wrap(
                [$box_size.x,$box_size.y,h-rim_gap],
                wall_bot=wall_top,
                rim_height=rim_height-rim_gap,
                rim_inside=false,
                rim_wall=wall_sides/2-get_slop(),
                rbot=rtop,
                rbot_inside=rtop_inside,
                rim_snap_ofs=rim_height-rim_snap_ofs-rim_snap_height,
                //
                );
        }
        // parts
        children();
    }
}
