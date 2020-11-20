*** Code for estimation of trade cost parameters (Table 2)

clear all
set more off
capture log close

*******************


*** set main directory here:
cd  ???
	


log using "Analysis/trade costs/TC_estimation.log", replace


****** Set point estimation alpha grid search width and density parameters (these need to line up with ones generated in matlab) ********

local roadmin = 1
local roadstep = 0.125
local roadmax = 10
local coastmin = 1
local coaststep = 0.125 
local coastmax = 10
local rivermin = 1
local riverstep = 0.125
local rivermax = 10



****** Insheet files created in matlab and convert to separate dta files   *****************

	forvalues roadcost = `roadmin'(`roadstep')`roadmax' {
		forvalues coastcost = `coastmin'(`coaststep')`coastmax' {
			forvalues rivercost = `rivermin'(`riverstep')`rivermax' {
				di "trying to insheet: Road=`roadcost', Coast=`coastcost',River=`rivercost'"
				forvalues Ridir =1/9 {
					clear
					capture: insheet using "Analysis/trade costs/Output_Ri`Ridir'/LCRED_Ro`roadcost'_Co`coastcost'_Ri`rivercost'.csv"
					if _rc ~= 601 {
						rename origin_id distid_o
						rename destination_id distid_d
						qui: gen ln_LCRED = log(lcred)
						qui: drop if year==0			
						sort distid_o distid_d year
						save "Analysis/trade costs/Output_Ri`Ridir'/LCRED_Ro`roadcost'_Co`coastcost'_Ri`rivercost'.dta", replace
						di "success"
						}
					}
				assert e(N)>1				
				}
			}
		}


***** Open and prepare the salt price data **********************

use "Data/Prices_salt/prices_salt.dta"
drop if distid==.


rename distid distid_d

gen distid_o =.
replace distid_o = 9000000 if commodity =="salt (didwana)"
replace distid_o = 9061104 if commodity =="salt (calcutta)"
replace distid_o = 9081006 if commodity =="salt (bombay sea)"
replace distid_o = 9151021 if commodity =="salt (lahori)"
replace distid_o = 9151027 if commodity =="salt (kohati)"
replace distid_o = 9162012 if commodity =="salt (sambhar)" | commodity =="salt (sambhar oudh AR)"


bys distid_o distid_d year: egen price_mean = mean(price)
drop price
rename price_mean price
duplicates drop distid_o distid_d year, force


gen ln_p = log(price)
	
egen od_id = group(distid_o distid_d)
egen ot_id = group(distid_o year) 
qui tab od_id, gen(od_id_)		



save "Analysis/trade costs/TC_estimation_temp.dta", replace


**** Estimation of TC function at historical freight rates (road=4.5, river=3.0 and coast=2.25) [Column (1) of Table 2]  **************

	
	foreach outdir of local outdirlist {
		merge 1:1 distid_o distid_d year using "Analysis/trade costs/`outdir'/DTA/LCRED_Ro4.5_Co3.0_Ri2.25.dta"
			if _rc ~= 601 {
			assert _m!=1
			drop if _m ==2
			areg ln_p ln_LCRED od_id_*, absorb(ot_id) cluster(distid_d)
			drop ln_LCRED alpha_* _m 
			}
		}	
	




***** Grid search NLS estimation of trade cost parameters [Column (2) of Table 2] ***********************


use "Analysis/trade costs/TC_estimation_temp.dta", clear
*** start the loop over candidate trade cost ("alpha") parameters:

	mata: results = J(1000000,12,.)
	timer clear 1
	timer on 1
	
	local i =0
	
	forvalues roadcost = `roadmin'(`roadstep')`roadmax' {
		forvalues coastcost = `coastmin'(`coaststep')`coastmax' {
			forvalues rivercost = `rivermin'(`riverstep')`rivermax' {
				local i = `i'+1
				di "point estimation, looking for road `roadcost', coast `coastcost', river `rivercost'"
				forvalues Ridir =1/9 {
					capture: merge 1:1 distid_o distid_d year using "Analysis/trade costs/Output_Ri`Ridir'/LCRED_Ro`roadcost'_Co`coastcost'_Ri`rivercost'.dta"
					if _rc== 601 {
						di "could not find road `roadcost', coast `coastcost', river `rivercost' in RiDir `Ridir'"
						}
					if _rc ~= 601 {
						assert _m!=1
						qui: drop if _m ==2
						drop _m
						
						qui summ alpha_road
						mata: results[`i',1]=`r(mean)'
						qui summ alpha_coast
						mata: results[`i',2]=`r(mean)'
						qui summ alpha_river
						mata: results[`i',3]=`r(mean)'

						qui: reghdfe ln_p ln_LCRED, absorb(ot_id od_id) vce(cluster distid_d)
				
						mata: results[`i',4]=`e(N)'
						mata: results[`i',7]=`e(rss)'
					
						gen b = _b[ln_LCRED]
						qui summ b
						mata: results[`i',5]=`r(mean)'
			
						gen se = _se[ln_LCRED]
						qui summ se
						mata: results[`i',6]=`r(mean)'

						*qui: areg ln_p ln_LCRED od_id_*, absorb(ot_id) cluster(distid_d)

						mata: results[`i',8]=`e(N)'
						mata: results[`i',11]=`e(rss)'
					
						drop b se
						gen b = _b[ln_LCRED]
						qui summ b
						mata: results[`i',9]=`r(mean)'
			
						gen se = _se[ln_LCRED]
						qui summ se
						mata: results[`i',10]=`r(mean)'

			
						mata: results[`i',12]=`i'	

						drop ln_LCRED alpha_* b se
						di "success"	
						}
					}
				}
			}
		}
		
		
		

*** pick best-fitting value of trade cost parameters:

	capture: drop results
	getmata (a_road a_coast a_river N_HD delta_HD SE_delta_HD RSS_HD N_A delta_A SE_delta_A RSS_A id_reg)=results, force double
		
	egen double min_RSS_HD = min(RSS_HD)
	egen double min_RSS_A = min(RSS_A)	
	
	local varlist "road coast river"
	foreach var of local varlist  {
		summ a_`var' if RSS_HD==min_RSS_HD, d
		di "estimated value of alpha_`var' is `r(mean)'"
		}
		
		
	summ delta_HD if RSS_HD==min_RSS_HD, d
	local d_minRSS = `r(mean)'
	summ SE_delta_HD if RSS_HD==min_RSS_HD, d
	local dSE_minRSS = `r(mean)'
	di "estimated value of delta is `d_minRSS' and SE (clustered at destination district level) is is `dSE_minRSS'"
	
	summ N_HD if RSS_HD == min_RSS_HD
	

	*** save point estimation grid search results file:
		keep if a_road~=.
		keep a_* N* delta* SE_delta* RSS* min_RSS* id_reg
		save "Analysis/trade costs/TC_point_estimation_gridsearch.dta", replace



	
*** Bootstrapped standard errors:
	
	use "Analysis/trade costs/TC_estimation_temp.dta", clear

	*** set bootstrap parameters:
		set seed 66712972
				* the serial number on a $1 bill I had when I wrote this.
						
		local Nbstrap = 200 // number of bootstrap replications
			
	
	*** set grid search parameters for bootstrap (coarser than for point estimate, for speed):
		local roadmin = 1
		local roadstep = 0.5
		local roadmax = 10
		local coastmin = 1
		local coaststep = 0.5 
		local coastmax = 10
		local rivermin = 1
		local riverstep = 0.5
		local rivermax = 10


	*** run the bootstrap:
				
		mata: Bresults = J(`Nbstrap',4,.)
		gen bstrapID=.
		
		*** start the bootstrap loop:
		forvalues b=1/`Nbstrap' {  
			di "starting bootstrap iteration number `b' of `Nbstrap'"
			replace bstrapID = `b' in `b'
			preserve
			
			bsample
	
			*** start the grid search loops within each bootstrap loop:
			mata: results = J(1000000,8,.)
			local i =0
			foreach outdir of local outdirlist {
				foreach roadcost of local roadcostlist {
					foreach coastcost of local coastcostlist { 
						foreach rivercost of local rivercostlist {
							local i = `i'+1
							di "dir `outdir', road `roadcost', coast `coastcost', river `rivercost'"
							
							if "`outdir'" == "Output" {
								capture: merge m:1 distid_o distid_d year using "Analysis/trade costs/Output_DTA/LCRED_Ro`roadcost'_Co`coastcost'_Ri`rivercost'.dta"
								}
							else if "`outdir'" == "Output2" {
								capture: merge m:1 distid_o distid_d year using "Analysis/trade costs/Output2/DTA/LCRED_Ro`roadcost'_Co`coastcost'_Ri`rivercost'.dta"
								}	
							if _rc ~= 601 {
								assert _m!=1
								
								drop if _m ==2
								
								qui summ alpha_road
								mata: results[`i',1]=`r(mean)'
								qui summ alpha_coast
								mata: results[`i',2]=`r(mean)'
								qui summ alpha_river
								mata: results[`i',3]=`r(mean)'

								qui: reghdfe ln_p ln_LCRED, absorb(ot_id od_id) 
				
								mata: results[`i',4]=`e(N)'
								mata: results[`i',7]=`e(rss)'
	
								gen b = _b[ln_LCRED]
								qui summ b
								mata: results[`i',5]=`r(mean)'
				
								gen se = _se[ln_LCRED]
								qui summ se
								mata: results[`i',6]=`r(mean)'
				
								mata: results[`i',8]=`i'	

								drop ln_LCRED alpha_* _m b se
								}
							}
						}
					}
				}
			
			capture: drop results
			getmata (a_road a_coast a_river N delta SE_delta RSS id_reg)=results, force double
	   
			egen double min_RSS = min(RSS)
   
   			summ a_road if RSS==min_RSS, d
			di "estimated value of alpha_road in this bootstrap sample is `r(mean)'"
   			summ a_coast if RSS==min_RSS, d
			di "estimated value of alpha_coast in this bootstrap sample is `r(mean)'"
   			summ a_river if RSS==min_RSS, d
			di "estimated value of alpha_river in this bootstrap sample is `r(mean)'"
			summ delta if RSS==min_RSS, d
			di "estimated value of delta  in this bootstrap sample is `r(mean)'"

			drop a_road a_coast a_river N delta SE_delta id_reg RSS min_RSS
			restore
			}
		
		
		
		capture: drop Bresults
		getmata (a_road a_coast a_river delta)=Bresults, force
		 
		local varlist "a_road a_coast a_river delta"
		foreach var of local varlist {
		   qui: summ `var', d
		   egen `var'_2_5 = pctile(`var'), p(2.5)
		   egen `var'_97_5 = pctile(`var'), p(97.5)
		   qui: summ `var'_2_5
		   local p2_5 = r(mean) 
		   qui: summ `var'_97_5
		   local p97_5 = r(mean)
		   di "for this bootstrap run, 95% CI for `var' is `p2_5' to `p97_5'"
		   }
					   
		
	
log close
	
		
		