# JL_SCAD

Box enclosure library for OpenSCAD that make use of [BOSL2](https://github.com/BelfrySCAD/BOSL2/tree/master).

This library makes it simple to design enclosures for electronic projects, etc.

![](images/jl_box_example.png)

## Installation
Clone this git repo inside your OpenSCAD libraries folder.
You also need BOSL2 installed.

## Basics

The main module is `box_make()`, which takes a box shell child. It allows to generate only the base, the lid, or both. And lay them out as assembled, or for 3D printing.

The box shell module defines the box, and takes all the parts as children. There's currently only one box type included, but it's easy to add more.

To place parts, you use `box_part(side, anchor)` which takes one or more parts as children. `side` is a vector that decides which side of the box to put the part, it should contain TOP or BOTTOM to decide if the part should be in the lid or the base, but can also be CENTER to put the part in both (useful for cutouts). if you add an X or Y vector to the side, the part will be placed against that side. The `anchor` defaults to CENTER and decides the box anchor to place the part at, the anchor is automatically adjusted according to `side`, so `side = TOP+LEFT` will include `LEFT` in the anchor, and orient the part so it points to the right.

So the most basic example looks like this:
```
include <jl_scad/box.scad>
include <jl_scad/parts.scad>

box_make(BOX_BOTH, BACK)
box_shell_rimmed([100,100,20])
{
    box_part(BOT, CENTER) standoff(); // add a standoff in the center of the base.
}
```

There are also `box_cutout()` to easily create cutouts from a 2D path, or `box_cut()` to cut with any shape. Cuts uses the standard BOSL2 diff(), with BOX_CUT_TAG and BOX_KEEP_TAG.

See the examples folder to learn more!

## Compound parts

Sometimes it's useful to have a part that has both a half in the base and one half in the lid. These are simply modules that gather parts for both TOP and BOT sides. They should be made `attachable()` so that they react correctly on the positioning and orientation:

```
module my_compound_part(size, anchor=CENTER, spin=0, orient=UP) {
    inside_height = $parent_size.z;
    attachable(anchor, spin, orient, size=[size.x,size.y,inside_height]) {
        union() {
            box_part(BOT, CENTER) cube(size, anchor=BOTTOM);
            box_part(TOP, CENTER) cube([size.x, size.y, inside_height - size.z], anchor=BOTTOM);
        }
        children();
    }
}
```

Some included compound parts:

- box_standoff_clamp() - A standoff with a pin in the base and hole in the lid part, to clamp a PCB or similar in place.
- box_scew_clamp() - similar but with a screw hole in the base, to screw the base and lid together.

## Orientations
The `box_part()` module automatically orient parts for the sides like below, with their bottom against the box face, either on inside (default) or outside. Note that parts oriented downwards are rotated around X-axis instead of Y-axis.

![](images/jl_box_orientations.png)

## Another example design
A box for a laser module, 9V battery, and toggle switch. The parts to be installed are show with `box_preview()` and shown transparent, and are not included in the final render.

![](images/jl_box_laserbox.png)
