# import classic python libs
import numpy as np

# libs for dataframes
import pandas as pd

# import ckdtree
from scipy.spatial import cKDTree
from shapely.geometry import Point, MultiPoint, LineString, MultiLineString, Polygon, MultiPolygon

# import ckdtree
from scipy.spatial import cKDTree


def round_any(value, limit):
    return round(value/limit)*limit


# function to simplify multilinestrings and maybe multipolygons
def simplify_geom(complex_geometry):
    simple_geom = []
    for i in range(len(complex_geometry.geometry)):
        feature = complex_geometry.geometry.iloc[i]

        if feature.geom_type == "Polygon":
            simple_geom.append(feature)
        elif feature.geom_type == "MultiPolygon":
            for geom_level2 in feature:
                simple_geom.append(geom_level2)
    return simple_geom


# function to use ckdtrees for nearest point finding
def ckd_distance(gdf_a, gdf_b):
    simplified_a = simplify_geom(gdf_a)
    A = np.concatenate(
        [np.array(geom.coords) for geom in simplified_a])
    simplified_b = simplify_geom(gdf_b)

    B = np.concatenate([np.array(geom.coords) for geom in simplified_b])
    ckd_tree = cKDTree(A)
    dist, idx = ckd_tree.query(B, k=1)
    return dist


# function to use ckdtrees for nearest point finding
def make_patch_pairs(patch_data, dist_indep):
    coords = patch_data[['x_mean', 'y_mean']]
    coords = np.asarray(coords)
    ckd_tree = cKDTree(coords)
    pairs = ckd_tree.query_pairs(r=dist_indep, output_type='ndarray')
    return pairs


# make modules from patch data
# function to process ckd_pairs
def make_patch_modules(patch_data, scale):
    # assign a unique id per dataframe
    patch_data['within_tide_id'] = np.arange(len(patch_data))
    patch_pairs = make_patch_pairs(patch_data=patch_data, dist_indep=scale)
    if len(patch_pairs) > 1:
        patch_pairs = pd.DataFrame(data=patch_pairs, columns=['p1', 'p2'])
        # get unique patch ids
        unique_patches = np.concatenate((patch_pairs.p1.unique(), patch_pairs.p2.unique()))
        unique_patches = np.unique(unique_patches)
        # make network
        network = nx.from_pandas_edgelist(patch_pairs, 'p1', 'p2')
        # get modules
        modules = list(nx.algorithms.community.greedy_modularity_communities(network))
        # get modules as df
        m = []
        for i in np.arange(len(modules)):
            module_number = [i] * len(modules[i])
            module_coords = list(modules[i])
            m = m + list(zip(module_number, module_coords))
        # add location, bird and tide
        aux_data = patch_data[patch_data.within_tide_id.isin(unique_patches)][
            ['id', 'tide_number', 'patch', 'within_tide_id', 'time_scale',
             'time_chunk']]
        module_data = pd.DataFrame(m, columns=['module', 'within_tide_id'])
        module_data = pd.merge(module_data, aux_data, on='within_tide_id')
        # add scale
        module_data['spatial_scale'] = scale
        return module_data
    else:
        return None

# ends here
