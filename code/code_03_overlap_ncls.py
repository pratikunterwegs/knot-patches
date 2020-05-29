# using ncls to get faster time overlap

import os
import pandas as pd
import numpy as np
import itertools
from ncls import NCLS
import collections
# read in the data
data = pd.read_csv("data/data2018/data_2018_patch_summary.csv")  # use good_patches for quality control
data.head()

# assign unique patch id
data['uid'] = np.arange(0, data.shape[0])

# make the ncls
ncls = NCLS(np.asarray(data.time_start),
            np.asarray(data.time_end),
            np.asarray(data.uid))

# the python way
it = ncls.find_overlap(data.iloc[1].time_start,
                       data.iloc[1].time_end)

for i in it:
    print(i)

# look at all the overlaps in time
# get a dataframe of the overlapping pairs and the extent of overlap
data_list = []
for i in np.arange():
    it = ncls.find_overlap(data.iloc[i].time_start,
                           data.iloc[i].time_end)
    # get the unique patch ids overlapping
    overlap_id = []
    overlap_extent = []
    for x in it:
        overlap_id.append(x[2])
        overlap_extent.append(min(x[1], data.iloc[i].time_end) - max(x[0], data.iloc[i].time_start))
    uid = [i] * len(overlap_id)
    tmp_data = pd.DataFrame(list(zip(uid, overlap_id, overlap_extent)),
                            columns=['uid', 'overlap_id', 'overlap_extent'])
    tmp_data = tmp_data[tmp_data.uid != tmp_data.overlap_id]
    data_list.append(tmp_data)
# wip
