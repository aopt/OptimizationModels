Sets
* this is bad: labels should be informative.
* so we should not use 1,2,3 etc.
k   sample number /1,2,3,4,5,6,7,8,9,10,11,12/
j   criterion /1,2,3,4/
n   class1 /1, 2, 3/
t   class2 /1, 2, 3/
nk(n,k) / 1.(1*4), 2.(5*8), 3.(9*12) /
tk(t,k) / 1.(1*4), 2.(5*8), 3.(9*12) /;

* missing explanatory text
Table a(k,j)
    1   2   3   4
1   1   1   1   3
2   1   1   2   2
3   1   2   1   3
4   1   2   2   1
5   1   1   1   3
6   1   1   2   2
7   1   2   1   3
8   1   2   2   1
9   1   1   1   3
10  1   1   2   3
11  1   2   1   3
12  1   2   2   1;


* missing explanatory text
Parameters p /2/;

* missing explanatory text
Parameters r /0.000001/;

* missing explanatory text
Parameters y(n,j);
y(n,j) = sum(nk(n,k), a(k,j))/sum(nk(n,k), 1);

* missing explanatory text
Parameters m(t,j);
m(t,j) = sum(tk(t,k), a(k,j))/sum(tk(t,k), 1);

* missing explanatory text
Variables
e(k)
w(j)
z;

* missing explanatory text
Positive Variable
e(k)
w(j);

* missing explanatory text
Equations
constraint1
constraint2
constraint3
objective;

objective..z=e=sum(k,e(k));
* this is bad. this is what I want to see in GAMS models.
constraint1(k,n,t)$(ord(n)<>ord(t))..rPower(sum(j,w(j)*power(((a(k,j))-y(n,j)),p)),(1/p))-e(k)=l=rPower(sum(j,w(j)*power(((a(k,j))-m(t,j)),p)),(1/p))-r;
constraint2..sum(j,w(j))=e=1;
constraint3(j)..w(j)=g=0.00000001;

Model nonrobust / all /;
Option nlp=baron, limrow=100;

solve nonrobust minimizing z using nlp;

display z.l, e.l, w.l , m, y, a;
