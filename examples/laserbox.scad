include <jl_scad/box.scad>
include <jl_scad/parts.scad>
include <jl_scad/utils.scad>

$fs = $preview?0.25:0.125;

 $slop = 0.11;
 // FIXME: if slop = 0.1 -> assert is_consistent(points) non-rect or invalid point array in vnf.scad

laser_d = 9.1;
laser_l = 20;

switch_h = 8;

bat_sz = [48,26,18]; // 9V max size
bat_clip = 6;
bat_ofs = 12;
box_sz = [bat_sz.x+laser_l+bat_clip+bat_ofs,bat_sz.y+5,bat_sz.z+switch_h+1];

//cut_inspect(LEFT,ofs=[-12,0,0])
// cut_inspect(BACK)
box_make(BOX_BOTH,TOP,topsep=50.1,hide_box=false)
box_shell_rimmed(box_sz,rsides=6,walls=2,base_height=3,rim_height=2)
{
    size = $parent_size;

    X(5) box_part(TOP,CENTER) xcopies(20,2) box_wall(BACK,width=1.6,gap=bat_sz.z-$box_base_height+1);

    // laser
    box_part(TOP+LEFT) box_hole(5.5,rounding=0.75);
    
    X(-0.5) {
        box_cut() box_part(LEFT) cyl(d=laser_d,h=laser_l,anchor=BOT);
          //tag(BOX_KEEP_TAG) preview("#f667") cyl(d=laser_d,h=laser_l,anchor=CENTER);
        preview("#f667") tag(BOX_KEEP_TAG) box_part(LEFT+TOP) cyl(d=laser_d,h=laser_l,anchor=BOT);
    }
    X(0.5) {
        s = [laser_l+1,laser_d+2,size.z/2-1.5];
        for(a = [TOP,BOT]) {
            box_part(a,LEFT)
                diff() cuboid(s,anchor=LEFT+BOT,rounding=-1.5,edges=BOTTOM/*,except=LEFT*/)
                    tag("remove") position(TOP) Z(0.001) {
                        cube([laser_l*0.4,s.y+5,s.z-2],anchor=TOP);
                        cube([s.x+5,laser_d*0.4,s.z-2],anchor=TOP);
                    }
        }

    }

    // switch
    Z(-switch_h/2-0.5) {
        box_part(RIGHT+TOP,TOP) {
            box_hole(6.5);
            preview() cube([13,switch_h,15],anchor=BOTTOM);
        }
    }

    // screw holes
    for(a = [BACK+LEFT, FRONT+RIGHT, BACK+RIGHT, FRONT+LEFT])
        M(a * -0.25) position(a) box_screw_clamp(anchor=a,gap=0.1);

    // battery
    preview() X(-bat_ofs-bat_clip+2) Z(0.1) box_part(BOT,RIGHT) scale(1) cuboid(bat_sz,rounding=1,anchor=BOTTOM+RIGHT);

    Z(-0.25) box_part(TOP, CENTER, inside=false) box_cut() text3d("LASER", h=2, size=10, atype="ycenter", anchor=BOTTOM);
}