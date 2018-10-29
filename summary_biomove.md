---
title: "Key talks from the Biomove Symposium 2018"
monofont: Inconsolata
papersize: A4
fontsize: 10pt
geometry: margin=2cm
document-class: article
bibliography: [knots_texts/knots_cite.bib]
csl: knots_texts/frontiers-in-ecology-and-the-environment.csl
header-includes:
  - \usepackage{multicol}
  - \usepackage{crimson}
---

# Session 1: From individuality to biodiversity

## Keynote: Individual variation in dispersal: Key to eco-evolutionary dynamics in populations and communities

**Dries Bonte, _University of Ghent_**

### Movement ecology as a field

See for a broad introduction in the literature: @Chesson2000, @Nathan2008, @Jeltsch2013. Movement is a behaviour within the scope of Tinbergen's Four Questions. It is hierarchically structured, and links habitat patches, and is important in understanding population processes. Behaviour including movement is assumed to be optimal --- leading to the question, what are the fitness consequences of movement? For example, @Salguero-Gomez2016 show that plant traits and dispersal are related, with evidence for bet-hedging. See also @Clobert2009, @Bonte2017.

### The evolution of dispersal in meta-populations

Related work is to be found in @VanBelleghem2015, @Hanski2011, @KLEMME2009, and @Bonte2014; all asking the question of whether dispersal has fitness benefits, especially in fragmented landscapes. For more work see @Cheptou2017. In experimental evolution, the question is, how does evolution in dispersal evolve? See @Fronhofer2014. The result is that dispersal itself doesn't evolve, but other traits do; see @DeRoissart2016 for a study with three different simulated landscapes.

### Evolution at range fronts

See @VanPetegem2018, @VanPetegem2016 for an overview of conditional dispersal. What feedbacks might we expect in such populations? @Pardikes2017, @Tack2015, and @Hillaert2018 provide interesting reading related to informed and un-informed movement, which is related to the predictability of a landscape. One general idea is that reshuffling in a population kills evolution, or leads to a loss of informations (i.e., a loss of informed individuals). Work related to this is found in @Bonte2018.

## Talks

### What's your move? Movement as a link between personality and spatial dynamics in animal populations

**Orr Spiegel, _Tel Aviv University_**

Speaking about the link between movement, personality, and evolution. A central assumption in animal movement and telemetry has been that all individuals of a species are essentially 'clones', or identical, but individuals matter. Personalities or behavioural types are often sub-optimal as plasticity is limited [see @Lloyd-Smith2005; @Sih2004; @Reale2007; @Dingemanse2010; @Korsten2013; @Reale2010]. Why do individuals differ? Three possible causes: 1. Method --- how you measure matters, 2. Proximate mechanisms, and 3. Ultimate mechanisms.

Animal search can be a behaviour and evolve a reaction norm. The intensity of local search can be a response to the clumpedness of resources, and behavioural type should determine habitat preferences. This can be tested with a simulation model of biased correlated random walk agents, in which the only difference between agents foraging in a landscape with clumped resources is 'giving-up time'. This affects home range size and structure. This can also be captured by a social network, such as a proximity based social network from tracking data. When resources are uniformly distributed, 'slow' _(meant as with high giving up time; in knots we could think of these as less exploratory - prg)_ individuals are likely to interact very little with other 'slow' individuals, while fast individuals would move more and thus have higher sociality scores _(edge weights in a social network)_. The opposite is likely in a scenario with more clumped patches [see @Duckworth2007; @Aplin2013]. Variation in the environment (variability, clumpedness) determines which neighbours an individual ends up with. Knowing the system well is imperative to determine the sensitivity of social networks to distance, and make reasonable assumptions about interactions/sociality. Null model testing of social networks is important [@Farine2015a; @Farine2017].

### Spatially structured trait variation between individuals may lead to biodiversity in heterogeneous, disturbed environments

**Thomas Banitz, _UFZ Leipzig_**

Individual differences may be thought of as intra-specific trait variation (ITV) [@Bolnick2011; @Hart2016; @Moran2016], and ITV can be structured or unstructured. Spatial structure of ITVS can be studied using a spatially explicit IBM. If there is no structure to ITV, trait values differ between species, or if they are the same between species, they change at different values. In a structured ITV scenario, disturbances of different kinds may be responsible (recurrent, non-random, or clumped). Clumped disturbances may allow species co-existence via dispersal differences see @Banitz2008; _somewhat unclear talk - prg_).

### Quantifying animal personalities from movement data: Repeatable among individual variation in wildlife studies

**Anne Hertel, _BiKF Senckenberg_**

Behavioural types in populations can lead to individuals consistently selecting for certain habitat types. Using a definition of personality as repeatable among individual variation, a number of behavioural types can combine, and evolve non-independently, to form a behavioural syndrome. Quantifying personality in an animal population is difficult, especially in post-hoc studies.

42 female brown bears in Sweden were tracked over 1 -- 7 years, and linear mixed models were used to separately relate different behavioural traits using the simple form `behaviour ~ fixed effect + random effect (bear identity, year)`. Repeatability was quantified as `r = (variance among individuals) ÷ (variance among individuals + variance among years + residual variance)`. The `R` package `rptr` provides confidence intervals for random effects. Syndromes were difficult to identify from this procedure, but there was a gradient of behavioural types which reflected human tolerance [@Leclerc2016; @Hertel2017].

### Fencing solves human-wildlife conflict locally but shifts problems elsewhere: Modelling seasonal landscape connectivity for African elephants

**Niko Balkenhol, _University of Göttingen_**

Landscape resistance is an important concept in movement ecology @Zeller2012, and step selection functions can help quantify resistance from tracking data, using the method `resistance = 1 ÷ step selection probability`. 14 elephants (10 males, 4 females) were tracked at four hour intervals in the Greater Amboseli system over two years. Landscape resistance can either be averaged using a single value from a population-level step selection function, or take into account individual variability and seasonal effects by running individual and/or seasonal step selection function models and weighing the step selection probability of each point in the landscape by distance to the individual's home range centre.

This results in the finding that not all predictors matter to all individuals. The averaged resistance method and the individual variability method predict very different resistances [see @Osipova2018a; @Osipova2018].

# Session 3: Animal movement across scales

## Keynote: Animal movement across scales and the existence of syndromic guilds

**Wayne Getz, _University of California, Berkeley_**

### The components of movement

The scales of structures and processes in animal movement are not well understood except for a few cases, such as the movement of the horse _(horses have five distinct movement modes, stationary, walk, trot, canter, gallop, that were only fully characterised after the the advent of film cameras - prg)_. Movement can be thought of as being made up of 'fundamental movement elements (FMEs)', a series of steps which can be scaled up to from a 'canonical activity mode (CAM)'. These FMEs and CAMs are best measured using accelerometer data for different parts of animal bodies in motion to characterise speed and other movement variables.
FMEs can be scaled down to their individual mechanistic components, such as a single wingbeat, or other discrete action. Such subFME strings can be identified in accelerometer data, and scaled up to FME strings, which form recognisable movement patterns (such as flight). CAMs are typically one level higher, and comprise such behaviours as grooming, dispersal, translocation.
'Syndromic movement types (SMTs)' are made up of a mix of CAMs that identify a behavioural type at one or more (and possibly ever increasing) temporal scales.

### Questions in movement

Questions in movement are scale-dependent. At the FME scale, questions focus on mechanism, such as mechanical efficiency or physiological processes. At the CAM scale, movement questions should focus on movement syndromes [@Sih2004], where a movement syndrome is a suite of correlated movement patterns in one or more ecological contexts. Movement syndromes can be integrative, and can be continuous or discrete as variables. Classifying movement modes from tracking data can be done in a number of ways [see @Nathan2012; @Gurarie2016; @Patterson2009; @Abrahms2017; @Wittemyer2008; @Cizauskas2015] at different scales. This classification can then be used to answer questions arising from variation in animal phenotypes.

### Syndromic guilds

In a 3 strategy movement model, three types emerge ---  $\rho$, which has a movement threshold based on local resource depletion ('tactical movement'), $\alpha$, which moves to avoid competition ('strategic movement'), and $\delta$, which is a mix of 'tactical' and 'strategic' movement types. Syndromic guilds with association based on movement types emerge in this model with otherwise identical agents. Introducing sex as a degree of freedom results in assortative mating [@Getz2016], and this may be similar to previously known assortative mating based on 'magic' genes (eg. MHC). _Three questions were asked but not clearly answered: 1. Do movement strategies co-exist, or does the population converge on to one strategy in the model? 2. Is the movement type phenotypically plastic? 3. What would happen if a movement type were artificially removed from the model population, how would space use across the landscape change? - prg_

\twocolumn

# References

\scriptsize
