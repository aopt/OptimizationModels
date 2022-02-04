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
   c      'colors' /orange,lightblue,yellow,green,chocolate,grey/

   county 'county names'
   map(n,county<)
;

$include data.inc

* fix data wrt Glades
a('12043','12085') = no;
a('12043','12099') = no;


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
    w(c)   'color is used'
    u(n)   'county is used'
;

variable
    numColors 'number of colors needed'
;

equations
    objective         'minimize number of colors used'
    assign(n)         'every node should have exactly one color'
    sameColor(i,j,c)  'adjacent vertices cannot have the same color'
*    count
;

objective..  numColors =e= sum(c, w(c));
assign(n)..  sum(c, x(n,c)) =e= 1;
*assign(n)..  sum(c, x(n,c)) =e= u(n);
sameColor(a(i,j),c).. x(i,c)+x(j,c) =l= w(c);
*count.. sum(n,u(n)) =e= card(n)-1;

*numColors.fx = 4;

* glades
*u.fx('12043') = 1;
* okeechobee
*u.fx('12093') = 1;

model color /all/;
option optcr=0, threads=16;
solve color minimizing numColors using mip;


*set removed(n,county) 'model ignored this node';
*removed(map(n,county)) = u.l(n)<0.5;
*display removed;

display x.l,w.l,numColors.l;

