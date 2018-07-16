
# Methods

## Knot capture and tracking **Direct from my imagination**

We captured xx Red Knots *Calidris canutus islandica*, hereafter knots, on the island of Griend (coordinates here) in the Dutch Wadden Sea (Fig. 1a) on the nights of 20 -- 23 August, 2017, using previously/well established mist-netting techniques for nocturnally foraging waders [^1].
We took body mass and the following morphometric measurements of each individual: *some measurements here: wing length, tarsus length, bill length*. We chose a subset of yy knots based on *some criteria here, body mass* were chosen to be fitted with radio transmitter tags (*manufacturer, place, mass in g, % of mean knot mass*).

We attached tags to the dorsal surface of each individual using a safe but strong glue (*manufacturer, place, exact active composition*; Fig. 1b). Tags were programmed to transmit a unique signal at a frequency of 1 Hz. These signals were received by a network of xx receivers (Fig. 1a, 1c), and the position of the tag was calculated based on the time of arrival of the signal [see **reference** for details on ToA tracking]. The receiver network reported tag positions along with the position timestamp, variance in the X and Y coordinates, and the covariance of the coordinates.

**real work from here**

The study period lasted 24 August -- 31 October, when we removed the radio receivers to avoid storm damage over the winter.
We retrieved knot position data at the end of the study period, and filtered it to include only the first 30 tracking days (24 August -- 23 September) to reduce computation load. We averaged individual positions to the nearest minute to further ease computation. Thus we obtained on average xx positions (range: yy -- zz) over a mean xx days (range: yy -- zz) for xx knots, with a mean position interval of xx minutes (range: yy -- zz).

## Tidal period and data filtering

To place our analyses in the context of the tidal cycle, we obtained sea level measurements at one minute intervals from Harlingen (*coordinates here*, Fig. 1a, *data provider name*, **citation_if_possible**), xx km from Griend, over the period 24 August -- 23 September, and calculated high and low tide times. We defined a tidal period as the time between consecutive high tides, and assigned the tidal period to each observation in the tracking data. Our data spanned 59 tidal periods with a mean duration of xx hours (range: yy -- zz).

We identified the number of 1 minute positions expected from knots in each tidal period (the duration of the tidal period in minutes), and calculated the ratio of observed to expected positions. We then filtered the tracking data to include only those knots that had an observed:expected ratio ≥ 0.3 per tidal period, and then selected only those tidal periods in which > 5 knots had been included. As a result, we obtained 36 tidal periods from xx August -- xx September, with an average of xx knots (range: xx -- yy; after filtering) observed in each tidal period.

## Track segmentation and interaction scores

For each track in each tidal period, we calculated the first passage time [**cite**] for a radius of 250 m, and then filtered out points with an FPT250 of < 10 minutes, reasoning  that these points did not comprise foraging behaviour [**cite some papers, see the tide simulation setup at NIOZ**]. We segmented the remainder of each track based on the FPT250[^2] using the Lavielle method [**cite**], allowing for a minimum segment length of 10 points [^3], and a maximum of 40 segments in each track. Following this, we corrected for potential over-segmentation, i.e., spatially proximate track points classified into different segments, by merging consecutive segments whose midpoints were < 250 m apart[^4].  This resulted in an average of xx segments (range: yy -- zz, n = zz) per track per tidal period.

For each knot within each tidal period, which we now refer to as the focal bird, we calculated the distance matrix between its median segment positions and the median segment positions of every other bird in turn (from here, non-focal birds), and checked whether focal bird and non-focal bird segments overlapped in time. We then obtained the number of foraging segments in which the focal and non-focal birds overlapped in space and time, which we interpreted as association, by counting the number of cells in each focal -- non-focal distance matrix that had a distance < 250 m, and which overlapped in time, thus obtaining an association matrix for each tidal period.

To test whether knot association is different from that expected by chance, we simulated a random associaton matrix for each tidal period by random permutation of the row order of the empirical matrix without replacement 100 times, and averaging the resultant 100 simulated matrices.

## Testing association strength

We then calculated the Wilkinson coherence score [**cite**] for each focal -- non-focal pair from the empirical association matrix of each tidal period as in [**cite myers_space_1983**], and did the same for the simulated association matrix. We then compared empirical pairwise coherence scores pooled over the tidal periods (i.e., the full tracking period) to simulated coherence scores using a two-sample Kolmogorov Smirnov test (**cite**).

All method were implented in the R (**cite**) statistical environment using the following packages:
*VulnToolkit* to find high tide times, *recurse* to find first passage time, and *segclust2d* for Lavielle segmentation.

[^1]: Caught during foraging or at high tide roosts ?
[^2]: adehabitatLT has 3 options here, what is `segclust2d` doing?
[^3]: Might want to think this over and reduce it.
[^4]: Rethink this, sum the knot distance, not displacement between the midpoint of consecutive segments. If the knot flies away and returns to a nearby point, is that a new segment?
