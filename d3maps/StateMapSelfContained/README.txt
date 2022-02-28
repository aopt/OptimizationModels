US States as self-contained HTML (no dependencies on files or URLs)

Files
=====

   
    cb_2020_us_state_20m.zip: shape file downloaded from https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html
    cb_2020_us_state_20m.geojson: Generated with QGIS. 5 decimals. deleted HI,PR,AK,DC 

    color-legend.js: code for drawing legend

    StateMap.gms: complete model
       inputs: cb_2020_us_state_20m.geojson,color-legend.js
       outputs: USStateMap.html
