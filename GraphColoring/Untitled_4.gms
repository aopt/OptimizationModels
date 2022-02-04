
set
   d 'day' /day1*day5/
   t 'teams' /team1*team20/
   p 'person in team' /person1*person10/
;

binary variable assign(t,p,d,s);

equations
   maxSlots
   min3
;

maxSlots(d)..  sum((t,p),assign(t,p,d)) =l= 150;
min3(t,p).. sum(d,assign(t,p,d)) =g= 3;