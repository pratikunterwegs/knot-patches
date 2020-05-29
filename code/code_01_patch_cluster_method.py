# code to get spatial-clusters in knot patches using ckdtree
# import custom functions and run on one tide
# using all patches not only those with good data

import os
import pandas as pd
import numpy as np
import itertools
from helper_functions import make_patch_modules, round_any

# read in the data
data = pd.read_csv("data/data_2018_good_patches.csv")  # use good_patches for quality control
data.head()
# look at one tidal cycle, first count patches per tide
pd.value_counts(data['tide_number'])
# choose the highest
# data = data[data['tide_number'] == 73]

# assign rounded values of time rather than tide number
# do this in a list
time_scale = [1, 3, 6, 12]

data_list = []
# what is the min of time
min_time = data.time_mean.min()/3600
for i in np.arange(len(time_scale)):
    tmp_data = data
    tmp_data['round_time'] = round_any((tmp_data['time_mean']/3600) - min_time,
                                       time_scale[i])
    tmp_data['time_scale'] = time_scale[i]
    data_list.append([pd.DataFrame(y) for x, y in
                      tmp_data.groupby('round_time',
                                       as_index=False)])

# add time chunk
for i in np.arange(len(data_list)):
    for j in np.arange(len(data_list[i])):
        data_list[i][j]['time_chunk'] = j

# flatten this list, time_scale is stored in each df
data_list = list(itertools.chain(*data_list))

# remove lists with single patch
data_list = [df for df in data_list if len(df) > 1]

# now get modules over spatial scales
# there are 4 list elements of temporal scale
# times 4 spatial scales
# run over spatial scales 100, 250, 500, 1000
spatial_scales = [50, 100, 250, 500]
ml_list = list(map(lambda x:
                   list(map(make_patch_modules, data_list, [x]*len(data_list))),
                   spatial_scales))


# flatten module list
ml_list = list(itertools.chain(*ml_list))
ml_list2 = [i for i in ml_list if i is not None]

# concatenate data
ml_data = pd.concat(ml_list2)

# write to file
ml_data.to_csv(index=False, path_or_buf="data/data_2018_patch_modules_small_scale.csv")