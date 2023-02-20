$ontext

  Supplier selection problem
  
  We want to order quantities for different items.
  The shipping cost is a fixed cost: any amount ordered from
     a supplier has the same shipping cost.
  There are also variable cost: the item cost.
  
  We use here random data.
  
  A check is added for the case that demand exceeds the availability.
  
  maxBuy are big-M values. We try to make them as small as possible.
  
  Reference:
  http://yetanothermathprogrammingconsultant.blogspot.com/2023/02/supplier-selection-easy-mip.html
  

$offtext

*-----------------------------------------------------------------------
* size of the problem
*-----------------------------------------------------------------------


Sets
   i 'items' /item1*item50/
   s 'suppliers' /supplier1*supplier10/  
;

*-----------------------------------------------------------------------
* random data
*-----------------------------------------------------------------------


Parameters
   demand(i)      'demand for items'
   avail(i,s)     'availability of items'
   shipcost(s)    'shipping cost'
   itemcost(i,s)  'cost of items'
;

demand(i) = uniformint(1,10);
avail(i,s) = uniformint(0,7);
shipcost(s) = uniform(10,40);
itemcost(i,s)$avail(i,s) = uniform(1,5);

display demand,avail,shipcost,itemcost;

*-----------------------------------------------------------------------
* derived data
*-----------------------------------------------------------------------

Parameters
   totalavail(i)  'total availability'
   short(i)       'shortages'
   maxbuy(i,s)    'upperbound on buy' 
;

totalavail(i) = sum(s,avail(i,s));
short(i) = max(0, demand(i)-totalavail(i));
maxbuy(i,s) = min(demand(i),avail(i,s));

display totalavail,short,maxbuy;


*-----------------------------------------------------------------------
* stop if we have shortages. That would yield an infeasible model.
*-----------------------------------------------------------------------

abort$card(short) "not enough availability";

*-----------------------------------------------------------------------
* model
*-----------------------------------------------------------------------

variables
    totalcost 'to be minimized'
    buy(i,s)  'orders to be placed at suppliers'
    use(s)    'supplier is used'
;
integer variable buy;
binary variable use;
buy.up(i,s) = maxbuy(i,s);

equations
    objective          'minimize totalcost'
    meetdemand(i)      'distribute demand over suppliers'
    use_supplier(i,s)  'use=0 => buy=0'
;
    

objective..  totalcost =e= sum(s,shipcost(s)*use(s)) + sum((i,s),itemcost(i,s)*buy(i,s));
meetdemand(i)..  sum(s, buy(i,s)) =e= demand(i);
use_supplier(i,s).. buy(i,s) =l= maxbuy(i,s)*use(s);

model m /all/;
option threads=0;
solve m minimizing totalcost using mip;

display totalcost.l,use.l,buy.l;
