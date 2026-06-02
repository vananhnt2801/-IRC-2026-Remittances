import excel "C:\Users\My_pc\Desktop\oecd-cit.xlsx", sheet("oecd-cit") firstrow
gen scit = cit
encode Country, gen (Country_id)
xtset Country_id year
gen ln_trade_gdp = ln(trade_gdp)
gen ln_exchange_rate = ln(exchange_rate)
summarize scit gmt gdp_growth inflation ln_trade_gdp popu_gr ln_exchange_rate
reg scit gmt gdp_growth inflation ln_trade_gdp popu_gr ln_exchange_rate
estat vif
reg scit gmt gdp_growth inflation ln_trade_gdp popu_gr ln_exchange_rate
estimates store POLS
xtreg scit gmt gdp_growth inflation ln_trade_gdp popu_gr ln_exchange_rate, fe
estimates store FE0
xtreg scit gmt gdp_growth inflation ln_trade_gdp popu_gr ln_exchange_rate, re
estimates store RE0
xttest0
hausman FE0 RE0, sigmamore
xtreg scit gmt gdp_growth inflation ln_trade_gdp popu_gr ln_exchange_rate, fe
xtreg scit gmt gdp_growth inflation ln_trade_gdp popu_gr ln_exchange_rate, fe
xttest3
xtserial scit gmt gdp_growth inflation ln_trade_gdp popu_gr ln_exchange_rate
xtreg scit gmt gdp_growth inflation ln_trade_gdp popu_gr ln_exchange_rate, fe
xtcsd, pesaran
xtscc scit gmt gdp_growth inflation ln_trade_gdp popu_gr ln_exchange_rate, fe
