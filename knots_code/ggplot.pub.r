#### ggplot publication theme ####
####
theme_pub <- function(base_size=10) {
  library(grid)
  library(ggthemes)
  (theme_foundation(base_size=base_size)+
  #  theme(plot.title = element_text(size = 12, face = "bold"))
    theme(plot.title = element_text(size = rel(1), face = "bold"),
            text = element_text(),
            panel.background = element_blank(),
            plot.background = element_blank(),
            panel.border = element_blank(),
            axis.title = element_text(face = "plain",size = rel(1)),
            axis.title.y = element_text(angle=90,vjust =2),
            axis.title.x = element_text(vjust = -0.2),
            axis.text = element_text(),
            axis.line = element_line(colour="black", size = 0.3),
            axis.ticks = element_line(),
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
            strip.background=element_blank(),
            #element_rect(colour="#f0f0f0",fill="#f0f0f0"),
            strip.text = element_text(face="italic")
    ))

}
#### ggplot printing options ####

library(ggplot2)
unit = unit(0, "cm")
g1 = theme(#panel.grid = element_blank(),
 legend.position="top", plot.title = element_text(size = 14, face = "italic"), axis.title = element_text(size = 10))+theme(strip.background=element_blank(), panel.spacing.y=unit, strip.text = element_text(size = 8))+ theme(panel.border = element_rect(fill = NA, colour = 1, size = 0.2), plot.caption=element_text(hjust = 0))

 # theme(axis.ticks.length=unit(-0.1, "cm"), axis.text.x = element_text(margin=unit(rep(0.2,4), "cm")), axis.text.y = element_text(margin=unit(rep(0.2,4), "cm")))

cola = "royalblue4"; colb = "indianred3"
cola2 = "dodgerblue3"; colb2 = "indianred1"

colc = "grey20"

cola3 = "grey70"; colb3 = "grey20"

cola1 = "lightblue";colb1 = "lightpink"

coltemp = "#fc8d62"

#### ggplot printing options ####

library(ggplot2)
unit = unit(0, "cm")
g1 = theme(#panel.grid = element_blank(),
 legend.position="top", plot.title = element_text(size = 14, face = "italic"), axis.title = element_text(size = 10))+theme(strip.background=element_blank(), panel.spacing.y=unit, strip.text = element_text(size = 8))+ theme(panel.border = element_rect(fill = NA, colour = 1, size = 0.2), plot.caption=element_text(hjust = 0))

 # theme(axis.ticks.length=unit(-0.1, "cm"), axis.text.x = element_text(margin=unit(rep(0.2,4), "cm")), axis.text.y = element_text(margin=unit(rep(0.2,4), "cm")))

scale_fill_Publication <- function(...){
  library(scales)
  discrete_scale("fill","Publication",manual_pal(values = c("#386cb0","#fdb462","#7fc97f","#ef3b2c","#662506","#a6cee3","#fb9a99","#984ea3","#ffff33")), ...)

}

scale_colour_Publication <- function(...){
  library(scales)
  discrete_scale("colour","Publication",manual_pal(values = c("#386cb0","#fdb462","#7fc97f","#ef3b2c","#662506","#a6cee3","#fb9a99","#984ea3","#ffff33")), ...)

}
