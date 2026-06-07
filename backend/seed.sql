-- ============================================
-- QUANT STUDY TRACKER - SEED DATA (Fixed UUIDs)
-- ============================================

-- ============================================
-- PHASES
-- ============================================
INSERT INTO phases (id, name, phase_number, duration_weeks, hours_per_week, weight, description, display_order, color) VALUES
  ('a0000000-0000-0000-0000-000000000000', 'Finance Foundations', 0, 2, 10, 5, 'Learn the language of markets and companies: equities vs debt, bonds & yields, enterprise value vs equity value, basic corporate finance.', 1, '#4a90d9'),
  ('a0000000-0000-0000-0000-000000000001', 'Probability & Statistics', 1, 4, 12, 10, 'Most quant interviews start here. Focus on EV, Bayes, combinatorics, Monte Carlo methods.', 2, '#50c878'),
  ('a0000000-0000-0000-0000-000000000002', 'Financial Mathematics', 2, 4, 10, 10, 'Linear algebra, calculus, stochastic basics applied to finance. Bond pricing, Black-Scholes, binomial trees.', 3, '#ff6b6b'),
  ('a0000000-0000-0000-0000-000000000003', 'Valuation & Corporate Finance', 3, 4, 10, 10, 'Develop intuition for why companies are worth their price. DCF, WACC, comparables.', 4, '#ffa500'),
  ('a0000000-0000-0000-0000-000000000004', 'Portfolio Theory', 4, 6, 12, 15, 'Core of AWM. Modern portfolio theory, risk/return metrics, factor models, optimization techniques.', 5, '#9b59b6'),
  ('a0000000-0000-0000-0000-000000000005', 'Time Series', 5, 4, 10, 10, 'Forecasting financial data, autocorrelation, volatility clustering, cointegration.', 6, '#1abc9c'),
  ('a0000000-0000-0000-0000-000000000006', 'Derivatives & Options', 6, 6, 10, 10, 'Options, futures, volatility. Black-Scholes, Greeks, binomial models, hedging.', 7, '#e74c3c'),
  ('a0000000-0000-0000-0000-000000000007', 'Game Theory', 7, 3, 8, 5, 'Market-making and auctions as games. Nash equilibrium, mechanism design.', 8, '#3498db'),
  ('a0000000-0000-0000-0000-000000000008', 'Financial Machine Learning', 8, 6, 10, 15, 'Alpha modeling using ML/DL. Feature engineering, backtesting, walk-forward validation.', 9, '#2ecc71'),
  ('a0000000-0000-0000-0000-000000000009', 'Reinforcement Learning', 9, 6, 8, 10, 'Apply RL to trading. Portfolio rebalancing, trade execution, state/reward design.', 10, '#e67e22'),
  ('a0000000-0000-0000-0000-00000000000a', 'Quant Engineering & Projects', 10, NULL, NULL, 5, 'Build scalable quant systems. Data pipelines, backtesters, risk engines, GPU acceleration.', 11, '#95a5a6')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- ACTIVITIES (per phase)
-- ============================================

-- Phase 0: Finance Foundations
INSERT INTO activities (phase_id, name, category, sub_category, estimated_minutes, resource_url, resource_name, notes) VALUES
  ('a0000000-0000-0000-0000-000000000000', 'Read Little Book of Common Sense Investing (Bogle)', 'book', 'reading', 300, NULL, 'Little Book of Common Sense Investing', 'Classic investing basics'),
  ('a0000000-0000-0000-0000-000000000000', 'Read Intelligent Investor (Graham) - key chapters', 'book', 'reading', 360, NULL, 'Intelligent Investor', 'Focus on chapters 1, 8, 20'),
  ('a0000000-0000-0000-0000-000000000000', 'Damodaran Foundations of Finance lectures', 'video', 'lecture', 480, 'https://pages.stern.nyu.edu/~adamodar/New_Home_Page/onlineclass.htm', 'Damodaran Foundations of Finance', 'Free NYU Stern OCW course'),
  ('a0000000-0000-0000-0000-000000000000', 'Damodaran Corporate Finance playlist (YouTube)', 'video', 'lecture', 360, 'https://www.youtube.com/@AswathDamodaranonValuation', 'Damodaran YouTube Channel', 'Follow along with slides'),
  ('a0000000-0000-0000-0000-000000000000', 'Khan Academy Finance videos', 'video', 'course', 180, 'https://www.khanacademy.org/economics-finance-domain', 'Khan Academy Finance', 'Good for visual learners'),
  ('a0000000-0000-0000-0000-000000000000', 'Define & compute market cap, P/E, beta for 5 stocks', 'task', 'exercise', 90, NULL, NULL, 'Pick 5 Indian stocks (TCS, Reliance, HDFC, Infosys, ICICI)'),
  ('a0000000-0000-0000-0000-000000000000', 'Find bond yields and compute DCF of a company', 'task', 'project', 180, NULL, NULL, 'Deliverable: DCF model in Excel or Python'),
  ('a0000000-0000-0000-0000-000000000000', 'Read Investopedia guides on core finance terms', 'reading', 'reference', 120, 'https://www.investopedia.com/', 'Investopedia', 'Reference for terminology'),
  ('a0000000-0000-0000-0000-000000000000', 'Study Damodaran valuation papers on SSRN', 'paper', 'research', 120, 'https://papers.ssrn.com/', 'SSRN Damodaran Papers', 'Search for capital markets intro');

-- Phase 1: Probability & Statistics
INSERT INTO activities (phase_id, name, category, sub_category, estimated_minutes, resource_url, resource_name, notes) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Blitzstein Introduction to Probability (Stat110)', 'book', 'textbook', 600, NULL, 'Blitzstein Stat110', 'Free PDF from Harvard Stat110'),
  ('a0000000-0000-0000-0000-000000000001', 'Mosteller 50 Challenging Problems in Probability', 'book', 'practice', 300, NULL, 'Mosteller Problems', 'Free online'),
  ('a0000000-0000-0000-0000-000000000001', 'Heard on the Street (Crack) - probability section', 'book', 'interview', 360, NULL, 'Heard on the Street', 'Quant interview questions'),
  ('a0000000-0000-0000-0000-000000000001', 'Xinfeng Zhou Quant Interview Questions', 'book', 'interview', 240, NULL, 'Xinfeng Zhou', 'Concise Q&A format'),
  ('a0000000-0000-0000-0000-000000000001', 'MIT OCW 6.041 Probabilistic Systems Analysis', 'course', 'video', 600, 'https://ocw.mit.edu/courses/6-041-probabilistic-systems-analysis-and-applied-probability-fall-2010/', 'MIT 6.041', 'Free MIT course'),
  ('a0000000-0000-0000-0000-000000000001', 'Harvard Stat110 YouTube (David Blitzstein)', 'video', 'lecture', 480, 'https://www.youtube.com/playlist?list=PL2SOU6wwxB0uwwH80KTQ6ht66KWxbzTIo', 'Stat110 YouTube', 'Excellent intuition builder'),
  ('a0000000-0000-0000-0000-000000000001', 'Khan Academy - Bayes theorem & combinatorics', 'video', 'tutorial', 180, 'https://www.khanacademy.org/math/statistics-probability', 'Khan Academy Probability', 'Refresher on basics'),
  ('a0000000-0000-0000-0000-000000000001', 'Rice Mathematical Statistics & Data Analysis', 'book', 'textbook', 400, NULL, 'Rice Math Stats', 'For deeper stats coverage'),
  ('a0000000-0000-0000-0000-000000000001', 'Solve EV puzzles (coin-flip games, dice odds)', 'task', 'exercise', 120, NULL, NULL, 'Practice 20+ problems'),
  ('a0000000-0000-0000-0000-000000000001', 'Implement Monte Carlo sampler (European option)', 'task', 'coding', 180, NULL, NULL, 'Price via MC simulation'),
  ('a0000000-0000-0000-0000-000000000001', 'Compute confidence intervals for returns (Bayesian)', 'task', 'exercise', 120, NULL, NULL, 'Use real stock data'),
  ('a0000000-0000-0000-0000-000000000001', 'Build Kelly criterion calculator', 'task', 'project', 120, NULL, NULL, 'Implement in Python'),
  ('a0000000-0000-0000-0000-000000000001', 'Reddit quant roadmap threads', 'reading', 'research', 60, 'https://www.reddit.com/r/quant/', 'r/quant Reddit', 'Read recent roadmap discussions'),
  ('a0000000-0000-0000-0000-000000000001', 'QuantNet forum probability puzzles', 'reading', 'practice', 120, 'https://quantnet.com/', 'QuantNet Forums', 'Classic interview puzzles');

-- Phase 2: Financial Mathematics
INSERT INTO activities (phase_id, name, category, sub_category, estimated_minutes, resource_url, resource_name, notes) VALUES
  ('a0000000-0000-0000-0000-000000000002', 'Shreve Financial Mathematics Vol I - SDE intro', 'book', 'textbook', 600, NULL, 'Shreve Vol I', 'Skip Shreve II unless PhD-level needed'),
  ('a0000000-0000-0000-0000-000000000002', 'Neftci Mathematics of Financial Derivatives', 'book', 'textbook', 480, NULL, 'Neftci Math Derivatives', 'Good practical derivations'),
  ('a0000000-0000-0000-0000-000000000002', 'Joshi Concepts and Practice of Math Finance (Ch 1-7)', 'book', 'textbook', 360, NULL, 'Joshi Math Finance', 'Concise chapters 1-7'),
  ('a0000000-0000-0000-0000-000000000002', 'MIT 18.642 Topics in Math Finance', 'course', 'video', 480, 'https://ocw.mit.edu/courses/18-642-topics-in-mathematics-with-applications-in-finance-fall-2024/', 'MIT 18.642', 'MIT OCW playlist'),
  ('a0000000-0000-0000-0000-000000000002', 'Gilbert Strang 18.06 Linear Algebra (MIT OCW)', 'course', 'video', 600, 'https://ocw.mit.edu/courses/18-06-linear-algebra-spring-2010/', 'MIT 18.06', 'Essential linear algebra'),
  ('a0000000-0000-0000-0000-000000000002', 'MIT 15.401 Finance Theory I', 'course', 'video', 360, 'https://ocw.mit.edu/courses/15-401-finance-theory-i-fall-2008/', 'MIT 15.401', 'CAPM, portfolio theory intro'),
  ('a0000000-0000-0000-0000-000000000002', 'MITx Mathematical Methods for Quant Finance (edX)', 'course', 'online', 480, 'https://www.edx.org/course/mathematical-methods-for-quantitative-finance', 'MITx Quant Finance', 'Overview course'),
  ('a0000000-0000-0000-0000-000000000002', 'Implement bond pricer and yield-curve builder', 'task', 'project', 240, NULL, NULL, 'Bootstrapping method'),
  ('a0000000-0000-0000-0000-000000000002', 'Create binomial tree option pricer', 'task', 'project', 240, NULL, NULL, 'Implement in Python'),
  ('a0000000-0000-0000-0000-000000000002', 'Build Black-Scholes pricer (MC and PDE methods)', 'task', 'project', 300, NULL, NULL, 'Compare MC vs PDE'),
  ('a0000000-0000-0000-0000-000000000002', 'Portfolio optimization (Markowitz with CVXPY or numpy)', 'task', 'project', 180, NULL, NULL, 'Solve small MV problem');

-- Phase 3: Valuation & Corporate Finance
INSERT INTO activities (phase_id, name, category, sub_category, estimated_minutes, resource_url, resource_name, notes) VALUES
  ('a0000000-0000-0000-0000-000000000003', 'Damodaran Valuation Course (25 lectures)', 'course', 'video', 750, 'https://pages.stern.nyu.edu/~adamodar/New_Home_Page/webcastvalonline.htm', 'Damodaran Valuation Course', 'NYU Stern, free'),
  ('a0000000-0000-0000-0000-000000000003', 'Investment Valuation by Damodaran', 'book', 'textbook', 600, NULL, 'Damodaran Investment Valuation', 'Comprehensive valuation guide'),
  ('a0000000-0000-0000-0000-000000000003', 'Narrative and Numbers (Damodaran)', 'book', 'reading', 300, NULL, 'Narrative and Numbers', 'Qualitative + quantitative aspects'),
  ('a0000000-0000-0000-0000-000000000003', 'Financial Statement Analysis (Cooke, Joy)', 'book', 'textbook', 360, NULL, 'Fin Statement Analysis', 'Fundamentals of reading statements'),
  ('a0000000-0000-0000-0000-000000000003', 'Coursera Valuation and Investing (U Michigan)', 'course', 'online', 360, 'https://www.coursera.org/lecture/valuation/', 'Coursera Valuation', 'Audit for free'),
  ('a0000000-0000-0000-0000-000000000003', 'DCF Valuation: TCS (Excel or Python)', 'task', 'project', 240, NULL, NULL, 'Full DCF with WACC'),
  ('a0000000-0000-0000-0000-000000000003', 'DCF Valuation: Reliance Industries', 'task', 'project', 240, NULL, NULL, 'Compute terminal growth'),
  ('a0000000-0000-0000-0000-000000000003', 'DCF Valuation: HDFC Bank', 'task', 'project', 240, NULL, NULL, 'Financial sector DCF'),
  ('a0000000-0000-0000-0000-000000000003', 'Compute WACC and terminal growth for one company', 'task', 'exercise', 120, NULL, NULL, 'Detailed WACC breakdown'),
  ('a0000000-0000-0000-0000-000000000003', 'Prepare 5-page valuation report for one company', 'task', 'deliverable', 360, NULL, NULL, 'Summarize all findings'),
  ('a0000000-0000-0000-0000-000000000003', 'Build mini cap-table calculator', 'task', 'project', 120, NULL, NULL, 'Cap table modeling tool'),
  ('a0000000-0000-0000-0000-000000000003', 'Damodaran blog/papers on DCF', 'paper', 'research', 180, 'https://aswathdamodaran.blogspot.com/', 'Damodaran Blog', 'Follow recent posts');

-- Phase 4: Portfolio Theory
INSERT INTO activities (phase_id, name, category, sub_category, estimated_minutes, resource_url, resource_name, notes) VALUES
  ('a0000000-0000-0000-0000-000000000004', 'Expected Returns (Ilmanen)', 'book', 'textbook', 600, NULL, 'Expected Returns Ilmanen', 'Comprehensive risk/return resource'),
  ('a0000000-0000-0000-0000-000000000004', 'Active Portfolio Management (Grinold & Kahn)', 'book', 'textbook', 720, NULL, 'Grinold & Kahn', 'Bible of active management'),
  ('a0000000-0000-0000-0000-000000000004', 'Quant Portfolio Management (Chincarini)', 'book', 'textbook', 480, NULL, 'Chincarini QPM', 'Practical portfolio construction'),
  ('a0000000-0000-0000-0000-000000000004', 'Convex Optimization (Boyd) - relevant chapters', 'book', 'textbook', 360, NULL, 'Boyd Convex Optimization', 'Free PDF, chapters on portfolio opt'),
  ('a0000000-0000-0000-0000-000000000004', 'MIT 15.401 Finance Theory I (CAPM, factor models)', 'video', 'lecture', 480, 'https://ocw.mit.edu/courses/15-401-finance-theory-i-fall-2008/', 'MIT 15.401', 'Deep dive into CAPM'),
  ('a0000000-0000-0000-0000-000000000004', 'Quantopian/Alpaca portfolio construction videos', 'video', 'tutorial', 240, 'https://alpaca.markets/learn/', 'Alpaca Learn', 'Free portfolio building tutorials'),
  ('a0000000-0000-0000-0000-000000000004', 'Coursera Investment Mgmt with Python/ML (Yale)', 'course', 'online', 600, 'https://www.coursera.org/specializations/investment-management-python-machine-learning', 'Coursera Investment Mgmt', 'Audit free'),
  ('a0000000-0000-0000-0000-000000000004', 'Build mini BlackRock platform: 50 ETFs universe', 'task', 'project', 360, NULL, NULL, 'Compute expected returns & cov matrix'),
  ('a0000000-0000-0000-0000-000000000004', 'Implement Mean-Variance optimization', 'task', 'project', 240, NULL, NULL, 'With constraints'),
  ('a0000000-0000-0000-0000-000000000004', 'Implement Risk Parity portfolio', 'task', 'project', 240, NULL, NULL, 'Compare to MV'),
  ('a0000000-0000-0000-0000-000000000004', 'Backtest with simple rebalancing (quarterly)', 'task', 'project', 300, NULL, NULL, 'Historical simulation'),
  ('a0000000-0000-0000-0000-000000000004', 'Calculate portfolio Sharpe & max drawdown', 'task', 'exercise', 90, NULL, NULL, 'Track weekly'),
  ('a0000000-0000-0000-0000-000000000004', 'QuantStart Sharpe Ratio article', 'reading', 'reference', 60, 'https://www.quantstart.com/articles/Sharpe-Ratio-for-Algorithmic-Trading-Performance-Measurement/', 'QuantStart Sharpe', 'Reference methodology'),
  ('a0000000-0000-0000-0000-000000000004', 'Weekly Sharpe challenge - measure strategy', 'challenge', 'weekly', 60, NULL, NULL, 'Compute Sharpe for chosen strategy each week'),
  ('a0000000-0000-0000-0000-000000000004', 'Fama-French factor research', 'paper', 'research', 180, 'https://papers.ssrn.com/', 'SSRN Fama-French', 'Search for empirical factor investing');

-- Phase 5: Time Series
INSERT INTO activities (phase_id, name, category, sub_category, estimated_minutes, resource_url, resource_name, notes) VALUES
  ('a0000000-0000-0000-0000-000000000005', 'Forecasting: Principles & Practice (Hyndman) - free online', 'book', 'textbook', 480, 'https://otexts.com/fpp3/', 'Hyndman FPP3', 'Free online textbook'),
  ('a0000000-0000-0000-0000-000000000005', 'Analysis of Financial Time Series (Ruey Tsay)', 'book', 'textbook', 600, NULL, 'Tsay Fin Time Series', 'Standard reference'),
  ('a0000000-0000-0000-0000-000000000005', 'Time Series Analysis (James) - free', 'book', 'textbook', 360, NULL, 'James Time Series', 'Alternative free resource'),
  ('a0000000-0000-0000-0000-000000000005', 'StatQuest ARIMA/GARCH videos', 'video', 'tutorial', 180, 'https://www.youtube.com/@statquest', 'StatQuest', 'Clear visual explanations'),
  ('a0000000-0000-0000-0000-000000000005', 'QuantInsti time series & algo trading videos', 'video', 'tutorial', 240, 'https://quantra.quantinsti.com/', 'QuantInsti', 'Practical time series for trading'),
  ('a0000000-0000-0000-0000-000000000005', 'Forecast NIFTY index returns with ARIMA', 'task', 'project', 240, NULL, NULL, 'Using statsmodels in Python'),
  ('a0000000-0000-0000-0000-000000000005', 'Model India VIX with GARCH', 'task', 'project', 240, NULL, NULL, 'Volatility modeling'),
  ('a0000000-0000-0000-0000-000000000005', 'Cointegration test between INR and another currency', 'task', 'exercise', 120, NULL, NULL, 'Pairs trading basis'),
  ('a0000000-0000-0000-0000-000000000005', 'Build regime-switching model (Markov switching)', 'task', 'project', 300, NULL, NULL, 'Use statsmodels or custom'),
  ('a0000000-0000-0000-0000-000000000005', 'QuantStart backtesting pitfalls article', 'reading', 'reference', 60, 'https://www.quantstart.com/articles/', 'QuantStart Backtesting', 'Avoid overfitting'),
  ('a0000000-0000-0000-0000-000000000005', 'GARCH volatility India VIX paper (SSRN)', 'paper', 'research', 120, 'https://papers.ssrn.com/', 'SSRN India VIX', 'Search for GARCH volatility applications');

-- Phase 6: Derivatives & Options
INSERT INTO activities (phase_id, name, category, sub_category, estimated_minutes, resource_url, resource_name, notes) VALUES
  ('a0000000-0000-0000-0000-000000000006', 'Hull Options, Futures and Other Derivatives (Ch 1-6, binomial, BS)', 'book', 'textbook', 600, NULL, 'Hull Derivatives', 'Bible of derivatives, focus on chapters 1-6, binomial, BS'),
  ('a0000000-0000-0000-0000-000000000006', 'Natenberg Option Volatility and Pricing', 'book', 'textbook', 480, NULL, 'Natenberg Volatility', 'Market intuition for volatility'),
  ('a0000000-0000-0000-0000-000000000006', 'Baxter & Rennie Financial Calculus', 'book', 'textbook', 360, NULL, 'Baxter Rennie', 'Pricing theory, concise'),
  ('a0000000-0000-0000-0000-000000000006', 'Trading and Exchanges (Harris)', 'book', 'reading', 300, NULL, 'Harris Trading Exchanges', 'Market microstructure'),
  ('a0000000-0000-0000-0000-000000000006', 'Patrick Boyle YouTube on Black-Scholes', 'video', 'tutorial', 180, 'https://www.youtube.com/@PatrickBoyleOnFinance', 'Patrick Boyle', 'Clear BS explanations'),
  ('a0000000-0000-0000-0000-000000000006', 'MIT 18.434 Stochastic Processes', 'course', 'video', 360, 'https://ocw.mit.edu/courses/18-434-stochastic-processes-fall-2002/', 'MIT 18.434', 'Optional Ito calculus background'),
  ('a0000000-0000-0000-0000-000000000006', 'Khan Academy derivatives intro', 'video', 'tutorial', 120, 'https://www.khanacademy.org/', 'Khan Academy Derivatives', 'Basic derivatives concepts'),
  ('a0000000-0000-0000-0000-000000000006', 'Implement Black-Scholes pricer', 'task', 'project', 180, NULL, NULL, 'Equity and FX options'),
  ('a0000000-0000-0000-0000-000000000006', 'Build binomial option pricer', 'task', 'project', 240, NULL, NULL, 'European and American'),
  ('a0000000-0000-0000-0000-000000000006', 'Compute Greeks (delta, gamma, theta, vega, rho)', 'task', 'exercise', 180, NULL, NULL, 'Analyze option sensitivity'),
  ('a0000000-0000-0000-0000-000000000006', 'Simulate hedging P/L for a short option position', 'task', 'project', 240, NULL, NULL, 'Delta hedging simulation'),
  ('a0000000-0000-0000-0000-000000000006', 'Create binomial model for American option pricing', 'task', 'project', 240, NULL, NULL, 'With early exercise'),
  ('a0000000-0000-0000-0000-000000000006', 'Build options market-making quoting system prototype', 'task', 'project', 360, NULL, NULL, 'Simulate bid/ask quoting');

-- Phase 7: Game Theory
INSERT INTO activities (phase_id, name, category, sub_category, estimated_minutes, resource_url, resource_name, notes) VALUES
  ('a0000000-0000-0000-0000-000000000007', 'Game Theory 101 (Vanderbei)', 'book', 'textbook', 300, NULL, 'Vanderbei Game Theory', 'Princeton lecture notes style'),
  ('a0000000-0000-0000-0000-000000000007', 'Games of Strategy (Straffin)', 'book', 'textbook', 360, NULL, 'Straffin Games', 'Accessible game theory intro'),
  ('a0000000-0000-0000-0000-000000000007', 'Algorithmic Game Theory (Arora-Barak)', 'book', 'textbook', 480, NULL, 'Arora Barak', 'More advanced computational focus'),
  ('a0000000-0000-0000-0000-000000000007', 'MIT 14.12 Economic Applications of Game Theory', 'course', 'video', 480, 'https://ocw.mit.edu/courses/14-12-economic-applications-of-game-theory-fall-2005/', 'MIT 14.12', 'Free MIT OCW course'),
  ('a0000000-0000-0000-0000-000000000007', 'Stanford CS261 Game Theory (notes online)', 'course', 'online', 360, 'https://web.stanford.edu/class/cs261/', 'CS261 Stanford', 'Classic Stanford course'),
  ('a0000000-0000-0000-0000-000000000007', 'Khan Academy Game Theory basics', 'video', 'tutorial', 120, 'https://www.khanacademy.org/', 'Khan Academy Game Theory', 'Quick refresher'),
  ('a0000000-0000-0000-0000-000000000007', 'Simulate market-making game with two agents', 'task', 'project', 300, NULL, NULL, 'Bid/ask negotiation with Kelly criterion'),
  ('a0000000-0000-0000-0000-000000000007', 'Model exchange auction (order stack simulation)', 'task', 'project', 240, NULL, NULL, 'LOB dynamics simulation'),
  ('a0000000-0000-0000-0000-000000000007', 'Implement Nash equilibrium solver for trading game', 'task', 'project', 240, NULL, NULL, 'Simple 2-player game'),
  ('a0000000-0000-0000-0000-000000000007', 'Read Glosten-Milgrom model paper', 'paper', 'research', 120, 'https://papers.ssrn.com/', 'SSRN Glosten-Milgrom', 'Market microstructure foundation'),
  ('a0000000-0000-0000-0000-000000000007', 'QuantInsti market microstructure whitepapers', 'paper', 'research', 120, 'https://quantra.quantinsti.com/', 'QuantInsti Microstructure', 'Search for market microstructure papers');

-- Phase 8: Financial Machine Learning
INSERT INTO activities (phase_id, name, category, sub_category, estimated_minutes, resource_url, resource_name, notes) VALUES
  ('a0000000-0000-0000-0000-000000000008', 'Advances in Financial ML (de Prado)', 'book', 'textbook', 600, NULL, 'de Prado Adv Fin ML', 'Must-read for ML in finance'),
  ('a0000000-0000-0000-0000-000000000008', 'Machine Learning for Asset Managers (de Prado)', 'book', 'textbook', 480, NULL, 'de Prado ML Asset Mgrs', 'Shorter companion volume'),
  ('a0000000-0000-0000-0000-000000000008', 'Elements of Statistical Learning (Hastie)', 'book', 'textbook', 600, NULL, 'Hastie ESL', 'Theoretical ML foundation'),
  ('a0000000-0000-0000-0000-000000000008', 'QuantInsti ML in Trading course', 'course', 'online', 480, 'https://quantra.quantinsti.com/', 'QuantInsti ML Trading', 'Practical ML for traders'),
  ('a0000000-0000-0000-0000-000000000008', 'Udacity AI for Trading (partially free)', 'course', 'online', 600, 'https://www.udacity.com/course/ai-for-trading--nd880', 'Udacity AI Trading', 'Partially free nanodegree'),
  ('a0000000-0000-0000-0000-000000000008', 'Coursera ML Andrew Ng (relevant sections)', 'course', 'online', 360, 'https://www.coursera.org/learn/machine-learning', 'Andrew Ng ML', 'Gold standard ML intro'),
  ('a0000000-0000-0000-0000-000000000008', 'Hudson & Thames Quantopy series', 'video', 'tutorial', 240, 'https://hudson-thames.com/', 'Hudson & Thames', 'ML & portfolio applications'),
  ('a0000000-0000-0000-0000-000000000008', 'Build alpha pipeline: 10 factor features', 'task', 'project', 360, NULL, NULL, 'Momentum, value, macro indicators'),
  ('a0000000-0000-0000-0000-000000000008', 'Train XGBoost model for next-day return prediction', 'task', 'project', 300, NULL, NULL, 'Use LightGBM or XGBoost'),
  ('a0000000-0000-0000-0000-000000000008', 'Implement backtesting with walk-forward validation', 'task', 'project', 360, NULL, NULL, 'Avoid look-ahead bias'),
  ('a0000000-0000-0000-0000-000000000008', 'Deliverable: out-of-sample Sharpe report', 'task', 'deliverable', 120, NULL, NULL, 'Document results and methodology'),
  ('a0000000-0000-0000-0000-000000000008', 'Build small feature store (CSV/SQL + caching)', 'task', 'project', 240, NULL, NULL, 'Data engineering practice'),
  ('a0000000-0000-0000-0000-000000000008', 'Journal of Financial Data Science articles', 'paper', 'research', 180, 'https://jfds.pm-research.com/', 'JFDS', 'Latest fin ML research');

-- Phase 9: Reinforcement Learning
INSERT INTO activities (phase_id, name, category, sub_category, estimated_minutes, resource_url, resource_name, notes) VALUES
  ('a0000000-0000-0000-0000-000000000009', 'David Silver UCL DeepMind RL Lectures', 'course', 'video', 600, 'https://www.youtube.com/playlist?list=PLqYmG7hTraZDM-OYHWgPebj2MfCFzFObQ', 'David Silver RL', 'Definitive RL course'),
  ('a0000000-0000-0000-0000-000000000009', 'Sutton & Barto Reinforcement Learning', 'book', 'textbook', 720, NULL, 'Sutton & Barto', 'Bible of RL'),
  ('a0000000-0000-0000-0000-000000000009', 'Berkeley CS285 (TensorFlow) lectures', 'course', 'video', 480, 'https://rail.eecs.berkeley.edu/deeprlcourse/', 'Berkeley CS285', 'Deep RL focus'),
  ('a0000000-0000-0000-0000-000000000009', 'Stanford CS234 RL notes', 'course', 'online', 360, 'https://web.stanford.edu/class/cs234/', 'Stanford CS234', 'Alternative RL course'),
  ('a0000000-0000-0000-0000-000000000009', 'OpenAI Gym finance environments', 'tool', 'framework', 120, 'https://www.gymlibrary.dev/', 'OpenAI Gym', 'RL environment toolkit'),
  ('a0000000-0000-0000-0000-000000000009', 'Simulate RL agent for portfolio rebalancing', 'task', 'project', 480, NULL, NULL, 'DQN or PPO on toy market data'),
  ('a0000000-0000-0000-0000-000000000009', 'RL agent for trade execution (minimize VWAP slippage)', 'task', 'project', 480, NULL, NULL, 'Execution optimization'),
  ('a0000000-0000-0000-0000-000000000009', 'Document state/reward design for trading agents', 'task', 'deliverable', 180, NULL, NULL, 'Explain design decisions');

-- Phase 10: Quant Engineering & Projects
INSERT INTO activities (phase_id, name, category, sub_category, estimated_minutes, resource_url, resource_name, notes) VALUES
  ('a0000000-0000-0000-0000-00000000000a', 'Designing Data-Intensive Applications (Kleppmann)', 'book', 'textbook', 600, NULL, 'DDIA Kleppmann', 'Must-read for systems design'),
  ('a0000000-0000-0000-0000-00000000000a', 'Systematic Trading (Carver)', 'book', 'reading', 300, NULL, 'Carver Systematic Trading', 'Practical system building'),
  ('a0000000-0000-0000-0000-00000000000a', 'Arpit Bhayani Redis Internals (YouTube)', 'video', 'tutorial', 240, 'https://www.youtube.com/@ArpitBhayani', 'Arpit Bhayani', 'Redis internals deep dive'),
  ('a0000000-0000-0000-0000-00000000000a', 'Arpit Bhayani System Design Masterclass', 'course', 'online', 480, 'https://arpitbhayani.me/masterclass/', 'System Design Masterclass', 'Or free YouTube videos'),
  ('a0000000-0000-0000-0000-00000000000a', 'CUDA by Example (IIT Delhi PDF)', 'book', 'textbook', 360, 'https://www.cse.iitd.ac.in/~rijurekha/col730_2022/cudabook.pdf', 'CUDA by Example', 'Free PDF, optional GPU acceleration'),
  ('a0000000-0000-0000-0000-00000000000a', 'Build data pipeline (Yahoo market data ingest)', 'task', 'project', 360, NULL, NULL, 'Kafka/Postgres or Redis cache'),
  ('a0000000-0000-0000-0000-00000000000a', 'Build factor engine & backtester framework', 'task', 'project', 480, NULL, NULL, 'Python + Pandas + backtrader/zipline'),
  ('a0000000-0000-0000-0000-00000000000a', 'Productionize portfolio optimizer (CVX or custom solver)', 'task', 'project', 360, NULL, NULL, 'Mean-Variance with constraints'),
  ('a0000000-0000-0000-0000-00000000000a', 'Build risk engine (VaR, stress tests, MC)', 'task', 'project', 360, NULL, NULL, 'Visualize with Plotly'),
  ('a0000000-0000-0000-0000-00000000000a', 'Mock order execution system (limit order book)', 'task', 'project', 360, NULL, NULL, 'Connect to Game Theory project'),
  ('a0000000-0000-0000-0000-00000000000a', 'GPU/Numba accelerate MC simulations', 'task', 'project', 240, NULL, NULL, 'Based on Nvidia guide'),
  ('a0000000-0000-0000-0000-00000000000a', 'Daily Striver LeetCode (1 problem)', 'task', 'daily', 30, NULL, 'Striver DSA', 'Daily coding practice'),
  ('a0000000-0000-0000-0000-00000000000a', 'Weekly Codeforces contest', 'task', 'weekly', 120, 'https://codeforces.com/', 'Codeforces', 'Weekly competitive programming'),
  ('a0000000-0000-0000-0000-00000000000a', 'Interview prep from Heard on the Street', 'task', 'interview', 120, NULL, 'Heard Interview Qs', 'Practice with Stefanica questions');

-- ============================================
-- PROJECTS & CHALLENGES
-- ============================================
INSERT INTO projects (name, category, phase_id) VALUES
  ('Bond Pricing Engine', 'project', 'a0000000-0000-0000-0000-000000000002'),
  ('Yield Curve Builder', 'project', 'a0000000-0000-0000-0000-000000000002'),
  ('Black-Scholes Engine', 'project', 'a0000000-0000-0000-0000-000000000006'),
  ('Portfolio Optimizer', 'project', 'a0000000-0000-0000-0000-000000000004'),
  ('Risk (VaR) Engine', 'project', 'a0000000-0000-0000-0000-00000000000a'),
  ('Factor/Signal Library', 'project', 'a0000000-0000-0000-0000-000000000008'),
  ('Alpha Research Platform', 'project', 'a0000000-0000-0000-0000-000000000008'),
  ('Backtester Framework', 'project', 'a0000000-0000-0000-0000-00000000000a'),
  ('RL Portfolio Agent', 'project', 'a0000000-0000-0000-0000-000000000009'),
  ('Market-Making Simulator', 'project', 'a0000000-0000-0000-0000-000000000007'),
  ('Weekly Sharpe Challenge', 'challenge', 'a0000000-0000-0000-0000-000000000004'),
  ('Monthly Valuation Challenge', 'challenge', 'a0000000-0000-0000-0000-000000000003'),
  ('Quarterly Factor Research Reproduction', 'challenge', 'a0000000-0000-0000-0000-000000000008');

-- ============================================
-- BOOKS (20 core books)
-- ============================================
INSERT INTO books (title, author, phase_id, status) VALUES
  ('Heard on the Street', 'Timothy Crack', 'a0000000-0000-0000-0000-000000000001', 'not_started'),
  ('Quant Interview Questions', 'Xinfeng Zhou', 'a0000000-0000-0000-0000-000000000001', 'not_started'),
  ('Expected Returns', 'Antti Ilmanen', 'a0000000-0000-0000-0000-000000000004', 'not_started'),
  ('Active Portfolio Management', 'Grinold & Kahn', 'a0000000-0000-0000-0000-000000000004', 'not_started'),
  ('Options, Futures and Other Derivatives', 'John Hull', 'a0000000-0000-0000-0000-000000000006', 'not_started'),
  ('Financial Calculus', 'Baxter & Rennie', 'a0000000-0000-0000-0000-000000000006', 'not_started'),
  ('Investment Valuation', 'Aswath Damodaran', 'a0000000-0000-0000-0000-000000000003', 'not_started'),
  ('Forecasting: Principles & Practice', 'Rob Hyndman', 'a0000000-0000-0000-0000-000000000005', 'not_started'),
  ('Introduction to Probability (Stat110)', 'Blitzstein & Hwang', 'a0000000-0000-0000-0000-000000000001', 'not_started'),
  ('Advances in Financial Machine Learning', 'Marcos de Prado', 'a0000000-0000-0000-0000-000000000008', 'not_started'),
  ('Systematic Trading', 'Robert Carver', 'a0000000-0000-0000-0000-00000000000a', 'not_started'),
  ('Algorithmic Trading', 'Ernie Chan', 'a0000000-0000-0000-0000-000000000008', 'not_started'),
  ('Option Volatility and Pricing', 'Sheldon Natenberg', 'a0000000-0000-0000-0000-000000000006', 'not_started'),
  ('Elements of Statistical Learning', 'Hastie, Tibshirani, Friedman', 'a0000000-0000-0000-0000-000000000008', 'not_started'),
  ('Designing Data-Intensive Applications', 'Martin Kleppmann', 'a0000000-0000-0000-0000-00000000000a', 'not_started'),
  ('Reinforcement Learning', 'Sutton & Barto', 'a0000000-0000-0000-0000-000000000009', 'not_started'),
  ('Mathematical Statistics & Data Analysis', 'John Rice', 'a0000000-0000-0000-0000-000000000001', 'not_started'),
  ('Convex Optimization', 'Boyd & Vandenberghe', 'a0000000-0000-0000-0000-000000000004', 'not_started'),
  ('Financial Mathematics Vol I', 'Steven Shreve', 'a0000000-0000-0000-0000-000000000002', 'not_started'),
  ('Mathematics of Financial Derivatives', 'Salih Neftci', 'a0000000-0000-0000-0000-000000000002', 'not_started');

-- ============================================
-- MBA SCHEDULE (from pgpmci_schedule.csv)
-- ============================================
-- Tue/Thu/Sat: Session 1 (6:15-7:15 PM), Session 2 (7:30-8:30 PM)
-- Sunday: Session 1 (9:15-10:15 AM), Session 2 (10:30-11:30 AM),
--          Session 3 (2:15-3:15 PM), Session 4 (3:30-4:30 PM)

DO $$
DECLARE
  rec RECORD;
  session_date DATE;
  day_name TEXT;
  session_start TIME;
  session_end TIME;
  color_val TEXT;
BEGIN
  FOR rec IN
    SELECT * FROM (VALUES
      ('2026-03-10', 'BSQT 1', 'BSQT 2', NULL, NULL),
      ('2026-03-12', 'FIAC 1', 'FIAC 2', NULL, NULL),
      ('2026-03-14', 'FIAC 3', 'FIAC 4', NULL, NULL),
      ('2026-03-17', 'BSQT 3', 'BSQT 4', NULL, NULL),
      ('2026-03-19', 'BSQT 5', 'BSQT 6', NULL, NULL),
      ('2026-03-21', 'FIAC 5', 'FIAC 6', NULL, NULL),
      ('2026-03-22', 'FIAC 7', 'FIAC 8', NULL, NULL),
      ('2026-03-24', 'FIAC 9', 'FIAC 10', NULL, NULL),
      ('2026-03-26', 'MKMT 1', 'MKMT 2', NULL, NULL),
      ('2026-03-28', 'MKMT 3', 'MKMT 4', NULL, NULL),
      ('2026-03-29', 'FIAC 11', 'FIAC 12', NULL, NULL),
      ('2026-03-31', 'MAEC 1', 'MAEC 2', NULL, NULL),
      ('2026-04-02', 'BSQT 7', 'BSQT 8', NULL, NULL),
      ('2026-04-04', 'FIAC 13', 'FIAC 14', NULL, NULL),
      ('2026-04-07', 'BSQT 9', 'BSQT 10', NULL, NULL),
      ('2026-04-09', 'Free Slot', 'Free Slot', NULL, NULL),
      ('2026-04-11', 'ORBE 1', 'ORBE 2', 'ORBE 1?', NULL),
      ('2026-04-12', 'FIAC 15', 'FIAC 16', NULL, NULL),
      ('2026-04-14', 'MAEC 3', 'MAEC 4', NULL, NULL),
      ('2026-04-16', 'MKMT 5', 'MKMT 6', NULL, NULL),
      ('2026-04-18', 'FIAC 17', 'FIAC 18', NULL, NULL),
      ('2026-04-19', 'BSQT 11', 'BSQT 12', NULL, NULL),
      ('2026-04-21', 'MKMT 7', 'MKMT 8', NULL, NULL),
      ('2026-04-23', 'MAEC 5', 'MAEC 6', NULL, NULL),
      ('2026-04-26', 'ORBE 3', 'ORBE 4', NULL, NULL),
      ('2026-04-30', 'MKMT 9', 'MKMT 10', NULL, NULL),
      ('2026-05-02', 'FIAC 19', 'FIAC 20', NULL, NULL),
      ('2026-05-03', 'BSQT 13', 'BSQT 14', 'ORBE 5', 'ORBE 6'),
      ('2026-05-07', 'ORBE 7', 'ORBE 8', NULL, NULL),
      ('2026-05-09', 'ORBE 9', 'ORBE 10', NULL, NULL),
      ('2026-05-10', 'BSQT 15', 'BSQT 16', 'IDD 9', 'IDD 10'),
      ('2026-05-14', 'ORBE 11', 'ORBE 12', NULL, NULL),
      ('2026-05-16', 'BSQT 17', 'BSQT 18', NULL, NULL),
      ('2026-05-19', 'BSQT 19', 'BSQT 20', NULL, NULL),
      ('2026-05-21', 'ORBE 13', 'ORBE 14', NULL, NULL),
      ('2026-05-23', 'MAEC 7', 'MAEC 8', NULL, NULL),
      ('2026-05-24', 'MAEC 9', 'MAEC 10', 'Free Slot', 'Free Slot'),
      ('2026-05-26', 'MAEC 11', 'MAEC 12', NULL, NULL),
      ('2026-05-28', 'MKMT 11', 'MKMT 12', NULL, NULL),
      ('2026-05-30', 'MKMT 13', 'MKMT 14', NULL, NULL),
      ('2026-05-31', 'MAEC 13', 'MAEC 14', 'Free Slot', 'Free Slot'),
      ('2026-06-02', 'MAEC 15', 'MAEC 16', NULL, NULL),
      ('2026-06-04', 'ORBE 15', 'ORBE 16', NULL, NULL),
      ('2026-06-06', 'MKMT 15', 'MKMT 16', NULL, NULL),
      ('2026-06-07', 'MAEC 17', 'MAEC 18', 'ORBE 17', 'ORBE 18'),
      ('2026-06-09', 'MKMT 17', 'MKMT 18', NULL, NULL),
      ('2026-06-11', 'MKMT 19', 'MKMT 20', NULL, NULL),
      ('2026-06-13', 'MAEC 19', 'MAEC 20', NULL, NULL),
      ('2026-06-14', 'ORBE 19', 'ORBE 20', NULL, NULL)
    ) AS d(date_val, s1, s2, s3, s4)
  LOOP
    session_date := rec.date_val::DATE;
    day_name := TO_CHAR(session_date, 'Day');

    IF rec.s1 IS NOT NULL THEN
      IF rec.s1 LIKE 'BSQT%' THEN color_val := '#e74c3c';
      ELSIF rec.s1 LIKE 'FIAC%' THEN color_val := '#3498db';
      ELSIF rec.s1 LIKE 'MKMT%' THEN color_val := '#2ecc71';
      ELSIF rec.s1 LIKE 'MAEC%' THEN color_val := '#f39c12';
      ELSIF rec.s1 LIKE 'ORBE%' THEN color_val := '#9b59b6';
      ELSIF rec.s1 LIKE 'IDD%' THEN color_val := '#1abc9c';
      ELSE color_val := '#95a5a6';
      END IF;
    END IF;

    -- Session 1 (6:15-7:15 PM)
    IF rec.s1 IS NOT NULL AND rec.s1 != 'Free Slot' THEN
      session_start := '18:15:00';
      session_end := '19:15:00';
      INSERT INTO schedule (title, description, category, subject, start_time, end_time, color)
      VALUES (rec.s1, 'MBA Class - ' || rec.s1, 'MBA Class',
              CASE
                WHEN rec.s1 LIKE 'BSQT%' THEN 'BSQT'
                WHEN rec.s1 LIKE 'FIAC%' THEN 'FIAC'
                WHEN rec.s1 LIKE 'MKMT%' THEN 'MKMT'
                WHEN rec.s1 LIKE 'MAEC%' THEN 'MAEC'
                WHEN rec.s1 LIKE 'ORBE%' THEN 'ORBE'
                WHEN rec.s1 LIKE 'IDD%' THEN 'IDD'
                ELSE 'Other'
              END,
              session_date + session_start, session_date + session_end, color_val);
    END IF;

    -- Session 2 (7:30-8:30 PM)
    IF rec.s2 IS NOT NULL AND rec.s2 != 'Free Slot' THEN
      session_start := '19:30:00';
      session_end := '20:30:00';
      INSERT INTO schedule (title, description, category, subject, start_time, end_time, color)
      VALUES (rec.s2, 'MBA Class - ' || rec.s2, 'MBA Class',
              CASE
                WHEN rec.s2 LIKE 'BSQT%' THEN 'BSQT'
                WHEN rec.s2 LIKE 'FIAC%' THEN 'FIAC'
                WHEN rec.s2 LIKE 'MKMT%' THEN 'MKMT'
                WHEN rec.s2 LIKE 'MAEC%' THEN 'MAEC'
                WHEN rec.s2 LIKE 'ORBE%' THEN 'ORBE'
                WHEN rec.s2 LIKE 'IDD%' THEN 'IDD'
                ELSE 'Other'
              END,
              session_date + session_start, session_date + session_end, color_val);
    END IF;

    -- Session 3 (2:15-3:15 PM)
    IF rec.s3 IS NOT NULL AND rec.s3 != 'Free Slot' THEN
      session_start := '14:15:00';
      session_end := '15:15:00';
      INSERT INTO schedule (title, description, category, subject, start_time, end_time, color)
      VALUES (rec.s3, 'MBA Class - ' || rec.s3, 'MBA Class',
              CASE
                WHEN rec.s3 LIKE 'BSQT%' THEN 'BSQT'
                WHEN rec.s3 LIKE 'FIAC%' THEN 'FIAC'
                WHEN rec.s3 LIKE 'MKMT%' THEN 'MKMT'
                WHEN rec.s3 LIKE 'MAEC%' THEN 'MAEC'
                WHEN rec.s3 LIKE 'ORBE%' THEN 'ORBE'
                WHEN rec.s3 LIKE 'IDD%' THEN 'IDD'
                ELSE 'Other'
              END,
              session_date + session_start, session_date + session_end, color_val);
    END IF;

    -- Session 4 (3:30-4:30 PM)
    IF rec.s4 IS NOT NULL AND rec.s4 != 'Free Slot' THEN
      session_start := '15:30:00';
      session_end := '16:30:00';
      INSERT INTO schedule (title, description, category, subject, start_time, end_time, color)
      VALUES (rec.s4, 'MBA Class - ' || rec.s4, 'MBA Class',
              CASE
                WHEN rec.s4 LIKE 'BSQT%' THEN 'BSQT'
                WHEN rec.s4 LIKE 'FIAC%' THEN 'FIAC'
                WHEN rec.s4 LIKE 'MKMT%' THEN 'MKMT'
                WHEN rec.s4 LIKE 'MAEC%' THEN 'MAEC'
                WHEN rec.s4 LIKE 'ORBE%' THEN 'ORBE'
                WHEN rec.s4 LIKE 'IDD%' THEN 'IDD'
                ELSE 'Other'
              END,
              session_date + session_start, session_date + session_end, color_val);
    END IF;
  END LOOP;
END $$;