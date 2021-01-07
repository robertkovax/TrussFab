using Grassmann, Makie;
streamplot(vectorfield(exp((π/4)*(v12+v∞3)),V(2,3,4),V(1,2,3)),-1.5..1.5,-1.5..1.5,-1.5..1.5,gridsize=(10,10))


# // Create a Clifford Algebra with 4,1 metric for 3D CGA.
# Algebra(4,1,()=>{
@basis S"∞++++"
# // We start by defining a null basis, and upcasting for points
#   var ni = 1e4+1e5, no = .5e5-.5e4, nino = ni^no;
ni = 1v12+1v23
no = .5v12-.5v23
nino = ni^no
#   var up = (x)=> no + x + .5*x*x*ni;
up = (x) -> no + x + .5*x*x*ni;

# // Next we'll define some objects.
#   var p  = up(0),                          // point
#       S  = ()=>!(p-.5*ni),                 // main dual sphere around point (interactive)
p = 1v1 + 2v2 + 1v3
S1 =  !(p-.5*ni)
#       S2 = !(up(-1.4e1)-0.125*ni),         // left dual sphere
S2 = !(up(-1.4v1)-0.125*ni)
#       C  = !(up(1.4e1)-.125*ni)&!(1e3),    // right circle
#       L  = up(.9e2)^up(.9e2-1e1)^ni,       // top line
#       P  = !(1e2-.9*ni),                   // bottom dual plane
#       P2 = !(1e1+1.7*ni);                   // right dual plane

# // The intersections of the big sphere with the other 4 objects.
#   var C1 = ()=>S&P, C2 = ()=>S&L, C3 = ()=>S&S2, C4 = ()=>S&C, C5 = ()=>C&P2;
C1 = S1&S2
# // For line meet plane its a bit more involved.
#   var lp = up(nino<<(P2&L^no));

println(C1)

pathof(C1)
# // Graph the items. (hex numbers are html5 colors, two extra first bytes = alpha)
#   document.body.appendChild(this.graph([ 
#       0x00FF0000, p, "s1",             // point 
#       0xFF00FF,lp,"l&p",               // line intersect plane
#       0x0000FF,C1,"s&p",               // sphere meet plane
#       0x888800,C2,"s&l",               // sphere meet line
#       0x0088FF,C3,"s&s",               // sphere meet sphere
#       0x008800,C4,"s&c",               // sphere meet circle
#       0x880000,C5,"c&p",               // circle meet sphere
#       0,L,0,C,                         // line and circle
#       0xE0008800, P, P2,               // plane
#       0xE0FFFFFF, S, "s1", S2          // spheres
#   ],{conformal:true,gl:true,grid:true}));
# });
lines(V(2,3,4).(points(C1)))
