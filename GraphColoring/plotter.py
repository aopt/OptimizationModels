#
# Coloring a map with all US counties
#
# This is a visualization of the output of the graph coloring model ColorCounties.gms.

from urllib.request import urlopen
import json
# next ones need to be installed
import pandas as pd
import plotly.express as px


#
# retrieve geojson file with county info
#
with urlopen('https://raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json') as response:
    counties = json.load(response)

#
# import the csv file with results from the GAMS model
#
df = pd.read_csv("mapcolors.csv",dtype={"id": str,"color":str,"county":str},encoding='cp437')

#
# plot the counties with our colors
#

fig = px.choropleth(df, geojson=counties, locations='id', color='color',
                           scope="usa", color_discrete_sequence=px.colors.qualitative.Set3,
                           hover_name="county",hover_data=["id","color"]
                          )
fig.update_layout(margin={"r":0,"t":0,"l":0,"b":0})
fig.show()
