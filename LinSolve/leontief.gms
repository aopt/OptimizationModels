$ontext

    Calculate the Leontief inverse.

$offtext

set i 'sectors/industries' /001*093/;
alias(i,j);

singleton sets
    totalProduction /115/
    finalDemand     /112/
    totalDomProd    /115/
;

table IOTable(*,*) 'complete IO table of 1995 Japan [millions yens]'
$include io93pro.inc
;

display IOTable;

parameter
   A(i,j)     'input coefficients'
   Ident(i,j) 'Identity matrix'
   IA(i,j)    'I-A'
   L(i,j)     'Leontief inverse'
;
A(i,j) = IOTable(i,j)/IOTable(totalProduction,j);

Ident(i,i) = 1;
IA(i,j) = Ident(i,j)-A(i,j);

$batinclude invert.inc IA L i

display L;

* check
parameter err(i), maxerr;
err(i) = sum(j, L(i,j)*IOTable(j,finalDemand)) - IOTable(TotalDomProd,i);
maxerr = smax(i,abs(err(i)));
display maxerr;

