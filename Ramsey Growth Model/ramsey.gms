$ontext

    Ramsey Growth Model,
    an example of a dynamic general equilibrium model.
    December 2001, Erwin Kalvelagen
    
    References:
       F.P. Ramsey: A Mathematical Theory of Saving,
       Economics Journal, December 1928.
       
       A. Manne: GAMS/MINOS: Three examples, manuscript,
       Department of Operations Research, Stanford University,
       1986
       
       M.I. Lau, A. Pahlke, and T.F. Rutherford,
       Modeling Economic Adjustment: A Primer in Dynamic General
       Equilibrium Analysis, Report, University of Colorado, 1997
       
$offtext

*
* data for the model
*

set t 'time periods' / t0*t25 /;
scalars
   rho    'discount factor'             / 0.05 /
   g      'labor growth rate'           / 0.03 /
   delta  'capital depreciation factor' / 0.02 /
   K0     'initial capital'             / 3.00 /
   I0     'initial investment'          / 0.05 /
   C0     'initial consumption'         / 0.95 /
   L0     'initial labor'               / 1.00 /
   b      'Cobb-Douglas coefficient'    / 0.25 /
   a      'Cobb-Douglas coefficient'
;

*
* derived sets
*
sets
   tfirst(t) ’first period’
   tlast(t) ’last period’
   tnotlast(t) ’all but last’
;

tfirst(t)$(ord(t)=1) = yes;
tlast(t)$(ord(t)=card(t)) = yes;
tnotlast(t)= not tlast(t);

parameters
   L(t)     'Labor (production input, exogeneous)'
   beta(t)  'weight factor for future utilities'
   tval(t)  'numerical value of t'
;
   
tval(t) = ord(t)-1;

*
* the terminal weight beta(tlast) will get extra emphasis to
* compensate for future utilities beyond tlast.
*
beta(tnotlast(t)) = (1+rho)**(-tval(t));
beta(tlast(t)) = (1/rho)*(1+rho)**(1-tval(t));
display beta;

*
* labor is exogeneously determined using an exponential growth process
*
L(t) = (1+g)**tval(t) * L0;
display L;

*
* we can calculate a from Y0 = C0 + I0 and Y0 = f(K0,L0) = a K0^b L0^(1-b)
*
a = (C0 + I0) / (K0**b * L0**(1-b));
display a;


positive variables
   C(t) 'consumption'
   Y(t) 'production output'
   K(t) 'capital (production input,endogeneous)'
   I(t) 'investment'
;
variable
   W    'total utility'
;

equation
   production(t)   'Cobb-Douglas production function'
   allocation(t)   'household chooses between consumption and saving'
   accumulation(t) 'capital accumulation'
   utility         'discounted utility'
   final(t)        'minimal investment in final period'
;

utility..                   W =e= sum(t,beta(t)*log(C(t)));
production(t)..             Y(t)=e= a * (K(t)**b) * (L(t)**(1-b));
allocation(t)..             Y(t)=e= C(t) + I(t);
accumulation(tnotlast(t)).. K(t+1) =e= (1-delta)*K(t) + I(t);
final(tlast)..              I(tlast) =g= (g+delta)*K(tlast);

*
* bounds so real power and log can be evaluated
*
K.lo(t) = 0.001; C.lo(t) = 0.001;

*
* initial conditions
*
K.fx(tfirst) = K0;
I.fx(tfirst) = I0;
C.fx(tfirst) = C0;

*
* initial point for nonlinear variables
*
K.l(t) = K0;
C.l(t) = C0;

model ramsey /all/;
*option nlp=conopt;
solve ramsey maximizing W using nlp;


parameter results(t,*);
results(t,'C') = C.l(t);
results(t,'Y') = Y.l(t);
results(t,'K') = K.l(t);
results(t,'I') = I.l(t);
option decimals=8;
display results,W.l;
