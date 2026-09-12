# =============================================================================
# SARIMA forecasting of the 0050 ETF (Yuanta Taiwan Top 50)
#
# Data : data/0050.dat  -- daily closing prices, 2022-01-03 to 2023-05-04
#        (312 rows in the original report; the TWSE pull in data/ has 320)
# Split: first 300 observations for fitting, the rest held out for validation
# Model: ARIMA(0,1,0)(0,0,1)[5]  (weekly seasonality, 5 trading days)
# =============================================================================

# install.packages("tseries")
library(tseries)

# --- 1. Load data ------------------------------------------------------------
data   <- read.table("data/0050.dat")[, 1]
data.t <- data[1:300]                    # training set

# --- 2. Raw series: plot, ACF, PACF -----------------------------------------
par(mfrow = c(2, 1))
plot.ts(data.t, main = "0050 daily close (training set)")
acf(data.t, 60)
pacf(data.t, 60)

# --- 3. Unit-root tests on the raw series -----------------------------------
# H0: series has a unit root (non-stationary)
adf.test(log(data.t), k = 0)  # Dickey-Fuller            p = 0.8565
adf.test(log(data.t))         # Augmented Dickey-Fuller  p = 0.7635
pp.test(log(data.t))          # Phillips-Perron          p = 0.8801
# -> all p > 0.05, cannot reject H0: difference the series

# --- 4. First difference: ACF, PACF, unit-root tests ------------------------
acf(diff(data.t), 60)
pacf(diff(data.t), 60)
# Both ACF and PACF spike at lag 20 -> p = 0, q = 0; search P <= 4, Q <= 4

adf.test(diff(log(data.t)), k = 0)  # p = 0.01
adf.test(diff(log(data.t)))         # p = 0.01
pp.test(diff(log(data.t)))          # p = 0.01
# -> all p < 0.05, series is stationary after one difference (D = 0)

# --- 5. Candidate models -----------------------------------------------------
# Period = 5 because the data are daily and there are 5 trading days per week.

# Model A: ARIMA(0,1,0)(2,0,4)[5]  -- lowest AIC among the candidates
fit.a <- arima(data.t, order = c(0, 1, 0),
               seasonal = list(order = c(2, 0, 4), period = 5))
fit.a$coef
tsdiag(fit.a, 10)
Box.test(fit.a$residuals, lag = 20, type = "Ljung-Box")  # p > 0.05 -> white noise
AIC(fit.a)  # 1140.547
BIC(fit.a)  # 1166.45

# Model B: ARIMA(0,1,0)(0,0,1)[5]  -- lowest BIC among the candidates
fit.b <- arima(data.t, order = c(0, 1, 0),
               seasonal = list(order = c(0, 0, 1), period = 5))
fit.b$coef  # sma1 = 0.0402
tsdiag(fit.b, 10)
Box.test(fit.b$residuals, lag = 20, type = "Ljung-Box")  # p > 0.05 -> white noise
AIC(fit.b)  # 1141.072
BIC(fit.b)  # 1148.473

# Both models pass the residual white-noise check; Model B has far fewer
# parameters (1 vs 6) at almost identical AIC, so Model B is selected.

# --- 6. Forecast the 12 held-out days with the selected model ---------------
best     <- fit.b
data.pre <- predict(best, n.ahead = 12)
U <- data.pre$pred + 1.96 * data.pre$se   # upper 95% bound
L <- data.pre$pred - 1.96 * data.pre$se   # lower 95% bound

par(mfrow = c(1, 1))

# Full series with forecast
plot.ts(data, type = "o", ylab = "price",
        main = "0050 close: actual (black) vs forecast (red), 95% CI (blue)")
lines(data.pre$pred, col = "red",  type = "o")
lines(U,             col = "blue", type = "o")
lines(L,             col = "blue", type = "o")
abline(v = 300.5, lty = "dotted")

# Zoom on the last 43 observations
data.r <- 270:312
plot(data.r, data[data.r], type = "o", ylim = c(100, 180), ylab = "price",
     xlab = "day", main = "Forecast window (days 301-312)")
lines(data.pre$pred, col = "red",  type = "o")
lines(U,             col = "blue", type = "o")
lines(L,             col = "blue", type = "o")
abline(v = 300.5, lty = "dotted")
