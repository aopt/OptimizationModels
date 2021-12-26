$ontext

   https://en.wikipedia.org/wiki/MacMahon_Squares

   We have 24 different squares with 4 colored edges, as in:

     _  _
   |\ W  /|
   |R\ /  |
   | /W\B |
   |/_ _\ |


   Place these 24 squares on a 4 x 6 grid.
   Squares can be rotated.

   Constraints:
      border of grid has white edges
      touching edges have the same color

   Q: how many ways to place squares on the grid.


$offtext


$set htmlfile MacMahon.html
$set jsfile   data.js


*--------------------------------------------------------------
* data
*--------------------------------------------------------------

sets
   i 'rows'      /row1*row4/
   j 'columns'   /col1*col6/
   k 'square'    /square1*square24/
   r 'rotation'  /0deg,45deg,90deg,135deg/
   c 'colors'    /Red,White,Blue/
   e 'edge'      /top,right,bottom,left/
   sq(k,r,e,c) 'squares'
;

acronym Wh,Rd,Bl;

parameter
   Colors(c) /Red Rd, White Wh, Blue Bl/
   Rotate(r) 'how many 45 degree rotations'
;
Rotate(r) = ord(r)-1;

table Squares(k,e)
          top  right bottom left
square1    Wh    Wh    Wh    Wh
square2    Rd    Wh    Wh    Wh
square3    Rd    Rd    Wh    Wh
square4    Rd    Wh    Rd    Wh
square5    Rd    Rd    Rd    Wh
square6    Rd    Rd    Rd    Rd
square7    Rd    Bl    Wh    Wh
square8    Rd    Wh    Bl    Wh
square9    Rd    Wh    Wh    Bl
square10   Rd    Bl    Bl    Wh
square11   Rd    Bl    Wh    Bl
square12   Rd    Bl    Bl    Bl
square13   Rd    Rd    Bl    Wh
square14   Rd    Rd    Wh    Bl
square15   Rd    Rd    Bl    Bl
square16   Wh    Bl    Bl    Rd
square17   Rd    Wh    Rd    Bl
square18   Rd    Bl    Rd    Bl
square19   Rd    Rd    Rd    Bl
square20   Bl    Wh    Wh    Wh
square21   Bl    Bl    Wh    Wh
square22   Bl    Wh    Bl    Wh
square23   Bl    Bl    Bl    Wh
square24   Bl    Bl    Bl    Bl
;

sq(k,r,e,c) = Squares(k,e--rotate(r))=colors(c);
option sq:0:0:4;
display sq;


parameter numsq(*) 'number of elements in sq (w or w/o duplicates)';
numsq('with dups') = card(sq);
display "with duplicates",sq;

*--------------------------------------------------------------
* remove duplicates from rotations
* this is not so important for finding a single solution
* but it is for enumerating all solutions.
*--------------------------------------------------------------

* flag, set to 0 or 1
scalar RemoveDuplicates /1/;

alias(r,rr);
scalar diff;
loop(k$RemoveDuplicates,
  loop(r$(ord(r)>1),
     loop(rr$(ord(rr)<ord(r)),
        diff = sum((e,c)$(sq(k,r,e,c) xor sq(k,rr,e,c)),1);
        if(diff=0,
           sq(k,r,e,c) = no;
           break;
        );
     );
  );
);

if(RemoveDuplicates,
  display "without duplicates",sq;
  numsq('without dups') = card(sq);
);

display numsq;

set kr(k,r) 'allowed rotations';
kr(k,r)$sum(sq(k,r,e,c),1) = yes;

*--------------------------------------------------------------
* construction of border and touch sets used in constraints.
*--------------------------------------------------------------

* we need to fix border to white
set border(i,j,e) 'border edges';
border('row1',j,'top') = yes;
border('row4',j,'bottom') = yes;
border(i,'col1','left') = yes;
border(i,'col6','right') = yes;
display border;

alias (i,i1,i2), (j,j1,j2), (e,e1,e2);
set touch(i1,j1,e1,i2,j2,e2) '(i1,j1,e1) touches (i2,j2,e2)';
touch(i1,j1,'right',i1,j1+1,'left') = yes;
touch(i1,j1,'bottom',i1+1,j1,'top') = yes;
option touch:0:0:4;
display touch;


*--------------------------------------------------------------
* Model, single solution
*--------------------------------------------------------------

binary variables
   x(i, j, k, r)  'placement of squares'
   y(i, j, e, c)  'colors of cell'
;

variable z 'dummy objective';

equations
   obj               'dummy'
   assign1(k)        'each square is assigned to one cell'
   assign2(i,j)      'each cell is occupied by one square'
   linkXy(i,j,e,c)   'links x and y'
   sharedEdges(i1,j1,e1,i2,j2,e2,c) 'shared edges have the same color'
;

* assignment square k to cell i,j
assign1(k)..   sum((i,j,r)$kr(k,r),x(i,j,k,r)) =e= 1;
assign2(i,j).. sum(kr,x(i,j,kr)) =e= 1;

* linking of y to x
linkXy(i,j,e,c).. y(i,j,e,c) =e= sum(sq(kr,e,c),x(i,j,kr));

* shared edges must have the same color
sharedEdges(touch(i1,j1,e1,i2,j2,e2),c)..
   y(i1,j1,e1,c) =e= y(i2,j2,e2,c);

* dummy objective: we only look for feasibile solutions
obj.. z =e= 0;

* fix color of edges at the border of the grid
y.fx(border,'white') = 1;


* relax y to be continuous
y.prior(i,j,e,c) = inf;

model m /all/;
solve m minimizing z using mip;

option x:0:0:4,y:0:0:4;
display x.l,y.l;

*--------------------------------------------------------------
* Model, a few solutions by adding cuts
*--------------------------------------------------------------

sets
   sol /solution1*solution10/
   s(sol)
;

parameters
   xsol(sol,i,j,k,r) 'recorded solutions'
   ysol(sol,i,j,e,c) 'recorded solutions'
;

equation cut(sol);

cut(s).. sum((i,j,kr), xsol(s,i,j,kr)*x(i,j,kr)) =l=  card(k)-1;


s('solution1') = yes;
xsol(s,i,j,kr) = round(x.l(i,j,kr));
ysol(s,i,j,e,c) = round(y.l(i,j,e,c));

model m2 /all/;
m2.solvelink = %solveLink.loadLibrary%;
m2.solprint = %solprint.Silent%;
option limrow=0,limcol=0;

loop(sol$(ord(sol)>1),
   solve m2 minimizing z using mip;
   xsol(sol,i,j,kr) = round(x.l(i,j,kr));
   ysol(sol,i,j,e,c) = round(y.l(i,j,e,c));
   s(sol) = yes;
);

display xsol;


*--------------------------------------------------------------
* Generate picture os solutions in HTML/JS
*--------------------------------------------------------------


file f /'%jsfile%'/;
put f;

* collection of squares
put "Squares=["/;
loop(k,
   put "  [";
   loop(sq(k,'0deg',e,c),put '"',c.tl:0,'",');
   put "],"/;
);
put "];"/;

* solutions
put "Solutions=["/;
loop(sol,
   put "[";
   loop((i,j,kr)$xsol(sol,i,j,kr),
     put ' {row:',ord(i):0:0,',col:',ord(j):0:0;
     put ',square:[';
     loop((e,c)$ysol(sol,i,j,e,c), put '"',c.tl:0,'",'; );
     put "]},"/;
   );
   put "],"/;
);
putclose "];";

*$libInclude win32 shellexecute  "%htmlfile%"
* for older gams systems use:
execute 'shellexecute "%htmlfile%"';

*--------------------------------------------------------------
* Use solution pool to enumerate all solutions
*--------------------------------------------------------------

option threads=8, mip=cplex;
m.optfile=1;
Solve m using mip minimizing z ;


$onecho > %htmlfile%
<html>
<head>
<title>MacMahon Squares</title>
<script src="%jsfile%"></script>
<script>

//
// draw a single triangle based on points specified in p
//
drawTriangle = function(p,ctx,color,offsets) {
   ctx.strokeStyle = "black";
   ctx.fillStyle = color;
   ctx.lineWidth = 2;
   ctx.beginPath();
   ctx.moveTo(offsets["x"]+p[0]["x"],offsets["y"]+p[0]["y"]);
   ctx.lineTo(offsets["x"]+p[1]["x"],offsets["y"]+p[1]["y"]);
   ctx.lineTo(offsets["x"]+p[2]["x"],offsets["y"]+p[2]["y"]);
   ctx.closePath();
   ctx.fill();
   ctx.stroke();
}

drawSquare = function(row,col,colors,ctx,size,margin,offsets) {
   const margin0 = 10, sqsize2 = Math.floor(size/2);
   var x1 = margin0+col*(margin+size),
       y1 = margin0+row*(margin+size);
   var p;
   // top
   p = [{"x":x1,"y":y1}, {"x":x1+sqsize2,"y":y1+sqsize2}, {"x":x1+size,"y":y1}];
   drawTriangle(p,ctx,colors[0],offsets)
   // right
   p = [{"x":x1+size,"y":y1}, {"x":x1+sqsize2,"y":y1+sqsize2}, {"x":x1+size,"y":y1+size}];
   drawTriangle(p,ctx,colors[1],offsets)
   // bottom
   p = [{"x":x1,"y":y1+size}, {"x":x1+sqsize2,"y":y1+sqsize2}, {"x":x1+size,"y":y1+size}];
   drawTriangle(p,ctx,colors[2],offsets)
   // left
   p = [{"x":x1,"y":y1}, {"x":x1+sqsize2,"y":y1+sqsize2}, {"x":x1,"y":y1+size}];
   drawTriangle(p,ctx,colors[3],offsets)
}


//
// draw collection of squares
//
drawSquares = function() {
  var canvas = document.getElementById("squares"),
      ctx = canvas.getContext("2d");
  var offsets = {"x":0, "y":0};
  var row = 0, col = 0;
  const size=50;
  ctx.font = "15px Arial";
  for (var k = 0; k<Squares.length; ++k) {
     drawSquare(row,col,Squares[k],ctx,size,20,offsets);
     ctx.fillStyle = "black";
     ctx.textAlign = 'center';
     ctx.fillText("k="+(k+1),10+col*(20+size)+Math.floor(size/2),75+row*(20+size));
     ++col;
     if (col>7) {col=0;++row};
  }
}


//
// draw a single solution
//
drawSolution = function(ctx,Solution,offsets) {
   for (var k = 0; k<Solution.length; ++k) {
     var row = Solution[k]["row"]-1,
         col = Solution[k]["col"]-1,
         sq = Solution[k]["square"];
     drawSquare(row,col,sq,ctx,30,4,offsets);
  }

}

//
// draw all solutions
//
drawSolutions = function() {
   const width = 220, height = 180;
   var canvas = document.getElementById("solution"),
      ctx = canvas.getContext("2d");
   var offsets = {"x":0, "y":0};
   for (var sol = 0; sol < Solutions.length; ++sol) {
      drawSolution(ctx,Solutions[sol],offsets);
      offsets["x"] += width;
      if (offsets["x"]+width > canvas.width) {
         offsets["x"] = 0;
         offsets["y"] += height;
      }
   }
}


window.onload = function() {
   drawSquares();
   drawSolutions();
}
</script>
</head>
<body>
<h2>MacMahon Squares</h2>
<h3>Collection of squares</h3>
<canvas id="squares" width="1200" height="220" ></canvas>
<h3>Subset of solutions</h3>
<canvas id="solution" width="1200" height="900" ></canvas>
</body>
</html>
$offecho


$onecho > cplex.opt
SolnPoolIntensity = 4
PopulateLim = 200000
SolnPoolPop = 2
solnpoolmerge solutions.gdx
$offecho
