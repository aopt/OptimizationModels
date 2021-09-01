$ontext

   Leontief inverse of a large regional IO table

   Data from http://www.wiod.org/database/wiots16

$offtext

*----------------------------------------------------------------
* Convert spreadsheet and import GDX file
*----------------------------------------------------------------

$set data     WIOT2014_Nov16_ROW
$set xls      %data%.xlsb
$set gdx      %data%.gdx

* make gdx file smaller
$setenv gdxcompress 1


* remove WIOT2014_Nov16_ROW.gdx to force rereading the speadsheet

$if not exist %gdx% $call 'gdxxrw %xls% par=wiot rng=A3 rdim=2 cdim=2 ignorerows=4,6 ignorecolumns=B,D'


parameter WIOT(*,*,*,*) 'WIOT Intercountry Input-Output Table';
$gdxin %gdx%
$loaddc WIOT


*----------------------------------------------------------------
* Sets
*----------------------------------------------------------------

sets
   i 'industries' /
      A01,A02,A03,B,C10-C12,C13-C15,C16,C17,C18,C19,C20,C21
      C22,C23,C24,C25,C26,C27,C28,C29,C30,C31_C32,C33,D35,E36
      E37-E39,F,G45,G46,G47,H49,H50,H51,H52,H53,I,J58,J59_J60
      J61,J62_J63,K64,K65,K66,L68,M69_M70,M71,M72,M73,M74_M75
      N,O84,P85,Q,R_S,T,U
    /
   r 'regions (43 countries + ROW)' /
      AUS,AUT,BEL,BGR,BRA,CAN,CHE,CHN,CYP,CZE,DEU,DNK,ESP
      EST,FIN,FRA,GBR,GRC,HRV,HUN,IDN,IND,IRL,ITA,JPN,KOR
      LTU,LUX,LVA,MEX,MLT,NLD,NOR,POL,PRT,ROU,RUS,SVK,SVN
      SWE,TUR,TWN,USA,ROW
    /
  ir(i,r)
;
ir(i,r) = yes;
alias(i,ii,i2,i3),(r,rr,r2,r3),(ir,ir2,ir3);


*----------------------------------------------------------------
* do some counting
*----------------------------------------------------------------

parameter counts(*) 'industries,regions,combinations';
counts('i:sectors') = card(i);
counts('r:regions') = card(r);
counts('ir:combinations') = card(ir);
option counts:0;
display counts;

*----------------------------------------------------------------
* extract parameters
*----------------------------------------------------------------

set
  fd 'final demand'/
          CONS_h  'Final consumption expenditure by households'
          CONS_np 'Final consumption expenditure by non-profit organisations serving households (NPISH)'
          CONS_g  'Final consumption expenditure by government'
          GFCF    'Gross fixed capital formation'
          INVEN   'Changes in inventories and valuables'
       /
;

parameter
   finalDemand(i,r) 'final demand f'
   grossOutput(i,r) 'total'
   A(i,r,i,r)       'technological coefficients'
   Ident(i,r,i,r)   'Indentity matrix I'
;
finalDemand(ir) = sum((fd,r),WIOT(ir,fd,r));
grossOutput(ir) = WIOT(ir,'GO','TOT');
A(ir,ir2)$grossOutput(ir2) = WIOT(ir,ir2)/grossOutput(ir2);
Ident(i,r,i,r) = 1;

*----------------------------------------------------------------
* sanity check
*----------------------------------------------------------------

* x = Z*1 + f

parameter Xerr(i,r) 'error in identity x = Z*1 + f';
Xerr(ir) = grossOutput(ir) - sum(ir2,WIOT(ir,ir2)) - finalDemand(ir);
abort$(smax(ir,abs(Xerr(ir)))>1e-5) "Check Xerr";

*----------------------------------------------------------------
* form Leontief inverse
*----------------------------------------------------------------

parameter L(i,r,i,r) 'Leontief inverse';

$batinclude leontief.inc A L ir

*----------------------------------------------------------------
* some checks
*----------------------------------------------------------------

* check  (I-A) * inv(I-A) = I
* do a small subset of countries (a complete check would take a long time).
set rsub(r) /AUS,AUT/;
parameter InvErr(i,r,i,r) 'error in identity (I-A)*L=I';
InvErr(ir(i,r),ir2(i2,r2))$(rsub(r) and rsub(r2)) =
    sum(ir3, (Ident(ir,ir3)-A(ir,ir3))*L(ir3,ir2)) - Ident(ir,ir2);
abort$(smax((ir,ir2),abs(InvErr(ir,ir2)))>1e-5) "Check InvErr";


* check  x = inv(I-A)*f = L*f
parameter xInvErr(i,r) 'error in x = inv(I-A)*f';
xInvErr(ir) = sum(ir2, L(ir,ir2)*finalDemand(ir2)) - GrossOutput(ir);
abort$(smax(ir,abs(XInvErr(ir)))>1e-5) "Check XInvErr";

$stop

parameter err(r,i), maxerr;
err(r,i) = sum((rr,ii), L(r,i,rr,ii)*finalDemand(r,i,rr,'total')) - Totals(r,i);
maxerr = smax((r,i),abs(err(r,i)));
display maxerr;



$stop

REGIONS
=======

     AUS      'Australia'
     AUT      'Austria'
     BEL      'Belgium'
     BGR      'Bulgaria'
     BRA      'Brazil'
     CAN      'Canada'
     CHE      'Switserland'
     CHN      'China'
     CYP      'Cyprus'
     CZE      'Czech Republic'
     DEU      'Germany'
     DNK      'Denmark'
     ESP      'Spain'
     EST      'Estonia'
     FIN      'Finland'
     FRA      'France'
     GBR      'UK'
     GRC      'Greece'
     HRV      'Croatia'
     HUN      'Hungary'
     IDN      'Indonesia'
     IND      'India'
     IRL      'Ireland'
     ITA      'Italy'
     JPN      'Japan'
     KOR      'South Korea'
     LTU      'Lithuania'
     LUX      'Luxembourg'
     LVA      'Latvia'
     MEX      'Mexico'
     MLT      'Malta'
     NLD      'The Netherlands'
     NOR      'Norway'
     POL      'Poland'
     PRT      'Portugal'
     ROU      'Romania'
     RUS      'Russia'
     SVK      'Slovak Republic'
     SVN      'Slovenia'
     SWE      'Sweden'
     TUR      'Turkey'
     TWN      'Taiwan'
     USA      'USA'
     ROW      'Rest of the world'


SECTORS
=======

     A01        'Crop and animal production, hunting and related service activities'
     A02        'Forestry and logging'
     A03        'Fishing and aquaculture'
     B          'Mining and quarrying'
     C10-C12    'Manufacture of food products, beverages and tobacco products'
     C13-C15    'Manufacture of textiles, wearing apparel and leather products'
     C16        'Manufacture of wood and of products of wood and cork, except furniture; manufacture of articles of straw and plaiting materials'
     C17        'Manufacture of paper and paper products'
     C18        'Printing and reproduction of recorded media'
     C19        'Manufacture of coke and refined petroleum products'
     C20        'Manufacture of chemicals and chemical products'
     C21        'Manufacture of basic pharmaceutical products and pharmaceutical preparations'
     C22        'Manufacture of rubber and plastic products'
     C23        'Manufacture of other non-metallic mineral products'
     C24        'Manufacture of basic metals'
     C25        'Manufacture of fabricated metal products, except machinery and equipment'
     C26        'Manufacture of computer, electronic and optical products'
     C27        'Manufacture of electrical equipment'
     C28        'Manufacture of machinery and equipment n.e.c.'
     C29        'Manufacture of motor vehicles, trailers and semi-trailers'
     C30        'Manufacture of other transport equipment'
     C31_C32    'Manufacture of furniture; other manufacturing'
     C33        'Repair and installation of machinery and equipment'
     D35        'Electricity, gas, steam and air conditioning supply'
     E36        'Water collection, treatment and supply'
     E37-E39    'Sewerage; waste collection, treatment and disposal activities; materials recovery; remediation activities and other waste management services'
     F          'Construction'
     G45        'Wholesale and retail trade and repair of motor vehicles and motorcycles'
     G46        'Wholesale trade, except of motor vehicles and motorcycles'
     G47        'Retail trade, except of motor vehicles and motorcycles'
     H49        'Land transport and transport via pipelines'
     H50        'Water transport'
     H51        'Air transport'
     H52        'Warehousing and support activities for transportation'
     H53        'Postal and courier activities'
     I          'Accommodation and food service activities'
     J58        'Publishing activities'
     J59_J60    'Motion picture, video and television programme production, sound recording and music publishing activities; programming and broadcasting activities'
     J61        'Telecommunications'
     J62_J63    'Computer programming, consultancy and related activities; information service activities'
     K64        'Financial service activities, except insurance and pension funding'
     K65        'Insurance, reinsurance and pension funding, except compulsory social security'
     K66        'Activities auxiliary to financial services and insurance activities'
     L68        'Real estate activities'
     M69_M70    'Legal and accounting activities; activities of head offices; management consultancy activities'
     M71        'Architectural and engineering activities; technical testing and analysis'
     M72        'Scientific research and development'
     M73        'Advertising and market research'
     M74_M75    'Other professional, scientific and technical activities; veterinary activities'
     N          'Administrative and support service activities'
     O84        'Public administration and defence; compulsory social security'
     P85        'Education'
     Q          'Human health and social work activities'
     R_S        'Other service activities'
     T          'Activities of households as employers; undifferentiated goods- and services-producing activities of households for own use'
     U          'Activities of extraterritorial organizations and bodies'
