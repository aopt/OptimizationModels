Files:

    drawMap.gms: part of GAMS model that only generates the map
                 run as > gams drawMap r=solution
    solution.g00: GAMS restart file 

    CompleteModel.gms: does the whole shebang. 
                 Warning this is a large, difficult model and
                 it takes a while to solve. It is better to use
                 only drawMap.gms.

    data.inc: data file for GAMS (used by CompleteModel.gms)

    geojson-counties-fips.js: topology of US counties
         we match data.inc/geojson on id (this is FIPS code)
         This file is used by the HTML file.
         Note: this is a JSON file but turned into a JS file
         by adding: geojsonData = at the beginning.
         It is easier to include local JS files than local JSON files.

     USCountyMap.html:
         output file with map. Open in browser.
         Note: this file is generated/overwritten by running drawMap.gms or
         CompleteModel.gms.
    
    results.js: 
         output file included by USCountyMap.html.
         Note: this file is generated/overwritten by running drawMap.gms or
         CompleteModel.gms.
