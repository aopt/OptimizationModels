$ontext

    Extract information from geojson file

    Single feature is:

    {"type": "Feature",
     "properties": {
          "GEO_ID": "0500000US01001",
          "STATE": "01",
          "COUNTY": "001",
          "NAME": "Autauga",
          "LSAD": "County",
          "CENSUSAREA": 594.436},
      "geometry": {"type": "Polygon", "coordinates": [[[-86.496774, 32.344437], ..., [-86.496774, 32.344437]]]},
      "id": "01001"}

$offtext


$set inputfile geojson-counties-3109.json

*--------------------------------------------------
* gams sets/parameters to hold data
*--------------------------------------------------

set
  id(*)
  properties(id,*,*)
;
parameter area(id);

*--------------------------------------------------
* Python code
*--------------------------------------------------

$onEmbeddedCode Python:

import json
print("")

with open('%inputfile%') as f:
    obj = json.load(f)

ids = []
props = []
area = []
for f in obj["features"]:
    id = f['id']
    prop = f['properties']
    ids.append((id))
    props.append((id,'GEO_ID',prop['GEO_ID']))
    props.append((id,'STATE',prop['STATE']))
    props.append((id,'COUNTY',prop['COUNTY']))
    props.append((id,'NAME',prop['NAME']))
    props.append((id,'LSAD',prop['LSAD']))
    area.append((id,prop['CENSUSAREA']))

gams.set('id',ids)
gams.set('properties',props)
gams.set('area',area)

$offEmbeddedCode id properties area


*--------------------------------------------------
* display, write to GDX file
*--------------------------------------------------

option id:0:0:10,properties:0:0:3;
display id,properties,area;


execute_unload "json";