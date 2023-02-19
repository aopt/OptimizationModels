mod.optfile=2;
option reslim=3000;
solve mod minimizing z using miqcp;

$onecho > cplex.op2
qtolin 1
*mipemphasis 3
*cuts 5
mipstart 1
*symmetry 5
*objdif 0.01
$offecho
