$ontext

   Only keep NUTS2 and remove French islands

   erwin@amsterdamoptimization.com

$offtext

*-----------------------------------------------------------
* convert geojson file
*-----------------------------------------------------------

$onEmbeddedCode Python:

import json
print("")

fln = "nuts.geojson"

skiplist = ["FRY1", "FRY2", "FRY3", "FRY4", "FRY5", "NO0B", "PT20", "PT30", "ES70" ]

with open(fln,encoding="utf-8") as f:
    obj = json.load(f)

arr = obj["features"]
print(f"Input: Number of features: {len(arr)}")
arr2 = [ c for c in arr if c["properties"]["LEVL_CODE"] == 2 and c["properties"]["NUTS_ID"] not in skiplist]
print(f"Features in output: {len(arr2)}")

obj["features"] = arr2
with open('nuts2.geojson',"w") as f:
    json.dump(obj,f)

with open('nuts2.geojson.js',"w") as f:
    f.write("geodata=")
    json.dump(obj,f)

$offEmbeddedCode


