library(tidyverse)
library(rstan)
rstan_options( auto_write = TRUE )
options( mc.cores = parallel::detectCores() )
library(bayesplot)

joshpath <- "/Users/joshuacfowler/Dropbox/EndodemogData/"
tompath <- "C:/Users/tm9/Dropbox/EndodemogData/"
#tompath <- "C:/Users/tm634/Dropbox/EndodemogData/"

LTREB_full <- read_csv(paste0(tompath,"Fulldataplusmetadata/LTREB_full.csv"))
LTREB_data_forsurv <- LTREB_full %>%
  filter(!is.na(surv_t1)) %>% 
  filter(!is.na(logsize_t)) %>% 
  filter(logsize_t >= 0) %>% 
  filter(!is.na(endo_01))
## note that I am fitting flowering model to size_t1 / flowering_t1 (Josh did size_t/flowering_t). We gain 2018 data my way.
LTREB_data_forflw <- LTREB_full %>% 
  filter(!is.na(FLW_STAT_T1)) %>% 
  filter(!is.na(logsize_t1)) %>% 
  filter(!is.na(endo_01))
LTREB_data_forgrow <- LTREB_full %>%
  filter(!is.na(logsize_t)) %>% 
  filter(!is.na(size_t1)) %>% 
  filter(!is.na(endo_01)) %>% 
  mutate(size_t1 = as.integer(size_t1))
## again, here I am using size_t1 and flw_count_t1
LTREB_data_forfert <- LTREB_full %>% 
  filter(!is.na(FLW_COUNT_T1)) %>% 
  filter(FLW_COUNT_T1 > 0) %>% 
  filter(!is.na(logsize_t1))

## this is good, there are no plot numbers duplicated across species
table(LTREB_data_forsurv$plot_fixed,LTREB_data_forsurv$species)

## note that this is how species are indexing:
cbind(unique(LTREB_data_forsurv$species),
as.integer(as.numeric(as.factor(unique(LTREB_data_forsurv$species)))))

surv_dat <- list(nYear = length(unique(LTREB_data_forsurv$year_t - (min(LTREB_data_forsurv$year_t)-1))),
                 nPlot = max(LTREB_data_forsurv$plot_fixed),
                 nSpp = length(unique(LTREB_data_forsurv$species)),
                 nEndo=length(unique(LTREB_data_forsurv$endo_01)),
                 N = nrow(LTREB_data_forsurv),
                 year_t = LTREB_data_forsurv$year_t - (min(LTREB_data_forsurv$year_t)-1),
                 plot = LTREB_data_forsurv$plot_fixed,
                 spp = as.integer(as.numeric(as.factor(LTREB_data_forsurv$species))),
                 y = LTREB_data_forsurv$surv_t1,
                 logsize_t = LTREB_data_forsurv$logsize_t,
                 endo_01 = LTREB_data_forsurv$endo_01,
                 origin_01 = LTREB_data_forsurv$origin_01)
flow_dat <- list(nYear = length(unique(LTREB_data_forflw$year_t - (min(LTREB_data_forflw$year_t)-1))),
                 nPlot = max(LTREB_data_forflw$plot_fixed),
                 nSpp = length(unique(LTREB_data_forflw$species)),
                 nEndo=length(unique(LTREB_data_forflw$endo_01)),
                 N = nrow(LTREB_data_forflw),
                 year_t = LTREB_data_forflw$year_t - (min(LTREB_data_forflw$year_t)-1),
                 plot = LTREB_data_forflw$plot_fixed,
                 spp = as.integer(as.numeric(as.factor(LTREB_data_forflw$species))),
                 y = LTREB_data_forflw$FLW_STAT_T1,
                 logsize_t = LTREB_data_forflw$logsize_t1,
                 endo_01 = LTREB_data_forflw$endo_01,
                 origin_01 = LTREB_data_forflw$origin_01)
grow_dat <- list(nYear = length(unique(LTREB_data_forgrow$year_t - (min(LTREB_data_forgrow$year_t)-1))),
                 nPlot = max(LTREB_data_forgrow$plot_fixed),
                 nSpp = length(unique(LTREB_data_forgrow$species)),
                 nEndo=length(unique(LTREB_data_forgrow$endo_01)),
                 N = nrow(LTREB_data_forgrow),
                 year_t = LTREB_data_forgrow$year_t - (min(LTREB_data_forgrow$year_t)-1),
                 plot = LTREB_data_forgrow$plot_fixed,
                 spp = as.integer(as.numeric(as.factor(LTREB_data_forgrow$species))),
                 y = LTREB_data_forgrow$size_t1,
                 logsize_t = LTREB_data_forgrow$logsize_t,
                 endo_01 = LTREB_data_forgrow$endo_01,
                 origin_01 = LTREB_data_forgrow$origin_01)
fert_dat <- list(nYear = length(unique(LTREB_data_forfert$year_t - (min(LTREB_data_forfert$year_t)-1))),
                 nPlot = max(LTREB_data_forfert$plot_fixed),
                 nSpp = length(unique(LTREB_data_forfert$species)),
                 nEndo=length(unique(LTREB_data_forfert$endo_01)),
                 N = nrow(LTREB_data_forfert),
                 year_t = LTREB_data_forfert$year_t - (min(LTREB_data_forfert$year_t)-1),
                 plot = LTREB_data_forfert$plot_fixed,
                 spp = as.integer(as.numeric(as.factor(LTREB_data_forfert$species))),
                 y = LTREB_data_forfert$FLW_COUNT_T1,
                 logsize_t = LTREB_data_forfert$logsize_t1,
                 endo_01 = LTREB_data_forfert$endo_01,
                 origin_01 = LTREB_data_forfert$origin_01)

sim_pars <- list(
  warmup = 1000, 
  iter = 5000, 
  thin = 3, 
  chains = 1
)

surv_fit <- stan(
  file = 'survival_flowering_random_spp.stan',
  data = surv_dat,
  warmup = sim_pars$warmup,
  iter = sim_pars$iter,
  thin = sim_pars$thin,
  chains = sim_pars$chains )
#write_rds(surv_fit,paste0(tompath,"Fulldataplusmetadata/SppRFX/surv_fit.rds"))
surv_fit <- read_rds(paste0(tompath,"Fulldataplusmetadata/SppRFX/surv_fit.rds"))
mcmc_dens_overlay(surv_fit,pars = c("mu_betaendo"))
mcmc_rhat(surv_fit,pars = c("mu_betaendo"))

flow_fit <- stan(
  file = 'survival_flowering_random_spp.stan',
  data = flow_dat,
  warmup = sim_pars$warmup,
  iter = sim_pars$iter,
  thin = sim_pars$thin,
  chains = sim_pars$chains )
write_rds(flow_fit,paste0(tompath,"Fulldataplusmetadata/SppRFX/flow_fit.rds"))

grow_fit <- stan(
  file = 'growth_fertility_random_spp.stan',
  data = grow_dat,
  warmup = sim_pars$warmup,
  iter = sim_pars$iter,
  thin = sim_pars$thin,
  chains = sim_pars$chains )
write_rds(grow_fit,paste0(tompath,"Fulldataplusmetadata/SppRFX/grow_fit.rds"))

fert_fit <- stan(
  file = 'growth_fertility_random_spp.stan',
  data = fert_dat,
  warmup = sim_pars$warmup,
  iter = sim_pars$iter,
  thin = sim_pars$thin,
  chains = sim_pars$chains )
write_rds(fert_fit,paste0(tompath,"Fulldataplusmetadata/SppRFX/fert_fit.rds"))


mcmc_trace(surv_fit,par=c("beta0"))
mcmc_trace(surv_fit,par=c("betasize"))
mcmc_trace(surv_fit,par=c("betaendo"))