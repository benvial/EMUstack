
// Force Gmsh to use legacy msh file format v2
Mesh.MshFileVersion = 2.2;


d = 1; // grating period
ff = 0;
d_in_nm = 0;
dy_in_nm = 0;
dy = dy_in_nm/d_in_nm;
a1 = 0;
a2 = 0;
a3 = 0;
radius1 = (a1/(2*d_in_nm))*d;
radius2 = (a2/(2*d_in_nm))*d;
radius3 = (a3/(2*d_in_nm))*d;
lc = 0; // 0.501 0.201 0.0701;
lc2 = lc/1; // on cylinder surfaces
lc3 = lc/1; // cylinder1 centres
lc4 = lc/1; // cylinder2 centres
lc5 = lc/1; // cylinder3 centres

hy = dy; // Thickness: Squre profile => hy=d
hx = 0.;

// 2*2 supercell outline

Point(1) = {0, 0, 0, lc4};
Point(2) = {-hx, -hy, 0, lc4};
Point(3) = {-hx+d, -hy, 0, lc4};
Point(4) = {d, 0, 0,lc4};
Point(5) = {-hx+d/2, -hy/2, 0,lc3};
Point(10) = {-hx+d/2, 0, 0, lc};
Point(11) = {0,-hy/2, 0, lc};
Point(12) = {-hx+d/2, -hy, 0, lc};
Point(13) = {d, -hy/2, 0, lc};

Point(14) = {-hx+radius2, 0, 0, lc2};
Point(15) = {d-radius2, 0, 0, lc2};
Point(16) = {0,-radius2, 0, lc2};
Point(18) = {-hx+d/2, -hy/2+radius1, 0, lc2};
Point(20) = {d,-radius2, 0, lc2};
Point(21) = {-hx+d/2-radius1, -hy/2, 0,lc2};
Point(22) = {-hx+d/2+radius1, -hy/2, 0,lc2};
Point(23) = {-hx, -hy+radius2, 0, lc2};
Point(25) = {-hx+d/2, -hy/2-radius1, 0, lc2};
Point(27) = {d,-hy+radius2, 0, lc2};
Point(28) = {-hx+radius2, -hy, 0, lc2};
Point(29) = {d-radius2, -hy, 0, lc2};

Point(30) = {0,-hy/2 + radius3, 0, lc};
Point(31) = {0,-hy/2 - radius3, 0, lc};
Point(32) = {0 + radius3,-hy/2, 0, lc};
Point(33) = {d,-hy/2 + radius3, 0, lc};
Point(34) = {d,-hy/2 - radius3, 0, lc};
Point(35) = {d - radius3,-hy/2, 0, lc};
Point(36) = {hy/2 + radius3,0, 0, lc};
Point(37) = {hy/2 - radius3,0, 0, lc};
Point(38) = {hy/2, -radius3, 0, lc};
Point(39) = {hy/2 + radius3, -hy, 0, lc};
Point(40) = {hy/2 - radius3, -hy, 0, lc};
Point(41) = {hy/2, -hy+radius3, 0, lc};

Line(1) = {1, 14};

Line(2) = {14, 37};
Line(3) = {37, 10};
Line(4) = {10, 36};
Line(5) = {36, 15};
Line(6) = {15, 4};
Line(7) = {4, 20};
Line(8) = {20, 33};
Line(9) = {33, 13};
Line(10) = {13, 34};
Line(11) = {34, 27};
Line(12) = {27, 3};
Line(13) = {3, 29};
Line(14) = {29, 39};
Line(15) = {39, 12};
Line(16) = {12, 40};
Line(17) = {40, 28};
Line(18) = {28, 2};
Line(19) = {2, 23};
Line(20) = {23, 31};
Line(21) = {31, 11};
Line(22) = {11, 11};
Line(23) = {30, 30};
Line(24) = {30, 11};
Line(25) = {30, 16};
Line(26) = {16, 1};
Line(27) = {11, 32};
Line(28) = {32, 21};
Line(29) = {21, 5};
Line(30) = {5, 22};
Line(31) = {22, 35};
Line(32) = {35, 13};
Line(33) = {10, 38};
Line(34) = {38, 18};
Line(35) = {18, 5};
Line(36) = {5, 25};
Line(37) = {25, 41};
Line(38) = {41, 12};

Circle(39) = {14, 1, 16};
Circle(40) = {15, 4, 20};
Circle(41) = {27, 3, 29};
Circle(42) = {28, 2, 23};
Circle(43) = {21, 5, 18};
Circle(44) = {18, 5, 22};
Circle(45) = {22, 5, 25};
Circle(46) = {25, 5, 21};
Circle(47) = {37, 10, 38};
Circle(48) = {38, 10, 36};
Circle(49) = {33, 13, 35};
Circle(50) = {35, 13, 34};
Circle(51) = {39, 12, 41};
Circle(52) = {41, 12, 40};
Circle(53) = {31, 11, 32};
Circle(54) = {32, 11, 30};

Line Loop(55) = {1, 39, 26};
Plane Surface(56) = {55};
Line Loop(57) = {6, 7, -40};
Plane Surface(58) = {57};
Line Loop(59) = {41, -13, -12};
Plane Surface(60) = {59};
Line Loop(61) = {42, -19, -18};
Plane Surface(62) = {61};
Line Loop(63) = {43, 35, -29};
Plane Surface(64) = {63};
Line Loop(65) = {35, 30, -44};
Plane Surface(66) = {65};
Line Loop(67) = {30, 45, -36};
Plane Surface(68) = {67};
Line Loop(69) = {36, 46, 29};
Plane Surface(70) = {69};
Line Loop(71) = {54, 24, 27};
Plane Surface(72) = {71};
Line Loop(73) = {27, -53, 21};
Plane Surface(74) = {73};
Line Loop(75) = {47, -33, -3};
Plane Surface(76) = {75};
Line Loop(77) = {4, -48, -33};
Plane Surface(78) = {77};
Line Loop(79) = {49, 32, -9};
Plane Surface(80) = {79};
Line Loop(81) = {32, 10, -50};
Plane Surface(82) = {81};
Line Loop(83) = {51, 38, -15};
Plane Surface(84) = {83};
Line Loop(85) = {38, 16, -52};
Plane Surface(86) = {85};
Line Loop(87) = {2, 47, 34, -43, -28, 54, 25, -39};
Plane Surface(88) = {87};
Line Loop(89) = {48, 5, 40, 8, 49, -31, -44, -34};
Plane Surface(90) = {89};
Line Loop(91) = {31, 50, 11, 41, 14, 51, -37, -45};
Plane Surface(92) = {91};
Line Loop(93) = {46, -28, -53, -20, -42, -17, -52, -37};
Plane Surface(94) = {93};

Physical Line(95) = {1, 2, 3, 4, 5, 6};
Physical Line(96) = {7, 8, 9, 10, 11, 12};
Physical Line(97) = {13, 14, 15, 16, 17, 18};
Physical Line(98) = {19, 20, 21, 24, 25, 26};

Physical Surface(1) = {88, 90, 92, 94};
Physical Surface(2) = {64, 66, 68, 70};
Physical Surface(3) = {56, 76, 78, 58, 80, 82, 60, 84, 86, 62, 74, 72};
