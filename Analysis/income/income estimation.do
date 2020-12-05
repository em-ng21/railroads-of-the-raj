*** do file to estimate real income regressions in Tables 4 and 5 


clear all
set more off
capture log close

*******************

*** set main directory here
cd ???


log using "Analysis/income/income_estimation.log", replace


* TABLE 4 REGRESSIONS:

*** prep the data required for regressions 
	use "Data/income/income.dta", clear
	sort distid year
	
	merge 1:1 distid year using "Data/maps/RAIL dummies.dta"
	drop if _m~=3
	drop _m
	
		
	gen ln_realincome = log(realincome)
	
*** run regressions for Table 4:
	
	
	*COL 1 (TABLE 4):
	
		reghdfe ln_realincome RAIL, absorb(distid year) vce(cluster distid)
	
		
		
	*COL 2 (TABLE 4):
		
		reghdfe ln_realincome RAIL RAIL_prop RAIL_rec RAIL_sur, absorb(distid year) vce(cluster distid)



	*COL 3 (TABLE 4):
	
		gen POST71 = 0
		replace POST71 = 1 if year>1871
		gen POST74 = 0
		replace POST74 = 1 if year>1874
		gen POST79 = 0
		replace POST79 = 1 if year>1879
		gen POST84 = 0
		replace POST84 = 1 if year>1884
		gen POST89 = 0
		replace POST89 = 1 if year>1889
		gen POST94 = 0
		replace POST94 = 1 if year>1894

		gen RAIL_L6973XPOST71 = RAIL_L6973*POST71
		gen RAIL_L7478XPOST74 = RAIL_L7478*POST74
		gen RAIL_L7983XPOST79 = RAIL_L7983*POST79 
		gen RAIL_L8488XPOST84 = RAIL_L8488*POST84 
		gen RAIL_L8993XPOST89 = RAIL_L8993*POST89 
		gen RAIL_L9498XPOST94 = RAIL_L9498*POST94
	
		reghdfe ln_realincome RAIL RAIL_L6973XPOST71 RAIL_L7478XPOST74 RAIL_L7983XPOST79 RAIL_L8488XPOST84 RAIL_L8993XPOST89 RAIL_L9498XPOST94, absorb(distid year) vce(cluster distid)
		
	
	
	*COL 4 (TABLE 4):
		gen year_48 = year-1848
		gen RAIL_KHiXyear_48 = RAIL_KHi*year_48
		gen RAIL_KLoXyear_48 = RAIL_KLo*year_48
		
		reghdfe ln_realincome RAIL RAIL_KHiXyear_48 RAIL_KLoXyear_48, absorb(distid year) vce(cluster distid)
	
	
	sort distid year
	save "Analysis/income/income_estimation_temp.dta", replace
	




*** prep the LCRED data for matlab simulations:

	use "Data/income/income.dta", clear
	duplicates drop distid, force
	keep distid
	sort distid
	save "Analysis/simulation/sim_prep_temp.dta", replace

	insheet using "Analysis/trade flows/LCRED_D2D_alphahat.csv", clear names
	
	rename origin_id distid_o
	rename destination_id distid_d
	drop  alpha*
	rename distid_o distid
	merge m:1 distid using "Analysis/simulation/sim_prep_temp.dta"
	replace distid=1000001 if distid==61104 
	replace distid=1000004 if distid==171001
		* These are Calcutta and Karachi respectively.  Not ag districts. So they don't match here, but want to keep them in.
		
	expand 2 if distid == 81006 | distid==121013, gen(dup)
	replace distid=1000002 if distid==81006 & dup==1
	replace distid=1000003 if distid==121013 & dup==1
		* these are Thana (ie Bombay port) and Madras respectively.  They are ag districts (ie have rural presence) so creating duplicate obs to be port.
	drop dup
	keep if _m==3 | distid==1000001 | distid==1000002  | distid==1000003 | distid==1000004
	drop _m
	
	rename distid distid_o
	rename distid_d distid
	sort distid
	merge m:1 distid using "Analysis/simulation/sim_prep_temp.dta"
	replace distid=1000001 if distid==61104 
	replace distid=1000004 if distid==171001
		* These are Calcutta and Karachi respectively.  Not ag districts. So they don't match here, but want to keep them in.
		
	expand 2 if distid == 81006 | distid==121013, gen(dup)
	replace distid=1000002 if distid==81006 & dup==1
	replace distid=1000003 if distid==121013 & dup==1
		* these are Thana (ie Bombay port) and Madras respectively.  They are ag districts (ie have rural presence) so creating duplicate obs to be port.
	drop dup
	keep if _m==3 | distid==1000001 | distid==1000002  | distid==1000003 | distid==1000004
	drop _m

	rename distid distid_d	
	
	replace lcred=-77777 if lcred==0
		*these are all the self-distance observations
		
	drop if year<1870
	rename lcred lcred_
	forvalues y = 1870/1930 {
		preserve
		keep if year==`y'
		sort distid_o distid_d 
		qui: reshape wide lcred_, i(distid_o) j(distid_d)
		sort distid_o
		drop distid_o year
		outsheet using "Analysis/simulation/inputs/LCRED_D2D_alphahat_`y'.csv", replace names comma
		restore
		}
		
		

*** prep the rainfall data for simulations in matlab:

	use "Data/rainfall/crop rainfall.dta", clear
	sort distid 
	merge m:1 distid using "Analysis/simulation/sim_prep_temp.dta"
	keep if _m==3
	drop _m province
	replace commodity = "cotton" if commodity=="cotton (cleaned)"
	replace commodity = "gram" if commodity=="gram (bengal)"
	
	
	rename rain rain_
	forvalues y = 1870/1930 {
		preserve
		keep if year==`y'
		sort distid 
		qui: reshape wide rain_, i(distid) j(commodity) string
		sort distid
		drop distid year
		outsheet using "Analysis/simulation/inputs/RAIN_`y'.csv", replace names comma
		restore
		}


	



* TABLE 5 REGRESSIONS (SUFFICIENT STATISTIC):
	*** Run matlab simulation.m file.  It takes the above .csv files and creates the "SelfTrade.csv" file used below....
	

	insheet using "Analysis/simulation/SelfTrade.csv", clear names
	gen comm = ""
	replace comm = "bajra" if commodity== 1
	replace comm = "barley" if commodity== 2
	replace comm = "cotton" if commodity== 3
	replace comm = "gram" if commodity== 4
	replace comm = "indigo" if commodity== 5
	replace comm = "jowar" if commodity== 6
	replace comm = "jute" if commodity== 7
	replace comm = "linseed" if commodity== 8
	replace comm = "maize" if commodity== 9
	replace comm = "opium" if commodity== 10
	replace comm = "ragi" if commodity== 11
	replace comm = "rice" if commodity== 12
	replace comm = "sesamum" if commodity== 13
	replace comm = "sugarcane" if commodity== 14
	replace comm = "tea" if commodity== 15
	replace comm = "tobacco" if commodity== 16
	replace comm = "wheat" if commodity== 17
	drop commodity
	rename comm commodity


	sort distid commodity year
	save "Analysis/simulation/SelfTrade.dta", replace
		
	
	insheet using "Analysis/simulation/kappa.csv", clear names
	summ kappa
	local kappa = `r(mean)'
		
	use "Data/rainfall/crop rainfall.dta", clear	
	replace commodity = "cotton" if commodity=="cotton (cleaned)"
	replace commodity = "gram" if commodity=="gram (bengal)"
	
	merge 1:1 distid commodity year using "Analysis/simulation/SelfTrade.dta" 
	drop if _m~=3
	drop _m
	
	gen double RAINsum_term = `kappa'*(mu/theta)*rain
	bys distid year: egen double RAINsum = total(RAINsum_term)
	drop RAINsum_term	
	
	gen double logSTsum_term = (mu/theta)*log(selftrade)
	bys distid year: egen double logSTsum = total(logSTsum_term)
	drop logSTsum_term
	
	
	drop rain province theta mu selftrade
	duplicates drop distid year, force	
	drop commodity
		
	sort distid year
	merge 1:1 distid year using  "Analysis/income/income_estimation_temp.dta"
	drop _m
		
	
	
*** run regressions for Table 5:

	gen y = ln_realincome - RAINsum
	
	*COL 1 (TABLE 5):
		reghdfe y RAIL, absorb(distid year) vce(cluster distid)
		
	
	*COL 2 (TABLE 5):	
		reghdfe y RAIL logSTsum, absorb(distid year) vce(cluster distid)



log close
