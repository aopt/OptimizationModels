### Matrix Operations using the GAMS Embedded Python API

## Write up

http://yetanothermathprogrammingconsultant.blogspot.com/2021/08/matrix-operations-via-gams-embedded.html


## Files

- `invert.gms/invert.inc` Invert an artificial matrix. We can resize by changing set `i`. Note that things get slow when we go beyond 1k.
- 'leontief.gms/invert.inc` Calculate the Leontief inverse of an actual Input-Output table (Japan, 1995, 93 sectors).
- 'RegionalIO.gms/leontief.inc` Calculate the Leontief inverse of a large regional Input-Output table (44 regions, 56 sectors). The resulting matrix 
   has size 2464×2464. This is relatively slow, a result of how the Python API uses very low-level data-structures. The input data can be downloaded 
   from http://www.wiod.org/database/wiots16. 





