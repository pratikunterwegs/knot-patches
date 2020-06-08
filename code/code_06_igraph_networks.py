# this is code to treat individuals as network nodes
# and overlaps as edges
# and then to find communities using igraph

import igraph as ig
import cairo
import pandas as pd
import matplotlib.pyplot as plt


# read in the data
data = pd.read_csv("data/data2018/data_id_overlap_2018.csv")
# read in the simultaneous tracking data
data_simul_tracking = pd.read_csv("data/data2018/data_2018_id_simul_tracking.csv")

# scale overlap by simultaneous tracking after merging
data = data.merge(data_simul_tracking, left_on=['id.x', 'id.y'],
           right_on=['uid', 'overlap_id'])
data['total_time_overlap'] = data['total_time_overlap']/data['total_time_overlap']
data['total_area_overlap'] = data['total_area_overlap']/data['total_time_overlap']


## HERE WE MAKE NETWORKS for TIME overlap
# make network from edgelist
g = ig.Graph.TupleList(data.values,
                       weights=True, directed=False)

# find communities, this is a two step process
g_time_comm = g.community_fastgreedy(weights=data['total_time_overlap'])
time_clusters = g_time_comm.as_clustering()

# Set edge weights based on communities
weights = {v: len(c) for c in time_clusters for v in c}
g.es["weight"] = [weights[e.tuple[0]] + weights[e.tuple[1]] for e in g.es]

# Choose the layout
visual_style = {}
visual_style["layout"] = g.layout_kamada_kawai()

# Plot the graph
a = ig.plot(time_clusters, **visual_style)
a.show()

## HERE WE MAKE NETWORKS for SPACE overlap
# find communities, this is a two step process
g_area_comm = g.community_fastgreedy(weights=data['total_area_overlap'])
area_clusters = g_area_comm.as_clustering()

# Set edge weights based on communities
weights = {v: len(c) for c in area_clusters for v in c}
g.es["weight"] = [weights[e.tuple[0]] + weights[e.tuple[1]] for e in g.es]

# Choose the layout
visual_style = {}
visual_style["layout"] = g.layout_kamada_kawai()

# Plot the graph
b = ig.plot(area_clusters, **visual_style)
b.show()
