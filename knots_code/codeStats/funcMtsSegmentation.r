
# Load the time series matrix including the comopnents profiles

# Here, the synthetic data is given as an example. To test the algorithm with synthetic data, uncomment the following two lines
# file <- "../Data/data_syn.obj"
# load(file)
library(penalized)

MTS.Segmentation <- function(data, lambda1=NULL, lambda2=NULL)
{
  main.data <- data
  
  data <- data[,seq(from=dim(data)[2],to=1,by=-1)]
  
  C<-matrix(0,ncol(data),ncol(data))
  
  diag(C) <-0
  
  time <- t(data)
  
  i <- 1
  dd <- ncol(data)-2
  
  if (is.null(lambda1)==T | is.null(lambda1)==T)
  {
    lambda1 <- rep(0,dd)
    lambda2 <- rep(0,dd)
    
    while(i<= dd)
    {
      print(paste("step",i))
      
      y <- time[i,]
      
      x <- data[,-c(1)]
      
      a <- rep(1,ncol(x))
      
      if (ncol(x) <10)
        fld <- 5
      else
        fld <- 10
      if (ncol(x) <5)
        fld <- ncol(x)
      
      while(1)
      {
        opt1 <- NULL
        tryCatch(opt1 <- {R.utils::withTimeout({optL1(response=y,penalized=x,fusedl=a,fold=fld,minlambda1=1,maxlambda1=50,trace=F,standardize=T);},
                                         timeout=3600,cpu=Inf)},
                 TimeoutException = function(ex) R.utils::withTimeout({cat("Timeout. Skipping.\n")},timeout=Inf))
        if (is.null(opt1)==F)
          break
      }

      lambda1[i] <- opt1$lambda

      print(paste("lambda1",i, lambda1[i]))
      
      while(1)
      {
        opt2 <- NULL
        tryCatch(opt2 <- {R.utils::withTimeout({optL2(response=y,penalized=x,fusedl=a,fold=fld,lambda1=opt1$lambda,minlambda2=1,maxlambda2=50,trace=F,standardize=T);},
                                          timeout=3600,cpu=Inf)},
                 TimeoutException = function(ex) R.utils::withTimeout({cat("Timeout. Skipping.\n")},timeout=Inf))
        if (is.null(opt2)==F)
          break
      }
      
      lambda2[i] <- opt2$lambda
      
      print(paste("lambda2",i, lambda2[i]))
      
      fit <- penalized(y,x,lambda1=opt1$lambda,lambda2=opt2$lambda,fusedl=a,standardize=T,trace=F)
      
      t1 <- coefficients(fit,standardize=T,"all")[-1]
      
      C[i,(i+1):ncol(C)]<-t1
      
      data <- data[,-1]
      
      i<-i+1
    }
  }
  else
  {
    while(i<= dd)
    {
      y <- time[i,]
      
      x <- data[,-c(1)]
      
      a <- rep(1,ncol(x))
      
      if (ncol(x) <10)
        fld <- 5
      else
        fld <- 10
      if (ncol(x) <5)
        fld <- ncol(x)
      
      while(1)
      {
        fit <- NULL
        
        tryCatch(fit <- {R.utils::withTimeout({penalized(y,x,lambda1=lambda1[i],lambda2=lambda2[i],fusedl=a,standardize=T,trace=F);},
                                         timeout=120,cpu=Inf)},
                 TimeoutException = function(ex) R.utils::withTimeout({cat("Timeout. Skipping.\n")},timeout=Inf))  
        if (is.null(fit)==F)
          break 
      }
      
      t1 <- coefficients(fit,standardize=T,"all")[-1]
      
      C[i,(i+1):ncol(C)]<-t1
      
      data <- data[,-1]
      
      i<-i+1
    }
  }
  
  data <- main.data
  
  result <- list()
  
  C <- C[seq(from=dim(data)[2],to=1,by=-1),seq(from=dim(data)[2],to=1,by=-1)]
  
  result[[1]] <- C
    
  # neglecting the first and the last three time points
  if (ncol(data)<15)
    rm <- 2
  else
    rm <- 3
  C[1:rm,] <-0.01
  C[,1:rm] <-0
  C[,(dd+2-(rm-1)):(dd+2)] <-0
  C[(dd+2-(rm-1)):(dd+2),] <-0.01
  
  # calculating the absolute average sum of the triangular matrix C which inludes the regression coefficients
  A <- apply(abs(C),2,sum)
  A[c(1,dd+2)]=0
  r<-dd-(rm-1)*2
  A <- A/c(rep(r,rm),(r):1,rep(1,rm))
  
  local_minima <- which(diff(sign(diff(A)))==2)+1
  
  bps <- local_minima
  
  load(file)
  ts.plot(t(data),ylim=range(data),col="grey39")
  abline(v=bps,col="darkgreen",lwd=4)
  par(new=T)
  ts.plot(c(1),ylim=range(A),xlim=c(1,dd+2),gpars=list(xaxt="n",yaxt="n"),ylab="",xlab="")
  lines(A,type="o",col="red",lwd=2)
  
  result[[2]] <- bps
  
  result[[3]] <- lambda1
  
  result[[4]] <- lambda2
  
  return(result)
}
