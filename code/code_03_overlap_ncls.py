# using ncls to get faster time overlap

import os
import pandas as pd
import numpy as np
import itertools
from ncls import NCLS
import collections

print(os.getcwd())

# read in the data
data = pd.read_csv("data/data2018/data_2018_patch_summary.csv")  # use good_patches for quality control
data.head()

# assign unique patch id
data['uid'] = np.arange(0, data.shape[0])

# overwrite data with uid
data.to_csv("data/data2018/data_2018_patch_summary.csv",
            index=False)

# convert data to int
data['time_start'] = data['time_start'].astype(np.int64)
data['time_end'] = data['time_end'].astype(np.int64)

# trial ncls
ncls = NCLS(np.asarray(data[0:].time_start),
                np.asarray(data[0:].time_end),
                np.asarray(data[0:].uid))

# look at all the overlaps in time
# get a dataframe of the overlapping pairs and the extent of overlap
data_list = []
for i in np.arange(len(data)):
    ncls = NCLS(np.asarray(data[i:].time_start),
                np.asarray(data[i:].time_end),
                np.asarray(data[i:].uid))
    it = ncls.find_overlap(data.iloc[i].time_start,
                           data.iloc[i].time_end)
    # get the unique patch ids overlapping
    overlap_id = []
    overlap_extent = []
    # get the extent of overlap
    for x in it:
        overlap_id.append(x[2])
        overlap_extent.append(min(x[1], data.iloc[i].time_end) - max(x[0], data.iloc[i].time_start))
    # add the overlap id for each obs
    uid = [i] * len(overlap_id)
    # zip the tuples together
    tmp_data = list(zip(uid, overlap_id, overlap_extent))
    # convert to lists
    tmp_data = list(map(list, tmp_data))
    tmp_data = list(filter(lambda x: x[0] != x[1], tmp_data))
    # tmp_data = tmp_data[tmp_data.uid != tmp_data.overlap_id]
    data_list = data_list + tmp_data

# concatenate to dataframe
data_overlap = pd.DataFrame(data_list,
                         columns=['uid', 'overlap_id', 'overlap_extent'])

# save data
data_overlap.to_csv("data/data2018/data_time_overlaps_patches_2018.csv", index=False)
# wip
