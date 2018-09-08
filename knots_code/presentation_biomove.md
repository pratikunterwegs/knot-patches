---
title: "Bound together or loose ends?"
subtitle: "Foraging associations in Red Knots"
author: "Pratik R Gupte, Selin Ersoy & Allert I Bijleveld"
date: "September 26, 2018"
output:
  ioslides_presentation:
    fig_caption: yes
    keep_md: yes
    widescreen: yes
    logo: ~/git/knots/knots_texts/logo_affils.png
    css: ~/git/knots/knots_texts/solarized-personal.css
---



# Introduction

## Introduction: Waders in the Wadden Sea

Waders such as red knots _Calidris canutus_ gather in large non-breeding flocks in the Wadden Sea, where they forage on the intertidal mudflats

<div class="figure">
<img src="~/git/knots/knots_texts/fig_mudflats.jpg" alt="Wadden Sea mudflats" width="600px" />
<p class="caption">Wadden Sea mudflats</p>
</div>

## Knots benefit from sociality

Knots can use social information in lab settings to find food^[1]^, and may learn the location of profitable foraging patches by observing flock-mates^[2]^


<font size="4"> 1: Bijleveld et al. 2015. _Behav. Processes_ </font>
<font size="4"> 2: Bijleveld et al. 2010. _Oikos_ </font>

## Do knots have friends?

Knots benefit from association, but do they have friends — persistent, non-random associations — within & between tidal intervals^[3][4]^?

<font size="4"> 3: Myers 1983. _Behav. Ecol. Sociobiol._ </font>
<font size="4"> 4: Conklin & Colwell 2007. _J. Field. Ornith._ </font>

# Methods: Tracking multitudes

## ATLAS tracking

We set up ATLAS --- a tracking tower system (n = 5) based on the **T**ime **o**f **A**rrival (**ToA**) of radio signals from tagged knots (n = 35)

<div class="figure">
<img src="~/git/knots/knots_texts/tracking_tower_map_picture.png" alt="Tracking tower and locations" width="800px" />
<p class="caption">Tracking tower and locations</p>
</div>

## Tidal intervals

- We obtained water-level data from Harlingen

- Identified 44 tidal intervals (~12 hrs) over 19 calendar days

- Grouped each knot's movement tracks by tidal interval

## Co-occurrence

- Calculated co-occurrence <font size="7"> _c<sub>ij</sub>_ </font>

- <font size="7"> _c<sub>ij</sub>_ </font> = proportion of positions at which birds _i_ & _j_ were within 250 m of each other

<img src="~/git/knots/knots_texts/fig_proximity_schematic.png" width="400px" />

# Results: Knot association is low

## Most knots rarely interact

<div class="figure">
<img src="~/git/knots/knots_texts/coherence_distribution.png" alt="Pair-wise co-occurrence distribution" width="400px" />
<p class="caption">Pair-wise co-occurrence distribution</p>
</div>

## Knot co-occurrence is rarely different from random

<div class="figure">
<img src="~/git/knots/knots_texts/figure_coherence_matrix.png" alt="Pair-wise co-occurrence matrix" width="300px" />
<p class="caption">Pair-wise co-occurrence matrix</p>
</div>

## Only ~10% of knot pairs are 'friends'

<div class="figure">
<img src="~/git/knots/knots_texts/coherence_test_prop.png" alt="% of pairs with _c&lt;sub&gt;ij&lt;/sub&gt;_ values higher than expected" width="400px" />
<p class="caption">% of pairs with _c<sub>ij</sub>_ values higher than expected</p>
</div>

# Results: Knot association is environmentally driven

## Knot co-occurrence is tidally forced

<img src="~/git/knots/knots_texts/figure_coherence_hour_handout.png" width="450px" />

## Post foraging co-occurrence is unrelated to pre-foraging scores

- GLMM: post-foraging _c<sub>ij</sub>_ ~ pre-foraging _c<sub>ij</sub>_ + foraging period distance mismatch + (1|pair) + (1|tidal interval)

- Pre-foraging _c<sub>ij</sub>_ is not a significant effect (z = 1.738, _p_-value = 0.08)

- Knots don't re-unite with pre-foraging 'friends'

## Post-foraging co-occurrence _is_ related to distance mismatch

- Knots which travel similar distances during foraging are more closely associated post-foraging (z = -2.72, _p_-value = 0.006)

<img src="~/git/knots/knots_texts/figure_coherence_friends_found.png" width="300px" />

# Discussion

## At what scales do interactions happen?

- Wader interactions may occur at scales not measured here

- Knots have previously been shown to be non-randomly associated^[5]^

<font size="4"> 5: Harrington & Leddy 1982. _Wader Study Group Bull._ </font>

## Neighbour _type_ might matter more than identity: Future work

- Knots have consistent personalities re: exploratory behaviour^[6]^

- May associate with individuals of similar personality due to shared resource requirements

- Identification of neighbour personality may still require sustained association

<font size="4"> 6: Bijleveld et al. 2014. _Proc. Royal Soc. B_ </font>

## Thank you!

**Ask your questions here, or on Twitter!**

- Pratik R Gupte <div class="blue2"> @pratikunterwegs </div> | p.r.gupte@rug.nl

- Selin Ersoy <div class="blue2"> @sellinj </div> | selin.ersoy@nioz.nl

- Allert I Bijleveld <div class="blue2"> @AllertBijleveld </div> | Allert.Bijleveld@nioz.nl
