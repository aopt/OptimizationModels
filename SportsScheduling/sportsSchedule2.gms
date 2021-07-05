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

This is version 2 of the model. We generate possible game configurations
in advance.

$offtext


*------------------------------------------------------
* base data
*------------------------------------------------------

sets

  p  'player'
     /Joe, Tom, Sam, Bill, Fred, John, Wex, Chip,
       Mike, Jeff, Steve, Kumar, Connor, Matt, Peter, Cindy/

  r 'rounds' /round1*round7/
  t 'teams' /team1,team2/
  g 'all possible games'
  game(g<,t,p) 'possible game configurations'
;

parameter rating(p)  /
   Joe    5.0,  Tom  4.2,  Sam   4.3,  Bill  5.1,
   Fred   4.4,  John 3.7,  Wex   3.8,  Chip  4.6,
   Mike   3.2,  Jeff 3.6,  Steve 3.8,  Kumar 4.7,
   Connor 4.3,  Matt 4.6,  Peter 4.2,  Cindy 3.4/
;


*------------------------------------------------------
* generate all game configurations
*------------------------------------------------------

$onEmbeddedCode Python:
from itertools import combinations
print("")

k = 4  # k is number to select

# n is number of players
players = [p for p in gams.get("p")]
n = len(players)
print(f"number of players={n}")

comb = list(combinations(range(n),k))
ncomb = len(comb)
print(f"number of combinations={ncomb}")


# for each combination A,B,C,D we have 3 different team arrangements:
#       team 1    team 2
#  1     A,B        C,D
#  2     A,C        B,D
#  3     A,D        B,C

ngame = ncomb*3
print(f"number of possible games={ngame}")

game = []
nn = 0 # counter
for c in comb:

   # configuration 1
   nn = nn + 1
   snn = f"game{nn}"
   game.append((snn,'team1',players[c[0]]))
   game.append((snn,'team1',players[c[1]]))
   game.append((snn,'team2',players[c[2]]))
   game.append((snn,'team2',players[c[3]]))

   # configuration 2
   nn = nn + 1
   snn = f"game{nn}"
   game.append((snn,'team1',players[c[0]]))
   game.append((snn,'team1',players[c[2]]))
   game.append((snn,'team2',players[c[1]]))
   game.append((snn,'team2',players[c[3]]))

   # configuration 3
   nn = nn + 1
   snn = f"game{nn}"
   game.append((snn,'team1',players[c[0]]))
   game.append((snn,'team1',players[c[3]]))
   game.append((snn,'team2',players[c[1]]))
   game.append((snn,'team2',players[c[2]]))

# export to gams
gams.set("game",game)
$offEmbeddedCode game

option game:0:0:4;
display game;

*------------------------------------------------------
* derived data to make the model simpler
*------------------------------------------------------

alias (p,pp);

set
   lt(p,pp)  'p<pp: used to limit comparisons'
   partner(g,p,pp)  'in game g, do p,pp play in same team'
   opponent(g,p,pp) 'in game g, do p,pp play in other team'
;
lt(p,pp) = ord(p)<ord(pp);
partner(g,lt(p,pp)) = sum(t$(game(g,t,p) and game(g,t,pp)),1);
opponent(g,lt(p,pp)) = sum(t$(game(g,t,p) and game(g,t++1,pp)),1);

parameter ratingDiff(g) 'difference in rating for game g';
ratingDiff(g) = abs(sum(game(g,'team1',p),rating(p)) - sum(game(g,'team2',p),rating(p)));

*------------------------------------------------------
* optimization model
*------------------------------------------------------

variables
   x(r,g)   'schedule'
   z        'objective'
;
binary variable x;

equations
   configuration(r)    'exactly 4 games for each round'
   play(p,r)           'player is scheduled exactly once in each round'
   epartner(p,pp)       'limit number of times p,pp are member of same team'
   eoppose(p,pp)        'limit number of times p,pp are member of opposing team'
   objective
;

* exactly four games for each round
configuration(r)..
   sum(g,x(r,g)) =e= 4;

* player p is scheduled in each round r exactly once
play(p,r)..
   sum(game(g,t,p), x(r,g)) =e= 1;

* limit number of times p,pp are member of same team
epartner(lt(p,pp))..
   sum((r,partner(g,p,pp)),x(r,g)) =l= 1;

* limit number of times p,pp are member of opposing team
eoppose(lt(p,pp))..
   sum((r,opponent(g,p,pp)),x(r,g)) =l= 2;

* minimize rate difference
objective..
   z =e= sum((r,g),x(r,g)*ratingDiff(g));

*------------------------------------------------------
* solve
*------------------------------------------------------

model sched /all/;
option optcr=0, threads=8, reslim=1000;
solve sched minimizing z using mip;

*------------------------------------------------------
* reporting
*------------------------------------------------------

x.l(r,g) = round(x.l(r,g));

parameter res(*,*,*) 'Results. Teams=1/2';
res(r,g,p)$x.l(r,g) = sum(game(g,t,p),ord(t));
res(r,g,'diff')$x.l(r,g) = x.l(r,g)*ratingDiff(g);

option res:1;
display res;


