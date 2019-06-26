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

Evolution of movement in fluctuating landscapes
===
type:sub-section

*with L. Boullosa, C. Netz, H. Hildenbrandt & F. Weissing*

Can we construct a spatially explicit model of individuals reacting to a fluctuating landscape?

What reaction norms are evolved in such landscapes?

Local sensing of global patterns
===

**Landscape**

- Neutral, continuous landscape

- Values represent resource 0 -- 1

- Landscape changes in space and time

- Landscape is not depleted

***

**Agents**

- *N* agents

- Simple neural network

- Single input, single output (distance), random direction

- Non-depleting, non-interacting

An introduction to neutral landscapes
===
Un-wrapped Gaussian landscapes^[1]

![plot of chunk nlm_figure](../presentation/figGaussianLand.png)

<small>
^[1]: following Sciani et al. (2018)
^[2]: Cenzer et al. (2019) </small>

***

Wrapped, clamped, 2 resource Gaussian landscapes^[2] 

![plot of chunk cenzer_figure](../presentation/figCenzer2019.png)


Perlin noise as neutral landscapes
===

Method developed for water surface graphics^[1]

![plot of chunk perlin_figure](../presentation/figurePerlinLandscapes.png)

<small>^[1]: Perlin (1985)</small>

What do landscape parameters mean?
===
type: alert

<font size="+12">Landscape simulation parameters **do not** always correspond to realised landscape metrics!^[1]</font>

<small>[1]: Haller et al. (2013)</small>

Fluctuations in Perlin noise
===
<video width="1280" height="800" controls>
  <source src="../presentation/figPerlinChange.webm" type="video/webm">
</video>

A reminder of Perlin parameters
===
**Space**

Perlin noise is varied by overlaying octaves in `C++`

![plot of chunk perlin_figure2](../presentation/figurePerlinLandscapes.png)

***

**Time**

Temporal variation is velocity along axis Z

![plot of chunk perlin_figure3](../presentation/figPerlinExplain.png)

Quantifying spatial predictability
===

- Semivariogram range as measure of spatial predictability

- Pairwise distance at which the semivariance ≈ global variance

- Computation in `Python` using library `gstat`

Perlin noise 2D variographs
===

X-axis: distance, Y-axis: semivariance, rows: temporal rate ++, cols: octaves ++
![plot of chunk perlin_variograph](../presentation/figurePerlinVariographs.png)

Expected effect of varying spatial scale
===

Landscapes generated using `nlmpy`^[1]

<img src="../presentation/figureNeutralLandscapes.png" title="plot of chunk nlmpy_landscape" alt="plot of chunk nlmpy_landscape" width="120%" />

**Perlin noise octaves do not produce spatial structure**

***

Variograms from `gstat`

<img src="../presentation/figureNeutralLandscapeVariograph.png" title="plot of chunk nlmpy_vgram" alt="plot of chunk nlmpy_vgram" width="100%" />

<small>[1]: Etherington et al. (2015)</small>

Quantifying spatio-temporal predictability
===
- Semivariance calculated in 3 dimensional space

- `Python` computation using `gstat`

- **Perlin noise does produce spatio-temporal structure**

Perlin noise 3D variographs
===

X-axis: distance, Y-axis: semivariance, rows: temporal rate ++, cols: octaves ++
<img src="../presentation/figurePerlin3dVariographs.png" title="plot of chunk perlin3d_variograph" alt="plot of chunk perlin3d_variograph" width="70%" />

Local sensing agents
===

- Simple ANN
- Landscape value the only input
- Distance the only output
- Random movement angle
- Reproduction ~ resource intake

<img src="../presentation/figPerlinAnn.png" title="plot of chunk ann_perlin" alt="plot of chunk ann_perlin" width="70%" />

Project progress
===
*co-supervised with C. Netz and F. Weissing*

- January through July *(?)*
- Mid-term evaluation --- none
- Expected EC --- ?

*Probability of manuscript in 2019* ≈ 20%, *in 2020* ≈ 70%

Project questions
===

- How can we better link this project to Botero et al. (2015)?

- Should we include more complexity in strategies, such as developmental switches?

- Are red knots or waders a system we want to model towards?

Evolution of movement with competition
===
type: sub-section

*with M. Pederboni, C. Netz & F. Weissing*

How do exploitation and interference competition affect space-use?

How can competition affect the evolution of movement strategies?

Movement types and/or foraging guilds
===
Getz et al. (2015). *Panmictic and clonal evolution on a single patchy resource produces polymorphic foraging guilds*. PLoS One.

- Evolved movement polymorphisms on a grid-based, depletable landscape
  - Morph emergence ~ competition
  - Competition ~ population size

***

![plot of chunk getz_figure](../presentation/figGetz2015fig05.png)

Conceptually modelling wader competition
===
Vahl (2006). *Interference competition among foraging waders*. RuG PhD thesis.

<img src="../presentation/figVahl2006fig6.1.png" title="plot of chunk vahl_figure" alt="plot of chunk vahl_figure" width="60%" />

Implementing competition in spatial models
===
**Landscape**
- Simple lattice landscape --- $S^2$ cells
- Discrete resources w/ handling time ---  
  - $R$ resources
  - $p(resource)$
  

<img src="../presentation/figDistGradientLand.png" title="plot of chunk distgrad_figure" alt="plot of chunk distgrad_figure" width="60%" />

***

**Agents**
- $N$ agents
- Agents choose position based on cell agents and resources

<img src="../presentation/figInterfSimScheme.png" title="plot of chunk interfscheme_figure" alt="plot of chunk interfscheme_figure" width="80%" />

Preliminary model output
===

<video width="1280" height="800" controls>
  <source src="../presentation/vidKleptomove.webm" type="video/webm">
</video>

Zoomed model output
===

<video width="1280" height="800" controls>
  <source src="../presentation/vidKleptomoveZoom.webm" type="video/webm">
</video>

Model questions
===
Building on Getz et al. (2015) with help from Vahl (2006)

- Can we evolve movement and interference polymorphisms?

- Do movement and interference co-evolve, and how?

- How do they affect space-use and population-level movement?


Master's student progress
===
*co-supervised with C. Netz and F. Weissing*

- February through September
- Mid-term evaluation -- next week
- Expected EC --- 30 *(?)*

*Probability of manuscript in 2019* ≈ 10%, *in 2020* ≈ 70%

Project questions
===

- Should we implement exploitation or only interference?

- Should there be state-dependent interaction outcomes?

- What area of eco-evo dynamics should we target this project towards?

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

<img src="../figs/figTimeTagRelease.png" title="plot of chunk tags_before_release" alt="plot of chunk tags_before_release" width="60%" />

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

- Performs better than more complex alogrithms^[1]

<small>[^1]: such as Patin et al. (2018)</small>

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

Linking patch area to predictors
===
<img src="/home/pratik/projects/redknotMoveWaddensea/figs/figPatchAreaVsPredictors2.png" title="plot of chunk area_predictors" alt="plot of chunk area_predictors" width="80%" />

To do
===

- Link residence patches to underlying resource values
- Get overlaps between individuals to test theoretical predictions, eg. Spiegel et al. (2017)

Project questions
===

- How should we divide up a complex story?

- When should we introduce the SIBES data?

Modelling the evolution of migration traditions
===
type: sub-section

*with I. Daras, M. Kozielska, T. Oudman(?) & F. Weissing*

How can IBMs reproduce the migration patterns of social animals?

How do age-structure and dominance hierarchies play a role?

Potential model system
===

- Waders
  - Migrate in groups
  - Complex migration dynamics
  - Potential information transfer of migration decisions --- departure flights, moulting

- Geese
  - Show family-size based dominance hierarchies
  - Vertical, oblique, and horizontal information transfer
  
Green-wave landscape
===

- *W* element vector --- each position is a site

- Shifting resource peak

- Constant or variable

  - End point
  - Rate of peak shift (green wave velocity)
  
- Green-wave reverses every $t$ timesteps

***

<img src="/home/pratik/projects/redknotMoveWaddensea/knots_code/figLandscape.png" title="plot of chunk greenwave" alt="plot of chunk greenwave" width="100%" />

Agent migration decision
===

- *N* agents each decide step-length

- Agents take 2 inputs from cell:
  - Resource value
  - Proportion of agents moving forward
  
***

<img src="/home/pratik/projects/redknotMoveWaddensea/presentation/figGooseMigANN.png" title="plot of chunk mig_ann" alt="plot of chunk mig_ann" width="100%" />
  
  
Agent currency & reproduction
===
- Currency = resource intake
- Intake ~ resource value, agent density^-1
- Cost ~ movement distance

**Reproduction**

- Fixed population --- proportional to intake
- Flexible population --- realistic reproduction dynamics

Project questions
===
- Should we pursue this modelling approach?

- Should we implement learning and non-genetic inheritance, and how?

- How complex should we make the system?

Thanks, and questions please
===
type: sub-section

Email: p.r.gupte@rug.nl
Github: pratikunterwegs

