include <jl_scad/box.scad>
include <jl_scad/parts.scad>
include <jl_scad/utils.scad>

$fs = 0.5;

// Making the path roughly symmetric about the origin make box_cutout
// easier to work with - but you will probably have to adjust depth
// (so that the cutout reaches the inside of the box), and orientation
// (so the cutout reaches the inside of the box uniformly across its
// width).
// The coordinates of the path won't be adjusted (eg centered). This
// makes it easier to reason about where to place things (simply position
// them relative to the origin in the path's coordinate system).
box_points = [
    [25, -10],
    [-25, -15],
    [-25, 15],
    [0, 15],
    [25, 8],
];

box_desc = [box_points, 15];

side_angle1 = atan2(5, 50);
side_angle2 = atan2(7, 25);

box_make(print=true,explode=0.2,hide_box=false, spread=12, halves=[BOTTOM, TOP])
    box_shell_base_lid(
        box_desc,
        rsides=4,
        rtop_inside=1,
        rbot_inside=1,
        rtop=1,
        wall_sides=2,
        base_height=box_desc[1]-4,
        rim_height=5,
        rim_snap=true,
        rim_snap_depth=0.3,
        walls_outside=true
    ) {

        box_half(BOT) box_pos(anchor=BOT,FRONT)
            right(10) back(4) yrot(side_angle1) box_cutout(rect([16, 4],rounding=1), depth=2, anchor=FRONT);

        box_half(BOT) box_pos(anchor=BOT,BACK)
            // side cut out for access to button
            right(15.5) back(3.5)
            yrot(-side_angle2) box_cutout(rect([16,4],rounding=1), depth=5, anchor=FRONT);
        
        box_half(BOT) box_pos(anchor=BOT) {
            // objects will be placed relative to the origin in the
            // paths original coordinate system.
            cylinder(6, 4, 2);
            left(10) back(5) cube(5);
        }
}
