$ontext

   Invert a square, dense matrix.
   With an edit

   This uses the Embedded Python API. We see that it is
   very slow for larger instances.

$offtext


set i /i1*i1000/;
alias(i,j,k);

parameters
  a(i,j) 'square matrix A'
  b(j,i) 'B=inv(A)'
;
a(i,j) = 1/(ord(i)+ord(j)-1);
a(i,i) = 1;
* This is a Hilbert matrix with diagonal replaced by ones.

$batinclude invert.inc A B i

display$(card(i)<50) B;

* check solution for smaller instances
parameters
   ident(i,j) 'identity matrix'
   maxerr     'maximum error'
;

if (card(i)<=200,
   ident(i,i)=1;
   maxerr = smax((i,j),abs(sum(k,A(i,k)*B(j,k))-ident(i,j)));
   display maxerr;
);

