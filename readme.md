# Replication package for Bubbles and Value of Innovation

*Bubbles and the Value of Innovation*; [Valentin Haddad](https://www.anderson.ucla.edu/faculty-and-research/finance/faculty/haddad), [Paul Ho](https://www.paulho.org), and [Erik Loualiche](https://loualiche.gitlab.io/www/); Journal of Financial Economics, Forthcoming

- The code is written in `R`. To get your environment setup, you can run `make setup-environment` in the directory and it will install the required packages for you.
- If your environment is set up, you can generate all of the tables and a pdf of these tables by running `make all` in the directory.

## Code

There are four main `R` files in the `src` folder which all generates their corresponding table in the paper (`table1.R` for table 1, etc.).


## Data 
Note that you will need access to the following dataset in the `input` folder:
  
  - `BsVR.rds`: data from Bloom, Schankerman, and Van Reenen (2013) used to estimate spillover. This dataset is directly drawn from their [replication code](https://www.econometricsociety.org/content/supplement-identifying-tehcnology-spillovers-and-product-market-rivalry). This dataset is **included** in the repo. 
  - `dsf_vol_full.fst`: includes volatility at the stock level from WRDS daily stock file. `table4.R` estimates this dataset starting from the raw daily stock file. This dataset is not included in the repo. Please email us if you cannot generate it.
  - `fama_bubbles.rds`: we reproduce Greenwood, Shleifer, and You (2018) and identify bubbles at the industry-year level. This dataset is **included** in the repo. 
  - `kpss_firm_innovation.rds`: this is the annual data from Kogan, Papanikolaou, Seru, and Stoffman (2017) used to estimate spillovers. See their replication code [here](https://github.com/KPSS2017/Technological-Innovation-Resource-Allocation-and-Growth-Replication-Kit).
  - `kpss_supplement_firm.rds`: this is the annual data from Kogan, Papanikolaou, Seru, and Stoffman (2017) augmented with firm data to estimate their tables IV/V/VI.
  - `mgr_typecode.rds`: ownership type codes from the thomson 13F dataset. This dataset is **included** in the repo. 
  - `panel_13F.rds`: panel of stock/manager/quarter ownership from the thomson 13F dataset.
  - `patents.fst` and `patents_dp.fst`: panel of patent data from Kogan, Papanikolaou, Seru, and Stoffman (2017). See link above. 

We do not include some of the files because of access rights and size. Email us if you would like to know more about how to access some of this data. 

## Output

- Generated tables are in `output/tables/`
- You can view these tables in the [`output/tables/view-tables.pdf`](output/view-tables.pdf)
