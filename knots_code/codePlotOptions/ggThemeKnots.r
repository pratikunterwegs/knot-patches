#### ggplot publication theme ####
#'make theme for plots
library(ggplot2)

themePubKnots <- function(base_size=10) {
  library(grid)
  #require(lemon)
  (theme_classic(base_size=base_size)+
      theme(plot.title = element_text(size = rel(1), face = "bold"),
            text = element_text(),
            panel.border = element_blank(),
            axis.title = element_text(face = "plain",size = rel(1)),
            axis.title.y = element_text(angle=90,vjust = 4),
            axis.title.x = element_text(vjust = -2),
            axis.text.x = element_text(vjust = -1),
            axis.text.y = element_text(angle=90, vjust = 2, hjust = 0.5),
            axis.ticks = element_line(size = 0.3),
            axis.ticks.length = unit(-0.1, "cm"),
            panel.grid.major = element_blank(),
            legend.position = "none",
            panel.grid.minor = element_blank(),
            plot.margin=unit(c(10,5,5,5),"mm"),
            plot.background = element_rect(fill = "white", colour = "transparent"),
            strip.background=element_rect(fill = "grey90", colour = "transparent"),
            strip.text = element_text(face="bold", hjust = 0)
      ))
  
}

themePubLegKnots <- function(base_size=10) {
  library(grid)
  (theme_classic(base_size=base_size)+
      theme(plot.title = element_text(size = rel(1), face = "bold"),
            text = element_text(),
            panel.border = element_blank(),
            axis.title = element_text(face = "plain",size = rel(1)),
            axis.title.y = element_text(angle=90,vjust = 4),
            axis.title.x = element_text(vjust = -2),
            axis.text.x = element_text(vjust = -1),
            axis.text.y = element_text(angle=90, vjust = 2, hjust = 0.5),
            axis.ticks = element_line(size = 0.3),
            axis.ticks.length = unit(-0.1, "cm"),
            panel.grid.major = element_blank(),
            legend.position = "right",
            panel.grid.minor = element_blank(),
          legend.title = element_text(),
          legend.background = element_rect(colour = 1, size = 0.2),
          legend.key = element_blank(),
            plot.margin=unit(c(10,5,5,5),"mm"),
            plot.background = element_rect(fill = "white", colour = "transparent"),
            strip.background=element_rect(fill = "grey90", colour = "transparent"),
            strip.text = element_text(face="bold", hjust = 0)
      ))
  
}

guidePub = guide_colorbar(frame.colour = 1,
                          ticks.colour = 1,
                          draw.ulim = T,
                          darw.llim = T)

#### specify some colours ####
stdBlu = "royalblue4"; stdRed = "indianred3"; stdGrn = "olivedrab"
altBlu = "dodgerblue3"; altRed = "indianred1"; altGrn = "seagreen3"

drkGry = "grey20"; stdGry = "grey70"

litBlu = "lightblue"; litRed = "lightpink"; litGrn = "paleGreen"
