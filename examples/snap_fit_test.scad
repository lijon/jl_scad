include <jl_scad/box.scad>
include <jl_scad/parts.scad>
include <jl_scad/utils.scad>

$slop = 0.1;
$fn = $preview?16:48;
$attachable_dump_tree = true;


sz = [30,30,10];

cut_inspect(BACK,color="black",ofs=0,s=200)
box_make(explode=10.1,hide_box=false)
{
    // snap fits
    xcopies(sz.x+10,2)
    box_shell_base_lid(sz,wall_sides=2,wall_top=1.2,rbot_inside=1,rtop_inside=1,rsides=15,rim_height=3,k=0.5)
    {
        if($idx == 0)
            up($box_rim_height) {
                box_part([LEFT,RIGHT])
                    box_snap_fit([5,2],spring_len=4,spring_dir=FRONT,thru_hole=false,depth=0.6,spring_slot2=5);

            }
        else
            up($box_rim_height/2)
                box_part([LEFT,RIGHT,FRONT,BACK])
                    box_snap_fit([5,1],anchor=BOT);
    }

    // rim snap
    right(sz.x*1.5+15) box_shell_base_lid(sz,wall_sides=2,wall_top=1.2,rbot_inside=1,rtop_inside=1,rsides=15,rim_height=3,k=0.5,rim_snap=true) {
        box_part([TOP+FRONT,TOP+BACK]) fwd(0.001) box_cutout(rect([4,1]),anchor=FRONT);
    }
}
