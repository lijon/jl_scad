include <jl_scad/box.scad>
include <jl_scad/parts.scad>

box_make(BOX_BASE)
box_shell1(80,wall_side=10,hide=true)
{
    a = [[TOP,"TOP"],
        [BOTTOM,"BOTTOM"],
        [LEFT,"LEFT"],
        [RIGHT,"RIGHT"],
        [BACK,"BACK"],
        [FRONT,"FRONT"]
    ];

    box_part(BOX_BASE) {
        box_inside()
        {
            for(i=a) box_pos(CENTER, i[0]) mytext(i[1],"white");

            wirecube("white");
        }

        // box_outside

        for(i=a) box_pos(CENTER, i[0]) mytext(i[1],"orange");

        wirecube("orange");
    }
}

module mytext(txt,clr) color(clr) text3d(txt,h=0.5,size=5,anchor=BOTTOM,atype="ycenter",spacing=1.5);
module wirecube(clr) position(CENTER) color(clr,0.5) edge_profile() square(0.5);