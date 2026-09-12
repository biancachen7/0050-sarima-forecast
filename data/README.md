# Data

- `0050.csv` — `date,close` for the Yuanta Taiwan Top 50 ETF (0050.TW), 2022-01-03 to 2023-05-04, 320 trading days
- `0050.dat` — the same closes only, one per line, no header (input for `0050_sarima.R`)

Source: Taiwan Stock Exchange daily quotes API
(`https://www.twse.com.tw/exchangeReport/STOCK_DAY`), pulled 2026-09-12. Both
files can be regenerated with `Rscript get_data.R`.

Note: the original 2023 report used a 312-row extract of the same period
(max 152, min 96.7 and median 119.1 all match this file); the exact rows that
were dropped are unknown, so the AIC/BIC values quoted in the README may differ
slightly if the analysis is re-run on this file.
