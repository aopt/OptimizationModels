$ontext

    D3 State Map, lower 48

    erwin@amsterdamoptimization.com

    Original topography from:


$offtext


*-----------------------------------------------------------------------
* states
*-----------------------------------------------------------------------
set id 'nuts2' /

     AL01,AL02,AL03,AT11,AT12,AT13,AT21,AT22,AT31,AT32,AT33,AT34,BE10
     BE21,BE22,BE23,BE24,BE25,BE31,BE32,BE33,BE34,BE35,BG31,BG32,BG33
     BG34,BG41,BG42,CH01,CH02,CH03,CH04,CH05,CH06,CH07,CY00,CZ01,CZ02
     CZ03,CZ04,CZ05,CZ06,CZ07,CZ08,DE11,DE12,DE13,DE14,DE21,DE22,DE23
     DE24,DE25,DE26,DE27,DE30,DE40,DE50,DE60,DE71,DE72,DE73,DE80,DE91
     DE92,DE93,DE94,DEA1,DEA2,DEA3,DEA4,DEA5,DEB1,DEB2,DEB3,DEC0,DED2
     DED4,DED5,DEE0,DEF0,DEG0,DK01,DK02,DK03,DK04,DK05,EE00,EL30,EL41
     EL42,EL43,EL51,EL52,EL53,EL54,EL61,EL62,EL63,EL64,EL65,ES11,ES12
     ES13,ES21,ES22,ES23,ES24,ES30,ES41,ES42,ES43,ES51,ES52,ES53,ES61
     ES62,ES63,ES64,FI19,FI1B,FI1C,FI1D,FI20,FR10,FRB0,FRC1,FRC2,FRD1
     FRD2,FRE1,FRE2,FRF1,FRF2,FRF3,FRG0,FRH0,FRI1,FRI2,FRI3,FRJ1,FRJ2
     FRK1,FRK2,FRL0,FRM0,HR02,HR03,HR05,HR06,HU11,HU12,HU21,HU22,HU23
     HU31,HU32,HU33,IE04,IE05,IE06,IS00,ITC1,ITC2,ITC3,ITC4,ITF1,ITF2
     ITF3,ITF4,ITF5,ITF6,ITG1,ITG2,ITH1,ITH2,ITH3,ITH4,ITH5,ITI1,ITI2
     ITI3,ITI4,LI00,LT01,LT02,LU00,LV00,ME00,MK00,MT00,NL11,NL12,NL13
     NL21,NL22,NL23,NL31,NL32,NL33,NL34,NL41,NL42,NO02,NO06,NO07,NO08
     NO09,NO0A,PL21,PL22,PL41,PL42,PL43,PL51,PL52,PL61,PL62,PL63,PL71
     PL72,PL81,PL82,PL84,PL91,PL92,PT11,PT15,PT16,PT17,PT18,RO11,RO12
     RO21,RO22,RO31,RO32,RO41,RO42,RS11,RS12,RS21,RS22,SE11,SE12,SE21
     SE22,SE23,SE31,SE32,SE33,SI03,SI04,SK01,SK02,SK03,SK04,TR10,TR21
     TR22,TR31,TR32,TR33,TR41,TR42,TR51,TR52,TR61,TR62,TR63,TR71,TR72
     TR81,TR82,TR83,TR90,TRA1,TRA2,TRB1,TRB2,TRC1,TRC2,TRC3,UKC1,UKC2
     UKD1,UKD3,UKD4,UKD6,UKD7,UKE1,UKE2,UKE3,UKE4,UKF1,UKF2,UKF3,UKG1
     UKG2,UKG3,UKH1,UKH2,UKH3,UKI3,UKI4,UKI5,UKI6,UKI7,UKJ1,UKJ2,UKJ3
     UKJ4,UKK1,UKK2,UKK3,UKK4,UKL1,UKL2,UKM5,UKM6,UKM7,UKM8,UKM9,UKN0

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

$set htmlfile Map.html
$set title    NUTS2 regions
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
<script src="https://d3js.org/d3-geo-projection.v4.min.js"></script>
<script src="nuts2.geojson.js"></script>
<script src="results.js"></script>
<script src="color-legend.js"></script>



</head>
<body>



  <h1>%title%</h1>

<script>

    var width = 960,  height = 700, margin = 20;

     var projection = d3.geoConicEquidistant().fitExtent([[margin, margin], [width-margin, height-margin]], geodata);
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
        var col = "white";

        var id = d["properties"]["NUTS_ID"];
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
      var id = p["NUTS_ID"];
      var name = p["NAME_LATN"];
      var data = solution[id]["data"];
      var s = `${id}<br><hr><br>${name}<br>GAMS data: ${data}`;
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






















































































