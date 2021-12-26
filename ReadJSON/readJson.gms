$ontext

   Reads json file using embedded Python

   Data from: https://www.eia.gov/opendata/bulkfiles.php

$offtext


$set dataset  EMISS
$set datafile %dataset%.txt
$set gdxfile  %dataset%.gdx

$setenv gdxCompress=1

set
  t 'date/year'
  id(*)  'series_id from txt file, explanatory text has name'
  errors(*,*,*) 'could not extract a value from these'
;

parameter
   series(id,t<) 'series_id, data from IEO.txt'
;

$onEmbeddedCode Python:
import json
print("")

fln = '%datafile%'

print(f"read {fln}")
with open(fln) as f:
     lines = f.readlines()
print(f"lines:{len(lines)}")

ids = [] # 1D set
series = [] # 2d parameter
errors = [] # 3d set

for s in lines:
     obj = json.loads(s)
     if 'series_id' in obj:
           id = obj['series_id']
           name = obj['name']
           ids.append((id,name))
           for item in obj['data']:
                  date = item[0]
                  value = item[1]
                  if type(value) in [float,int]:
                         series.append((id,date,value))
                  else:
                         series.append((id,date,float('nan')))
                         errors.append((id,date,str(value)))


gams.set('id',ids)
gams.set('series',series)
gams.set('errors',errors)


$offEmbeddedCode id series errors

execute_unload "%gdxfile%",id,series,errors;
