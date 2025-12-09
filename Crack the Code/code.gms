$onText

Find

  |x1|x2|x3|  where x(i) ∈ {0,..,9}

with the following rules

  |6|8|2|  One number is correct and well placed
  
  |6|1|4|  One number is correct but wrongly placed
  
  |2|0|6|  Two numbers are correct but wrongly placed
  
  |7|3|8|  Nothing is correct
  
  |7|8|0|  One number is correct but wrongly placed 


References:

   https://yetanothermathprogrammingconsultant.blogspot.com/2025/12/crack-passcode.html
   https://www.reddit.com/r/mathmemes/comments/1bbld8t/okay_reddit_geniuses_what_is_the_answer_im_stuck/
   https://www.youtube.com/watch?v=lK857tIT4X4
   

---------------------------------------------------------------    

  |6|8|2|  One number is correct and well placed
  <=> x[1,6]+x[2,8]+x[3,2]=1
      
  |6|1|4|  One number is correct but wrongly placed
  <=> x[2,6]+x[3,6]+x[1,1]+x[3,1]+x[1,4]+x[2,4]=1
    
  |2|0|6|  Two numbers are correct but wrongly placed
  <=> x[2,2]+x[3,2]+x[1,0]+x[3,0]+x[1,6]+x[2,6]=2    

  |7|3|8|  Nothing is correct
  <=> x[1,7]+x[2,7]+x[3,7]+x[1,3]+x[2,3]+x[3,3]+x[1,8]+x[2,8]+x[3,8]=0
    
  |7|8|0|  One number is correct but wrongly placed 
  <=> x[2,7]+x[3,7]+x[1,8]+x[3,8]+x[1,0]+x[2,0]=1
    

$offText

*-----------------------------------------------------------------------
* base model
*-----------------------------------------------------------------------


Sets
   i 'position' /i1,i2,i3/
   v 'value'    /0*9/
;

binary variable x(i,v);

equations
   onevalue(i) 'each position has one value'
   e1 '|6|8|2|  One number is correct and well placed'
   e2 '|6|1|4|  One number is correct but wrongly placed'
   e3 '|2|0|6|  Two numbers are correct but wrongly placed'
   e4 '|7|3|8|  Nothing is correct'
   e5 '|7|8|0|  One number is correct but wrongly placed'
;

onevalue(i).. sum(v, x(i,v)) =e= 1;
e1..   x['i1','6']+x['i2','8']+x['i3','2'] =e= 1;
e2..  x['i2','6']+x['i3','6']+x['i1','1']+x['i3','1']+x['i1','4']+x['i2','4'] =e= 1;
e3..  x['i2','2']+x['i3','2']+x['i1','0']+x['i3','0']+x['i1','6']+x['i2','6'] =e= 2;
e4..  sum(i,x[i,'7']+x[i,'3']+x[i,'8']) =e= 0;
e5..  x['i2','7']+x['i3','7']+x['i1','8']+x['i3','8']+x['i1','0']+x['i2','0'] =e= 1;

variable z;
equation obj 'dummy';
obj.. z=e=0;

* model 1: solve problem as is
model m1 /all/;
solve m1 minimizing z using mip;
display x.l;

* result:
* |0|4|2|


*-----------------------------------------------------------------------
* check solution is unique
* this model should be infeasible
*-----------------------------------------------------------------------

* model m2: forbid this solution (from m1)
* now should be infeasible
equation forbid 'cut off solution';
forbid.. sum((i,v)$(x.l[i,v]>0.5),x[i,v]) =l= 2;

model m2/m1+forbid/;
solve m2 minimizing z using mip;

abort$(m2.modelstat = %modelStat.optimal% or m2.modelstat = %modelStat.integerSolution%) "This should be infeasible;";

* result:
* (integer) infeasible


*-----------------------------------------------------------------------
* can we find the same solution using just equations 1,2,3?
* this will give a wrong solution
*-----------------------------------------------------------------------

model m3 /m1-e4-e5/;
solve m3 minimizing z using mip;
display x.l;

* result (depending on solver):
* |6|6|3| 