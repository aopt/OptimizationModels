$ontext

   2d knapsack problem

   Fill a container with most valuable rectangles.

   Covering formulation.

$offtext

set
  dummy 'for display' /xmin,xmax,ymin,ymax,width,height,available,value/

  i 'rows in container' /r1*r20/
  j 'columns in container' /c1*c30/
  k 'rectangular items to place in container' /k1*k10/
  r 'rotate' /nr,r/
;

*---------------------------------------------------------------------
* data
*---------------------------------------------------------------------

parameter data(*,*) 'problem data';
data('container','height') = card(i);
data('container','width') = card(j);
data(k,'height') = uniformint(1,20);
data(k,'width') = uniformint(1,20);
data(k,'value/size') = uniform(1,10);
data(k,'value') = data(k,'value/size')*data(k,'height')*data(k,'width');
data(k,'available') = uniformint(1,10);
display data;

*---------------------------------------------------------------------
* derived data
*---------------------------------------------------------------------

alias (i,ii),(j,jj);

parameters
   w(k,r) 'item width'
   h(k,r) 'item height'
;

w(k,r) = data(k,'width')$sameas(r,'nr')+ data(k,'height')$sameas(r,'r');
h(k,r) = data(k,'height')$sameas(r,'nr') + data(k,'width')$sameas(r,'r');

sets
  ok(k,r,i,j) 'item (k,r) can be placed at (i,j)'
  cover(k,r,i,j,ii,jj) '(ii,jj) is covered when item (k,r) is placed at (i,j)'
;
ok(k,r,i,j) = ord(i)+h(k,r)-1 <= card(i)
              and ord(j)+w(k,r)-1 <= card(j);

cover(ok(k,r,i,j),ii,jj) =
           ord(ii)>=ord(i) and ord(ii)<ord(i)+h(k,r) and
           ord(jj)>=ord(j) and ord(jj)<ord(j)+w(k,r);


*-----------------------------------------------------------------------
* model
*-----------------------------------------------------------------------

binary variable x(k,r,i,j) 'item k is placed at (i,j)';
variable totalValue 'objective (maximized)';

equations
   noOverlap(i,j) 'only one item can cover (i,j)'
   count(k)       'limit number of each item'
   objective      'maximize total value'
;

noOverlap(ii,jj).. sum(cover(k,r,i,j,ii,jj),x(k,r,i,j)) =l= 1;

count(k).. sum(ok(k,r,i,j), x(k,r,i,j)) =l= data(k,'available');

objective.. totalValue =e= sum(ok(k,r,i,j),x(k,r,i,j)*data(k,'value'));

model m /all/;
option optcr=0,threads=8;
solve m maximizing totalValue using mip;

*-----------------------------------------------------------------------
* reporting
*-----------------------------------------------------------------------

option x:0:2:2;
display x.l,totalValue.l;

parameter plotdata(k,r,i,j,*);
loop((k,r,i,j)$(x.l(k,r,i,j)>0.5),
    plotdata(k,r,i,j,'xmin') = ord(j) - 1 + EPS;
    plotdata(k,r,i,j,'xmax') = plotdata(k,r,i,j,'xmin') + w(k,r);
    plotdata(k,r,i,j,'ymin') = ord(i) - 1 + EPS;
    plotdata(k,r,i,j,'ymax') = plotdata(k,r,i,j,'ymin') + h(k,r);
    plotdata(k,r,i,j,'value') = data(k,'value');
);
options plotdata:2:4:1;
display plotdata;
