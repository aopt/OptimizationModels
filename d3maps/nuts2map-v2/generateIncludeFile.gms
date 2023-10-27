$onText

 Generate a GAMS include file with NUTS2 region names from the GeoJSON file.
 These names will be recognized by the plotting code in nuts2.gms.
 

$offText


* geojson file downloaded from
* https://ec.europa.eu/eurostat/web/gisco/geodata/reference-data/administrative-units-statistical-units/nuts#nuts21
$set geojson nuts2.geojson

* name of generated include file
$set incfile nuts2.inc

* use latin (1) or native name (0) for explanatory text
$set latin 0

$onEmbeddedCode Python:

import json
from datetime import date

print('Input file: %geojson%')
print('Output file: %incfile%')

# read GeoJSON file
with open('%geojson%') as f:
    data = json.load(f)

# extract features    
features = data['features']
numfeatures = len(features)
print(f'Number of features: {numfeatures}')

# name to use in explanatory text
if %latin%==1:
    key = 'NAME_LATN'
else:
    key = 'NUTS_NAME'

# extract useful data 
rdict = {}
for f in features:
    prop = f['properties']
    r = prop['NUTS_ID']
    name = prop[key]
    rdict[r] = name

# sort ids alphabetically
a = list(rdict.keys())
a.sort()

# open output file
inc = open('%incfile%','w',encoding='utf-8')
inc.write(
f'''
*---------------------------------------------------------------
* Regions extracted from \'%geojson%\'
* Contents:
*   set  nuts2:  all nuts2 regions in the geojson file
*   ordered alphabetically 
* 
* Generated: {date.today()}
*---------------------------------------------------------------

''')

inc.write("set nuts2 \'NUTS2 regions\' /\n")
for r in a:
    inc.write(f"  {r}   \'{rdict[r]}\'\n")
inc.write("/;\n\n")

inc.close()  
$offEmbeddedCode