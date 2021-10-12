
*---------------------------------------------------------------
* data
*---------------------------------------------------------------

set
  dummy 'for display' /xmin,xmax,ymin,ymax,width,height,available,value/
  k 'rectangular items to place in container' /k1*k10/
  n 'item# for each k' /n1*n10/
  r 'rotate' /nr,r/
  xy 'coordinates' /x,y/
;

parameter data(*,*);
data(k,'height') = uniformint(1,20);
data(k,'width') = uniformint(1,20);
data(k,'value/area') = uniform(1,10);
data(k,'available') = uniformint(1,10);
data('container','height') = 20;
data('container','width') = 30;

data(k,'area') = data(k,'height')*data(k,'width');
data('container','area') = data('container','height')*data('container','width');
data(k,'value') = data(k,'value/area')*data(k,'area');
display data;

*---------------------------------------------------------------
* derived data
*---------------------------------------------------------------

parameter
   wh(k,r,xy) 'width or height'
   whn(k,n,r,xy) 'auxiliary'
   num(k,n) 'sequence numbers for (k,n)'
   cWH(xy) 'width or height of container'

;
wh(k,r,'x') = data(k,'width')$sameas(r,'nr') + data(k,'height')$sameas(r,'r');
wh(k,r,'y') = data(k,'height')$sameas(r,'nr') + data(k,'width')$sameas(r,'r');
whn(k,n,r,xy) = wh(k,r,xy);

cWH(xy) = data('container','width')$sameas(xy,'x') +
             data('container','height')$sameas(xy,'y');

set kn(k,n) '(k,n) combinations';
kn(k,n)$(ord(n)<=data(k,'available')) = yes;
alias(kn,kn2);

scalar cnt /0/;
loop(kn,
   cnt = cnt+1;
   num(kn) = cnt;
);

option num:0;
display kn,num;

alias (k,kk),(n,nn),(r,rr);

set compare(k,n,kk,nn) 'we need no-overlap between these';
compare(kn,kn2) = num(kn) < num(kn2);


*-----------------------------------------------------------------------
* model
*-----------------------------------------------------------------------

binary variables
   x(k,n) 'item (k,n) is placed (rotated/non-rotated)'
   rot(k,n) 'item (k,n) is rotated'
   delta 'used in no-overlap constraints'
;
positive variables
    pos(k,n,xy) 'position'
    pos2(k,n,xy) 'pos+width/height'
;
variable totalValue 'objective (maximized)';

pos.up(kn(k,n),xy) = cWH(xy) - smin(r,wh(k,r,xy));
pos2.up(kn(k,n),xy) = cWH(xy);

equations
   epos2(k,n,xy)           'pos+width/height'
   noOverlap1(k,n,k,n,xy)  'no-overlap between items'
   noOverlap2(k,n,k,n,xy)  'no-overlap between items'
   noOverlap3(k,n,k,n)     'no-overlap between items'
   objective

* these are extras. They may help performance
   order
   order2
   area
;

epos2(kn(k,n),xy)..
   pos2(kn,xy) =e= pos(kn,xy) + rot(kn)*wh(k,'r',xy) + (1-rot(kn))*wh(k,'nr',xy);

noOverlap1(compare(kn,kn2),xy)..
   pos(kn,xy) =g= pos2(kn2,xy)
                  - cWH(xy)*(3-delta(kn,kn2,xy,'1')-x(kn)-x(kn2));
noOverlap2(compare(kn,kn2),xy)..
   pos(kn2,xy) =g= pos2(kn,xy)
                   - cWH(xy)*(3-delta(kn,kn2,xy,'2')-x(kn)-x(kn2));
noOverlap3(compare(kn,kn2))..
    sum(xy, delta(kn,kn2,xy,'1')+delta(kn,kn2,xy,'2')) =g= 1;

objective.. totalValue =e= sum(kn(k,n),x(kn)*data(k,'value'));

order(k,n)$(kn(k,n) and kn(k,n-1)).. x(k,n-1) =g= x(k,n);
order2(k,n)$(kn(k,n) and kn(k,n-1)).. pos(k,n-1,'x') =l= pos(k,n,'x');

area.. sum(kn(k,n), x(kn)*data(k,'area')) =l= prod(xy,cWH(xy));

model m /all/;
option optcr=0, threads=8;
solve m maximizing totalValue using mip;


parameter positions(k,n,*) 'rectangles (x1,y1)-(x2,y2)';
positions(kn,'x1')$(x.l(kn)>0.5) = pos.l(kn,'x');
positions(kn,'y1')$(x.l(kn)>0.5) = pos.l(kn,'y');
positions(kn,'x2')$(x.l(kn)>0.5) = pos2.l(kn,'x');
positions(kn,'y2')$(x.l(kn)>0.5) = pos2.l(kn,'y');
positions(kn,'rotated')$(x.l(kn)>0.5) = rot.l(kn);

option x:0;
display x.l,positions,totalValue.l;

parameter plotdata(k,n,*);
loop(kn(k,n)$(x.l(kn)>0.5),
   plotdata(kn,'xmin') = pos.l(kn,'x')+EPS;
   plotdata(kn,'xmax') = pos2.l(kn,'x');
   plotdata(kn,'ymin') = pos.l(kn,'y')+EPS;
   plotdata(kn,'ymax') = pos2.l(kn,'y');
   plotdata(kn,'value') = data(k,'value');
);
option plotdata:2:2:1;
display plotdata;



