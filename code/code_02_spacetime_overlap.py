# code to get spatial-clusters in knot patches using ckdtree
# import custom functions and run on one tide
# using all patches not only those with good data

import os
import pandas as pd
import numpy as np
import itertools
from interval_tree import IntervalTree
import collections
# read in the data
data = pd.read_csv("data/data2018/data_2018_patch_summary.csv")  # use good_patches for quality control
data.head()

# assign unique patch id
data['uid'] = np.arange(0, data.shape[0])

# make an interval tree
feature_list = []
for index, rows in data.iterrows():
    a_list = [rows.time_start, rows.time_end, rows.uid]
    feature_list.append(a_list)

# needs max and min time
min_time = min(data.time_start)
max_time = max(data.time_end)

# make the tree
tree = IntervalTree(feature_list, min_time, max_time)

# get the data of overlapping pairs
data_list = []
for i in np.arange(0, 10):
    pairs = [element for element in
                     tree.find_range([feature_list[i][0], feature_list[i][1]])
                     if element not in [i]]
    uid_list = [i] * len(pairs)
    pair_list = list(zip(uid_list, pairs))
    data_list = data_list + pair_list

# keep only unique pairs accounting for pair order
ctr = collections.Counter(map(frozenset, data_list))
# this lambda counts the number of frozen sets, which do not care for order
data_list = list(filter(lambda x: (ctr[frozenset(x)] == 1 for x in data_list), data_list))

# concat the list of data to get the overlapping unique pairs
data_overlap = pd.DataFrame(data_list,
                            columns=['uid', 'overlap'])


# ends here
