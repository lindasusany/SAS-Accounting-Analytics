# Contrarian and Momentum Trading Strategies - Data Analysis

## Overview
This repository contains code and analysis to replicate Contrarian and Momentum trading strategies using CRSP monthly return data. The goal of this project is to investigate the performance of these strategies under different time horizons and analyze the results in comparison to the original research.

## Data Source
I used CRSP (Center for Research in Security Prices) monthly return data for a specific decade, focusing on either the 1990s or the 2010s, as chosen. The dataset includes monthly returns for a wide range of securities, allowing me to form portfolios and evaluate trading strategies.

## Sample Selection
Formation Period:
- I tested two different formation windows: one with a three-year formation window (J) and another with a one-year formation window.

Holding Period:
- Various holding periods (K values) were tested to assess strategy performance over different durations.

Number of Groups:
- The number of groups for past winner/loser portfolios was adjusted to ensure that each group contained roughly 30 to 50 securities, maintaining a balanced sample.

## Key Findings
### Contrarian Strategy (3-year Formation Window)
- **1980s**: In this decade, Contrarian strategy exhibited positive performance, with past loser portfolios outperforming past winner portfolios, resulting in a LONG_SHORT of 0.0817.
- **1990s**: Contrarian strategy had mixed results, with past winner portfolios significantly underperforming past loser portfolios (LONG_SHORT: -0.1838).
- **2000s**: Similar to the 1990s, Contrarian strategy in the 2000s saw underperformance of past winner portfolios compared to past losers (LONG_SHORT: -0.1649).
- **2010s**: Contrarian strategy showed a modest positive performance, with past losers outperforming past winners (LONG_SHORT: 0.0506).
- **2020s**: In this decade, Contrarian strategy exhibited significant underperformance, with past winner portfolios significantly outperforming past loser portfolios (LONG_SHORT: -0.2778).

### Momentum Strategy (3-year Formation Window)
- **1980s**: Momentum strategy displayed positive performance, with past winner portfolios outperforming past loser portfolios (LONG_SHORT: 0.0523).
- **1990s**: Momentum strategy showed strong performance, with past winner portfolios significantly outperforming past loser portfolios (LONG_SHORT: -0.1285).
- **2000s**: Momentum strategy exhibited mixed results, with past winner portfolios underperforming past loser portfolios (LONG_SHORT: -0.1705).
- **2010s**: In the 2010s, Momentum strategy displayed modest positive performance, with past winner portfolios outperforming past loser portfolios (LONG_SHORT: 0.0286).
- **2020s**: Momentum strategy had a significant underperformance, with past winner portfolios outperforming past loser portfolios (LONG_SHORT: -0.3192).

## Discussion
The performance of Contrarian and Momentum trading strategies varies across different decades, highlighting the importance of adapting investment strategies to changing market conditions. Contrarian strategies may perform well in some decades, while Momentum strategies exhibit strong performance in others. These findings underscore the need for adaptive and data-driven investment approaches, considering the specific time period and market dynamics.

Please note that the number of securities in past winner/loser groups varied across decades, which could also impact strategy performance. Further analysis and exploration of these results can provide valuable insights for investors and portfolio managers.

For a more detailed analysis, consider visualizing these results in graphical format to gain a better understanding of performance trends over time.
