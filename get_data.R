# =============================================================================
# get_data.R -- download 0050 daily closing prices from the TWSE open API
# and write data/0050.dat (one close per line) + data/0050.csv (date, close)
#
# Usage:  Rscript get_data.R
# Needs:  install.packages("jsonlite")
# =============================================================================
library(jsonlite)

stock_no   <- "0050"
start_date <- as.Date("2022-01-03")
end_date   <- as.Date("2023-05-04")

fetch_month <- function(ym) {
  url <- sprintf(
    "https://www.twse.com.tw/exchangeReport/STOCK_DAY?response=json&date=%s01&stockNo=%s",
    ym, stock_no)
  res <- tryCatch(fromJSON(url), error = function(e) NULL)
  if (is.null(res) || is.null(res$data) || length(res$data) == 0) return(NULL)
  d <- as.data.frame(res$data, stringsAsFactors = FALSE)
  # columns: 日期, 成交股數, 成交金額, 開盤價, 最高價, 最低價, 收盤價, 漲跌價差, 成交筆數
  roc  <- strsplit(d[[1]], "/")
  date <- as.Date(sapply(roc, function(x)
    sprintf("%d-%s-%s", as.integer(x[1]) + 1911, x[2], x[3])))
  data.frame(date = date, close = as.numeric(gsub(",", "", d[[7]])))
}

months <- format(seq(as.Date("2022-01-01"), as.Date("2023-05-01"), by = "month"), "%Y%m")
out <- do.call(rbind, lapply(months, function(m) {
  message("fetching ", m)
  Sys.sleep(3)          # TWSE rate-limits rapid requests
  fetch_month(m)
}))

out <- out[out$date >= start_date & out$date <= end_date, ]
out <- out[order(out$date), ]
dir.create("data", showWarnings = FALSE)
write.csv(out, "data/0050.csv", row.names = FALSE)
writeLines(format(out$close), "data/0050.dat")
message(nrow(out), " rows written (expected 320)")
