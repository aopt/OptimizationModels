US States

Files
=====

   
    cb_2020_us_state_20m.zip: shape file downloaded from https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html
    cb_2020_us_state_20m.geojson: Generated with QGIS. 5 decimals.
    cb_2020_us_state_20m.geojson.js: deleted HI,PR,AK,DC, added geodata= (all by hand)

    color-legend.js: code for drawing legend

    StateMap.gms: complete model
       inputs: cb_2020_us_state_20m.geojson.js,color-legend.js
       outputs: results.js,USStateMap.html
