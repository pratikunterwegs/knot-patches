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
g_comm = g.community_fastgreedy()
clusters = g_comm.as_clustering()

# assign cluster
data['flock'] = pd.Series(clusters.membership)

# export
data.to_csv("data/data2018/data_patch_flocks_2018.csv")
