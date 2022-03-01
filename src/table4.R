# -----------------------------------------------------------------------------
library(lubridate)
library(purrr)
library(fst)
library(stringr)
library(glue)
library(lfe)
library(texreg)
library(brew)
library(data.table);
library(statar); 

source("./src/star_builder.R")
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
dt1 = readRDS("./input/panel_13F.rds") %>% data.table
dt1[, date_tmp := ISOdate(year, quarter*3-2, 1) ]
dt1[, date := as.Date(date_tmp) ]
dt1[, date_tmp := NULL ]
dt1[, date_fac := as.factor(date) ]
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# MERGE TYPECODES
dt_mgr_codes = readRDS("./input/mgr_typecode.rds") %>% data.table
dt_mgr_codes = dt_mgr_codes[, .(date = as.Date(dateq), mgrno, mgrtype=as.character(type_ky)) ]
dt1 = merge(dt1, dt_mgr_codes, all.x = TRUE, by = c("date", "mgrno"))
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# MERGE VOLATILITY
# dt_dsf = fread("~/path/to/file/dsf.csv",   # your version of CRSP DSF File
#   select=c("PERMNO", "date", "HEXCD", "SHRCD", "PRC", "RET", "SICCD") )
# setnames(dt_dsf, tolower(colnames(dt_dsf)) )
# dt_dsf = dt_dsf[hexcd %in% c(1,2,3) & shrcd %in% c(10,11)    ]       # keep only stocks
# dt_dsf[, c("hexcd", "shrcd") := NULL ]
# dt_dsf[, `:=`(ret     = as.numeric(ret),
#               date    = as.Date( as.character(date), "%Y%m%d") ) ]
# dt_dsf[, date_y := year(date) ]
# setnames(dt_dsf, "siccd", "sic")
# source("./src/FF49.R") # assign industries
# dt_tmp = dt_dsf[, .(permno, date_y, sic) ] %>% unique
# dt_tmp = FF49(dt_tmp)
# dt_dsf_tmp = merge(dt_dsf, dt_tmp, all.x=T, by=c("permno", "date_y", "sic") )
# dt_dsf_tmp[, vol_annual := sd(ret, na.rm=T), by=.(date_y, permno) ]
# setorder(dt_dsf_tmp, permno, date)
# dt_dsf_tmp[, vol_rolling := frollmean(ret, 300L, align="right", fill=NA), by=.(permno)]
# dt_dsf_tmp[, vol_rolling := sqrt(frollmean((ret-vol_rolling)^2, 300L, align="right", fill=NA)), by=.(permno)]
# # industry
# dt_vol_ind = dt_dsf_tmp[, .(permno, date_y, date, ret, ff49) ] %>% unique
# dt_vol_ind = dt_vol_ind[, .(ret = mean(ret, na.rm=T)), by = .(date, date_y, ff49) ]
# dt_vol_ind[, vol_ind_annual := sd(ret, na.rm=T), by = .(date_y, ff49) ]
# dt_vol_ind_annual = dt_vol_ind[, .(date_y, ff49, vol_ind_annual)] %>% unique
# setorder(dt_vol_ind, ff49, date)
# dt_vol_ind[, vol_ind_rolling := frollmean(ret, 300L, align="right", fill=NA), by=.(ff49)]
# dt_vol_ind[, vol_ind_rolling := sqrt(frollmean((ret-vol_ind_rolling)^2, 300L, align="right", fill=NA)), by=.(ff49)]
# dt_dsf_tmp = merge(dt_dsf_tmp, dt_vol_ind[, .(date, ff49, vol_ind_annual, vol_ind_rolling)], 
#                    all.x=T, by=c("date", "ff49"))
# dt_dsf_tmp[, dateq := as.quarterly(date) ]
# dt_vol_full = dt_dsf_tmp[, .(date, dateq, date_y, ff49, permno,
#                              vol_annual, vol_rolling, vol_ind_annual, vol_ind_rolling)] %>% unique
# fst::write_fst(dt_vol_full, "./output/dsf_vol_full.fst", compress=100)

dt_vol = read_fst("./input/dsf_vol_full.fst", as.data.table=TRUE) # SEE TABLE 4
dt_vol[, dateq := as.quarterly(dateq) ]
dt_vol_ind = dt_vol[, .(vol_ind_rolling=mean(vol_ind_rolling, na.rm=T)), by = .(dateq, ff49) ]
dt1[, dateq := as.quarterly(date) ]
dt1 = merge(dt1, dt_vol_ind[, .(dateq, ff49=as.character(ff49), vol_ind_rolling)], all.x=T, by = c("ff49", "dateq"))
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
setorder(dt1, ff49, date, mgrno)
dt1[, inv_nfrac := 1/nfrac_ff49 ]
dt1[, log_aum   := log(aum) ]
dt1[, log_Nstocks_ff49   := log(totalstocks_ff49) ]
setnames(dt1, "hhi", "HHI")

dt1[, mgr_name := fcase(mgrtype==1L, "bank",    mgrtype==2L, "insur",   
                        mgrtype==3L, "adviser", mgrtype==4L, "mutual", 
                        mgrtype==5L, "pension", mgrtype==6L, "other", 
                        default="other_other")]
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
do_allreg = function(dt_reg, rhs=c("log_aum", "log_Nstocks_ff49")){

lhs1  = glue("inv_nfrac  ~ bubble ")
lhs1b = glue("inv_nfrac ~ bubble:as.factor(mgr_name)")
fe1 = "| 0 | 0 | date_fac"
fe2 = "| ff49 | 0 | date_fac"
fe3 = "| date_fac | 0 | date_fac"
fe4 = "| ff49 + date_fac | 0 | date_fac"
fe1b = "| as.factor(mgr_name) | 0 | date_fac"
fe2b = "| as.factor(mgr_name) + ff49 | 0 | date_fac"
fe3b = "| as.factor(mgr_name) + date_fac | 0 | date_fac"
fe4b = "| as.factor(mgr_name) + ff49 + date_fac | 0 | date_fac"
rhs_formula = paste(ifelse(sum(str_length(rhs))>0, "+", ""), paste(rhs, collapse=" + "))

r1  = felm(as.formula(paste0(lhs1,  rhs_formula, fe1)), dt_reg)
r2  = felm(as.formula(paste0(lhs1,  rhs_formula, fe2)), dt_reg)
r3  = felm(as.formula(paste0(lhs1,  rhs_formula, fe3)), dt_reg)
r4  = felm(as.formula(paste0(lhs1,  rhs_formula, fe4)), dt_reg)
r1b = felm(as.formula(paste0(lhs1b, rhs_formula, fe1b)), dt_reg)
r2b = felm(as.formula(paste0(lhs1b, rhs_formula, fe2b)), dt_reg)
r3b = felm(as.formula(paste0(lhs1b, rhs_formula, fe3b)), dt_reg)
r4b = felm(as.formula(paste0(lhs1b, rhs_formula, fe4b)), dt_reg)

l_res = list(r1, r2, r3, r4, r1b, r2b, r3b, r4b)
}
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# ROBUSTNESS #1 --> controlling for volatility
dt_reg = dt1[ n_ff49 >= 10 & mgr_name != "other_other" ]
l_res = do_allreg(dt_reg,  rhs=c("log_aum", "log_Nstocks_ff49", "vol_ind_rolling"))

screenreg(l_res, digits=3, stars=c(0.01, 0.05, 0.1))

brew("./input/tables/table4.brew.tex", "./output/tables/table4.tex")
# -----------------------------------------------------------------------------


