$onText

https://stackoverflow.com/questions/78987960/suggestion-on-which-constraint-to-adds-to-optimize-minizincs-model

Problem definition:

   I have grid of dimensions H and W of boolean variables. The only constraint is that if
   a variable is false then at least one of the adjacent variables (top, right, left, bottom,
   diagonals don't count) must be true. The goal is to minimize the number of true values in the grid.

I.e.
     x(i,j) = 0 => x(i-1,j) + x(i+1,j) + x(i,j-1) + x(i,j+1) >= 1
     
This can be written as:

     x(i-1,j) + x(i+1,j) + x(i,j-1) + x(i,j+1) >= 1 - x(i,j)
     
or

     x(i,j) + x(i-1,j) + x(i+1,j) + x(i,j-1) + x(i,j+1) >= 1
     

$offText

*------------------------------------------------
* problem size
*------------------------------------------------

set
   i 'rows' /row1*row32/
   j 'columns' /col1*col32/
;

*------------------------------------------------
* MIP model (difficult to prove optimality)
*------------------------------------------------

variable z 'objective';
binary variable x(i,j) 'cells';

equations
    obj 'objective'
    eq(i,j) 'implication'
;

obj.. z =e= sum((i,j),x(i,j));
eq(i,j).. x(i,j) + x(i-1,j) + x(i+1,j) + x(i,j-1) + x(i,j+1) =g= 1;

model m /all/;
option reslim = 100;
solve m minimizing z using mip;

option x:0:0:7;
display x.l;

*------------------------------------------------
* improved MIP model (solves very fast)
*------------------------------------------------

set
  interior(i,j)
  border(i,j)
;

interior(i,j) = ord(i) > 2 and ord(i) < card(i)-1 and ord(j) > 2 and ord(j) < card(j)-1;
border(i,j) = not interior(i,j);

equations
    eq1(i,j) 'interior constraints'
    eq2(i,j) 'border constraints'
;

eq1(interior(i,j)).. x(i,j) + x(i-1,j) + x(i+1,j) + x(i,j-1) + x(i,j+1) =e= 1;
eq2(border(i,j))..   x(i,j) + x(i-1,j) + x(i+1,j) + x(i,j-1) + x(i,j+1) =g= 1;

model m2 /obj,eq1,eq2/;
solve m2 minimizing z using mip;

display x.l;

*------------------------------------------------
* Visualization
*------------------------------------------------

$set html board.html
$set drawborder 1


file f /%html%/;
put f;

put '<h1>Board Problem</h1>'/;

put '<table>'
    '<tr><td>Board size<td><td><pre>',card(i):0:0,'x',card(j):0:0,'</pre></td></tr>'
    '<tr><td>Binary variables<td><td><pre>',card(x):0:0,'</pre></td></tr>'
    '<tr><td>Objective<td><td><pre>',z.l:0:0,'</pre></td></tr>'
    '</table><p>'/; 

put '<svg height="500" width="500" viewbox="0 0 35 35">'/;
loop((i,j),
     put '<rect x="',ord(j):0:0,'" y="',ord(i):0:0,'" width="1" height="1" ';
     put$(x.l(i,j)<0.5) 'fill="white" ';
     put$(x.l(i,j)>0.5) 'fill="lightblue" ';
     put 'stroke-width="0.01" stroke="black" '
     put$(%drawborder%=1 and border(i,j)) 'style="filter: brightness(90%);"';
     put '/>'/;
);
put '</svg>'/;

putclose;

executetool 'win32.ShellExecute "%html%"';
