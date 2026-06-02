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
reg ln_patent ln_remit fdi_in ln_gdp ln_ppp urban_po gcf property
estat vif
estimates store POLS
xtreg ln_patent ln_remit fdi_in ln_gdp ln_ppp urban_po gcf property, fe
estimates store FE
xtreg ln_patent ln_remit fdi_in ln_gdp ln_ppp urban_po gcf property, re
estimates store RE
xttest0
hausman FE RE, sigmamore
xtreg ln_patent ln_remit fdi_in ln_gdp ln_ppp urban_po gcf property, fe
xtcsd, pesaran abs
xtreg ln_patent ln_remit fdi_in ln_gdp ln_ppp urban_po gcf property, fe
xttest3
xtserial ln_patent ln_remit fdi_in ln_gdp ln_ppp urban_po gcf property
xtscc ln_patent ln_remit fdi_in ln_gdp ln_ppp urban_po gcf property, fe
reg ln_patent ln_remit ln_remit2 lnremit_prop lnremit2_prop property fdi_in ln_gdp ln_ppp gcf urban_po
estimates store POLS
xtreg ln_patent ln_remit ln_remit2 lnremit_prop lnremit2_prop property fdi_in ln_gdp ln_ppp gcf urban_po, fe
xttest3
xtserial ln_patent ln_remit ln_remit2 lnremit_prop lnremit2_prop property fdi_in ln_gdp ln_ppp gcf urban_po
xtreg ln_patent ln_remit ln_remit2 lnremit_prop lnremit2_prop property fdi_in ln_gdp ln_ppp gcf urban_po, fe
xtcsd, pesaran abs
utest ln_remit ln_remit2
sum ln_remit
nlcom -_b[ln_remit]/(2*_b[ln_remit2])
sum property, meanonly
local pm = r(mean)
nlcom -(_b[ln_remit] + _b[lnremit_prop]*`pm') / (2*(_b[ln_remit2] + _b[lnremit2_prop]*`pm'))
sum property, detail
local p25 = r(p25)
local p50 = r(p50)
local p75 = r(p75)

lincom _b[ln_remit] + _b[lnremit_prop]*`p25'
lincom _b[ln_remit2] + _b[lnremit2_prop]*`p25'
nlcom (tp_p25: -(_b[ln_remit] + _b[lnremit_prop]*`p25') / (2*(_b[ln_remit2] + _b[lnremit2_prop]*`p25')))

lincom _b[ln_remit] + _b[lnremit_prop]*`p50'
lincom _b[ln_remit2] + _b[lnremit2_prop]*`p50'
nlcom (tp_p50: -(_b[ln_remit] + _b[lnremit_prop]*`p50') / (2*(_b[ln_remit2] + _b[lnremit2_prop]*`p50')))

lincom _b[ln_remit] + _b[lnremit_prop]*`p75'
lincom _b[ln_remit2] + _b[lnremit2_prop]*`p75'
nlcom (tp_p75: -(_b[ln_remit] + _b[lnremit_prop]*`p75') / (2*(_b[ln_remit2] + _b[lnremit2_prop]*`p75')))

sum ln_remit
xtscc ln_patent ln_remit ln_remit2 lnremit_prop lnremit2_prop property fdi_in ln_gdp ln_ppp gcf urban_po, fe