library(alabama)

#-----------------------------------------
# data
#-----------------------------------------

T <- 26

ρ  <- 0.05
g  <- 0.03
δ  <- 0.02
K0 <- 3
I0 <- 0.05
C0 <- 0.95
L0 <- 1
b  <- 0.25


τ <- 0:(T-1)

β <- (1+ρ)^(-τ)
β[T] <- (1/ρ)*(1+ρ)^(1-T+1)


L <- (1+g)^τ * L0
Lb <- L^(1-b)

a <- (C0+I0)/(K0^b * L0^(1-b))

#-----------------------------------------
# indexing
#-----------------------------------------

Ci <- 1:T
Yi <- (T+1):(2*T)
Ki <- (2*T+1):(3*T)
Ii <- (3*T+1):(4*T)

n <- 4*T

#-----------------------------------------
# objective
#-----------------------------------------

# we don't have bounds, so protect log(Ct) here
obj <- function(x) {
  Ct <- x[Ci]
  if(any(Ct <= 0.001)) return(1e20)
  -sum(β * log(Ct))
}

#-----------------------------------------
# equality constraints
#-----------------------------------------

heq <- function(x){
  
  Ct <- x[Ci]
  Yt <- x[Yi]
  Kt <- x[Ki]
  It <- x[Ii]
  
  # protect against Kt[t] < 0
  Kt[Kt<0] <- 0
  
  prod  <- Yt - a*Kt^b*Lb
  alloc <- Yt - Ct - It
  accum <- Kt[2:T] - ((1-δ)*Kt[1:(T-1)] + It[1:(T-1)])
  
  # in GAMS period 1 is fixed
  # no bounds in this solver so we use equality constraints
  init <- c(
    Kt[1]-K0,
    It[1]-I0,
    Ct[1]-C0
  )
  
  c(prod,alloc,accum,init)
}

#-----------------------------------------
# single inequality constraint
#-----------------------------------------

hin <- function(x) {
  
  Klast <- x[3*T]
  Ilast <- x[4*T]
  
  Ilast - (g+δ)*Klast
}

#-----------------------------------------
# starting point
#-----------------------------------------

x0 <- rep(1,n)

x0[Ci] <- C0
x0[Yi] <- C0+I0
x0[Ki] <- K0
x0[Ii] <- I0

#-----------------------------------------
# solve
#-----------------------------------------

res <- auglag(
  par=x0,
  fn=obj,
  heq=heq,
  hin=hin
)

#-----------------------------------------
# results
#-----------------------------------------

x <- res$par

Ct <- x[Ci]
Yt <- x[Yi]
Kt <- x[Ki]
It <- x[Ii]

results <- data.frame(
  t=0:(T-1),
  C=Ct,
  Y=Yt,
  K=Kt,
  I=It
)

print(results)
cat("Utility =", -res$value,"\n")

