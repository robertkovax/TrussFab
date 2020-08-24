// Draws a jig for welding hubs made out of steel balls
// TOODO: cleanup and extract constants

aaa =[1.5743510519027641, 1.236204332513596, 0.440568038537731];

bbb =[1.825771601680959, 1.6716774987963312, 0.440568038537731];

ccc = (aaa-bbb)/norm(aaa-bbb);



ballRadius = 30.0;
mapVec = [0,0,1];

function sumVector(v) = [for(p=v) 1]*v;

function localAngle(vec,pv) = [for (i = [0:len(vec)-1]) abs(vec[pv][0]*vec[i][0]+vec[pv][1]*vec[i][1]+vec[pv][2]*vec[i][2])/sqrt(vec[pv][0]*vec[pv][0]+vec[pv][1]*vec[pv][1]+vec[pv][2]*vec[pv][2])];

function localMinimalAngle(vec,a) = min(localAngle(vec,a));

function allMinimalAngle(vec) = [for (i = [0:len(vec)-1]) localMinimalAngle(vec,i)];

bestVecNum = search(max(allMinimalAngle(dataFileVectorArray)),allMinimalAngle(dataFileVectorArray))[0];

centerVector = sumVector(dataFileVectorArray)/len(dataFileVectorArray);


function rotationZ(r) =
[
[cos(r), -sin(r), 0],
[sin(r),  cos(r), 0],
[0, 0, 1]
];

function rotationY(r) =
[
[cos(r), 0, sin(r)],
[0, 1, 0],
[-sin(r), 0, cos(r)]
];


function rotationX(r) =
[
[1, 0, 0],
[0, cos(r), -sin(r)],
[0, sin(r), cos(r)]
];

function zAngle(vec,mapVec) = vec[0]>0 ? 360 -acos(([vec[0],vec[1]]*[mapVec[0],mapVec[1]])/(norm([vec[0],vec[1]])*norm([mapVec[0],mapVec[1]]))):acos(([vec[0],vec[1]]*[mapVec[0],mapVec[1]])/(norm([vec[0],vec[1]])*norm([mapVec[0],mapVec[1]])));

function xAngle(vec,mapVec) = vec[1]<0 ? 360 - acos(([vec[1],vec[2]]*[mapVec[1],mapVec[2]])/(norm([vec[1],vec[2]])*norm([mapVec[1],mapVec[2]]))) : acos(([vec[1],vec[2]]*[mapVec[1],mapVec[2]])/(norm([vec[1],vec[2]])*norm([mapVec[1],mapVec[2]])));

function yAngle(vec,mapVec) = vec[0]<0 ? acos(([vec[2],vec[0]]*[mapVec[2],mapVec[0]])/(norm([vec[2],vec[0]])*norm([mapVec[2],mapVec[0]]))) :360 - acos(([vec[2],vec[0]]*[mapVec[2],mapVec[0]])/(norm([vec[2],vec[0]])*norm([mapVec[2],mapVec[0]])));

function xyzAngle(vec1,vec2) = acos(vec1*vec2/norm(vec1)*norm(vec2));

function linearMap(vec,mat) = [for (i = [0:len(vec)-1]) mat*vec[i]];

function moveToPlane(vec,planeZ) = [for  (i = [0:len(vec)-1]) [vec[i][0],vec[i][1],planeZ]];

function vecFromStein(vec,num) =   [for(i = [0:len(vec)-1])  norm(vec[i]-vec[num]) !=0 ? (vec[i]-vec[num])/norm(vec[i]-vec[num]) : [0,0,0]];

function arcLength(vec,num) = [for(i = [0:len(vec)-1]) vec[i]!=vec[num] ? ballRadius*2*PI*xyzAngle(vec[i],vec[num])/360 : 1];

function multiplyArray(array1,array2) = [for(i = [0:len(array1)-1]) array1[i]*array2[i]];


vecRotatedX = linearMap(dataFileVectorArray,rotationX(xAngle(dataFileVectorArray[bestVecNum],mapVec)));

vecRotatedXY = linearMap(vecRotatedX,rotationY(yAngle(vecRotatedX[bestVecNum],mapVec)));

branchVec = multiplyArray(vecFromStein(moveToPlane(vecRotatedXY*ballRadius,ballRadius),bestVecNum),
                   arcLength(dataFileVectorArray,bestVecNum));

//function grandtruthVec(vec) = [for(i=[0:len(branchVec)-1])


module drawJig(){
    for(i = [0:len(branchVec)-1]){
        if(i!=bestVecNum){
            difference(){
                translate(branchVec[i]) cylinder(h=10,r=8,center = true);
                translate(branchVec[i]) cylinder(h=11,r=1,center = true);
            }
        }
    }

    difference(){
        echo(branchVec[bestVecNum]);
        translate(branchVec[bestVecNum]) cylinder(h=10,r=10,center = true);
        translate(branchVec[bestVecNum]) cylinder(h=11,r=1,center = true);
    }

    difference(){
        makeLines();
        makeHoleCircles();
    }
}

module makeLines(){
    union(){
        for(i = [0:len(branchVec)-1]){
            line(branchVec[bestVecNum],branchVec[i]);
        }
    }
}

module line(start, end, thickness = 4) {
    hull() {
        translate(start) sphere(thickness);
        translate(end) sphere(thickness);
    }
}


module makeHoleCircles(){
    for(i = [0:len(branchVec)-1]){
        translate(branchVec[i]) cylinder(h=11,r=2,center = true);
    }
}

module drawWeldingJig(){
     color("#facd00",1.0)
     projection(cut = false)
     difference(){
         drawJig();
         drawID();
     }
}

//debugPoint(branchVec,"red");

//DEBUG
//translate([0,0,-32])
//color("#1c4c93",0.7) drawDebugJig();

module drawID()
{
    i = 0;
    for(i = [0:len(branchVec)-1]){
        if(i != bestVecNum){
            branchAngle = zAngle(branchVec[i],[0,1,0]);
            //branchAngle = branchVec[i][1]<0 ? zAngle(branchVec[i],[0,1,0]) : -zAngle(branchVec[i],[0,1,0]);
            //echo(branchAngle);

            translate(branchVec[i]+(branchVec[i]/norm(branchVec[i]))*4)
            rotate(branchAngle)
            translate([-5.2,-1.5,-25]){
                linear_extrude(height = 50){
                    text(str("ID:",dataFileAddonParameterArray[i][1]),size = 2.5,font = "Sukima");
                }
            }

            translate(branchVec[i]-(branchVec[i]/norm(branchVec[i]))*4)
            rotate(branchAngle)
            translate([-5.2,-1.5,-25]){
                linear_extrude(height = 50){
                text(str("E-ID:",dataFileAddonParameterArray[i][2]), size = 3, font = "Sukima");
                }
            }
        }else{
            tempVec = [0,1,0];
            translate(tempVec*5)
            translate([-5.2,-1.5,-25]){
                linear_extrude(height = 50){
                text(str("ID:",dataFileAddonParameterArray[i][1]),size = 3,font = "Sukima");
                }
            }

           //translate(tempVec*5)
            translate([-8.2,-1.5,-25]){
                linear_extrude(height = 50){
                text(str(":",hubID,":"),size = 3,font = "Sukima");
                }
            }

            translate(tempVec*(-5))
            translate([-5.2,-1.5,-25]){
                linear_extrude(height = 50){
                text(str("L:",connectionLengthArray[i]),size = 3,font = "Sukima");
                }
            }
        }
     }
}

module drawDebugJig(){
    difference() {
        baseCup();
        cylinderForHoles2();
    }
}

module baseCup(){
    difference(){
        sphere (31.2);
        sphere (30.2);
    }
}


module cylinderForHoles(vec){
    for(i = [0:len(vec)-1]){
        x = vec[i][0];
        y = vec[i][1];
        z = vec[i][2];
        length = norm([x,y,z]);
        b = acos(z/length);
        c = atan2(y,x);
        tv = [0,b,c];
        rotate(tv) cylinder( r = 4, h = 580);


    }
}
module cylinderForHoles2(){

    for(i = [0:len(vecRotatedXY)-1]){
        line([0,0,0],vecRotatedXY[i]*30);
    }
}


module debugPoint(points,colorText){
    for(i = [0:len(points)-1]){
        if(i==bestVecNum){
            color(colorText,0.6) translate(points[i]) cube(2,true);
        }else{
            color(colorText,0.6) translate(points[i]) cube(1,true);
        }
    }
}
