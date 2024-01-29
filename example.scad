include <utils.scad>
include <box.scad>
include <parts.scad>

$slop = 0.1;

$fs=$preview?0.5:0.125;
$fa = 1;


cut_inspect(BACK)
box_make(BOX_BOTH)
color($box_half==BOX_BASE?"#888":"#bbb") render(5)
box_shell1([50,40,20],wall_bot=1.2,wall_top=1.2,wall_side=1.6,rim_gap=0,rbot=1,rbot_inside=2,rtop=1,rtop_inside=1,rsides=3,base_height=0)
{
    
    box_inside()
    {
        box_add_base() {
            M(10,25) box_pos() standoff(h=5); // default box anchor is bottom+left+front corner.
            
            Y(10) box_pos(CENTER,LEFT) standoff(h=3);
            
            box_pos(CENTER,RIGHT) standoff(h=1);            
        }
                    
        box_add_lid() {
            X(1) box_pos(LEFT) standoff(h=2,anchor=BOTTOM+LEFT);
        }
        
        box_pos(CENTER) // bottom center
            box_standoff_clamp(h=5,od=4,id=2,gap=1.7,pin_h=3);
            
        X(15) box_pos(CENTER) box_flip() box_screw_clamp();
                  
        box_cut_base() {
            Z(0.001) box_pos(BACK+BOTTOM, BACK) box_cutout(rect([8,4]),depth=5,anchor=FRONT);
        }
         
        box_cut_lid() {
            M(0,10) box_pos(LEFT) box_cutout(rect([8,5],rounding=1),os_chamfer(-0.25),anchor=LEFT);
            M(-5,10) box_pos(RIGHT) box_hole(3,os_chamfer(-0.5));
            
            // vents
            box_pos(TOP,BACK) xcopies(2,5) cuboid([1,4,4],rounding=0.5,anchor=CENTER);
         }
         
         box_cut_both()
            box_pos(CENTER,LEFT) box_cutout(rect([14,4],chamfer=0.5));

    }

    // outside box
    box_cut_lid() Z(-0.25) Y(2) box_pos(CENTER) text3d("JL BOX", h=2, size=3, anchor=BOTTOM);
    
    box_add_lid() Z(-3) Y(2) {
        box_pos(RIGHT+TOP,RIGHT) text3d("RIGHT", h=0.25, size=3, anchor=BOTTOM+LEFT+BACK);
        box_pos(LEFT+TOP,LEFT) text3d("LEFT", h=0.25, size=3, anchor=BOTTOM+RIGHT+BACK);
    }
}

