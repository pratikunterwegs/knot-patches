# import classic python libs
import numpy as np

# libs for dataframes
import pandas as pd
import geopandas as gpd

# import ckdtree
from scipy.spatial import cKDTree
from shapely.geometry import Point, MultiPoint, LineString, MultiLineString, Polygon, MultiPolygon

# import ckdtree
from scipy.spatial import cKDTree

# read in data
patches = gpd.read_file("data/data2018/spatials/patches_2018.gpkg")
patches.head()
patches.crs = {'init': 'epsg:32631'}
# reproject
unique_locs.crs = {'init' :'epsg:4326'}

# reproject spatials to 43n epsg 32643

roads = roads.to_crs({'init': 'epsg:32643'})