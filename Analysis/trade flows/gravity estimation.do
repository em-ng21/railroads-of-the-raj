*** Code for estimation of trade flow/gravity parameters

clear all
set more off
set mem 2g
set matsize 11000
capture log close

*******************

*** set main directory here:
cd  ???


log using "Analysis/trade flows/gravity_estimation.log", replace




*** prep rainfall data for analysis here:
	use "Data/crosswalks/district-block_correlation.dta", clear
	gen distid = 10000*province + 1000*bd_ns_code + district
	sort distid
	save "Data/crosswalks/district-block_correlation_wdistid.dta", replace


	use "Data/rainfall/crop rainfall.dta", clear
	sort distid 
	merge m:1 distid using "Data/crosswalks/district-block_correlation_wdistid.dta"
	drop if _m~=3
	drop _m
	
	replace blockname = "assam block" if provname=="assam"
	replace blockname = "sindh block" if provname=="sind"
	replace blockname = "NS block" if provname=="hyderabad"
	
	drop if blockname == ""
	
	bys blockname commodity year: egen rain_m = mean(rain)
	duplicates drop blockname commodity year, force
	drop rain
	rename rain_m rain
	drop distid prov* distname bd_ns* district
	
	rename blockname exporter_block
	
	*** aggregate/rename crops to match with trade data:
		gen newcomm = ""
		replace newcomm = "jowar and bajra" if commodity=="jowar" | commodity=="bajra"
		replace newcomm = "cotton" if commodity=="cotton (cleaned)"
		replace newcomm = "gram" if commodity=="gram (bengal)"
		replace newcomm = "sugar" if commodity=="sugarcane"
		replace newcomm = commodity if newcomm==""
		drop if newcomm == "ragi" | newcomm=="maize" | newcomm=="barley"
		drop commodity
		rename newcomm commodity	
		collapse (mean) rain, by(exporter_block commodity year)
			
	sort exporter_block commodity year
	save  "Analysis/trade flows/rainfall_temp.dta", replace





*** prep income data for analysis here:

	use "Data/crosswalks/district-block_correlation_wdistid.dta", clear
	rename blockname block
	drop province district
	rename provname province
	rename distname district
	sort province district
	replace province = "up" if province=="nwp"
	
	merge 1:m province district using "Data/income/income.dta"
		drop if _m==1
		drop _m

	drop bd_ns* realincome distid province district
	
	collapse (sum) nomincome, by(block year)
	
	rename block exporter_block
	sort exporter_block year
	save "Analysis/trade flows/income_temp.dta", replace




*** prep LCRED distances for gravity regresssions:
	*** First, run "trade flows/TF_est_prep.m" file in matlab (it generates "LCRED_D2D_alphahat.csv").  Then come back and run the rest of the Stata code below.

	insheet using "Analysis/trade flows/LCRED_D2D_alphahat.csv", clear names
	
	rename origin_id distid_o
	rename destination_id distid_d
	drop  alpha*

	rename distid_o distid
	sort distid distid_d year
	merge m:1 distid using "Data/crosswalks/district-block_correlation_wdistid.dta"
		drop _m
	rename blockname block
	drop provname distname bd_ns* province district
	rename block block_o
	rename distid distid_o
		
	rename distid_d distid
	merge m:1 distid using "Data/crosswalks/district-block_correlation_wdistid.dta"
		drop _m
	rename blockname block_d
	drop provname bd_ns* province district distname
	rename distid distid_d
	
	
	*** take block of "bombay port" to be district of "thana" (closest one)
		expand 2 if distid_o==81006, gen(id)
		replace block_o = "bombay port" if id==1
		drop id	
		expand 2 if distid_d==81006, gen(id)
		replace block_d = "bombay port" if id==1
		drop id
	
	*** Assign external blocks to districts (Assam (use Goalpara), Sindh (use Karachi), NS (use Hyderabad)):
		expand 2 if distid_o==41001, gen(id)
		replace block_o = "assam block" if id==1
		drop id
		expand 2 if distid_d==41001, gen(id)
		replace block_d = "assam block" if id==1
		drop id
	
		expand 2 if distid_o==171001, gen(id)
		replace block_o = "sindh block" if id==1
		drop id
		expand 2 if distid_d==171001, gen(id)
		replace block_d = "sindh block" if id==1
		drop id
	
		expand 2 if distid_o==112012, gen(id)
		replace block_o = "NS block" if id==1
		drop id
		expand 2 if distid_d==112012, gen(id)
		replace block_d = "NS block" if id==1
		drop id
	
	
	collapse (mean) lcred, by(block_o block_d year)
	drop if block_o==""
	drop if block_d==""
	
	rename block_o exporter_block
	rename block_d importer_block
	
	keep if year>=1870
	sort exporter_block importer_block year
	save "Analysis/trade flows/LCRED_temp.dta", replace

	
	

	

*** Merge all of the above datasets together:

	use "Data/trade flows/trade_data.dta", clear

	merge m:1 exporter_block importer_block year using "Analysis/trade flows/LCRED_temp.dta"
		drop if _m==2
		drop _m

	sort exporter_block year
	merge m:1 exporter_block year using "Analysis/trade flows/income_temp"
		drop if _m==2
		drop _m		
	
	sort exporter_block commodity year
	merge m:1 exporter_block commodity year using "Analysis/trade flows/rainfall_temp"
		drop _m
		
	sort commodity
	merge m:1 commodity using "Data/trade flows/weight-value.dta"
 	 	drop _m
 	 
 	sort commodity
	merge m:1 commodity using "Data/trade flows/freight class.dta"
 		drop _m
 

 
 
 *** Estimation (gravity equation - "Step 2" in paper):
	local delta 0.1689108
		* Value estimated from Step 1 goes here
		
 	gen ln_q = log(q)
 	gen ln_LCRED = ln(lcred)
 	gen deltaXln_LCRED = `delta'*ln_LCRED
 
	egen kod_id = group(commodity exporter_block importer_block)
	egen kot_id = group(commodity exporter_block year)
	egen kdt_id = group(commodity importer_block year)
	egen o_id = group(exporter_block)
	egen ot_id = group(exporter_block year)
	egen dt_id = group(importer_block year)
	egen od_id = group(exporter_block importer_block)
	egen kt_id = group(commodity year)
	
	
	
	* TABLE 3, COL 1: POOLED (ALL COMMODITIES):
 
		reghdfe ln_q ln_LCRED, absorb(kot_id kdt_id kod_id) vce(cluster od_id)


 	* TABLE 3, COL 2: POOLED BUT WITH FREIGHT/WEIGHT INTERACTIONS:
 		
 		gen ln_CRED__WVR = ln_LCRED*WVR
 		gen ln_CRED__FC =  ln_LCRED*FC_Hi
		reghdfe ln_q ln_LCRED ln_CRED__WVR ln_CRED__FC, absorb(kot_id kdt_id kod_id) vce(cluster od_id)
 		
  
 	* ESTIMATION OF THETAS (USED IN STEP 4):
 		drop if commodity=="salt"
 
 		gen portFE=.
 		gen theta=.
  		
 		levelsof commodity, local(klist)
 		foreach k of local klist {
 			di "estimation for commodity `k'..."
			reghdfe ln_q deltaXln_LCRED if commodity=="`k'", absorb(expFE=ot_id dt_id od_id) 
			
			gen b = _b[deltaXln_LCRED]
			qui summ b
			replace theta = -`r(mean)' if commodity=="`k'"
			drop b
			replace portFE= expFE if commodity=="`k'"
			drop expFE
			}
			
		bys exporter_block year commodity: egen portFE_m = mean(portFE)
		drop portFE
		rename portFE_m portFE
		bys exporter_block year commodity: gen count = _N
		replace portFE=0 if portFE==. & ln_q~=. & ln_LCRED~=. & count>1
		replace portFE=-99999 if ln_q==. & count>1
		replace portFE=-88888 if ln_q~=. & count==1
	 	drop count
	
	 
 	* ESTIMATION OF KAPPA (USED IN STEP 4):

		gen y = ln_q + theta*deltaXln_LCRED + theta*log(nomincome)
		reghdfe y rain, absorb(kod_id kdt_id ot_id) vce(cluster od_id)

		local kappa = _b[rain]			
 		
 	
 
*** save port city location fixed effects, theta and kappa for use in matlab simulations:
		expand 5 if commodity == "jowar and bajra"
		gen newcomm = ""
		bys exporter_block importer_block commodity year: gen id = _n
		replace newcomm = "bajra" if comm=="jowar and bajra" & id==1
		replace newcomm = "jowar" if comm=="jowar and bajra" & id==2
		replace newcomm = "barley" if comm=="jowar and bajra" & id==3
		replace newcomm = "maize" if comm=="jowar and bajra" & id==4
		replace newcomm = "ragi" if comm=="jowar and bajra" & id==5
		replace newcomm = comm if newcomm==""
		drop comm id
		rename newcomm commodity

	
	*** for thetas:
		preserve
		collapse (mean) theta, by(commodity)
		sort commodity
		gen theta2 = theta
		replace theta2=. if commodity=="jowar" | commodity=="barley" | commodity=="maize" | commodity=="ragi"
		summ theta2
				
			* This reports the mean and range of the theta estimates across the 13 estimates

		drop commodity theta2 	
		outsheet using "Analysis/simulation/thetas.csv", replace names comma
				
		restore
 	

	*** for port city location fixed effects:
		keep if exporter_block == "sindh block" | exporter_block == "calcutta" | exporter_block == "madras port" | exporter_block == "bombay port"
		duplicates drop exporter_block commodity year, force
		keep portFE exporter_block commodity year
	
		fillin exporter_block commodity year
		drop _f
		
		bys exporter_block year: egen portFE_t = mean(portFE)
		gen MVyr = 0
		replace MVyr = 1 if portFE_t==.
		drop portFE_t
		
		gen portFE_no8 = portFE
		replace portFE_no8=. if portFE==-88888
		bys exporter_block commodity: ipolate portFE_no8 year, gen(portFE_i)
		replace portFE = portFE_i if portFE==-88888 | MVyr==1
		drop portFE_i portFE_no8 MVyr
	
		gen pFE_1890 = .
		replace pFE_1890 = portFE if year==1890
		bys exporter_block commodity: egen pFE_1890_m = mean(pFE_1890)
		replace portFE = pFE_1890_m if year<1890
		gen pFE_1909 = .
		replace pFE_1909 = portFE if year==1909
		bys exporter_block commodity: egen pFE_1909_m = mean(pFE_1909)
		replace portFE = pFE_1909_m if year<1909 & exporter_block == "madras port"		
		gen pFE_1920 = .
		replace pFE_1920 = portFE if year==1920
		bys exporter_block commodity: egen pFE_1920_m = mean(pFE_1920)
		replace portFE = pFE_1920_m if year>1920
		drop pFE_*
	
		replace portFE=-99999 if portFE==.
		gen distid=.
		replace distid=1000001 if exporter_block == "calcutta" 
		replace distid=1000004 if exporter_block == "sindh block"
		replace distid=1000002 if exporter_block == "bombay port" 
		replace distid=1000003 if exporter_block == "madras port"
		drop exporter_block
	
	
		rename portFE portFE_
		forvalues y = 1870/1930 {
			preserve
			keep if year==`y'
			sort distid commodity
			qui: reshape wide portFE_, i(distid) j(commodity) string
			sort distid
		
			drop distid year
			outsheet using "Analysis/simulation/inputs/portFE_`y'.csv", replace names comma
			restore
			}
	
 	
	*** for kappa: 	
		clear
		set obs 1
		gen kappa = .
		replace kappa = `kappa' in 1
		outsheet using "Analysis/simulation/kappa.csv", replace
 	

log close

