include <jl_scad/box.scad>
include <jl_scad/parts.scad>

box_make(BOX_BOTH)
box_shell1(80,wall_side=10,hide=true)
{
    a = [[TOP,"TOP"],
        [BOTTOM,"BOTTOM"],
        [LEFT+BOT,"LEFT"],
        [RIGHT+BOT,"RIGHT"],
        [BACK+BOT,"BACK"],
        [FRONT+BOT,"FRONT"]
    ];

    for(i=a) box_part(i[0], CENTER, inside=true) mytext(i[1],"white");
    for(i=a) box_part(i[0], CENTER, inside=false) mytext(i[1],"orange");

    box_part(BOT, CENTER, auto_anchor=false, inside=true) wirecube("white");
    box_part(BOT, CENTER, auto_anchor=false, inside=false) wirecube("orange");
}

module mytext(txt,clr) color(clr) text3d(txt,h=0.5,size=5,anchor=BOTTOM,atype="ycenter",spacing=1.5);
module wirecube(clr) color(clr,0.5) tag("keep") edge_profile() square(0.5);