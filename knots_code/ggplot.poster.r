#### ggplot publication theme ####
####
theme_poster <- function(base_size=10) {
  library(grid)
  library(ggthemes)
  (theme_foundation(base_size=base_size)+
  #  theme(plot.title = element_text(size = 12, face = "bold"))
    theme(plot.title = element_text(size = rel(1.2), face = "bold"),
            text = element_text(),
            panel.background = element_blank(),
            plot.background = element_blank(),
            panel.border = element_blank(),
            axis.title = element_text(size = 16),
            axis.title.y = element_text(margin=unit(rep(0,4), "cm")),
            axis.title.x = element_text(margin=unit(rep(0,4), "cm")),
            axis.text = element_text(size = 14),
            axis.text.x = element_text(margin=unit(rep(0.6,4), "cm")), axis.text.y = element_text(margin=unit(rep(0.6,4), "cm")),
            axis.line = element_line(colour="black", size = 0.3),
            axis.ticks = element_line(),
            axis.ticks.length=unit(-0.3, "cm"),
            panel.grid.major = element_blank(),
            legend.position = "top",
          #element_line(size = 0.2, colour = "grey80"),
            panel.grid.minor = element_blank(),
           legend.key = element_blank(),
          #  legend.position = "bottom",
          #  legend.direction = "horizontal",
          #  legend.key.size= unit(0.2, "cm"),
          #  legend.margin = unit(0, "cm"),
           legend.text = element_text(size = 14),
           legend.title = element_text(size = 14),
           plot.margin=unit(c(5,5,5,5),"mm"),
            strip.background=element_blank(),
            #element_rect(colour="#f0f0f0",fill="#f0f0f0"),
            strip.text = element_text(face="italic")
    ))

}
#### ggplot printing options ####

library(ggplot2)
unit = unit(0, "cm")
 # theme(axis.ticks.length=unit(-0.1, "cm"), axis.text.x = element_text(margin=unit(rep(0.2,4), "cm")), axis.text.y = element_text(margin=unit(rep(0.2,4), "cm")))

cola = "royalblue4"; colb = "indianred3"
cola2 = "dodgerblue3"; colb2 = "indianred1"

colc = "grey20"

cola3 = "grey70"; colb3 = "grey20"

cola1 = "lightblue";colb1 = "lightpink"

coltemp = "#fc8d62"
