$ontext

  Standard Graph Coloring Model

  Color map with US counties

$offtext


*---------------------------------------------------------------
* data
*---------------------------------------------------------------

sets
   n      'nodes: counties (fips code)'
   a(n,n) 'arcs: adjacency -- upper-triangular part only'
   c      'colors' /color1*color5/

   county 'county names'
   map(n,county<)
;

$include data.inc

* fix data wrt Glades County, FL
a('12043','12085') = no;
*a('12043','12099') = no;


scalar numCounties 'number of counties in map';
numCounties = card(n);
display numCounties;

alias(n,i,j);

*---------------------------------------------------------------
* data checks
*---------------------------------------------------------------

abort$(card(map)<>numCounties) "check map";
abort$sum(a(i,j)$(ord(i)>=ord(j)),1) "a(i,j) is not strictly upper-triangular";

*---------------------------------------------------------------
* model
*---------------------------------------------------------------

binary variables
   x(n,c) 'assign color to node'
   u(c)   'color is used'
;

variable
   numColors 'number of colors needed'
;

equations
   objective            'minimize number of colors used'
   assign(n)            'every node should have exactly one color'
   notSameColor(i,j,c)  'adjacent vertices cannot have the same color'
   order(c)             'ordering constraint (optional)'
;

objective..  numColors =e= sum(c, u(c));

assign(n)..  sum(c, x(n,c)) =e= 1;

notSameColor(a(i,j),c).. x(i,c)+x(j,c) =l= u(c);

order(c-1).. u(c) =l= u(c-1);


model color /all/;
option optcr=0, threads=16;
solve color minimizing numColors using mip;


display x.l,u.l,numColors.l;

*---------------------------------------------------------------
* export results
*---------------------------------------------------------------

parameter mapcolors(n);
mapcolors(n) = sum(c, ord(c)*round(x.l(n,c)));

file f /mapcolors.csv/;
* csv format
f.pc=5;
put f,"id","color"/;
loop(n,
   put n.tl:0,mapcolors(n):0:0/;
);
putclose;

*---------------------------------------------------------------
* create map
*---------------------------------------------------------------

$ontext

  Notes: py is part of python 3.10
         Make sure that the following packages are installed:
            pandas, plotly

$offtext

execute "py plotter.py";


