# using ncls to get faster time overlap

import os
import pandas as pd
import geopandas as gpd
import numpy as np
from ncls import NCLS

print(os.getcwd())

# read in the SPATIAL data
# because the patch data has some spatials missing
# ie patches are described but not made
patches = gpd.read_file("data/data2018/spatials/patches_2018.gpkg")

# plot patches for a sanity check
# subset = patches.iloc[0:1000]
# subset.plot(linewidth=0.5,
#             column='id',
#             alpha=0.2,
#             cmap='tab20b', edgecolor='black')

# merge with identified good patches
# a uid based approach wont work because some patches have no spatials
good_patches = pd.read_csv("data/data2018/data_2018_good_patches.csv")

# id tide and patch to keep
good_patch_indicator = good_patches[['id', 'tide_number', 'patch', 'uid', 'speed']]

patches = patches.merge(good_patch_indicator, on=['id', 'tide_number', 'patch'])
patches = patches.dropna(subset=['uid'])

# write to file
patches.to_file("data/data2018/spatials/patches_2018_good.gpkg",
                layer='residence_patches', driver="GPKG")

# convert to dataframe, export, and read in again
data = pd.DataFrame(patches.drop(columns='geometry'))

# assign unique patch id
data['uid'] = np.arange(0, data.shape[0])

# overwrite data with uid
data.to_csv("data/data2018/data_2018_patch_summary_has_patches.csv",
            index=False)

# remove from memory
del patches

# re-read csv data because of integer handling differences
data = pd.read_csv("data/data2018/data_2018_patch_summary_has_patches.csv")
# get integer series of start and end times of patches
t_start = data['time_start'].astype(np.int64)
t_end = data['time_end'].astype(np.int64)
t_id = data['uid']

# trial ncls
# only works on pandas and not geopandas else throws error!
# this is very weird behaviour, pd and gpd must differ in int implementation
ncls = NCLS(t_start.values, t_end.values, t_id.values)

# look at all the overlaps in time
# get a dataframe of the overlapping pairs and the extent of overlap
data_list = []
for i in np.arange(len(t_id)):
    ncls = NCLS(t_start[i:].values, t_end[i:].values, t_id[i:].values)
    it = ncls.find_overlap(t_start[i],
                           t_end[i])
    # get the unique patch ids overlapping
    overlap_id = []
    overlap_extent = []
    # get the extent of overlap
    for x in it:
        overlap_id.append(x[2])
        overlap_extent.append(min(x[1], t_end[i]) - max(x[0], t_start[i]))
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

# NEW SECTION

# in this section, we quanitify the temporal overlap between individuals
# at the global scale, so, how long were two individuals tracked together

# read in the data again
# group by id and get the first time_start and the final time_end
data = pd.read_csv("data/data2018/data_2018_id_tracking_interval.csv")
# get integer series of start and end times of patches
t_start = data['time_start'].astype(np.int64)
t_end = data['time_end'].astype(np.int64)
t_id = data['id']

# total overlap
data_list = []
for i in np.arange(len(t_id)):
    ncls = NCLS(t_start[i:].values, t_end[i:].values, t_id[i:].values)
    it = ncls.find_overlap(t_start[i],
                           t_end[i])
    # get the unique patch ids overlapping
    overlap_id = []
    overlap_extent = []
    # get the extent of overlap
    for x in it:
        overlap_id.append(x[2])
        overlap_extent.append(min(x[1], t_end[i]) - max(x[0], t_start[i]))
    # add the overlap id for each obs
    uid = [t_id[i]] * len(overlap_id)
    # zip the tuples together
    tmp_data = list(zip(uid, overlap_id, overlap_extent))
    # convert to lists
    tmp_data = list(map(list, tmp_data))
    tmp_data = list(filter(lambda x: x[0] != x[1], tmp_data))
    # tmp_data = tmp_data[tmp_data.uid != tmp_data.overlap_id]
    data_list = data_list + tmp_data

# concatenate to dataframe
data_overlap = pd.DataFrame(data_list,
                         columns=['uid', 'overlap_id', 'total_simul_tracking'])


# write total simul tracking data
data_overlap.to_csv("data/data2018/data_2018_id_simul_tracking.csv", index=False)

# wip
