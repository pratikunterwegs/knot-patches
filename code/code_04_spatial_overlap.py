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

# import helper functions
from helper_functions import simplify_geom, ckd_distance

# read in spatial data
patches = gpd.read_file("data/data2018/spatials/patches_2018.gpkg")
patches.head()
patches.crs = {'init': 'epsg:32631'}

# read in temporal overlaps
patch_overlaps = pd.read_csv("data/data2018/data_time_overlaps_patches_2018.csv")

# for each overlap uid/overlap_id get the ckd distance of
# the corresponding rows in the spatial
spatial_cross = []
for i in np.arange(len(patch_overlaps)):
    # get the geometries
    g_a = patches.iloc[patch_overlaps.iloc[i].uid]
    g_b = patches.iloc[patch_overlaps.iloc[i].overlap_id]
    covers = g_a.geometry.intersects(g_b.geometry)
    spatial_cross.append(covers)

# convert to series and add to data frame
patch_overlaps['spatial_overlap'] = pd.Series(spatial_cross)
