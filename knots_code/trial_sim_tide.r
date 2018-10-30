p <- list()
for(i in 1:1000){
  p[["x"]][i] <- rnorm(1,0,1)
  p[["y"]][i] <- rnorm(1,mean = i/1e3, 1) + rnorm(1,2*i/1e3,1)
  p[["water"]][i] <- rnorm(1, mean = i/1e3,1)
}

#'plot pos
ggplot()+
  geom_point(aes(x = cumsum(p[[1]]), y = cumsum(p[[2]])))+
  geom_text(aes(x = cumsum(p[[1]])[c(1,1000)], y = cumsum(p[[2]])[c(1,1000)]), col = c(3,2), label = c("start","end"))+
  geom_hline(yintercept = cumsum(p[[3]]), col = 4, alpha = .1)
