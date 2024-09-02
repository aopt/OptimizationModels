$onText

  n-queens problem with Cplex solution pool
  we should get 92 solutions  
 
  with Cplex options threads=1 and SolnPoolAGap=0
  we find 91 solutions (instead of 92)  

  Erwin Kalvelagen
  erwin@amsopt.com 

$offtext


*--------------------------------------------------------------------
* basic sets
*--------------------------------------------------------------------

Sets
  i      'rows' /8*1/
  j      'columns' /a*h/
  kd     'diagonals have i-j=k for k=-6..6' /'-6'*'-1',0*6/
  kad    'anti-diagonals have i+j=k for k=3..15' /3*15/
;

*--------------------------------------------------------------------
* describe diagonals and anti-diagonals
*--------------------------------------------------------------------

sets
   diag(i,j,kd) 'diagonals'
   antidiag(i,j,kad) 'anti-diagonals'
;
diag(i,j,kd) = i.val - ord(j) = kd.val;
antidiag(i,j,kad) = i.val + ord(j) = kad.val;

option diag:0:0:8, antidiag:0:0:8;
display diag, antidiag;

*--------------------------------------------------------------------
* model
*--------------------------------------------------------------------

binary variable x(i,j) 'placement of queens';
variable numqueens 'number of queens we can place';

equations
   obj               "objective: place as many queens as we can"
   row(i)            "don't place two queens in same row"
   column(j)         "don't place two queens in same column"
   diagonal(kd)      "don't place two queens on the same diagonal"
   antidiagonal(kad) "don't place two queens on the same anti-diagonal"
;

obj..       numqueens =e= sum((i,j),x(i,j));

row(i)..    sum(j, x(i,j)) =l= 1;
column(j).. sum(i, x(i,j)) =l= 1;

diagonal(kd).. sum(diag(i,j,kd),x(i,j)) =l= 1;
antidiagonal(kad).. sum(antidiag(i,j,kad),x(i,j)) =l= 1;

model queens /all/;

*--------------------------------------------------------------------
* find a single solution
*--------------------------------------------------------------------

option mip=cplex;
solve queens maximizing numqueens using mip;

option numqueens:0,x:0;
display "----- Single Solution --------------------",
         numqueens.l,x.l
        "------------------------------------------";
;

*--------------------------------------------------------------------
* find all solutions using the Cplex solution pool
* note: threads=1 and SolnPoolAGap=0 gives 91 solutions (instead of 92)
*--------------------------------------------------------------------

$set gdx allsols.gdx

$onecho > cplex.opt
SolnPoolAGap=0.1
solnpoolintensity=4
solnpoolpop=2
populatelim=100000
solnpoolmerge=%gdx%

*to reproduce Cplex bug use:
*SolnPoolAGap=0
*threads=1
$offecho

queens.optfile=1;
solve queens maximizing numqueens using mip;

* if all is ok we'll see:
* --- Dumping 92 solutions from the solution pool...

*--------------------------------------------------------------------
* load all solutions
*--------------------------------------------------------------------

Sets
   index0'register elements' /soln_queens_p1*soln_queens_p100/
   index(index0)  
;

parameter allsols(index0,i,j);

execute_load "%gdx%" index,allsols=x;
display index;


*--------------------------------------------------------------------
* plot all solutions
*--------------------------------------------------------------------

$set html allsolutions.html

scalar
   tablecolnum 'column counter' /1/
   solnum      'solution counter' /1/
   posx        'x position'
   posy        'y position' 
   iswhite     'square is white if i+j=even' 
;


file f /%html%/;
put f;

put '<h1>n-Queens Problem</h1>'/;
put '<p>Place as many queens as possible on a standard 8×8 chess board such that they '
    "don't attack each other. Show all possible optimal solutions.</p>"/;


put '<table>'/;
put '<tr>'/;

loop(index,
   put '<td>'/;
   put '<svg height="200" width="250" viewbox="0 0 9 9">'/;

* 
*  column headers (a,b,c,...)
*

   loop(i,
      posy = 0.5+ord(i);
      put '<text x="0.5" y="',posy:0:1,
            '" dominant-baseline="middle" text-anchor="middle" stroke="black" stroke-width="0.01" fill="black" font-size="1">',
            i.tl:0:0,
            '</text>'/;
   );

* 
*  row labels (8,7,6,...)
*
   
   loop(j,
      posx = 0.5+ord(j);
      put '<text x="',posx:0:1,
            '" y="0.5" dominant-baseline="middle" text-anchor="middle" stroke="black" stroke-width="0.01" fill="black" font-size="1">',
            j.tl:0:0,
            '</text>'/;
   );


*
*  black/white board
*  black squares are painted light blue
*   
   loop((i,j),
     iswhite = (ord(i)+ord(j))/2 <> floor((ord(i)+ord(j))/2);
     put '<rect x="',ord(j):0:0,'" y="',ord(i):0:0,'" width="1" height="1" ';
     put$(iswhite=1) 'fill="white" ';
     put$(iswhite=0) 'fill="lightblue" ';
     put 'stroke-width="0.01" stroke="black" />'/;
   );

   loop((i,j)$(allsols(index,i,j)>0.5),
      posx = 0.5+ord(j);
      posy = 0.9+ord(i);
      put '<text x="',posx:0:1,'" y="',posy:0:1,'" '
            'text-anchor="middle" stroke="black" '
            'stroke-width="0.01" fill="black" font-size="1">♕</text>'/;
                              
   );
     
   put '</svg><br><div style="text-align: center;">Solution:',solnum:0:0,' of ',card(index):0:0,'</div></td>'/;

   if (tablecolnum=8 and solnum<card(index),
      tablecolnum = 0;
      put '</tr><tr>'/;
   );
   tablecolnum=tablecolnum+1;
   solnum=solnum+1;
);
put '</tr></table>'/;

putclose;


executetool 'win32.ShellExecute "%html%"';