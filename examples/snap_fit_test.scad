include <jl_scad/box.scad>
include <jl_scad/parts.scad>
include <jl_scad/utils.scad>

$slop = 0.1;
$fn = $preview?16:24;

sz = [20,20,15];

//cut_inspect(BACK,color="green",ofs=0)
box_make(explode=10.01,hide_box=false)
{
    // snap fits
    box_shell_base_lid(sz,wall_sides=2,wall_top=1.2,rbot_inside=1,rtop_inside=1,rsides=8,rim_height=5,k=0.6)
    {
        up($box_rim_height) {
            box_part([BACK,FRONT])
                box_snap_fit([5,2],spring_len=5,spring_dir=FRONT,thru_hole=true);

             box_part([LEFT,RIGHT])
                box_snap_fit([3,2]);
        }
    }

    // rim snap
    right(sz.x+10) box_shell_base_lid(sz,wall_sides=2,wall_top=1.2,rbot_inside=1,rtop_inside=1,rsides=8,rim_height=3,k=0.6,rim_snap=true,rim_snap_gap=0);
}
