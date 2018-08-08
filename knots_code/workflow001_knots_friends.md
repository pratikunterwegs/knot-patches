# Workflow for knots friends

## Getting data

Get raw data from the knots using _knotscode001_getdata.rmd_. Use _knotscode002_knots01.rmd_ to export all data -- knots batch 01, 02, and sanderlings 2017 -- as an _.rdata_ file.
_knotscode002_knots01.rmd_ also has graphics to visualise data per id.

## FPT and residence metrics

### Preparing data for *recurse*

Run _knotscode003_recursion.rmd_ for 1-minute FPT and residence metrics between 2017-08-24 and 2017-09-23. FPT and residence are run only on ids which have > 30% of expected positions, and appear in ≥ 5 tides, and on tides with ≥ 5 individuals (which must also appear in 5 or more tides). Code has a graphic for visualisation. Saves recursion analysis output by id as _.csv_ files.

### Retrieving *recurse* data

Run _knotscode020_lavielle_segments.rmd_ to handle individual recursion analyses -- gather recurse _.csv_ files, bind them to the raw data, filter for presumed foraging patches, and Lavielle segment each track in each tidal period using the _segclust2d_ package.

Run _knots_code019_segment_reorder_and_distance_matrix.rmd_ to merge spatially proximate segments -- an example is plotted. Then get the foraging segment summaries for each id in each tidal period.
Convert to a list structure with names. Prepare a list to hold proximity data. Create the interaction matrix conditioned on the cell values of the distance matrix and the temporal overlap. Convert to a df with a pairwise structure with the focal and non-focal individual, and the tide and number of interactions. Save as _.rdata_.

## Coherence scores

Run _knotscode021_randomise_distance_matrix.rmd_ to determine which birds are present -- i.e., number of segments per tide -- in each tide to fill the interaction matrix from above with true absence of interaction data (zeroes), and setting missing data as NA. Add this data to the pairwise interaction df to determine the coherence score. Randomise the coherence matrix save as _.rdata_ file.

Run _knotscode022_coherence_stats.rmd_ to test the empirical and simulated pairwise coherence scores using Kolmogorov-Smirnov tests.

# Using higher frequency data
