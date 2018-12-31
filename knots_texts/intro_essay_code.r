#### Introductory essay code ####

library(tidyverse);library(RColorBrewer)
a = data_frame(x = 0:8, y = seq(-0.8, 0.8, length.out = 9), v1 = 0.1, v2 = 0.5, v3 = 0.9) %>% expand(x,y,v1,v2,v3) %>% gather(comp, val, - x, -y) %>% mutate(suit = (x*val)+(x*y))

#### movement and competition ####
ggplot(a)+geom_point(aes(x=x, y = suit, fill = y), shape = 21, size = 3)+labs(list(x = "conspecifics in destination cell", y = "suitability ∝ f(y)", fill = "delta\ncompetitiveness", size = "individual\ncompetitiveness"))+scale_fill_gradientn(colours = brewer.pal(9, "PiYG"))+theme_bw()+geom_abline(slope = 0, col = "dodgerblue")+theme(legend.position="top")+coord_equal()+facet_wrap(~val)

#### movement and internal state ####

b = data_frame(x = 0.5, y = c(0:8)/1, state = c(0:8)/10, slope = seq(-0.8, 0.8, length.out = 9)) %>% expand(x,y, state, slope) %>% mutate(cost = ifelse(y == 0.5, 0, 1), suit = (1 - scales::rescale(slope)) * y - state - cost)

head(b)

ggplot(b)+geom_point(aes(x = state, y = suit))+facet_wrap(~slope)
