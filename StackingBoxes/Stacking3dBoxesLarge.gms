$ontext

   stack boxes under rotation


   1. Boxes on top should have a strictly smaller x/y base than the one
      underneith
   2. Assume always: size x < size y
   3. In size comparison I no longer assume integer sizes.
      We want to be at least 0.001 smaller.
   4. This example has different results for max height vs
      max num boses.
   5. We also sompare if the inclusion of the ordering constraint
      can be useful.

$offtext

*--------------------------------------------------------------
* data
*--------------------------------------------------------------

sets
   s 'size' /size-x,size-y,size-z/
   xy(s) /size-x,size-y/
   r 'rotation' /rot1*rot3/
   k 'box' /box1*box10/
   i 'stack level' /level1*level20/
;

parameter boxes(k,s) 'available box sizes';
boxes(k,s) = 0;
loop(s,
   boxes(k,s) = uniform(boxes(k,s-1)+1,boxes(k,s-1)+10);
);
display boxes;

scalar delta 'shrinkage in x,y directions' /0.001/;

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
display sizes;

*--------------------------------------------------------------
* model
*--------------------------------------------------------------

scalar extra '0 or 1: whether to include the order constraint'  / 1 /;

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
order(i-1)$extra .. b(i) =l= b(i-1);
esize(i,s).. size(i,s) =e= sum((k,r),assign(i,k,r)*sizes(k,r,s));
smaller(i-1,xy).. size(i,xy) =l= size(i-1,xy)-delta*b(i);
countboxes.. numboxes =e= sum(i,b(i));
totalheight.. height =e= sum(i,size(i,'size-z'));

model stackboxes /all/;
option optcr=0;

*--------------------------------------------------------------
* compare "max height" vs "max boxes" objective
*--------------------------------------------------------------


parameters
   results(*,i,k,r,*) 'optimal stack'
   objectives(*,*) 'optimal values height vs boxes'
   stats(*,*)      'statistics'
;


solve stackboxes maximizing height using mip;

results('max height', i,k,r,s)$(assign.l(i,k,r)>0.5) = size.l(i,s);
objectives('max height','height') = height.l;
objectives('max height','boxes') = numboxes.l;

stats('extra','iterations') =  stackboxes.iterusd;
stats('extra','nodes') =  stackboxes.nodusd;
stats('extra','objective') =  stackboxes.objval;

solve stackboxes maximizing numboxes using mip;

results('max boxes', i,k,r,s)$(assign.l(i,k,r)>0.5) = size.l(i,s);
objectives('max boxes','height') = height.l;
objectives('max boxes','boxes') = numboxes.l;



*--------------------------------------------------------------
* compare "max height" with extra and without extra constratnt
*--------------------------------------------------------------

extra = 0;
solve stackboxes maximizing height using mip;

stats('no extra','iterations') =  stackboxes.iterusd;
stats('no extra','nodes') =  stackboxes.nodusd;
stats('no extra','objective') =  stackboxes.objval;


option results:3:3:1;
display results,objectives;


display stats;