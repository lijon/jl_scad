include <jl_scad/box.scad>
include <jl_scad/parts.scad>
include <jl_scad/utils.scad>

$slop = 0.1;
$fn = 24;

sz = [20,20,20];

cut_inspect(BACK,color="green")
box_make(explode=10,hide_box=false)
{
    // snap fits
    box_shell_base_lid(sz,wall_sides=2,wall_top=1.2,rbot_inside=1,rtop_inside=1,rsides=8,rim_height=4,k=0.6)
    {
        box_part([LEFT,RIGHT]) {
            box_snap_fit(length=8);
        }

        // box_part([LEFT,RIGHT]) { // flipped
        //     box_flip(UP) box_snap_fit(length=10,anchor=BOT);
        // }
    }

    // rim snap
    right(sz.x+10) box_shell_base_lid(sz,wall_sides=2,wall_top=1.2,rbot_inside=1,rtop_inside=1,rsides=8,rim_height=4,k=0.6,rim_snap=true);
}
