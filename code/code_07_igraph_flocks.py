# this is code to treat patches as network nodes
# and overlaps as edges
# and then to find communities using igraph

import igraph as ig
import pandas as pd
import matplotlib.pyplot as plt


# read in the data
data = pd.read_csv("data/data2018/data_spatio_temporal_overlap_2018.csv")

## HERE WE MAKE NETWORKS for TIME overlap
# make network from edgelist
g = ig.Graph.TupleList(data.values,
                       weights=True, directed=False)

# find communities, this is a two step process
g_time_comm = g.community_fastgreedy(weights=data['temporal_overlap_seconds'])
time_clusters = g_time_comm.as_clustering()

## NETWORKS FOR SPACE OVERLAP
# find communities, this is a two step process
g_area_comm = g.community_fastgreedy(weights=data['spatial_overlap_area'])
area_clusters = g_area_comm.as_clustering()

# assign cluster
data['time_cluster'] = pd.Series(time_clusters.membership)
data['area_clusetr'] = pd.Series(area_clusters.membership)

# export
data.to_csv("data/data2018/data_patch_flocks_2018.csv")
