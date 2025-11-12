$onText

   Clock problem
   
   References:
   https://www.scientificamerican.com/game/math-puzzle-find-the-time/
   https://yetanothermathprogrammingconsultant.blogspot.com/2025/11/clock-problem.html

$offText


Set
   h 'hand' /h1,h2,h3/
   r 'role' /hour,minute,second/
;
*alias (h,hh);

variable

* hands h1,h2,h3
   relpos(h) 'relative position of hands (define h1=0)'
   offset    'from relpos'
   hpos(h)   'final position of hands (relpos + offset mod 12, in decimal hours)'
   modulo(h) 'binary variable to implement mod 12'

* role hour,minute,second
   assign(h,r) 'assign unique role to hand'
   rpos(r)     'position of hr/min/sec hand ∈[0,11.99]'
   
* proper clock
   v(r)        '(integer) value in hours,minutes and seconds'

* objective
   z        'dummy objective variable'
;
integer variable offset,v;
binary variable modulo, assign;

offset.up = 11;

hpos.lo(h) = 0;
hpos.up(h) = 11.999;

v.lo(r) = 0;
v.up(r) = 59;
v.up('hour') = 11;

* read relative positions from the clock:
* h1 = 0, h2 = 2, h3 ∈ [6.8,7] 
table relposdata(h,*) 'relative position (interval) in units of hours (define h1=0)' 
       lo    up 
   h1   0    0  
   h2   2    2  
   h3   6.8  7      
;
relpos.lo(h) = relposdata(h,'lo');
relpos.up(h) = relposdata(h,'up'); 

equations
   obj 'dummy objective'
   
   e_hpos(h) 'position of hands (in decimal hours)'
   e_assign1 'unique assignment hand <=> role'
   e_assign2 'unique assignment hand <=> role'
   assignpos 'calc rpos from hpos (nonlinear)'

* unit conversions
   seconds   'calc seconds from rpos' 
   minutes   'calc minutes from rpos'
   hours     'calc hours from rpos'
;

* label(h) = (relpos(h) + offset) mod 12
e_hpos(h)..  hpos(h) =e= relpos(h) + offset - modulo(h)*12;

* unique assignment hand <=> role
e_assign1(r).. sum(h,assign(h,r)) =e= 1;
e_assign2(h).. sum(r,assign(h,r)) =e= 1;

assignpos(r).. rpos(r) =e= sum(h, assign(h,r)*hpos(h));

* proper clock values
seconds.. v('second') =e= rpos('second')*60/12;
minutes.. v('minute') =e= rpos('minute')*60/12 - v('second')/60;
hours..   v('hour') =e= rpos('hour') - v('minute')/60 - v('second')/60/60;

obj.. z =e= 0;

*------------------------------------------------
* nonconvex quadratic model
*------------------------------------------------

model m1 /all/;
option miqcp=baron;
solve m1 minimizing z using miqcp;
display relpos.l,offset.l,hpos.l,assign.l,rpos.l,v.l;

*------------------------------------------------
* linearized model
*------------------------------------------------

positive variables prd(h,r) 'product prd(h,r)=assign(h,r)*hpos(h)';
prd.up(h,r) = hpos.up(h);

equations
   prod1(h,r) 'linearization of product'
   prod2(h,r) 'linearization of product'
   prod3(h,r) 'linearization of product'
   assignpos2(r) 'linearization of product'
;

prod1(h,r).. prd(h,r) =l= hpos.up(h)*assign(h,r);
prod2(h,r).. prd(h,r) =l= hpos(h);
prod3(h,r).. prd(h,r) =g= hpos(h)-hpos.up(h)*(1-assign(h,r));

assignpos2(r)..  rpos(r) =e= sum(h, prd(h,r));

model m2 /m1-assignpos,prod1,prod2,prod3,assignpos2/;
solve m2 minimizing z using mip;
display relpos.l,offset.l,hpos.l,assign.l,rpos.l,v.l;
