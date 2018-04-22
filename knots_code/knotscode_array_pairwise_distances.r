
#### data for array based pairwise distances

#'hold this for now
#'it's possible to convert the positions into an array of depth 37, which may be an easier way of getting NND eventually
a = k1 #%>% filter(id %in% c("151", "157","231"))
a = a %>% select(id,X,Y)

a = a %>% group_by(id) %>% sample_n(size = 100)
a = a %>% dlply("id") %>% map(function(x) x %>% mutate(id = NULL)) %>% map(as.matrix)

b = abind::abind(a, along = 3)

d = array(dim = c(100,2,3))

for (i in 1:3) {
  x = a[!names(a) %in% names(a)[i]]
  for(j in 1:length(x)){
  d[,j,i] = diag(spDists(x = a[[i]], y = x[[j]]))
  }
}

t(apply(d, c(3,1), mean))