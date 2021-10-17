$ontext

   stack boxes under rotation


   1. Boxes on top should have a strictly smaller x/y base than the one
      underneath
   2. Assume always: size x < size y
   3. In size comparison I assume integer sizes, so we want to be at least
      0.5 smaller.


$offtext

*--------------------------------------------------------------
* data
*--------------------------------------------------------------

sets
   s 'size' /size-x,size-y,size-z/
   xy(s) /size-x,size-y/
   r 'rotation' /rot1*rot3/
   k 'box' /box1*box4/
   i 'stack level' /level1*level10/
;

table boxes(k,s) 'available box sizes'
        size-x   size-y   size-z
box1       4        6        7
box2       1        2        3
box3       4        5        6
box4      10       12       32
;
option boxes:0;
display boxes;

scalar delta 'shrinkage in x,y directions' /0.5/;

alias(s,s1,s2);

*--------------------------------------------------------------
* derived data
*--------------------------------------------------------------

set rot(r,s1,s2) 'rotate s1->s2' /
   rot1.(size-x.size-x, size-y.size-y, size-z.size-z)
   rot2.(size-x.size-x, size-y.size-z, size-z.size-y)
   rot3.(size-x.size-z, size-y.size-x, size-z.size-y)
/;
display rot;

parameter sizes(k,r,s) 'sizes under rotation';
sizes(k,r,s2) = sum(rot(r,s1,s2),boxes(k,s1));
option sizes:0;
display sizes;

*--------------------------------------------------------------
* model
*--------------------------------------------------------------


binary variable
   assign(i,k,r)  'assign (k,r) to level i'
   b(i)           'level i has a box'
;
variables
   size(i,s) 'size of box at level i'
   numboxes  'number of stacked boxes'
   height    'total height of stack'
;

equations
   level(i)      'box per level'
   order(i)      'below a box should be another box (optional: covered by eq. smaller)'
   esize(i,s)    'size of box at level i'
   smaller(i,xy) 'smaller boxes on top of large ones (xy only)'
   countboxes    'number of boxes we can stack'
   totalheight   'total height of the tower'
;

level(i)..   b(i) =e= sum((k,r),assign(i,k,r));
order(i-1).. b(i) =l= b(i-1);
esize(i,s).. size(i,s) =e= sum((k,r),assign(i,k,r)*sizes(k,r,s));
smaller(i-1,xy).. size(i,xy) =l= size(i-1,xy)-delta*b(i);
countboxes.. numboxes =e= sum(i,b(i));
totalheight.. height =e= sum(i,size(i,'size-z'));

model stackboxes /all/;
option optcr=0;

*--------------------------------------------------------------
* solve
*--------------------------------------------------------------

*solve stackboxes maximizing numboxes using mip;
solve stackboxes maximizing height using mip;

*--------------------------------------------------------------
* reporting
*--------------------------------------------------------------

parameter results(i,k,r,*) 'optimal stack';
results(i,k,r,s)$(assign.l(i,k,r)>0.5) = size.l(i,s);
option results:0:3:1;
display results;


