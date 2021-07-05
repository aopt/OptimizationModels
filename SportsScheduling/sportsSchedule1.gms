
$ontext

There are 16 players and 7 rounds. Each round consists of 4 games.
Each game is two players vs. two players. Each player has a rating.
The objective is to minimize the absolute rating difference between
the teams. The constraints are that every player:

 -must play 7 rounds
 -can only play 1 game per round
 -can only be partnered with another player 0 or 1 times
 -can only be opponent of another player 0, 1, or 2 times

From:
https://stackoverflow.com/questions/67604569/pulp-scheduling-program-needs-more-efficient-problem-definition

This model does not work very well. It is not able to find a good schedule
within a reasonable time.


$offtext

*------------------------------------------------------
* data
*------------------------------------------------------

set
  p  'player'
     /Joe, Tom, Sam, Bill, Fred, John, Wex, Chip,
       Mike, Jeff, Steve, Kumar, Connor, Matt, Peter, Cindy/
  r 'rounds' /round1*round7/
  g 'game' /game1*game4/
  t '2 teams per game' /team1,team2/
;
alias(p,pp);

parameter rating(p)  /
   Joe    5.0,  Tom  4.2,  Sam   4.3,  Bill  5.1,
   Fred   4.4,  John 3.7,  Wex   3.8,  Chip  4.6,
   Mike   3.2,  Jeff 3.6,  Steve 3.8,  Kumar 4.7,
   Connor 4.3,  Matt 4.6,  Peter 4.2,  Cindy 3.4/
;

display p,r,g,t,rating;

set lt(p,pp) 'combinations of players with p<pp';
lt(p,pp) = ord(p)<ord(pp);

*------------------------------------------------------
* optimization model
*------------------------------------------------------

variables
   x(p,r,g,t)              'schedule'
   isPartner(p,pp,r,g,t)   '1 if p and pp are partners'
   isOpponent(p,pp,r,g,t)  '1 if p and pp are opponents'
   diff(r,g)               'rating difference'
   z                       'objective'
;
binary variable x;
positive variable isPartner,isOpponent,diff;

isPartner.up(lt(p,pp),r,g,t) = 1;
isOpponent.up(lt(p,pp),r,g,t) = 1;

equations
   play(p,r)           'player is scheduled in each round'
   team(r,g,t)         'team consist of 2 persons'
   partner(p,pp,r,g,t) 'p,pp are partners'
   oppose(p,pp,r,g,t)  'p,pp are in opposing teams'
   maxPartner(p,pp)    '0 or 1 times partnered with same person'
   maxOppose(p,pp)     '0,1 or 2 times opposed to the same person'
   ediff(r,g)          'difference in rating'
   objective           'sum of absolute values'
;

* player p is scheduled in each round r
play(p,r)..
   sum((g,t),x(p,r,g,t)) =e= 1;

* a team consist of 2 persons
team(r,g,t)..
   sum(p,x(p,r,g,t)) =e= 2;

* p,pp are partners at r,g,t
partner(lt(p,pp),r,g,t)..
   isPartner(p,pp,r,g,t) =g= x(p,r,g,t)+x(pp,r,g,t)-1;

* limit numbers of times p,pp can be partners
maxPartner(lt(p,pp))..
   sum((r,g,t),isPartner(p,pp,r,g,t)) =l= 1;

* p,pp are opponents at r,g,t (pp will be at opposite team of t)
oppose(lt(p,pp),r,g,t)..
   isOpponent(p,pp,r,g,t) =g= x(p,r,g,t)+x(pp,r,g,t++1)-1;

* limit numbers of times p,pp can be opponents
maxOppose(lt(p,pp))..
   sum((r,g,t),isOpponent(p,pp,r,g,t)) =l= 2;

* we force team 2 to be the higher rated team
* that is removing some symmetry in the model
ediff(r,g)..
   diff(r,g) =e= sum(p,x(p,r,g,'team2')*rating(p)) - sum(p,x(p,r,g,'team1')*rating(p));

* minimize the difference between team ratings
objective..
   z =e= sum((r,g),diff(r,g));

*------------------------------------------------------
* solve
*------------------------------------------------------

model sched /all/;
option optcr=0, threads=8, reslim=1000;
solve sched minimizing z using mip;

