European NUTS2 regions using Eurostat geo data.


Data from: https://ec.europa.eu/eurostat/web/gisco/geodata/reference-data/administrative-units-statistical-units/nuts

Files
-----


    geodata.gms
         remove (French) islands and NUTS levels other than 2
         input:  nuts.geojson
         output: nuts2.geojson, nuts2.geojson.js
         

    drawmap.gms
          create HTML map
          input: guts.geojson.js, color-legend.js
          output: results.js, Map.html 
     