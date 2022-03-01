# ---------------------------------------------------------------------
# PACKAGES
library(lubridate)
library(lfe);
library(fixest)
library(glue)
library(fst);
library(sandwich); 
library(stringr)
library(lmtest); 
library(stargazer);
library(texreg)
library(brew)
library(dplyr); 
library(magrittr); 
library(data.table);
library(statar); 

source("./src/star_builder.R")
# ---------------------------------------------------------------------


# ---------------------------------------------------------------------
# READ BSvR data
dt_reg = readRDS("./input/BSvR.rds") %>% data.table
# ---------------------------------------------------------------------


# ---------------------------------------------------------------------
# --- set up the regressions
rhs_var1 = "grd_k1_dum + grd_kt2 + grd_kt3 + grd_kt4 + grd_kt5 + grd_kt6 + lsales_ind + lsales_ind1"
rhs_var2 = "lemp1 + lppent1 + lgrd1 + lgrd1_dum + lsales_ind + lsales_ind1 + lpind_ind"
fe_var = "cusip + date_y"

form_jaf_Q_1 = glue("lq ~ lgspilltec1  + lgspillsic1*bubble + grd_k1*bubble + {rhs_var1} |",
  " {fe_var} | 0 | date_y")
form_mal_Q_1 = glue("lq ~ lgspillmaltec1  + lgspillmalsic1*bubble + grd_k1*bubble + {rhs_var1} |",
  " {fe_var} | 0 | date_y")
form_jaf_S_1 = glue("lsales ~ lgspilltec1  + lgspillsic1*bubble + {rhs_var2} |",
  " {fe_var} | 0 | date_y")
form_mal_S_1 = glue("lsales ~ lgspillmaltec1  + lgspillmalsic1*bubble + {rhs_var2} |",
  " {fe_var} | 0 | date_y")
form_jaf_Q_IV1 = glue("lq ~ grd_k1*bubble + {rhs_var1} | {fe_var} ",
  "| lgspilltec1 + lgspillsic1 + lgspillsic1:bubble ~ lgspilltecIV1 + lgspillsicIV1 + lgspillsicIV1:bubble")
form_jaf_S_IV1 = glue("lsales ~ {rhs_var2} | {fe_var} ",
  "| lgspilltec1 + lgspillsic1 + lgspillsic1:bubble ~ lgspilltecIV1 + lgspillsicIV1 + lgspillsicIV1:bubble")

r_Q_jaf1    = felm(as.formula(form_jaf_Q_1), dt_reg)
r_Q_mal1    = felm(as.formula(form_mal_Q_1), dt_reg)
r_S_jaf1    = felm(as.formula(form_jaf_S_1), dt_reg)
r_S_mal1    = felm(as.formula(form_mal_S_1), dt_reg)
r_Q_jaf_IV1 = feols(as.formula(form_jaf_Q_IV1), dt_reg)
r_Q_jaf_IV1 = summary(r_Q_jaf_IV1, se = "hetero", dof = dof(cluster.df = "conv"))
r_S_jaf_IV1 = feols(as.formula(form_jaf_S_IV1), dt_reg)
r_S_jaf_IV1 = summary(r_S_jaf_IV1, se = "hetero", dof = dof(cluster.df = "conv"))

# TO DO: include in a brew
r_list = list(r_Q_jaf1, r_Q_mal1, r_Q_jaf_IV1, r_S_jaf1, r_S_mal1, r_S_jaf_IV1)
brew("./input/tables/table3.brew.tex", "./output/tables/table3.tex")          
# ---------------------------------------------------------------------













