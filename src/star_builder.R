#! /usr/local/bin/R
#
#
#
# 'star_builder.R'
#
# Print out stars for estimates given t-stats cutoffs
#
#
#
# Created on     August   06th  2019
# Last modified  August   06th  2019
#
#
# --------------------------------------------------------------------------------


# --------------------------------------------------------------------------------
star_builder <- function(b, se){

# values for 100 degrees of freedom two sided t
# 0.80    0.9     0.95    0.99   
# 1.29    1.66    1.98    2.63   
z <- abs(b/se)

	if ( z < 1.66 ){
		star <- ""
	} else if ( z < 1.98 ){
		star <- "*"
	} else if ( z < 2.63 ){
		star <- "**"
	} else if ( z >= 2.63){
		star <- "***"
	}

	return(star)

}