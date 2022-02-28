$ontext

    D3 State Map, lower 48
    Generates a self-contained HTML file (i.e. no dependencies) 

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
* names
*-----------------------------------------------------------------------

$set d3           d3.v7.min.js 
$set geojson      cb_2020_us_state_20m.geojson 
$set title        State-level map using random GAMS data
$set legend       Data drawn from U(0,100) 
$set html         USStateMap.html
$set colorlegend  color-legend.js
$set template     template.html

*-----------------------------------------------------------------------
* download D3
*-----------------------------------------------------------------------

$if not exist %d3% $call 'curl -O https://d3js.org/%d3%'

*-----------------------------------------------------------------------
* generate HTML file
*-----------------------------------------------------------------------


EmbeddedCode Python:
print("\n >> HTML Generator")

import json

# parameter data(id)
data = {}
for rec in gams.get('data'):
    data[rec[0]] = rec[1]
datas = json.dumps(data) 

def ffetch(fln):
  '''
     Fetch content of local file
  '''
  with open(fln) as f:
    return f.read()


replace = {
  "&d3lib&"       :  ffetch("%d3%"),
  "&geojson&"     :  ffetch("%geojson%"),
  "&data&"        :  datas,
  "&legendjs&"    :  ffetch("%colorlegend%"),
  "&title&"       :  "%title%",
  "&legendtitle&" :  "%legend%"
}

print(" >>   reading '%template%'")
template = ffetch("%template%")


import re
class StringReplacer:
    '''
      replace substrings using regular expression 
      inspired by answers on stackoverflow
    '''

    def __init__(self, replacements):
        patterns = sorted(replacements, key=len, reverse=True)
        self.replacements = [replacements[k] for k in patterns]
        self.pattern = re.compile('|'.join(("({})".format(p) for p in patterns)))
        def tr(matcher):
            index = next((index for index,value in enumerate(matcher.groups()) if value), None)
            return self.replacements[index]
        self.tr = tr

    def __call__(self, string):
        return self.pattern.sub(self.tr, string)


print(f" >>   replacing strings {list(replace.keys())}")
repl = StringReplacer(replace)
htmls = repl(template)

print(" >>   writing '%html%'")
with open("%html%","w") as f:
    f.write(htmls)

endEmbeddedCode



*-----------------------------------------------------------------------
* launch HTML file
*-----------------------------------------------------------------------


*$libInclude win32 shellexecute  "%htmlfile%"
* for older gams systems use:
execute 'shellexecute "%html%"';











































































