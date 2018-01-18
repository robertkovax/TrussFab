// https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/List_Comprehensions
function cat(L1, L2) = [for (i=[0:len(L1)+len(L2)-1]) 
                        i < len(L1)? L1[i] : L2[i-len(L1)]] ;

module construct_intersection_poly(vectors) {
    points = cat([[0, 0, 0]], vectors);
    
    // NB: The order of the faces must be clock-wise (looking from the outside towards the face)
    
    // the top face depends on the number of input vector (points)
    top = [[for(i=[1:len(vectors)]) i ]];
    // always triangles, first get the easy sides
    side_all_but_not_last = [for(i=[1:len(vectors) - 1]) [i + 1, i, 0]];
    // the last to connect to the first one
    side_last = [[0, 1, len(vectors)]];

    // concat all together
    faces = cat(cat(side_all_but_not_last, side_last), top);

    polyhedron( points, faces );
}


construct_intersection_poly([[5, 0, 10], [0, 5, 10], [-5, 0, 7],[0, -5, 7]]);


//intersection() {
//difference() {
// mirror([0, 0, 1])
// sphere(26, 5, center=true);
// 
// union() {   
// sphere(20, 5, center=true);
// 
// translate([-50, -50, -100])
// cube([100, 100, 100]);
//     
// }
//}
//
//translate([0, 0, 26])
//mirror([0, 0, 1])
//cylinder(20,20,00,$fn=3);
//
//}