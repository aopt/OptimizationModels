Example of county level map with random data


Files
=====

     geodata.gms: run this to create the geojson files. It will download the original file
                  and remove states HI, PR and AK

        Counties in geojson-counties-fips.json: 3221
        Counties in output: 3109

        input: geojson-counties-fips.json: downloaded from https://raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json

        output: geojson-counties-3109.json, geojson-counties-3109.js

    ExtractData.gms: extract data from JSON file
         input: geojson-counties-3109.json
         output: json.gdx 
        

    CountyMap.gms: run this to create a US county map.
        Input:  geojson-counties-3109.js. color-legend.js countymapsets.inc
        Output: results.js, USCountyMap.html


