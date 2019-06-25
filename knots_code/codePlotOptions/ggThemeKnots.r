#### ggplot publication theme ####
#'make theme for plots
library(ggplot2)

themePubKnots <- function(base_size=10) {
  library(grid)
  #require(lemon)
  (theme_classic(base_size=base_size)+
      #  theme(plot.title = element_text(size = 12, face = "bold"))
      theme(plot.title = element_text(size = rel(1), face = "bold"),
            text = element_text(),
            #panel.background = element_rect(fill = "white", colour = 1),
            panel.border = element_blank(),
            axis.title = element_text(face = "plain",size = rel(1)),
            axis.title.y = element_text(angle=90,vjust = 4),
            axis.title.x = element_text(vjust = -2),
            axis.text.x = element_text(vjust = -1),
            axis.text.y = element_text(angle=90, vjust = 2, hjust = 0.5),
            #axis.line = element_line(),
            axis.ticks = element_line(size = 0.3),
            axis.ticks.length = unit(-0.1, "cm"),
            panel.grid.major = element_blank(),
            legend.position = "none",
            #element_line(size = 0.2, colour = "grey80"),
            panel.grid.minor = element_blank(),
            #  legend.key = element_rect(colour = NA),
            #  legend.position = "bottom",
            #  legend.direction = "horizontal",
            #  legend.key.size= unit(0.2, "cm"),
            #  legend.margin = unit(0, "cm"),
            # legend.title = element_text(face="italic"),
            plot.margin=unit(c(10,5,5,5),"mm"),
            plot.background = element_rect(fill = "white", colour = "transparent"),
            strip.background=element_rect(fill = "grey90", colour = "transparent"),
            #element_rect(colour="#f0f0f0",fill="#f0f0f0"),
            strip.text = element_text(face="bold", hjust = 0)
      ))
  
}

themePubLegKnots <- function(base_size=10) {
  library(grid)
  #require(lemon)
  (theme_classic(base_size=base_size)+
      #  theme(plot.title = element_text(size = 12, face = "bold"))
      theme(plot.title = element_text(size = rel(1), face = "bold"),
            text = element_text(),
            #panel.background = element_rect(fill = "white", colour = 1),
            panel.border = element_blank(),
            axis.title = element_text(face = "plain",size = rel(1)),
            axis.title.y = element_text(angle=90,vjust = 4),
            axis.title.x = element_text(vjust = -2),
            axis.text.x = element_text(vjust = -1),
            axis.text.y = element_text(angle=90, vjust = 2, hjust = 0.5),
            #axis.line = element_line(),
            axis.ticks = element_line(size = 0.3),
            axis.ticks.length = unit(-0.1, "cm"),
            panel.grid.major = element_blank(),
            legend.position = "right",
          #element_line(size = 0.2, colour = "grey80"),
            panel.grid.minor = element_blank(),
            #legend.key = element_rect(colour = 1),
          #  legend.position = "bottom",
          #  legend.direction = "horizontal",
          #  legend.key.size= unit(0.2, "cm"),
          #  legend.margin = unit(0, "cm"),
          legend.title = element_text(),
          legend.background = element_rect(colour = 1),
          legend.key = element_blank(),
            #  legend.margin = unit(0, "cm"),
            # legend.title = element_text(face="italic"),
            plot.margin=unit(c(10,5,5,5),"mm"),
            plot.background = element_rect(fill = "white", colour = "transparent"),
            strip.background=element_rect(fill = "grey90", colour = "transparent"),
            #element_rect(colour="#f0f0f0",fill="#f0f0f0"),
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
