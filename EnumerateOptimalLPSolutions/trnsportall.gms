$ontext

  Enumerate all optimal LP bases

$offtext


Sets
     k                       /seattle, san-diego, new-york, chicago, topeka/
     i(k)   canning plants   / seattle, san-diego /
     j(k)   markets          / new-york, chicago, topeka /
;

Parameters

     a(i)  capacity of plant i in cases
       /    seattle     350
            san-diego   600  /

     b(j)  demand at market j in cases
       /    new-york    325
            chicago     300
            topeka      275  / ;

Table d(i,j)  distance in thousands of miles
                  new-york       chicago      topeka
    seattle          2.5           1.7          1.8
    san-diego        2.5           1.8          1.4  ;

Scalar f  freight in dollars per case per thousand miles  /90/ ;

Parameter c(i,j)  transport cost in thousands of dollars per case ;

          c(i,j) = f * d(i,j) / 1000 ;
Scalars
     nb  'number of basic variables'
     nnb 'number of non-basic variables'
  ;
nb = card(i)+card(j);
nnb = card(i)*card(j);

parameter Mx(i,j), Mk(k);
Mx(i,j) = min(a(i),b(j));
Mk(i) = a(i);
Mk(j) = b(j);

set bs(*,*);
bs(i,j)=yes;
bs('-',k) = yes;

set n /iter1*iter100/;
set cn(n) 'used cuts';
parameter alpha(n,*,*);
cn(n) = no;
alpha(n,bs) = 0;

Variables
     x(i,j)  shipment quantities in cases
     z       total transportation costs in thousands of dollars
     s(k)       'slacks'
     beta(*,*)  'basis'
;

Positive Variable x,s;
Binary Variable beta;


Equations
     cost        define objective function
     supply(i)   observe supply limit at plant i
     demand(j)   satisfy demand at market j
     basisx(i,j)  'x=nb => x=0'
     basiss(k)    's=nb => s=0'
     basis        'basis accounting'
     cut(n)       '0-1 cuts'
;

cost ..        z  =e=  sum((i,j), c(i,j)*x(i,j)) ;
supply(i) ..   sum(j, x(i,j)) + s(i) =e=  a(i) ;
demand(j) ..   sum(i, x(i,j)) - s(j) =e=  b(j) ;

basis..        sum(bs,beta(bs)) =e= nb;
basisx(i,j)..  x(i,j) =l= Mx(i,j)*beta(i,j);
basiss(k)..    s(k) =l= Mk(k)*beta('-',k);


cut(cn)..      sum(bs, alpha(cn,bs)*beta(bs)) =l= nb-1;


Model transport /all/ ;

scalar zopt;
scalar continue /1/;
parameter reportv(*,*,*,*);
parameter reportb(*,*,*,*);
option reportv:2:3:1;
option reportb:0:3:1;

option optcr=0;
transport.solvelink=%Solvelink.LoadLibrary%;
transport.solprint=%Solprint.Quiet%;

loop(n$continue,
   Solve transport using mip minimizing z ;
   zopt$(ord(n)=1) = z.l;
   continue$(transport.modelstat<>%modelstat.Optimal% or z.l > zopt + 0.0001) = 0;
   if(continue,
      alpha(n,bs) = round(beta.l(bs));
      cn(n) = yes;
      reportv('x',i,j,n) = x.l(i,j);
      reportv('s','-',k,n) = s.l(k);
      reportv('z','-','-',n) = z.l;
      reportb('x',i,j,n) = beta.l(i,j);
      reportb('s','-',k,n) = beta.l('-',k);
   );
);

Display reportv, reportb;

