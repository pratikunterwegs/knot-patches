# this is code to treat individuals as network nodes
# and overlaps as edges
# and then to find communities

import networkx as nx
from networkx.algorithms.community import greedy_modularity_communities
import pandas as pd
import matplotlib.pyplot as plt


# read in the data
data = pd.read_csv("data/data2018/data_id_overlap_2018.csv")


# make network from edgelist
g = nx.from_pandas_edgelist(data,
                            source='id.x',
                            target='id.y',
                            edge_attr= ['total_time_overlap',
                                        'total_area_overlap'])

# make circular layout
pos = nx.spring_layout(g)
nx.draw(g, node_color='black',
        pos = pos,
        node_size=10,
        edge_color=data['total_time_overlap'], width=0.2,
        edge_cmap=plt.cm.viridis)

cl = list(greedy_modularity_communities(g))
nx.draw(cl)