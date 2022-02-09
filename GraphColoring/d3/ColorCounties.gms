$ontext

  Standard Graph Coloring Model

  Color map with US counties

  Files:
      ColorCounties.gms (this file)
      data.inc
      geojson-counties-fips.js

$offtext


*---------------------------------------------------------------
* data
*---------------------------------------------------------------

sets
   n      'nodes: counties (fips code)'
   a(n,n) 'arcs: adjacency -- upper-triangular part only'
   c      'colors' /
               col1  '#96CEB4'
               col2  '#FFEEAD'
               col3  '#D9534F'
               col4  '#FFAD60'
               col5  '#2C3333'
             /
   county 'county names'
   map(n,county<)
;

$include data.inc

* fix data wrt Glades County, FL
* set one of these to "no"
a('12043','12085') = no;
*a('12043','12099') = no;

scalar numCounties 'number of counties in map';
numCounties = card(n);
display numCounties;

alias(n,i,j);

*---------------------------------------------------------------
* data checks
*---------------------------------------------------------------

abort$(card(map)<>numCounties) "check map";
abort$sum(a(i,j)$(ord(i)>=ord(j)),1) "a(i,j) is not strictly upper-triangular";

*---------------------------------------------------------------
* optimization model: minimize number of colors needed
*---------------------------------------------------------------

binary variables
   x(n,c) 'assign color to node'
   u(c)   'color is used'
;

variable
   numColors 'number of colors needed'
;

equations
   objective            'minimize number of colors used'
   assign(n)            'every node should have exactly one color'
   notSameColor(i,j,c)  'adjacent vertices cannot have the same color'
   order(c)             'ordering constraint (optional)'
;

objective..  numColors =e= sum(c, u(c));

assign(n)..  sum(c, x(n,c)) =e= 1;

notSameColor(a(i,j),c).. x(i,c)+x(j,c) =l= u(c);

order(c-1).. u(c) =l= u(c-1);


model color /all/;
option optcr=0, threads=16;
solve color minimizing numColors using mip;

display x.l,u.l,numColors.l;

parameter colcount(c) 'number of counties with given color';
colcount(c) = sum(n$(x.l(n,c)>0.5), 1);
display colcount;


*---------------------------------------------------------------
* export results
*---------------------------------------------------------------


file f /results.js/;

* write color and name of each county
put f,'solution = {'/;
loop(n,
   put '  "',n.tl:0,'": {';
   loop(c$(x.l(n,c)>0.5),
        put 'color:"',c.te(c):0:0,'", colorno:',ord(c):0:0;
   );
   loop(map(n,county),
       put ', name:"',county.tl:0:0,'"';
   );
   put '},'/
);
put '};'/;

* content of HTML tables with statistics
put 'htmltable = "<table>"'/;
put '+"<tr><th colspan=2>Model Statistics</th></tr>"'/;
put '+"<tr><td>Number of counties</td><td class=ra>',(card(n)):0:0,'</td></tr>"'/;
put '+"<tr><td>Decision variables</td><td class=ra>',(color.numvar):0:0,'</td></tr>"';
put '+"<tr><td>&nbsp;&nbsp;&nbsp;Discrete variables</td><td class=ra>',(color.numdvar):0:0,'</td></tr>"'/;
put '+"<tr><td>Constraints</td><td class=ra>',(color.numequ):0:0,'</td></tr>"'/;
put '+"<tr><td>Solution time (seconds)</td><td class=ra>',(color.resusd):0:0,'</td></tr>"'/;
put '+"<tr><td>Nodes</td><td class=ra>',(color.nodusd):0:0,'</td></tr>"'/;
put '+"<tr><td>Iterations</td><td class=ra>',(color.iterusd):0:0,'</td></tr>"'/;
put '+"</table>";'/;

put 'htmltable2 = "<table style=\"margin-left:50px\">"'/;
put '+"<tr><th colspan=2>Color Count</th></tr>"'/;
loop(c$colcount(c),
   put '+"<tr><td class=colorbox style=\"background-color:',c.te(c):0:0,'\" width=\"50%\"></td>';
   put '<td class=ra>',colcount(c):0:0,'</td></tr>"'/;
);
put '+"<tr><td>Total</td><td class=ra>',(sum(c,colcount(c))):0:0,'</td></tr>"'/;
put '+"</table>";'/;


*---------------------------------------------------------------
* HTML report
*---------------------------------------------------------------

$set htmlfile USCountyMap.html

*$libInclude win32 shellexecute  "%htmlfile%"
* for older gams systems use:
execute 'shellexecute "%htmlfile%"';


$onecho > "%htmlfile%"
<!DOCTYPE html>
<html>
<head>
<meta charset="cp437">

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

</style>


<script src="https://d3js.org/d3.v7.min.js"></script>

<script src="geojson-counties-fips.js"></script>
<script src="results.js"></script>

</head>
<body>

  <h1>Coloring a map of US counties with four colors</h1>

<script>

    var width = 960,  height = 700, margin = 20;

    var projection = d3.geoAlbersUsa().fitExtent([[margin, margin], [width-margin, height-margin]], geojsonData);
    var path = d3.geoPath().projection(projection);

    var svg = d3.select("body").append("svg")
        .attr("width", width)
        .attr("height", height);

    // return color of county c (black if not found)
    var colorCounty = function(c) {
        col = "black";
        if (c in solution) col = solution[c].color;
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
        return solution[d.id]["name"]+"<br><hr><br>fips: " + d.id + "<br>color: "+solution[d.id]["colorno"];
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
      .data(geojsonData.features)
      .enter().append("path")
      .attr("d", path)
      .style("fill", function(d) { return colorCounty(d.id); } )
      .on("mouseover", mouseover)
      .on("mousemove", mousemove)
      .on("mouseleave", mouseleave);


    // display tables with statistics
    d3.select("body").append("div").attr("class","statdiv").html(htmltable)
    d3.select("body").append("div").attr("class","statdiv").html(htmltable2)


</script>

</body>
</html>
$offecho


