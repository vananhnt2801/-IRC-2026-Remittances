clear
import excel "C:\Users\My_pc\Downloads\DATA-ĐỦ-VANH.xlsx", sheet("heritage-index-of-economic-free") firstrow
cap which xtserial
if _rc ssc install xtserial, replace
cap which xtcsd
if _rc ssc install xtcsd, replace
cap which xtscc
if _rc ssc install xtscc, replace
cap which utest
if _rc ssc install utest, replace
capture confirm numeric variable year
if _rc destring year, replace

encode country, gen(country_id)
xtset country_id year

foreach v in remit property patent fdi_in gcf ppp urban_po gdp {
    gen miss0_`v' = missing(`v')
    gen fill_`v' = 0
    replace `v' = (L.`v' + F.`v')/2 if miss0_`v' & !missing(L.`v') & !missing(F.`v') & abs(L.`v') > 0 & abs(F.`v' - L.`v')/abs(L.`v') <= 0.02
    replace fill_`v' = 1 if miss0_`v' & !missing(`v')
    drop miss0_`v'
}
foreach v in remit property patent fdi_in gcf ppp urban_po gdp {
    count if fill_`v' == 1
    di "`v' filled: " r(N)
}
list country year remit fill_remit if fill_remit==1, sepby(country)
list country year property fill_property if fill_property==1, sepby(country)
list country year patent fill_patent if fill_patent==1, sepby(country)
list country year fdi_in fill_fdi_in if fill_fdi_in==1, sepby(country)
list country year gcf fill_gcf if fill_gcf==1, sepby(country)
list country year ppp fill_ppp if fill_ppp==1, sepby(country)
list country year urban_po fill_urban_po if fill_urban_po==1, sepby(country)
list country year gdp fill_gdp if fill_gdp==1, sepby(country)
foreach v in remit property patent fdi_in gcf ppp urban_po gdp {
    count if missing(`v')
    di "`v' còn missing: " r(N)
}

sort country_id year
by country_id: ipolate patent year, gen(_tmp_patent)
replace patent = _tmp_patent if missing(patent)
drop _tmp_patent

gen ln_patent = ln(patent)
gen ln_remit  = ln(remit)
gen ln_gdp    = ln(gdp)
gen ln_remit2 = ln_remit^2
gen lnremit_prop = ln_remit * property
gen lnremit2_prop = ln_remit2 * property
gen ln_ppp = ln(ppp)
xtset country_id year
summ ln_remit ln_patent ppp gdp fdi_in urban_po gcf property
summ ln_remit ln_patent ln_gdp ln_ppp fdi_in urban_po gcf property

xtcd2 ln_patent
xtcd2 ln_remit
xtcd2 ln_gdp
xtcd2 ln_ppp
xtcd2 property
xtcd2 fdi_in
xtcd2 gcf
xtcd2 urban_po
xtcd2 ln_remit2
xtcd2 lnremit_prop
xtcd2 lnremit2_prop

xtcips ln_patent, maxlags(2) bglags(1)
xtcips ln_remit, maxlags(2) bglags(1)
xtcips ln_gdp, maxlags(2) bglags(1)
xtcips ln_ppp, maxlags(2) bglags(1)
xtcips property, maxlags(2) bglags(1)
xtcips fdi_in, maxlags(2) bglags(1)
xtcips gcf, maxlags(2) bglags(1)
xtcips urban_po, maxlags(2) bglags(1)
xtcips ln_remit2, maxlags(2) bglags(1)
xtcips lnremit_prop, maxlags(2) bglags(1)
xtcips lnremit2_prop, maxlags(2) bglags(1)

gen D_ln_remit = D.ln_remit
xtcips D_ln_remit, maxlags(2) bglags(1)

gen D_ln_gdp = D.ln_gdp
xtcips D_ln_gdp, maxlags(2) bglags(1)

gen D_ln_ppp = D.ln_ppp
xtcips D_ln_ppp, maxlags(2) bglags(1)

gen D_property = D.property
xtcips D_property, maxlags(2) bglags(1)

gen D_urban_po = D.urban_po
xtcips D_urban_po, maxlags(2) bglags(1)

gen D_ln_remit2 = D.ln_remit2
xtcips D_ln_remit2, maxlags(2) bglags(1)

gen D_lnremit_prop = D.lnremit_prop
xtcips D_lnremit_prop, maxlags(2) bglags(1)

gen D_lnremit2_prop = D.lnremit2_prop
xtcips D_lnremit2_prop, maxlags(2) bglags(1)

gen D2_urban_po = D.D_urban_po
xtcips D2_urban_po, maxlags(2) bglags(1)

xthst ln_patent ln_remit fdi_in ln_gdp ln_ppp gcf property
xthst ln_patent ln_remit ln_remit2 lnremit_prop lnremit2_prop property fdi_in ln_gdp ln_ppp gcf

xtwest ln_patent ln_remit ln_remit2 lnremit_prop lnremit2_prop ln_gdp property, constant lags(0) leads(0) bootstrap(400)
xtwest ln_patent ln_remit fdi_in ln_gdp ln_ppp gcf property, constant lags(0) leads(0) bootstrap(400)
xtwest ln_patent ln_remit ln_remit2 ln_gdp property, constant lags(0) leads(0) bootstrap(400)

xtdcce2 ln_patent D.ln_remit D.ln_remit2 D.lnremit_prop D.lnremit2_prop D.ln_gdp D.property, crosssectional(ln_patent D.ln_remit) cr_lags(0) lr(D.ln_remit D.ln_remit2 D.lnremit_prop D.lnremit2_prop D.property) lr_options(ardl)

xtdcce2 ln_patent ln_remit ln_remit2 lnremit_prop lnremit2_prop ln_gdp property, crosssectional(ln_patent ln_remit) cr_lags(0) lr(ln_remit ln_remit2 lnremit_prop lnremit2_prop property) lr_options(ardl)

sum property, detail
local p25 = r(p25)
local p50 = r(p50)
local p75 = r(p75)
sum ln_remit, meanonly
local xmin = r(min)
local xmax = r(max)
preserve
clear
set obs 200
gen xgrid = `xmin' + (`xmax' - `xmin') * (_n - 1) / 199
gen y_p25 = _b[ln_remit]*xgrid + _b[ln_remit2]*(xgrid^2) + _b[lnremit_prop]*(xgrid*`p25') + _b[lnremit2_prop]*((xgrid^2)*`p25') + _b[property]*`p25'
gen y_p50 = _b[ln_remit]*xgrid + _b[ln_remit2]*(xgrid^2) + _b[lnremit_prop]*(xgrid*`p50') + _b[lnremit2_prop]*((xgrid^2)*`p50') + _b[property]*`p50'
gen y_p75 = _b[ln_remit]*xgrid + _b[ln_remit2]*(xgrid^2) + _b[lnremit_prop]*(xgrid*`p75') + _b[lnremit2_prop]*((xgrid^2)*`p75') + _b[property]*`p75'
twoway (line y_p25 xgrid, sort) (line y_p50 xgrid, sort) (line y_p75 xgrid, sort), title("Predicted ln_patent by ln_remit") xtitle("ln_remit") ytitle("Predicted ln_patent") legend(order(1 "property = p25" 2 "property = p50" 3 "property = p75"))
restore

utest ln_remit ln_remit2
utest lnremit_prop lnremit2_prop

sum property, detail
local p25 = r(p25)
local p50 = r(p50)
local p75 = r(p75)

sum ln_remit, meanonly
local xmin = r(min)
local xmax = r(max)

display "===== p25 ====="
nlcom -(_b[ln_remit] + _b[lnremit_prop]*`p25') / (2*(_b[ln_remit2] + _b[lnremit2_prop]*`p25'))
lincom (_b[ln_remit] + _b[lnremit_prop]*`p25') + 2*(_b[ln_remit2] + _b[lnremit2_prop]*`p25')*`xmin'
lincom (_b[ln_remit] + _b[lnremit_prop]*`p25') + 2*(_b[ln_remit2] + _b[lnremit2_prop]*`p25')*`xmax'

display "===== p50 ====="
nlcom -(_b[ln_remit] + _b[lnremit_prop]*`p50') / (2*(_b[ln_remit2] + _b[lnremit2_prop]*`p50'))
lincom (_b[ln_remit] + _b[lnremit_prop]*`p50') + 2*(_b[ln_remit2] + _b[lnremit2_prop]*`p50')*`xmin'
lincom (_b[ln_remit] + _b[lnremit_prop]*`p50') + 2*(_b[ln_remit2] + _b[lnremit2_prop]*`p50')*`xmax'

display "===== p75 ====="
nlcom -(_b[ln_remit] + _b[lnremit_prop]*`p75') / (2*(_b[ln_remit2] + _b[lnremit2_prop]*`p75'))
lincom (_b[ln_remit] + _b[lnremit_prop]*`p75') + 2*(_b[ln_remit2] + _b[lnremit2_prop]*`p75')*`xmin'
lincom (_b[ln_remit] + _b[lnremit_prop]*`p75') + 2*(_b[ln_remit2] + _b[lnremit2_prop]*`p75')*`xmax'
