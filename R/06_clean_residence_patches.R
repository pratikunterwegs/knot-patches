## ----prep_libs, message=FALSE, warning=FALSE----------------------------------
library(data.table)
library(purrr)
library(ggplot2)
library(colorspace)


## -----------------------------------------------------------------------------
# load data
patches <- fread("data/data_2018/data_2018_patch_summary.csv")

# add uid
patches[, uid := seq_len(nrow(patches))]


## -----------------------------------------------------------------------------
# histogram of durations (in s converted to mins)
hist(patches$duration / (3600))


## -----------------------------------------------------------------------------
# hour of day
patch_times <- patches$time_mean
# convert to posixct
patch_times <- as.POSIXct(patch_times, tz = "Berlin", origin = "1970-01-01")

# hour day
hour_day <- hour(patch_times)
hist(hour_day)

# looks okay

# get julian day
julian_day <- as.numeric(julian(patch_times, origin = "2018-01-01"))
hist(julian_day)
# looks okay as there are more patches as more birds are tagged in september


## -----------------------------------------------------------------------------
# check max times
range(patch_times)
# looks okay


## -----------------------------------------------------------------------------
# add date
patch_summary <- copy(patches[, c("id", "time_mean", "tide_number")])
patch_summary[, day := round(as.numeric(julian(
  as.POSIXct(patch_times,
    tz = "Berlin", origin = "1970-01-01"
  ),
  origin = "2018-01-01"
)))]

# count per tide and or day
patch_count <- patches[, .N,
  by = c("id", "tide_number")
]


## -----------------------------------------------------------------------------
ggplot(patch_count) +
  geom_tile(aes(tide_number, id,
    fill = N
  )) +
  scale_fill_continuous_sequential(
    palette = "Sunset"
  ) +
  coord_cartesian(expand = F)


## -----------------------------------------------------------------------------
# this is the speed in metres per second
patches[, c("speed_in", "speed_out") := list(
  distBwPatch / (shift(time_start, type = "lead") - shift(time_end)),
  shift(distBwPatch, type = "lead") / (shift(time_end, type = "lead") -
    shift(time_start))
),
by = .(id, tide_number)
]

# histogram of speeds
hist(patches$speed_in)


range(patches$speed_in, na.rm = T)
range(patches$speed_out, na.rm = T)

# quantiles
quantile(patches$speed_in, probs = seq(0.9, 1, 0.01), na.rm = T)
quantile(patches$speed_out, probs = seq(0.9, 1, 0.01), na.rm = T)

# what is 150 km/hr in m/s
cutoff_speed <- 15 # around 70 kmph

# filter ridiculous speeds
patches <- patches[between(speed_in, 0, cutoff_speed) &
  between(speed_out, 0, cutoff_speed), ]
# goes from 90k to 78k


## -----------------------------------------------------------------------------
ggplot(patches) +
  geom_path(aes(x_mean, y_mean,
    group = interaction(id, tide_number)
  ),
  size = 0.1,
  alpha = 0.2
  )


## -----------------------------------------------------------------------------
# above 600, which means at least two points
patches <- patches[area > 600, ]

# now 71k


## -----------------------------------------------------------------------------
ggplot(patches) +
  geom_path(aes(x_mean, y_mean,
    group = interaction(id, tide_number)
  ),
  size = 0.1,
  alpha = 0.2
  )


## -----------------------------------------------------------------------------
# export the summary
fwrite(patches, "data/data_2018/data_2018_good_patches.csv")
