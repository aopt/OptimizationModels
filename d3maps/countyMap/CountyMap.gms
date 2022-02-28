$ontext

    D3 Counties Map

    erwin@amsterdamoptimization.com

    Original topography from:
       https://raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json

$offtext


*-----------------------------------------------------------------------
* read geo data
*-----------------------------------------------------------------------
sets
   FIPS     'US counties (lower 48 states)'
   County   'US county names  (lower 48 states)'
   FIPSCountyMap(FIPS<,County<) 'Mapping between FIPS code and name'
;

$include CountyMapSets.inc

option FIPS:0:0:12,County:0:0:4,FIPSCountyMap:0:0:4;
display FIPS,County,FIPSCountyMap;

*-----------------------------------------------------------------------
* quick sanity checks
*-----------------------------------------------------------------------

scalar NumCounties 'number of counties in lower 48 states';
NumCounties = card(FIPS);
display NumCounties;

abort$(card(FIPS)<>card(FIPSCountyMap)) "FIPS not unique";
abort$(card(County)<>card(FIPSCountyMap)) "County not unique";

*-----------------------------------------------------------------------
* generate random data
*-----------------------------------------------------------------------

parameter data(FIPS) 'random data';
data(FIPS) = uniform(0,100);
display data;


*-----------------------------------------------------------------------
* write solution file in js format
*-----------------------------------------------------------------------

$set resultfile results.js

file f /%resultfile%/;
put f,"solution = {"/;
loop(FIPS,
   put '  "',FIPS.tl:0,'": {';
   put 'data:',data(FIPS):0:3;
   loop(FIPSCountyMap(FIPS,county),
       put ', name:"',county.tl:0:0,'"';
   );
   put '},'/
);
putclose '};'/;



*-----------------------------------------------------------------------
* launch HTML file
*-----------------------------------------------------------------------

$set htmlfile USCountyMap.html
$set title    County-level map using random data
$set legend   Uniform U(0,100)


$libInclude win32 shellexecute  "%htmlfile%"
* for older gams systems use:
* execute 'shellexecute "%htmlfile%"';



*-----------------------------------------------------------------------
* echo HTML file
* done at compile time so we can place this big piece
* at the bottom of this .gms file
*-----------------------------------------------------------------------


$onecho > "%htmlfile%"
<!DOCTYPE html>
<html>
<head>

<style>

    path {
      stroke: black;
      stroke-width: .3px;
    }

    th,td.colorbox {
      border: 1px solid black;
    }

    td.ra {
      text-align: right;
      font-family: monospace;
    }

    div.statdiv {
      display:inline-block;
      vertical-align: top;
    }

    div.tooltip {
      position: absolute;
      text-align: left;
      width: 80px;
      height: 100px;
      padding: 2px;
      font: 12px sans-serif;
      background: rgb(17, 11, 94);
      color:aqua;
      border: 0px;
      border-radius: 8px;
      pointer-events: none;
    }

    .title {
       font-family: "Helvetica Neue", sans-serif;
       font-size: 15px;
    }

</style>


<script src="https://d3js.org/d3.v7.min.js"></script>
<script src="geojson-counties-3109.js"></script>
<script src="results.js"></script>
<script src="color-legend.js"></script>

</head>
<body>



  <h1>%title%</h1>

<script>

    var width = 960,  height = 700, margin = 20;

    var projection = d3.geoAlbersUsa().fitExtent([[margin, margin], [width-margin, height-margin]], geodata);
    var path = d3.geoPath().projection(projection);

    var svg = d3.select("body").append("svg")
        .attr("width", width)
        .attr("height", height);

    // extract data from JSON solution as array
    const arr = Object.keys(solution).map((key) => solution[key]["data"]);
    const extent = d3.extent(arr)

    var colorScale = d3.scaleSequential().interpolator(d3.interpolateViridis).domain(extent);


    // return color of county c (black if not found)
    var colorCounty = function(c) {
        var col = "black";
        if (c in solution) col = colorScale(solution[c]["data"]);
        return col;
    }

    var Tooltip = d3.select("body").append("div")
        .attr("class", "tooltip")
        .style("opacity", 0);

    var mouseover = function(e,d) {
        Tooltip.style("opacity", 1)
    }

    var tooltipHtml = function(d) {
      if (d.id in solution) {
        return solution[d.id]["name"]+"<br><hr><br>fips: " + d.id + "<br>data: "+solution[d.id]["data"];
      }

      return d.id+" not recognized";
    }

    var mousemove = function(e,d) {
        Tooltip
          .html(tooltipHtml(d))
          .style("left", (e.x+10) + "px")
          .style("top", (e.y) + "px")
    }

    var mouseleave = function(e,d) {
        Tooltip
          .style("opacity", 0)
    }

    // plot map
    svg.selectAll("path")
      .data(geodata.features)
      .enter().append("path")
      .attr("d", path)
      .style("fill", function(d) { return colorCounty(d.id); } )
      .on("mouseover", mouseover)
      .on("mousemove", mousemove)
      .on("mouseleave", mouseleave);



     svg.append("g")
        .attr("transform", "translate(580,20)")
        .append(() => Legend(colorScale, {
                  title: "%legend%"
                 }))

</script>

</body>
</html>
$offecho
