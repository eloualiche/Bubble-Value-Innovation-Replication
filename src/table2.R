# -----------------------------------------------------------------------------
library(crayon)
library(devtools)

library(fst)
library(stringr)
library(zeallot)
library(dplyr)
library(brew)
library(glue)
library(lfe)
library(texreg)
library(data.table);
library(statar)

source("./src/star_builder.R")
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
dt_kpss = readRDS("./input/kpss_supplement_firm.rds")
setDT(dt_kpss)
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
dt_kpss[, l1_logP := tlag(logP, time=year), by = .(permno) ] 
for (i_lead in seq(1, 5)){
  dt_kpss[, d_tmp := tlead(logP, time=year, n=i_lead) - l1_logP, by = .(permno)]
  setnames(dt_kpss, "d_tmp", glue("df{i_lead}_logP"))
}

# dt_kpss[, l1_logY := tlag(logY, time=year), by = .(permno) ] 
# for (i_lead in seq(1, 5)){
#   dt_kpss[, d_tmp := tlead(logY, time=year, n=i_lead) - l1_logY, by = .(permno)]
#   setnames(dt_kpss, "d_tmp", glue("df{i_lead}_logY"))
# }
# dt_kpss[, l1_logX := tlag(logX, time=year), by = .(permno) ] 
# for (i_lead in seq(1, 5)){
#   dt_kpss[, d_tmp := tlead(logX, time=year, n=i_lead) - l1_logX, by = .(permno)]
#   setnames(dt_kpss, "d_tmp", glue("df{i_lead}_logX"))
# }

# Stock market
dt_kpss[, l_AfI := tlag(AfI, time=year), by = .(permno) ] 
dt_kpss[, l_Af := tlag(Af, time=year), by = .(permno) ]   
dt_kpss[, l_AcwI := tlag(AcwI, time=year), by = .(permno) ] 
dt_kpss[, l_Acw := tlag(Acw, time=year), by = .(permno) ]   

# merge with bubbles
dt_kpss[, date_y := gyear ]
dt_bubble_y     <- readRDS("./input/fama_bubbles.rds")      
dt_kpss <- merge(dt_kpss, dt_bubble_y, all.x = T, by = c("date_y", "permno"))
dt_kpss <- dt_kpss[ !is.na(date_y) & !is.na(permno)]
dt_kpss[, bubble0 := fifelse(bubble==1, 0, 1) ]
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# REGRESSIONS FOR ALL HORIZONS: PROFITS ON CITATION PATENTS AND SM PATENTS
run_val_desires <- function(lhs = "logP"){
  for (i_lead in seq(1, 5)){
    message("# Running regressions for horizon: .... ", i_lead)
    dt_reg_bubbles <- dt_kpss[ is.finite(get(glue("df{i_lead}_{lhs}"))) & is.finite(LlogK) & 
                               is.finite(LlogH) & is.finite(l_AcwI) & is.finite(l_Acw) & 
                               is.finite(Lvol_iret) & is.finite(get(glue("l1_{lhs}"))) ]
    # KPSS coefficients standardized the RHS variables l_AfI and l_Af
    dt_reg_bubbles[, l_z_AcwI := l_AcwI / sd(l_AcwI)] 
    dt_reg_bubbles[, l_z_Acw  := l_Acw  / sd(l_Acw)] 
    dt_reg_bubbles[, l_z_AfI := l_AfI / sd(l_AfI)] 
    dt_reg_bubbles[, l_z_Af  := l_Af  / sd(l_Af)] 
    reg_fi_formd <- glue("df{i_lead}_{lhs} ~ LlogK + LlogH + bubble*l_z_Acw + Lvol_iret + l1_{lhs}",
                         "| year + indcd", "| 0", "| permno + year")
    reg_fid <- felm(as.formula(reg_fi_formd), dt_reg_bubbles)
    assign(glue("reg_f{i_lead}d"), reg_fid)
  }
  return(list(reg_f1d, reg_f2d, reg_f3d, reg_f4d, reg_f5d))
}
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
c(reg_f1d_P, reg_f2d_P, reg_f3d_P, reg_f4d_P, reg_f5d_P) %<-% run_val_desires("logP")
# c(reg_f1d_X, reg_f2d_X, reg_f3d_X, reg_f4d_X, reg_f5d_X) %<-% run_val_desires("logX")
# c(reg_f1d_Y, reg_f2d_Y, reg_f3d_Y, reg_f4d_Y, reg_f5d_Y) %<-% run_val_desires("logY")

r_l_P = list(reg_f1d_P, reg_f2d_P, reg_f3d_P, reg_f4d_P, reg_f5d_P)
screenreg(r_l_P, digits=3, stars=c(0.01, 0.05, 0.1))

brew("./input/tables/table2.brew.tex", "./output/tables/table2.tex")

# -----------------------------------------------------------------------------



