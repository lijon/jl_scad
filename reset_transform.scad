
use <BOSL2/builtins.scad>
include <BOSL2/std.scad>

$_matrix = IDENT;

module translate(v) {
    $_matrix = $_matrix * translate(v);
    _translate(v) children();
}

module rotate(a,v) {
    $_matrix = $_matrix * rot(a=a,v=v);
    _rotate(a,v) children();
}

module scale(v) {
    $_matrix = $_matrix * scale(v);
    _scale(v) children();
}

module multmatrix(m) {
    $_matrix = $_matrix * m;
    _multmatrix(m) children();
}

module save_transform() {
    $_matrix = IDENT;
    children();
}

module reset_transform() {
    _multmatrix(matrix_inverse($_matrix)) save_transform() children();
}
