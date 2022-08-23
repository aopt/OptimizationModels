$ontext

    Using a large collection of words, form a subset of 5 words such that
    each letter is not used more than once.

$offtext


$set inc words.inc
$set url xxx


*-------------------------------------------------
* 5-letter Words
*-------------------------------------------------

* download file
$if not exist %inc% $call curl -O %url%

set
  w  'words: large list of 5-letter words' /
$include %inc%
  /
;
display w;

scalar numWords 'number of words in our collection';
numWords = card(w);
display numWords;

*-------------------------------------------------
* Derived data
* Characters in words
*-------------------------------------------------

sets
  c  'characters' /a*z/
  p  'position' /1*5/
  inWord(w,c) 'character c is in word w'
;

* ord(string,n) = ascii number of string[n]
inWord(w,c) = sum(p$(ord(w.tl,p.val)=ord(c.tl)), 1);
display inWord;


*-------------------------------------------------
* Optimization Model
*-------------------------------------------------

binary variable x(w) 'select word';
variable count 'number of selected words';

equations
   counting  'number of different words with unique characters'
   cover(c)  'number of selected words containing char c'
;

counting..  count =e= sum(w, x(w));
cover(c)..  sum(inWord(w,c), x(w)) =l= 1;

model m /all/;
solve m maximizing count using mip;
display x.l,count.l;

* remove if you want to see all solutions
$stop

*-------------------------------------------------
* How many solutions?
*-------------------------------------------------

$onecho > cplex.opt
SolnPoolAGap = 0.5
SolnPoolIntensity = 4
PopulateLim = 10000
SolnPoolPop = 2
solnpoolmerge solutions.gdx
$offecho

m.optfile=1;
option threads=0;

* not strictly needed, but seems to help
count.fx = round(count.l);

Solve m using mip maximizing count ;



set
  index0 'superset of solution indices' /soln_m_p1*soln_m_p10000/
  index(index0) 'used solution indices'
;
parameter
  xall(index0,w) 'all solutions'
;

execute_load "solutions.gdx",index,xall=x;
display xall;

scalar numSolutions 'number of solutions';
numSolutions = card(index);
display numSolutions;


