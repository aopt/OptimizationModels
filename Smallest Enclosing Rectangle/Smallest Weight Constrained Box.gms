*---------------------------------------------------------------
* options
*---------------------------------------------------------------

* 0: no plot
* 1: produce HTML plot)
$set htmlplot 0

option minlp=antigone;

option seed=12345;

*---------------------------------------------------------------
* data
*---------------------------------------------------------------

scalars
   maxsize 'size of the outer box' / 10 /
   minWeight  'required total weight' / 25 /
;

sets
   i    'points' /point1*point100/
   a    'attributes (coordinates,weight)' /x,y,z,w/
   c(a) 'coordinates' /x,y,z/
   lu   'lower/upper values' /min,max/
;

parameters p(i,a) 'points';
      
p(i,c) = uniform(0,maxsize);
p(i,'w') = uniform(0,2);
display minWeight,p;


*---------------------------------------------------------------
* derived data
*---------------------------------------------------------------

parameter box(c,lu) 'outer box: min/max values';
box(c,'min') = smin(i, p(i,c));
box(c,'max') = smax(i, p(i,c));
display box;

*---------------------------------------------------------------
* model: enclose k points 
*---------------------------------------------------------------

binary variable delta(i) 'point is selected';

variable
   sbox(c,lu)  'box to contain selected points'
   d(c)       'length of sides'
   volume     'size of box'    
;

* bounds
sbox.lo(c,lu) = box(c,'min');
sbox.up(c,lu) = box(c,'max');

d.lo(c) = 0;
d.up(c) = box(c,'max') - box(c,'min');


equations
    obj      'objective: area of enclosing rectangle'
    sumweight   'weight restriction'
    inside_min(i,c)  'points are inside'
    inside_max(i,c)  'points are inside'
    calcd(c)         'calculate d' 
;

sumweight..  sum(i, p(i,'w')*delta(i)) =g= minWeight;

* inside: delta(i)=1  ==> sbox(c,'min') <= p(i,c) <= sbox(c,'max') 
inside_min(i,c)..  sbox(c,'min') =l= delta(i)*p(i,c) + (1-delta(i))*box(c,'max');
inside_max(i,c)..  sbox(c,'max') =g= delta(i)*p(i,c) + (1-delta(i))*box(c,'min');

calcd(c).. d(c) =e= sbox(c,'max')-box(c,'min');

obj.. volume =e= d('x')*d('y')*d('z');

model m /all/;
solve m minimizing volume using minlp;

scalars
  count 'number of selected points'
  totw  'total weight of selected points'  
;
count = sum(i$(delta.l(i)>0.5),1);
totw = sum(i$(delta.l(i)>0.5),p(i,'w'));

display sbox.l,delta.l,volume.l,count,totw;
