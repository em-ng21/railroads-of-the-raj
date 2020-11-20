*** do-file to make Table 1 (descriptive statistics)

clear all
set more off
capture log close

*******************

*** set main directory here:
cd  ???


log using "Analysis/descriptives/descriptives.log", replace



*** ROW 1 (REAL AG INCOME):

	use "Data/income/income.dta", clear
	count
		* this is the number of observations (reported in col 1)
		
	sort distid year
	by distid: gen realincomePA_firstyr = realincome/area_total if _n==1
	summ realincomePA_firstyr

		* this reports the mean (and SD) value at beginning of available data (reported in col 2)
		
	sort distid year
	by distid: gen area_firstyr = area_total if _n==1
	by distid: egen area_firstyr_m = mean(area_firstyr)
	by distid: gen realincomePA_lastyr = realincome/area_firstyr_m if _n==_N
	summ realincomePA_lastyr
		
		* this reports the mean (and SD) value at end of available data (reported in col 3)

	
	
	
*** ROW 2 (SALT PRICES):
	
	use "Data/Prices_salt/prices_salt.dta", clear
	
	collapse (mean) price, by(distid year)
	
	count if price~=.	

		* this is the number of observations (reported in col 1)
	
	sort distid year
	by distid: gen price_firstyr = price if _n==1
	summ price_firstyr
	
		* this reports the mean (and SD) value at beginning of available data (reported in col 2)

	sort distid year	
	by distid: gen price_lastyr = price if _n==_N
	summ price_lastyr
	
		* this reports the mean (and SD) value at end of available data (reported in col 3)
	


	
	
*** ROW 3 (RAINFALL):
	
	
	use "Data/rainfall/crop rainfall.dta", clear	
	drop province
	
	sort distid year
	merge m:1 distid year using "Data/income/income.dta"
	keep if _m==3
	
	count if rain~=.

		* this is the number of observations (reported in col 1)
	
	sort distid commodity year
	by distid commodity: gen first_yr = year if _n==1
	by distid: egen first_yr_min = min(first_yr)
	summ rain if year==first_yr_min
	
		* this reports the mean (and SD) value at beginning of available data (reported in col 2)

	sort distid commodity year
	bys distid commodity: gen last_yr = year if _n==_N
	bys distid: egen last_yr_max = max(last_yr)
	summ rain if year==last_yr_max
	
		* this reports the mean (and SD) value at end of available data (reported in col 3)
	
	summ rain
		
		* this reports the SD reported in Section 4.3
	
	
	
	
*** ROW 4 (TRADE FLOWS):
	
	use "Data/trade flows/trade_prices_1870.dta", clear
	
	merge 1:m commodity using "Data/trade flows/trade_data.dta"
	
	bys exporter_block year: egen value = total(p*q)
	replace value = value/1000000	
	duplicates drop exporter_block year, force
	
	count
		* this is the number of observations (reported in col 1)
	
	
	sort exporter_block year
	by exporter_block: gen first_yr = year if _n==1
	by exporter_block: egen first_yr_min = min(first_yr)
	replace first_yr_min = first_yr_min
	
	summ value if year==first_yr_min
	
		* this reports the mean (and SD) value at beginning of available data (reported in col 2)


	sort exporter_block year
	by exporter_block: gen last_yr = year if _n==_N
	by exporter_block: egen last_yr_max = max(last_yr)
	summ value if year==last_yr_max
	
		* this reports the mean (and SD) value at end of available data (reported in col 3)
	

		
	
	
log close	
	

