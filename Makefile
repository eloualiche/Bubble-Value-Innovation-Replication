# --------------------------------------------------------------------------------------------------------
# Makefile for replication files
all: table1 table2 table3 table4 view-tables
# --------------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------------
# --- 
table1: 
	$(call colorecho, "Creating Table 1...")
	R CMD BATCH --vanilla src/table1.R log/table1.log.R
	$(TIME-END)
	@echo

# --- 
table2: 
	$(call colorecho, "Creating Table 2...")
	R CMD BATCH --vanilla src/table2.R log/table2.log.R
	$(TIME-END)
	@echo

# --- 
table3: 
	$(call colorecho, "Creating Table 3...")
	R CMD BATCH --vanilla src/table3.R log/table3.log.R
	$(TIME-END)
	@echo

# --- 
table4: 
	$(call colorecho, "Creating Table 4...")
	R CMD BATCH --vanilla src/table4.R log/table4.log.R
	$(TIME-END)
	@echo

# --- 
view-tables:
	$(call colorecho, "Compile all LaTeX Tables...")	
	pdflatex -interaction=batchmode -output-directory output input/view-tables.tex
	pdflatex -interaction=batchmode -output-directory output input/view-tables.tex
	rm output/*.aux output/*.log output/*.lot output/*.out
	$(TIME-END)
	@echo	
# --------------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------------
setup-environment:
	$(call colorecho, "Setting R environment...")
	R CMD BATCH --vanilla src/setup-environment.R log/setup-environment.log.R
	$(TIME-END)
	@echo

clean-all:
	$(call colorecho, "Cleaning tables...")
	rm -f output/tables/*.tex
	rm -f output/view-tables.pdf
	rm -f log/*
# --------------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------------
# HOMEMADE SCRIPTS
define colorecho
      @tput setaf 6
      @echo $1
      @tput sgr0
endef
WHITE='\033[1;37m'
NC   ='\033[0m' # No Color

 # Timing: see here https://stackoverflow.com/questions/8483149/gnu-make-timing-a-build-is-it-possible-to-have-a-target-whose-recipe-executes
 TIME_START := $(shell date +%s)
 define TIME-END
 	@time_end=`date +%s` ; time_exec=`awk -v "TS=${TIME_START}" -v "TE=$$time_end" 'BEGIN{TD=TE-TS;printf "%02dm:%02ds\n", TD/(60),TD%60}'` ; echo \\t${WHITE}cumulative time elapsed ... $${time_exec} ... $@ ${NC}
endef
# --------------------------------------------------------------------------------------------------------
