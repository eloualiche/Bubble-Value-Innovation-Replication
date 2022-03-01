# ---------------------------------------------------------------------
library(crayon)
library(devtools)

library(fst)
library(stringr)
library(dplyr)
library(glue)
library(texreg)
library(haven)
library(bit64)
library(lfe)
library(skimr)
library(brew)

library(data.table);
library(statar)

# LOAD PERSONAL UTILITIES 
source("./src/star_builder.R")
# ---------------------------------------------------------------------


# ---------------------------------------------------------------------
# READ DATA
dt_pat = read_fst("./input/patents.fst", as.data.table = TRUE)
dt_pat_firm = readRDS("./input/kpss_firm_innovation.rds")
setnames(dt_pat_firm, "year", "date_y")
dt_pat_dp = read_fst("./input/patents_dp.fst", as.data.table = TRUE)

dt_bubble_y    <- readRDS("./input/fama_bubbles.rds")      
dt_bubble_y[, crash_dummy := as.factor(fifelse(is.na(crash), 0, crash+1)) ]
# ---------------------------------------------------------------------


# ---------------------------------------------------------------------
dt_pat_bubbles <- copy(dt_pat_dp)
dt_pat_bubbles[, date_y := gyear ]
dt_pat_bubbles <- merge(dt_pat_bubbles, dt_bubble_y, all.x = T, by = c("date_y", "permno"))
dt_pat_bubbles <- dt_pat_bubbles[ !is.na(date_y) & !is.na(permno)]
dt_pat_bubbles <- dt_pat_bubbles[ is.finite(log_Af) & is.finite(log_N) & is.finite(log_M) & is.finite(log_vol) ]

dt_pat_firm_bubbles <- merge(dt_pat_firm, dt_bubble_y, all.x=T, by=c("date_y", "permno"))
dt_pat_firm_bubbles <- merge(dt_pat_firm_bubbles, 
  unique(dt_pat_bubbles[, .(date_y, gvkey, permno, log_l1y_me)]), all.x=T, by=c("date_y", "permno") ) 
dt_pat_firm_bubbles <- dt_pat_firm_bubbles[ !is.na(date_y) & !is.na(permno)]
dt_pat_firm_bubbles <- dt_pat_firm_bubbles[ !is.na(ff49) ]
dt_pat_firm_bubbles[, year_fac := as.factor(date_y) ]
dt_pat_firm_bubbles[ Tsm > 0, log_Tsm := log(Tsm) ]
dt_pat_firm_bubbles[ Tsm >= 0, log_ext_Tsm := log(1+Tsm) ]
dt_pat_firm_bubbles[ Tcw > 0, log_Tcw := log(Tcw) ]
dt_pat_firm_bubbles[ Tcw >= 0, log_ext_Tcw := log(1+Tcw) ]
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# REGRESSIONS
# ------------------------------------------------------------------------------
# patent level
r_sm_p_1a = felm(log_Af ~ bubble | year_fac + as.factor(permno) | 0 | year_fac, dt_pat_bubbles)
r_sm_p_2a = felm(log_Af ~ bubble + log_N | year_fac + as.factor(permno)  | 0 | year_fac, dt_pat_bubbles)
r_sm_p_3a = felm(log_Af ~ bubble + log_N + log_l1y_me | year_fac + as.factor(permno)  | 0 | year_fac, dt_pat_bubbles)
r_sm_p_4a = felm(log_Af  ~ bubble + log_N + log_N*bubble   | year_fac + as.factor(permno)  | 0 | year_fac, dt_pat_bubbles)
# firm level
r_sm_f_1a = felm(log_Tsm ~ bubble           | year_fac + as.factor(permno) | 0 | year_fac, dt_pat_firm_bubbles)
r_sm_f_2a = felm(log_Tsm ~ bubble + log_Tcw | year_fac + as.factor(permno) | 0 | year_fac, dt_pat_firm_bubbles)
r_sm_f_3a = felm(log_Tsm ~ bubble + log_Tcw + log_l1y_me | as.factor(permno) + year_fac | 0 | year_fac, dt_pat_firm_bubbles)
r_sm_f_4a = felm(log_Tsm ~ bubble + log_Tcw + log_Tcw*bubble   | as.factor(permno) + year_fac | 0 | year_fac, dt_pat_firm_bubbles)

r_dp_bubble_list = list(r1 = r_sm_p_1a, r2 = r_sm_p_2a, r4 = r_sm_p_4a, 
                        r5 = r_sm_f_1a, r6 = r_sm_f_2a, r8 = r_sm_f_4a)
screenreg(r_dp_bubble_list, digits=3, stars=c(0.01, 0.05, 0.1))

brew("./input/tables/table1.brew.tex", "./output/tables/table1.tex")
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
