$ontext

   Different formulations of the minimum spanning tree problem.

   References:
     Magnanti, Thomas L.; Wolsey, Laurence A., "Optimal Trees",
     in M.O. Ball, T.L. Magnanti, C.L. Monma, and G.L. Nemhauser, editors,
     Network Models, volume 7 of Handbooks in Operations Research and Management Science,
     Chapter 9, pages 503--616. North-Holland, 1995.

  Distances from TSPLIB

  See:
  https://yetanothermathprogrammingconsultant.blogspot.com/2021/03/minimum-spanning-trees-in-math.html

  erwin@amsterdamoptimization.com


$offtext

set
  i cities /c1*c42/
;

table cityData(i,*,*)
                                   lat        lon
 c1  . 'Manchester, N.H.'       42.99564  -71.45479
 c2  . 'Montpelier, Vt.'        44.26006  -72.57539
 c3  . 'Detroit, Mich.'         42.33143  -83.04575
 c4  . 'Cleveland, Ohio'        41.49932  -81.69436
 c5  . 'Charleston, W.Va.'      38.34982  -81.63262
 c6  . 'Louisville, Ky.'        38.25266  -85.75846
 c7  . 'Indianapolis, Ind.'     39.76840  -86.15807
 c8  . 'Chicago, Ill.'          41.87811  -87.62980
 c9  . 'Milwaukee, Wis.'        43.03890  -87.90647
 c10 . 'Minneapolis, Minn.'     44.97775  -93.26501
 c11 . 'Pierre, S.D.'           44.36679 -100.35375
 c12 . 'Bismarck, N.D.'         46.80833 -100.78374
 c13 . 'Helena, Mont.'          46.58915 -112.03911
 c14 . 'Seattle, Wash.'         47.60621 -122.33207
 c15 . 'Portland, Ore.'         45.50511 -122.67503
 c16 . 'Boise, Idaho'           43.61502 -116.20231
 c17 . 'Salt Lake City, Utah'   40.76078 -111.89105
 c18 . 'Carson City, Nevada'    39.16380 -119.76740
 c19 . 'Los Angeles, Calif.'    34.05223 -118.24368
 c20 . 'Phoenix, Ariz.'         33.44838 -112.07404
 c21 . 'Santa Fe, N.M.'         35.68698 -105.93780
 c22 . 'Denver, Colo.'          39.73924 -104.99025
 c23 . 'Cheyenne, Wyo.'         41.13998 -104.82025
 c24 . 'Omaha, Neb.'            41.25654  -95.93450
 c25 . 'Des Moines, Iowa'       41.58684  -93.62496
 c26 . 'Kansas City, Mo.'       39.09973  -94.57857
 c27 . 'Topeka, Kans.'          39.04735  -95.67516
 c28 . 'Oklahoma City, Okla.'   35.46756  -97.51643
 c29 . 'Dallas, Tex.'           32.77666  -96.79699
 c30 . 'Little Rock, Ark.'      34.74648  -92.28959
 c31 . 'Memphis, Tenn.'         35.14953  -90.04898
 c32 . 'Jackson, Miss.'         32.29876  -90.18481
 c33 . 'New Orleans, La.'       29.95107  -90.07153
 c34 . 'Birmingham, Ala.'       33.51859  -86.81036
 c35 . 'Atlanta, Ga.'           33.74900  -84.38798
 c36 . 'Jacksonville, Fla.'     30.33218  -81.65565
 c37 . 'Columbia, S.C.'         34.00071  -81.03481
 c38 . 'Raleigh, N.C.'          35.77959  -78.63818
 c39 . 'Richmond, Va.'          37.54072  -77.43605
 c40 . 'Washington, D.C.'       38.90719  -77.03687
 c41 . 'Boston, Mass.'          42.36008  -71.05888
 c42 . 'Portland, Me.'          43.65910  -70.25682
;

alias (i,j,k);

table d(i,j) 'from dantzig42 data set in TSPLIB'
     c1  c2  c3  c4  c5  c6  c7  c8  c9 c10 c11 c12 c13 c14 c15 c16 c17 c18 c19 c20 c21
c2    8
c3   39  45
c4   37  47   9
c5   50  49  21  15
c6   61  62  21  20  17
c7   58  60  16  17  18   6
c8   59  60  15  20  26  17  10
c9   62  66  20  25  31  22  15   5
c10  81  81  40  44  50  41  35  24  20
c11 103 107  62  67  72  63  57  46  41  23
c12 108 117  66  71  77  68  61  51  46  26  11
c13 145 149 104 108 114 106  99  88  84  63  49  40
c14 181 185 140 144 150 142 135 124 120  99  85  76  35
c15 187 191 146 150 156 142 137 130 125 105  90  81  41  10
c16 161 170 120 124 130 115 110 104 105  90  72  62  34  31  27
c17 142 146 101 104 111  97  91  85  86  75  51  59  29  53  48  21
c18 174 178 133 138 143 129 123 117 118 107  83  84  54  46  35  26  31
c19 185 186 142 143 140 130 126 124 128 118  93 101  72  69  58  58  43  26
c20 164 165 120 123 124 106 106 105 110 104  86  97  71  93  82  62  42  45  22
c21 137 139  94  96  94  80  78  77  84  77  56  64  65  90  87  58  36  68  50  30
c22 117 122  77  80  83  68  62  60  61  50  34  42  49  82  77  60  30  62  70  49  21
c23 114 118  73  78  84  69  63  57  59  48  28  36  43  77  72  45  27  59  69  55  27
c24  85  89  44  48  53  41  34  28  29  22  23  35  69 105 102  74  56  88  99  81  54
c25  77  80  36  40  46  34  27  19  21  14  29  40  77 114 111  84  64  96 107  87  60
c26  87  89  44  46  46  30  28  29  32  27  36  47  78 116 112  84  66  98  95  75  47
c27  91  93  48  50  48  34  32  33  36  30  34  45  77 115 110  83  63  97  91  72  44
c28 105 106  62  63  64  47  46  49  54  48  46  59  85 119 115  88  66  98  79  59  31
c29 111 113  69  71  66  51  53  56  61  57  59  71  96 130 126  98  75  98  85  62  38
c30  91  92  50  51  46  30  34  38  43  49  60  71 103 141 136 109  90 115  99  81  53
c31  83  85  42  43  38  22  26  32  36  51  63  75 106 142 140 112  93 126 108  88  60
c32  89  91  55  55  50  34  39  44  49  63  76  87 120 155 150 123 100 123 109  86  62
c33  95  97  64  63  56  42  49  56  60  75  86  97 126 160 155 128 104 128 113  90  67
c34  74  81  44  43  35  23  30  39  44  62  78  89 121 159 155 127 108 136 124 101  75
c35  67  69  42  41  31  25  32  41  46  64  83  90 130 164 160 133 114 146 134 111  85
c36  74  76  61  60  42  44  51  60  66  83 102 110 147 185 179 155 133 159 146 122  98
c37  57  59  46  41  25  30  36  47  52  71  93  98 136 172 172 148 126 158 147 124 121
c38  45  46  41  34  20  34  38  48  53  73  96  99 137 176 178 151 131 163 159 135 108
c39  35  37  35  26  18  34  36  46  51  70  93  97 134 171 176 151 129 161 163 139 118
c40  29  33  30  21  18  35  33  40  45  65  87  91 117 166 171 144 125 157 156 139 113
c41   3  11  41  37  47  57  55  58  63  83 105 109 147 186 188 164 144 176 182 161 134
c42   5  12  55  41  53  64  61  61  66  84 111 113 150 186 192 166 147 180 188 167 140

+
    c22 c23 c24 c25 c26 c27 c28 c29 c30 c31 c32 c33 c34 c35 c36 c37 c38 c39 c40 c41
c23   5
c24  32  29
c25  40  37   8
c26  36  39  12  11
c27  32  36   9  15   3
c28  36  42  28  33  21  20
c29  47  53  39  42  29  30  12
c30  61  62  36  34  24  28  20  20
c31  64  66  39  36  27  31  28  28   8
c32  71  78  52  49  39  44  35  24  15  12
c33  76  82  62  59  49  53  40  29  25  23  11
c34  79  81  54  50  42  46  43  39  23  14  14  21
c35  84  86  59  52  47  51  53  49  32  24  24  30   9
c36 105 107  79  71  66  70  70  60  48  40  36  33  25  18
c37  97  99  71  65  59  63  67  62  46  38  37  43  23  13  17
c38 102 103  73  67  64  69  75  72  54  46  49  54  34  24  29  12
c39 102 101  71  65  65  70  84  78  58  50  56  62  41  32  38  21   9
c40  95  97  67  60  62  67  79  82  62  53  59  66  45  38  45  27  15   6
c41 119 116  86  78  84  88 101 108  88  80  86  92  71  64  71  54  41  32  25
c42 124 119  90  87  90  94 107 114  77  86  92  98  80  74  77  60  48  38  32   6

;


sets
   s(i) 'source node (can be any node)' /c40/
   t(i) 'terminal nodes'
;
t(i)$(not s(i)) = yes;

parameter c(i,j) 'cost directed arcs';
c(i,j) = d(i,j) + d(j,i);

set a(i,j) 'existing arcs (exclude extries without c(i,j))';
a(i,j)$c(i,j) = yes;

scalar n 'number of nodes';
n = card(i);

*------------------------------------------------------------------------------
* reporting
*------------------------------------------------------------------------------

$macro report(m,label)  \
    results('equations',label) = m.numequ; \
    results('variables',label) = m.numvar; \
    results('discr.var.',label) = m.numdvar; \
    results('nz elem.',label) = m.numnz; \
    results('objective',label) = m.objval; \
    results('time',label) = m.resusd; \
    results('nodes',label) = m.nodusd; \
    results('iterations',label) = m.iterusd;

parameter results(*,*);



*------------------------------------------------------------------------------
* model 1: multicommodity flow
*
* this model can be solved as an LP
* variables are integer automatically
*------------------------------------------------------------------------------


parameter b(i,k) 'right-hand side (exogenous net inflow)';
b(s,t) = 1;
b(t,t) = -1;

variables
   z         'objective'
   x(i,j)    '0-1 variable indicating tree'
   y(i,j,k)  'flow variables (last index is terminal node)'
;
binary variable x,y;

equations
   objective      'minimize total cost'
   nodebal(i,k)   'node balance'
   compare(i,j,k) 'implication x=0 => y=0'
;


objective..
   z =e= sum(a, c(a)*x(a));

nodebal(i,t)..
   sum(a(i,j), y(a,t)) =e= sum(a(j,i), y(a,t)) + b(i,t);

compare(a,t)..
   y(a,t) =l= x(a);

option optcr=0,threads=8;
model m1 /objective,nodebal,compare/;
solve m1 minimizing z using rmip;
display y.l, x.l, z.l;

report(m1,'mcf')

*------------------------------------------------------------------------------
* model 2: single commodity flow
*
* this model must be solved as a MIP
*------------------------------------------------------------------------------

parameter b2(i) 'right-hand side (exogenous net inflow)';
b2(s) = card(i)-1;
b2(t) = -1;

scalar M 'upper bound on f';
M = n-1;

integer variable
   y2(i,k)    'flow variables (last index is terminal node)'
;

equations
   nodebal2(i)     'node balance'
   compare2(i,k)   'implication x=0 => f=0'
;

nodebal2(i)..
   sum(a(i,j), y2(a)) =e= sum(a(j,i), y2(a)) + b2(i);

compare2(a)..
   y2(a) =l= M*x(a);


model m2 /objective,nodebal2,compare2/;
solve m2 minimizing z using mip;
display y2.l, x.l, z.l;

report(m2,'scf')


*------------------------------------------------------------------------------
* model 3: MST formulation
*------------------------------------------------------------------------------

positive variables
  v(i)      'ordering of nodes (>=hops from source node)'
;
v.fx(s) = 0;
v.lo(t) = 1;
v.up(t) = n-1;

equations
   objective      'minimize total cost'
   degree1        'out-degree of source node'
   degree2(k)     'in-degree of all other nodes'
   mst(i,j)       'MST constraint'
;

degree1..
   sum(a(s,j), x(a)) =g= 1;

degree2(t)..
   sum(a(j,t), x(a)) =e= 1;

mst(a(i,j))$(t(i) and t(j))..
     v(j) =g= v(i) + 1 - (n-1)*(1-x(i,j));

model m3 /objective,degree1,degree2,mst/;
solve m3 minimizing z using mip;
display v.l, x.l, z.l;

report(m3,'mst')

*------------------------------------------------------------------------------
* model 4: lifted MST formulation
*------------------------------------------------------------------------------

equations
   mst2(i,j)       'lifted MST constraint'
;

mst2(a(i,j))$(t(i) and t(j))..
   v(i) - v(j) + (n-1)*x(i,j) + (n-3)*x(j,i) =l= n-2;

model m4 /objective,degree1,degree2,mst2/;
solve m4 minimizing z using mip;
display v.l, x.l, z.l;

report(m4,'lifted mst')

display results;