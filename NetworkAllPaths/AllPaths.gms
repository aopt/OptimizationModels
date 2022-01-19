$ontext

   Here we consider a directed network. We want to find all feasible
   paths from A->B such that arcs are used only once (nodes can be
   visited several times).

   We use an augmented graph for this, in combination with the
   MTZ subtour-elimination constraint (from TSP models). We solve
   using the solution pool.

   References:
     https://yetanothermathprogrammingconsultant.blogspot.com/2022/01/an-all-paths-network-problem.html

$offtext

*-----------------------------------------------------------
* network topology
*-----------------------------------------------------------

option seed=1;

set
   n 'nodes' /n1*n10/
   a(n,n) 'directed arcs'
;

alias (n,i,j);

a(i,j) = uniform(0,1)<0.2;

scalar M 'maximum hops' /3/;

display n,a,M;


singleton sets
   src(n) 'source' /n1/
   snk(n) 'sink'   /n10/
;
set ni(n) 'interior nodes';
ni(n) = yes;
ni(src) = no;
ni(snk) = no;


*-----------------------------------------------------------
* visualization using GraphViz
*-----------------------------------------------------------

file gv1 /graph1.gv/;
put gv1;
put "digraph neato{"/;
put "node [shape=circle,style=filled,color=yellowgreen] ",src.tl/;
put "node [shape=circle,style=filled,color=orange] ",snk.tl/;
put "node [shape=circle,style=filled,color=lightblue]"/;
loop(ni, put ni.tl:0," ";); put /;
put "edge [color=grey]"/;
loop(a(i,j), put i.tl:0,"->",j.tl:0/;);
putclose"}"/;

*-----------------------------------------------------------
*   shortest path n1->n2 as MIP/RMIP model
*-----------------------------------------------------------

parameter inflow(n) 'exogenous inflow';
inflow(src) = 1;
inflow(snk) = -1;

binary variable f(i,j) 'flow';
variable count 'length of shortest path (hops)';

equations
    obj           'objective'
    flowbal(n)    'flow balance at node'
;

obj.. count =e= sum(a,f(a));
flowbal(n)..  sum(a(i,n),f(a)) + inflow(n) =e= sum(a(n,j),f(a));

model sp /all/;
solve sp minimizing count using rmip;

display "#### Model SP: Single Shortest Path Solution", count.l,f.l;


*-----------------------------------------------------------
*   add hop count
*   and solve with solution pool
*-----------------------------------------------------------

count.up = M;

sp.optfile=1;
solve sp minimizing count using mip;

set
  solIndex /soln_sp_p1*soln_sp_p20
            soln_sp2_p1*soln_sp2_p20
            soln_sp3_p1*soln_sp3_p20/
  sol(solIndex)
;
parameter fsol(solIndex,n,n) 'solution from solution pool';

execute_load "solutions.gdx",sol=index,fsol=f;
option fsol:0:1:1;
display "#### Model SP/solution pool: Find all feasible paths with max length",
         count.up,sol,fsol,
        "#### WARNING: This solution contains subtours";

*-----------------------------------------------------------
*   add MTZ subtour elimination constraints
*-----------------------------------------------------------

positive variable t(i) 'ordering of hops';

equation mtz(i,j) 'subtour elimination constraints';

mtz(a(i,j))$(not src(i) and not snk(j))..
    t(j) =g= t(i) + 1 + card(n)*(f(i,j)-1);

model sp2 /sp+mtz/;
sp2.optfile=1;
solve sp2 minimizing count using mip;

execute_load "solutions.gdx",sol=index,fsol=f;
display "#### Model SP2/solution pool: Find all feasible paths with max length",
         sol,fsol,
        "#### WARNING: This solution excludes tours";


*-----------------------------------------------------------
*  make arcs nodes, and arcs indicate adjacency
*-----------------------------------------------------------

set in(*)  'references to old nodes while adding src/snk' /src,snk/;
in(n) = yes;
alias(in,jn,kn);

set nn(*,*) 'new nodes' /src.n1, n10.snk/;
nn(a) = yes;
display nn;
alias (nn,nn2);

set an(*,*,*,*) 'new arcs (w/o self-loops)';
an(in,jn,jn,kn)$(nn(in,jn) and nn(jn,kn)
                and not (sameas(in,jn) and sameas(jn,kn))) = yes;
option an:0:2:2;
display an;


*-----------------------------------------------------------
* visualization using GraphViz
*-----------------------------------------------------------

file gv2 /graph2.gv/;
put gv2;
put "digraph neato{"/;
put "node [shape=circle,style=filled,color=yellowgreen] ";
loop(nn('src',in), put 'src_':0,in.tl:0/ );
put "node [shape=circle,style=filled,color=orange] ";
loop(nn(in,'snk'), put in.tl:0,'_snk':0/ );
put "node [shape=circle,style=filled,color=lightblue]"/;
loop(nn(in,jn)$(not sameas(in,'src') and not sameas(jn,'snk')),
    put in.tl:0,"_":0,jn.tl:0," ":0;);
put /;
put "edge [color=grey]"/;
loop(an(in,jn,jn,kn),
   put in.tl:0,"_":0,jn.tl:0,"->":0,jn.tl:0,"_",kn.tl:0/);
putclose"}"/;

*-----------------------------------------------------------
* Model v2
*-----------------------------------------------------------

M = 4;

singleton sets
   srcn(*,*) / src.n1 /
   snkn(*,*) /n10.snk /
;

parameter inflown(*,*) 'new inflow';
inflown(srcn) = 1;
inflown(snkn) = -1;

binary variables fn 'new flow variables';
positive variable tn 'MTZ variable';

equations
    objn     'new objective'
    flowbaln 'new flow balance on nodes'
    mtzn     'new MTZ subtour elimination constraints'
;

objn.. count =e= sum(an,fn(an));
flowbaln(nn).. sum(an(nn2,nn),fn(an)) + inflown(nn) =e= sum(an(nn,nn2),fn(an));
mtzn(an(nn,nn2))$(not srcn(nn) and not snkn(nn2))..
    tn(nn2) =g= tn(nn) + 1 + card(nn)*(fn(nn,nn2)-1);
count.up = M+1;

model sp3 /objn,flowbaln,mtzn/;
sp3.optfile=1;
solve sp3 minimizing count using mip;

parameter fsoln(solIndex,*,*,*,*) 'solution from solution pool';

execute_load "solutions.gdx",sol=index,fsoln=fn;
option fsoln:0:2:2;
display "#### Model SP3/solution pool: augmented graph",
         count.up,sol,fsoln;


$onecho > cplex.opt
SolnPoolIntensity = 4
PopulateLim = 10000
SolnPoolPop = 2
solnpoolmerge solutions.gdx
$offecho

