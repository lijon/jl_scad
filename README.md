# JL_SCAD

Box enclosure library on top of BOSL2 (https://github.com/BelfrySCAD/BOSL2/tree/master)

Example:
![](images/jl_box_example.png)

More documentation to come...

## Orientations
The `box_pos(anchor, side)` module automatically orient parts for the box sides like below. Note that top and bottom are rotated around X-axis regardless of inside or outside, in contrast to BOSL2 normal `orient()` behaviour.

![](images/jl_box_orientations.png)
