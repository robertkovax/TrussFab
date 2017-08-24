rotate([0,0,0])
difference(){
    
    length=20;
    cylinder(r=12, h=length,center=true);
    
    cylinder(r=8, h=length, center=true);
    translate([0,5])
    cube(size = [2.5,20,length], center=true);
    render()
    difference(){
        cylinder(r=12, h=9.25,center=true);
        cylinder(r=11, h=9.25,center=true);
    }
}