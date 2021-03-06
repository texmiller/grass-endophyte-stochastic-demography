## Title: Grass endophyte population model with a bayesian framework
## Purpose: Creates growth kernel written in STAN with mixed effects, 
## and does visualisation of posterior predictive checks
## Authors: Joshua and Tom
#############################################################

library(tidyverse)
library(rstan)
library(StanHeaders)
library(shinystan)
library(bayesplot)
library(devtools)
library(countreg)


#############################################################################################
####### Data manipulation to prepare data as lists for Stan models------------------
#############################################################################################

# Growth data lists are generated in the endodemog_data_processing.R file
# within the section titled "Preparing datalists for Growth Kernel"
source("endodemog_data_processing.R")

#########################################################################################################
# GLMM for size_t1 ~ size_t + Endo + Origin + size_t*Endo with year and plot random effects------------------------------
#########################################################################################################
## run this code recommended to optimize computer system settings for MCMC
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())
set.seed(123)

## MCMC settings
ni <-1000
nb <- 500
nc <- 3

# Stan model -------------
## here is the Stan model with a model matrix and species effects ##



sink("endodemog_grow.stan")
cat("
    data { 
    int<lower=0> N;                       // number of observations
    int<lower=0> K;                       // number of predictors
    int<lower=0> lowerlimit;                         //lower limit for truncated negative binomial
    int<lower=0> nYear;                       // number of years (used as index)
    int<lower=0> year_t[N];                      // year of observation
    int<lower=0> nEndo;                       // number of endo treatments
    int<lower=1, upper=2> endo_index[N];          // index for endophyte effect
    int<lower=0> nPlot;                         // number of plots
    int<lower=0> plot[N];                   // plot of observation
    int<lower=lowerlimit> size_t1[N];      // plant size at time t+1 and target variable (response)
    vector<lower=0>[N] logsize_t;             // plant size at time t (predictor)
    int<lower=0,upper=1> endo_01[N];            // plant endophyte status (predictor)
    int<lower=0,upper=1> origin_01[N];          // plant origin status (predictor)
    }
    
    parameters {
    vector[K] beta;                     // predictor parameters

    vector[nYear] tau_year[nEndo];      // random year effect
    real<lower=0> sigma_e[nEndo];        //year variance by endophyte effect
    vector[nPlot] tau_plot;        // random plot effect
    real<lower=0> sigma_p;          // plot variance
    real<lower=0> phi;            // dispersion parameter
    }
    
    transformed parameters{
    real mu[N];                         // Linear Predictor

    
      for(n in 1:N){
    mu[n] = beta[1] + beta[2]*logsize_t[n] + beta[3]*endo_01[n] +beta[4]*origin_01[n]
    + tau_year[endo_index[n],year_t[n]]
    + tau_plot[plot[n]];
      }
    
    }
    
    model {

    // Priors
    beta ~ normal(0,100);      // prior for predictor intercepts
    tau_plot ~ normal(0,sigma_p);   // prior for plot random effects
    to_vector(tau_year[1]) ~ normal(0,sigma_e[1]);   // prior for E- year random effects
    to_vector(tau_year[2]) ~ normal(0,sigma_e[2]);   // prior for E+ year random effects
    phi ~ cauchy(0., 5.);


    // Likelihood
    for(n in 1:N){
    size_t1[n] ~ neg_binomial_2_log(mu[n],phi);
      target += -log1m(neg_binomial_2_log_lpmf(lowerlimit | mu[n], phi)); // manually adjusting computation of likelihood because T[,] truncation syntax doesn't compile for neg binomial
    }
    }
    
   generated quantities{
   }
  
    ", fill = T)
sink()

stanmodel <- stanc("endodemog_grow.stan")


## Run the model by calling stan()
## and save the output to .rds files so that they can be called later

smAGPE <- stan(file = "endodemog_grow.stan", data = AGPE_grow_data_list,
           iter = ni, warmup = nb, chains = nc, save_warmup = FALSE)

# saveRDS(smAGPE, file = "endodemog_grow_AGPE.rds")

smELRI <- stan(file = "endodemog_grow.stan", data = ELRI_grow_data_list,
               iter = ni, warmup = nb, chains = nc, save_warmup = FALSE)
# saveRDS(smELRI, file = "endodemog_grow_ELRI.rds")

smELVI <- stan(file = "endodemog_grow.stan", data = ELVI_grow_data_list,
               iter = ni, warmup = nb, chains = nc, save_warmup = FALSE)
# saveRDS(smELVI, file = "endodemog_grow_ELVI.rds")

smFESU <- stan(file = "endodemog_grow.stan", data = FESU_grow_data_list,
               iter = ni, warmup = nb, chains = nc, save_warmup = FALSE)
# saveRDS(smFESU, file = "endodemog_grow_FESU.rds")

smLOAR <- stan(file = "endodemog_grow.stan", data = LOAR_grow_data_list,
               iter = ni, warmup = nb, chains = nc, save_warmup = FALSE)
# saveRDS(smLOAR, file = "endodemog_grow_LOAR.rds")

smPOAL <- stan(file = "endodemog_grow.stan", data = POAL_grow_data_list,
               iter = ni, warmup = nb, chains = nc, save_warmup = FALSE)
# saveRDS(smPOAL, file = "endodemog_grow_POAL.rds")

smPOSY <- stan(file = "endodemog_grow.stan", data = POSY_grow_data_list,
               iter = ni, warmup = nb, chains = nc, save_warmup = FALSE)
# saveRDS(smPOSY, file = "endodemog_grow_POSY.rds")





print(sm)
summary(sm)
print(sm, pars = "tau_year")


## to read in model output without rerunning models

smAGPE <- readRDS(file = "/Users/joshuacfowler/Dropbox/EndodemogData/Model_Runs/endodemog_grow_AGPE.rds")
smELRI <- readRDS(file = "/Users/joshuacfowler/Dropbox/EndodemogData/Model_Runs/endodemog_grow_ELRI.rds")
smELVI <- readRDS(file = "/Users/joshuacfowler/Dropbox/EndodemogData/Model_Runs/endodemog_grow_ELVI.rds")
smFESU <- readRDS(file = "/Users/joshuacfowler/Dropbox/EndodemogData/Model_Runs/endodemog_grow_FESU.rds")
smLOAR <- readRDS(file = "/Users/joshuacfowler/Dropbox/EndodemogData/Model_Runs/endodemog_grow_LOAR.rds")
smPOAL <- readRDS(file = "/Users/joshuacfowler/Dropbox/EndodemogData/Model_Runs/endodemog_grow_POAL.rds")
smPOSY <- readRDS(file = "/Users/joshuacfowler/Dropbox/EndodemogData/Model_Runs/endodemog_grow_POSY.rds")


#########################################################################################################
###### Perform posterior predictive checks and assess model convergence-------------------------
#########################################################################################################
params <- c("beta[1]", "beta[2]", "tau_year[1,1]", "sigma_e[1]", "sigma_e[2]")


##### POAL - growth
print(smPOAL)

## plot traceplots of chains for select parameters
traceplot(smAGPE, pars = params)
traceplot(smELRI, pars = params)
traceplot(smELVI, pars = params)
traceplot(smFESU, pars = params)
traceplot(smLOAR, pars = params)
traceplot(smPOSY, pars = params)
traceplot(smPOSY, pars = params)


# Pull out the posteriors
post_growAGPE <- rstan::extract(smAGPE)
post_growELRI <- rstan::extract(smELRI)
post_growELVI <- rstan::extract(smELVI)
post_growFESU <- rstan::extract(smFESU)
post_growLOAR <- rstan::extract(smLOAR)
post_growPOAL <- rstan::extract(smPOAL)
post_growPOSY <- rstan::extract(smPOSY)


post_growAGPE$phi

# This function rstan::extracts the posterior draws and generates replicate data for each given model

prediction <- function(data, fit, n_post_draws){
  post <- rstan::extract(fit)
  mu <- post$mu
  phi <- post$phi
  yrep <- matrix(nrow =n_post_draws, ncol = data$N)
  for(i in 1:n_post_draws){
    for(j in 1:data$N)
    yrep[i,j] <- sample(x = 1:n_post_draws, size=1, replace=T, prob=dnbinom(1:n_post_draws, mu = exp(mu[i,j]), size = phi[i]/(1-dnbinom(0, mu = exp(mu[i,j]), size = phi[i]))))
  }
  out <- list(yrep, mu)
  names(out) <- c("yrep", "mu")
  return(out)
}

# apply the function for each species
AGPE_grow_yrep <- prediction(data = AGPE_grow_data_list, fit = smAGPE, n_post_draws =100)
ELRI_grow_yrep <- prediction(data = ELRI_grow_data_list, fit = smELRI, n_post_draws =100)
ELVI_grow_yrep <- prediction(data = ELVI_grow_data_list, fit = smELVI, n_post_draws =100)
FESU_grow_yrep <- prediction(data = FESU_grow_data_list, fit = smFESU, n_post_draws =100)
LOAR_grow_yrep <- prediction(data = LOAR_grow_data_list, fit = smLOAR, n_post_draws =100)
POAL_grow_yrep <- prediction(data = POAL_grow_data_list, fit = smPOAL, n_post_draws =100)
POSY_grow_yrep <- prediction(data = POSY_grow_data_list, fit = smPOSY, n_post_draws =100)


# overlay 100 replicates over the actual dataset
ppc_dens_overlay( y = AGPE_grow_data_list$size_t1, yrep = AGPE_grow_yrep$yrep[1:100,]) + xlim(0,50) + xlab("prob. of y") + ggtitle("AGPE")

ppc_dens_overlay( y = AGPE_grow_data_list$size_t1, yrep = AGPE_grow_trunc$yrep[1:100,]) + xlim(0,50) + xlab("prob. of y") + ggtitle("AGPE")

ppc_dens_overlay( y = ELRI_grow_data_list$size_t1, yrep = ELRI_grow_yrep$yrep[1:100,]) + xlim(0,50) + xlab("prob. of y") + ggtitle("ELRI")

ppc_dens_overlay( y = ELVI_grow_data_list$size_t1, yrep = ELVI_grow_yrep$yrep[1:100,]) + xlim(0,20) + xlab("prob. of y") + ggtitle("ELVI")

ppc_dens_overlay( y = FESU_grow_data_list$size_t1, yrep = FESU_grow_yrep$yrep[1:100,])+ xlim(0,30)  + xlab("prob. of y") + ggtitle("FESU")

ppc_dens_overlay( y = LOAR_grow_data_list$size_t1, yrep = LOAR_grow_yrep$yrep[1:100,]) + xlim(0,50)  + xlab("prob. of y") + ggtitle("LOAR")

ppc_dens_overlay( y = POAL_grow_data_list$size_t1, yrep = POAL_grow_yrep$yrep[1:100,]) + xlim(0,50) + xlab("prob. of y") + ggtitle("POAL")

ppc_dens_overlay( y = POSY_grow_data_list$size_t1, yrep = POSY_grow_yrep$yrep[1:100,]) + xlim(0,50) + xlab("prob. of y") + ggtitle("POSY")













