$ontext

   1. download geojson-counties-fips.json
   2. remove PR, HI, AK from geojson file
   3. create geojson-counties-3109.[json,js]

   Counties in geojson-counties-fips.json: 3221
   Counties in output: 3109

   erwin@amsterdamoptimization.com

$offtext

*-----------------------------------------------------------
* define names
*-----------------------------------------------------------

$set inputfile  geojson-counties-fips.json
$set inputurl   https://raw.githubusercontent.com/plotly/datasets/master/%inputfile%

$set outputjson  geojson-counties-3109.json
$set outputjs    geojson-counties-3109.js

*-----------------------------------------------------------
* download geojson file
*-----------------------------------------------------------

$if not exist %inputfile% $call 'curl -O %inputurl%'

*-----------------------------------------------------------
* convert geojson file
*-----------------------------------------------------------

$onEmbeddedCode Python:

import json
print("")

statesToSkip = ["72","15","02"]

with open('%inputfile%') as f:
    obj = json.load(f)

arr = obj["features"]
print(f"Counties in %inputfile%: {len(arr)}")
arr2 = [ c for c in arr if c["properties"]["STATE"] not in statesToSkip ]
print(f"Counties in output: {len(arr2)}")

obj["features"] = arr2
with open('%outputjson%',"w") as f:
    json.dump(obj,f)

with open('%outputjs%',"w") as f:
    f.write("geodata=")
    json.dump(obj,f)

$offEmbeddedCode


