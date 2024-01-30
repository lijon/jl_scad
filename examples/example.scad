include <jl_scad/utils.scad>
include <jl_scad/box.scad>
include <jl_scad/parts.scad>

$slop = 0.1;

$fs=$preview?0.5:0.125;
$fa = 1;

cut_inspect(BACK)
box_make(BOX_BOTH,topsep=0.1)
//color($box_half==BOX_BASE?"#888":"#bbb") render(5)
//color("blue")
box_shell1([50,40,20],wall_bot=2.2,wall_top=1.2,wall_side=1.6,rim_gap=0,rbot=1,rbot_inside=2,rtop=1,rtop_inside=1,rsides=5,base_height=0)
{
    
    box_inside()
    {
        box_add_base() {
            M(10,25) box_pos() standoff(h=5); // default box anchor is bottom+left+front corner.
            
            Y(10) box_pos(CENTER,LEFT) standoff(h=3,anchor=BOTTOM);
            
            box_pos(CENTER,RIGHT) standoff(h=1);
        }

        box_add_lid() {
            X(1) box_pos(LEFT) standoff(h=2,anchor=BOTTOM+LEFT);
        }
                          
        box_cut_base() {
            Z(0.001) box_pos(BACK+BOTTOM, BACK) box_cutout(rect([8,4]),depth=2,anchor=FRONT);
        }

        box_cut_lid() {
            M(1,10) box_pos(LEFT) box_cutout(rect([8,5],rounding=1),chamfer=0.5,depth=5,anchor=LEFT);
            M(-5,10) box_pos(RIGHT) box_hole(3,rounding=0.5);
            
            // vents
            box_pos(TOP,BACK) xcopies(2,5) cuboid([1,4,4],rounding=0.5,anchor=CENTER);
         }
         
        box_cut_both()
            box_pos(CENTER,LEFT) box_cutout(rect([14,7],chamfer=0.5),chamfer=0.5);

        X(-7) { // wall. TODO: make module?
            edges = [BOTTOM+LEFT,BOTTOM+RIGHT];
            w = 1;
            f = 1;
            box_add_base() box_pos(FRONT) diff() cuboid([w,$parent_size.y,$box_base_height],rounding=-f,edges=edges,anchor=FRONT+BOTTOM) position(CENTER) orient(RIGHT) tag("remove") cyl(h=w*2,d=3);
            box_add_lid() box_pos(FRONT) cuboid([w,$parent_size.y,$box_lid_height],rounding=-f,edges=edges,anchor=BACK+BOTTOM);
        }

        // compound parts, no box_add/cut calls.
        box_pos(CENTER) box_standoff_clamp(h=5,od=4,id=2,gap=1.7,pin_h=2);

        X(-10) box_pos(RIGHT) box_flip() box_screw_clamp(rounding=0.5);

    }
    // outside box

    box_cut_base() Z(-4) Y(10) box_pos(CENTER,RIGHT) box_hole(2,chamfer=0.5);

    box_cut_lid() Z(-0.25) Y(2) box_pos(CENTER) text3d("JL BOX", h=2, size=3, anchor=BOTTOM);
    
    box_add_lid() Z(-3) Y(2) {
        box_pos(RIGHT+TOP,RIGHT) text3d("RIGHT", h=0.25, size=3, anchor=BOTTOM+LEFT+BACK);
        box_pos(LEFT+TOP,LEFT) text3d("LEFT", h=0.25, size=3, anchor=BOTTOM+RIGHT+BACK);
    }
}
