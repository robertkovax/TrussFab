bottleNeckHeight = 26;
bottleNeckRadius = 14.5; //14.1 more exact, leave extra space to insert bottle easily
bottleNeckEndHeight = 78;
bottleNeckDiscHeight = 20;
bottleNeckDiscRadius = 19.2;
bottleBodyHeight = 235;
bottleBodyRadius = 34;

module drawBottle() {
  cylinder(r=bottleNeckRadius,h=bottleNeckHeight+0.1);
  translate([0,0,bottleNeckHeight])
  cylinder(r1=bottleNeckRadius,r2=bottleBodyRadius, h=bottleNeckEndHeight-bottleNeckHeight);
  translate([0,0,bottleNeckEndHeight-0.1])
  cylinder(r=bottleBodyRadius, h=bottleBodyHeight-bottleNeckEndHeight-bottleNeckHeight+0.1);
  translate([0,0,bottleNeckDiscHeight])
  cylinder(r=bottleNeckDiscRadius, h=4);
}

//drawBottle();
