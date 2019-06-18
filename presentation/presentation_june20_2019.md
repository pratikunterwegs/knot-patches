Half-yearly progress meeting
===
author: Pratik Gupte
date: 20th June, 2019
autosize: false
width: 1440
height: 900
font-family: 'IBM Plex Serif'

Structure
===
type: sub-section

- **Summary**

- **Coursework + conferences**

- **Projects + master's students**

- **Planned projects + outcomes**

Summary
===

- 28% of PhD duration

- 16 + 2 ECTS (60%)
  
  - 1 ongoing course (10 EC), 1 planned (5 EC)
  - 2 + 1 conferences


- 4 + 1 projects
- 2 master's students

Coursework
===

**Completed**

- C++ for Biologists
- Consumer-Resource Interactions
- Scientific Integrity

**Ongoing and planned**

- Mathematical Models in Ecology & Evolution --- ongoing
- Practical Modelling for Biologists --- Jan 2020

**Estimated date for 30 EC** --- February 2020 (~50% of PhD)

Conferences
===

- 1st Biomove Symposium

- 3rd Gordon Research Conference on Movement Ecology of Animals

- 1st Gordon Research Seminar on Movement Ecology of Animals

Projects
===

**Ongoing**
>
- Modelling
  1. Evolution of movement in fluctuating landscapes
  2. Evolution of movement with competition

>
- Empirical
  3. Exploring movement consistency across scales

***
  
**Proposed**

1. Evolution of migration traditions

**Side project

Evolution of movement in fluctuating landscapes
===
type:sub-section

*with L. Boullosa, C. Netz, H. Hildenbrandt & F. Weissing*

- 

- 

Master's student progress
===
*co-supervised with C. Netz and F. Weissing*

- Start date --- January
- Expected end date --- July
- Mid-term evaluation --- none
- Expected EC --- ??

*Probability of manuscript in 2019* ≈ 20%, *in 2020* ≈ 70% 

Evolution of movement with competition
===
type: sub-section

*with M. Pederboni, C. Netz & F. Weissing*

Master's student progress
===
*co-supervised with C. Netz and F. Weissing*

- Start date --- February
- Expected end date --- September
- Mid-term evaluation -- next week (June)
- Expected EC --- 30 ?.

*Probability of manuscript in 2019* ≈ 10%, *in 2020* ≈ 70%

Exploring movement consistency in red knots
===
type: sub-section

*with S. Ersoy & A. Bijleveld*

How does space-use in red knots change within and between tidal cycles?

Are individuals consistent in their movement behaviour across scales?

Cleaning movement data
===

- Issue: tags transmitting before release
- Solution: remove fixes before release + 24 hrs

<img src="/home/pratik/projects/redknotMoveWaddensea/figs/figTimeTagRelease.png" title="plot of chunk tags_before_release" alt="plot of chunk tags_before_release" width="60%" />

Calculating residence time
===
- Residence time at a focal point = total time spent within 
  - 50m buffer of the focal point

- Here:
  - res time = $(t_{in} - t_{out})$
  
***

<img src="/home/pratik/projects/redknotMoveWaddensea/presentation/figSchematicResidence.png" title="plot of chunk restime_scheme" alt="plot of chunk restime_scheme" width="60%" />

Manual track segmentation
===
- Criterion: residence time > 2 minutes?

- TRUE; classify as residence point

- FALSE; classify as non-residence point

- Performs better than more complex alogrithms (eg. Patin et al. 2018)

Comparing segmentation methods
===

<img src="/home/pratik/projects/redknotMoveWaddensea/presentation/figRawDataSegmentation.png" title="plot of chunk restime_segmentation" alt="plot of chunk restime_segmentation" width="100%" />


Preventing patch misidenfication
===

- Issue: tidally-driven cyclical movements can inflate residence time

- Solution: count only residence times for a point within 60 mins

- Red and blue patches overlap in space but not time

- Points in each don't contribute to the other's residence time

***

<img src="/home/pratik/projects/redknotMoveWaddensea/presentation/figResTimeInflation.png" title="plot of chunk restime_inflate" alt="plot of chunk restime_inflate" width="60%" />

Residence patch metrics
===

- Spatial metrics --- area, circularity, distance moved within patches, distance between patches

- Temporal metrics --- time within patch, time since high tide

- Social metrics --- number of overlapping individuals

***

<img src="/home/pratik/projects/redknotMoveWaddensea/presentation/figResPatchMetrics.png" title="plot of chunk respatch_metrics" alt="plot of chunk respatch_metrics" width="50%" />

Patch area within and between tides
===
<img src="/home/pratik/projects/redknotMoveWaddensea/figs/figPatchAreaVsTime.png" title="plot of chunk area_time" alt="plot of chunk area_time" width="80%" />

Number of patches within a tidal cycle
===
<img src="/home/pratik/projects/redknotMoveWaddensea/figs/figPatchNumberVsTidalTime.png" title="plot of chunk number_time" alt="plot of chunk number_time" width="70%" />

Inter-patch distance
===
<img src="/home/pratik/projects/redknotMoveWaddensea/figs/figPatchDistanceVsTime.png" title="plot of chunk distance_time" alt="plot of chunk distance_time" width="80%" />

In the works
===

- Extract resource values for patches (SIBES data)

- Count overlapping individuals

Linking patch area to predictors
===
