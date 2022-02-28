$ontext

    D3 State Map, lower 48

    erwin@amsterdamoptimization.com

    Original topography: 
         cb_2020_us_state_20m.zip 
         shape file downloaded from 
         https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html


$offtext


*-----------------------------------------------------------------------
* states
*-----------------------------------------------------------------------
set
  id   'state code' /

       AL, AR, AZ, CA, CO, CT
       DE, FL, GA, IA, ID, IL
       IN, KS, KY, LA, MA, MD
       ME, MI, MN, MO, MS, MT
       NC, ND, NE, NH, NJ, NM
       NV, NY, OH, OK, OR, PA
       RI, SC, SD, TN, TX, UT
       VA, VT, WA, WI, WV, WY

   /;


*-----------------------------------------------------------------------
* generate random data
*-----------------------------------------------------------------------

parameter data(id) 'random data';
data(id) = uniform(0,100);
display data;


*-----------------------------------------------------------------------
* write solution file in js format
*-----------------------------------------------------------------------

$set resultfile results.js

file f /%resultfile%/;
put f,"solution = {"/;
loop(id,
   put '  "',id.tl:0,'": {';
   put 'data:',data(id):0:3;
   put '},'/
);
putclose '};'/;



*-----------------------------------------------------------------------
* launch HTML file
*-----------------------------------------------------------------------

$set htmlfile USStateMap.html
$set title    State-level map using random data
$set legend   Uniform U(0,100)


*$libInclude win32 shellexecute  "%htmlfile%"
* for older gams systems use:
execute 'shellexecute "%htmlfile%"';



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
      width: 120px;
      height: 100px;
      padding: 2px;
      font: 12px sans-serif;
      background: Orange;
      color: DarkBlue;
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
<script src="cb_2020_us_state_20m.geojson.json.js"></script>
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

    var colorScale = d3.scaleSequential().interpolator(d3.interpolateBlues).domain(extent);


    // return color of region
    var colorCounty = function(d) {
        var col = "black";

        var id = d["properties"]["STUSPS"];
        if (id in solution) {
            var data = solution[id]["data"];
            col = colorScale(data);
        }
        return col;
    }

    var Tooltip = d3.select("body").append("div")
        .attr("class", "tooltip")
        .style("opacity", 0);

    var mouseover = function(e,d) {
        Tooltip.style("opacity", 1)
    }

    var tooltipHtml = function(d) {
      var p = d["properties"];
      var id = p["STUSPS"];
      var name = p["NAME"];
      var fips = p["STATEFP"];
      var gins = p["STATENS"];
      var data = solution[id]["data"];
      var s = `${name}<br><hr><br>fips: ${fips}<br>gins: ${gins}<br>GAMS data: ${data}`;
      return s;
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
      .style("fill", function(d) { return colorCounty(d); } )
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






















































































