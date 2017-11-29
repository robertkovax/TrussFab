// taken from https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Primitive_Solids   
   
module prism(l, w, h){
   polyhedron(
           points=[[0,0,0], [l,0,0], [l,w,0], [0,w,0], [0,w,h], [l,w,h]],
           faces=[[0,1,2,3],[5,4,3,2],[0,4,5,1],[0,3,4],[5,2,1]]
           );
   }

prism(10, 5, 3);