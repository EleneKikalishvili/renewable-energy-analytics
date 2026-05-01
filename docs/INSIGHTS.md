# Renewable Energy Analytics - Key Insights
**Last updated:** May 2026

> **Scope:** Global analysis covering 2000-2023 (cost and performance data from 2010-2023).  
> **Data sources:** IRENA, Energy Institute, Eurostat (staged, not analyzed), DataHub ISO country codes.  
> **Note:** Public investment data covers 2000-2020 only. Emissions analysis covers 2000-2023 but was excluded from Tableau dashboards due to data limitations (see Section 5). Public investment analysis was excluded from Tableau dashboards due to data scope limitations (see Section 4).

---

## Executive Summary

This document synthesizes analytical findings from a full-stack renewable energy analytics project covering global electricity generation, installed capacity, technology costs, public investment, and CO₂ emissions from 2000 to 2023. Findings draw on SQL analysis of four integrated public datasets and interactive Tableau dashboard exploration across four dashboards.

**The ten most important findings across all sections:**

1. **The transition is real but incomplete.** Renewables' share of global electricity generation grew from 18.3% to 29.9% over 23 years - but fossil fuels still generate nearly twice as much electricity as all renewables combined, and coal alone outproduces the entire renewable sector.

2. **Solar PV is the defining technology of the transition.** From effectively zero in 2000, Solar PV grew 2,034x in generation and 1,755x in installed capacity, overtaking hydropower in 2023 to become the world's #1 renewable technology. Its LCOE fell 90.4% since 2010 - the steepest cost reduction of any energy technology in history.

3. **Capacity is being built faster than it's being used - and the gap is widening.** Renewable capacity share (43%) is now 13.2 pp ahead of generation share (29.9%), and the gap is accelerating: renewable capacity YoY growth hit 14.39% in 2023 while generation YoY growth was 5.57%. Investment pipelines are decoupled from short-term demand signals.

4. **Two renewable technologies are now cheaper than fossil fuels.** Onshore wind ($0.03/kWh) and solar PV ($0.04/kWh) sit below the cheapest fossil fuel ($0.07/kWh). Across the full renewable portfolio, LCOE fell 35.2% while installed costs fell only 12.2% - operational improvements account for the gap, meaning renewables are more competitive than capital cost data alone suggests.

5. **The renewable cost revolution is not universal.** Geothermal is the only renewable technology where both LCOE (+30.8%) and installed cost (+52.4%) increased since 2010 - crossing from below to within the fossil fuel cost range. Resource-constrained, site-specific technologies with no manufacturing learning curve are not benefiting from the same forces driving solar and wind costs down.

6. **Hydropower's growth is effectively over, and climate risk is rising.** At 47.8% of renewable generation, hydropower is still the backbone of the renewable mix - but its 5-year CAGR is 0.30%, 2023 saw an absolute generation decline of -72K GWh, and installed costs have nearly doubled (+92.3%) since 2010. New dams are still being built, but hydrological variability is suppressing returns.

7. **Coal remains the critical barrier.** At 10,171K GWh, coal generates more electricity than all renewables combined. Its 5-year CAGR has decelerated to 0.83%, but the 2021 post-pandemic rebound (+7.25% YoY) confirms demand remains highly elastic. The fossil capacity build-out in developing Asia is continuing in parallel with the renewable transition.

8. **The stranded-asset signal is already visible.** Coal capacity CAGR (4.15%) is nearly double its generation CAGR (2.34%); natural gas shows the same pattern (4.93% vs 3.85%). New thermal plants are being commissioned while the fleet runs at declining utilization rates.

9. **Public investment has tilted toward renewables since 2012 - but the overall picture is more complex than it appears.** Renewables received 49.6% of $531B in total public energy finance (2000-2020), exceeding fossil fuels. But this covers public finance only; private investment data would be required to assess the full picture. China alone accounts for ~44% of all public energy investment.

10. **Higher renewable share strongly correlates with lower CO₂ intensity - but global emissions have not peaked.** Countries combining high renewables with nuclear (Iceland, Norway, Sweden, France) achieve the lowest emissions intensities. Globally, renewables now offset most new electricity demand growth, stabilizing emission growth rates - but a sustained decline has not yet been achieved.

---

## Table of Contents

- [1. Global Renewable Share Trends](#1-global-renewable-share-trends)
  - Electricity Generation & Installed Capacity
  - Country-Level Leaders
  - Primary Energy Consumption
- [2. Technology Adoption: Capacity, Generation & Performance](#2-technology-adoption-capacity-generation--performance)
  - Installed Capacity Growth
  - Electricity Generation
  - Capacity Factor Trends
  - Geographic Spread
  - Regional Shift in Capacity Leadership
- [2b. Growth Dynamics & Velocity](#2b-growth-dynamics--velocity-dashboard-3--electricity-generation)
  - 23-Year & 5-Year Generation CAGR Tables
  - YoY Category Volatility
  - Technology Trajectory Narratives (12 technologies)
  - Cross-Cutting Observations
  - Installed Capacity CAGR Tables
  - Aggregate Capacity Dynamics
  - Capacity vs. Generation Divergence Analysis
- [3. Technology Cost Trends](#3-technology-cost-trends-lcoe--installed-costs-2010-2023)
  - Global LCOE Declines
  - Installed Cost Declines
  - Country & Regional Cost Leaders
- [3b. LCOE Trajectory Analysis](#3b-lcoe-trajectory-analysis-dashboard-4--visual-layer)
  - Technology Trajectory Shapes (LCOE vs Installed Cost)
  - Capacity Factor Trajectory Shapes
  - Cross-Cutting Observations
- [4. Public Investment in Renewable Energy](#4-public-investment-in-renewable-energy-2000-2020)
  - Global Investment Composition
  - Technology Distribution
  - Top Donors
  - Alignment with Cost Declines
- [5. Renewables & CO₂ Emissions](#5-renewables--co2-emissions)
  - Global Emissions vs Renewable Growth
  - Emissions Intensity vs Renewable Share
- [6. Regional Electricity Profiles](#6-regional-electricity-profiles-2023)
  - Africa · Americas · Asia · Europe · Oceania

---

## 1. Global Renewable Share Trends

### Electricity Generation & Installed Capacity

- Renewables' share of global electricity **generation** grew from **18.3% (2000) to 29.9% (2023)** - a gain of +11.6 percentage points (+63% relative).
- Renewables' share of global **installed capacity** doubled from **22% (2000) to 43% (2023)** - a gain of +21 pp (+95.6% relative).
- **Capacity is outpacing generation:** the gap between capacity share and generation share widened from 3.7 pp (2000) to 13.2 pp (2023), reflecting the rapid build-out of solar and wind (which have lower average capacity factors than legacy hydro and thermal plants) and growing integration and storage needs.
- In absolute terms, total renewable installed capacity grew from **764 GW (2000) → 1,227 GW (2010) → 3,861 GW (2023)** - a 5.1x increase since 2000 and 3.1x since 2010.
- Total renewable electricity generation grew from **2,851K GWh (2000) → 4,201K GWh (2010) → 8,929K GWh (2023)** - a 3.1x increase since 2000.

### Country-Level Leaders

- Among the top 50 countries by renewable electricity generation share (2023), RE share ranges from 65% to 100%.
- **6 countries/territories report 100% renewable electricity:** Nepal, Bhutan, Iceland, Albania, Ethiopia, Paraguay.
- Distribution within top 50: 100% (6 countries), 90-99.9% (15), 80-89.9% (10), 70-79.9% (12), 60-69.9% (7). Median: 87.6%.
- Countries achieving high RE shares primarily rely on hydropower as the backbone technology.

### Primary Energy Consumption

- Renewables' share of **global primary energy** grew from ~7.8% (2000) to **14.6% (2023)** - nearly doubling in two decades.
- Growth was slow until 2011, then accelerated; the largest single-year increase was +1.17 pp in 2020.
- In 2023, renewables supplied ~90 EJ of ~620 EJ total global primary energy - roughly 1 in every 7 units of energy consumed.
- **Primary energy mix (2023):** Hydropower 43.3% (38.5 EJ), Wind 24.5% (21.7 EJ), Solar 17.2% (15.3 EJ), Geothermal/Biomass/Other 9.8% (8.7 EJ), Biofuels 5.2% (4.6 EJ).
- Hydropower's share of renewable primary energy fell from **90.7% (2000) to 43.9% (2023)** as wind and solar surged.
- Wind grew from 1.1% → 24.1% of renewable primary energy; Solar from 0.04% → 17.0%.
- Wind primary energy consumption is up **65x since 2000**; Solar up **1,356x since 2000**.

---

## 2. Technology Adoption: Capacity, Generation & Performance

### Installed Capacity Growth (2010-2023)

| Technology | Share of RE Capacity (2023) | Growth Since 2000 | Growth Since 2010 |
|---|---|---|---|
| Solar PV | 36.4% | +1,755.7x | +35.1x |
| Onshore Wind | 24.5% | +55.9x | +5.3x |
| Hydropower | 32.8% | +1.8x | +1.4x |
| Offshore Wind | 1.9% | +1,109.1x | +24.3x |
| Bioenergy | 3.8% | +4.7x | +2.1x |
| Geothermal | 0.4% | +1.8x | +1.5x |
| CSP | 0.2% | +16.4x | +5.4x |

- **Solar PV overtook hydropower in 2023** to become the #1 renewable technology by installed capacity globally.
- Offshore wind grew 24x since 2010 from a very small base; it remains 1.9% of renewable capacity but its trajectory is steep.

### Electricity Generation (2010-2023)

| Technology | Share of RE Generation (2023) | Growth Since 2000 | Growth Since 2010 |
|---|---|---|---|
| Hydropower | 47.8% (4,270K GWh) | +1.6x | +1.2x |
| Onshore Wind | 23.7% (2,119K GWh) | +68.7x | +6.3x |
| Solar PV | 18.0% (1,611K GWh) | +2,034.6x | +50.1x |
| Bioenergy | 7.1% (632K GWh) | +4.3x | +2.0x |
| Offshore Wind | 2.1% (185K GWh) | +1,584.2x | +24.6x |
| Geothermal | 1.1% (98K GWh) | +1.9x | +1.4x |
| CSP | 0.1% (13K GWh) | +24.7x | +7.9x |

- Solar PV generated **4,912% more electricity in 2023 than in 2010** (~50x), leading all renewables.
- Fossil fuels generated 17,875K GWh in 2023 (59.8% of global, up 1.8x since 2000). Renewables are growing faster but fossil absolute output continues to rise.

### Capacity Factor Trends (2010-2023, global weighted average)

> **Note:** This table documents capacity factors as a technology performance and adoption metric - how efficiently each technology converts installed capacity into actual generation. The same capacity factor data appears in a different analytical context in [Section 3b](#3b-lcoe-trajectory-analysis-dashboard-4--visual-layer), where it is used to explain the divergence between LCOE and installed cost trajectories for each technology. The two treatments are complementary, not redundant.

| Technology | 2023 Capacity Factor | Direction Since 2010 |
|---|---|---|
| Geothermal | **82.11%** | Slight decline (from ~86% in 2010); near-flat with oscillation |
| Bioenergy | **71.92%** | Stable; spike to ~85% in 2017-2018, otherwise 66-75% range |
| CSP | **54.50%** | **Highly volatile**: 30% (2010) → gradual rise → ~80% spike (2021) → 35% (2022) → 54.50% (2023); net +79% |
| Hydropower | **53.31%** | Steady gradual improvement from ~44% (+21% overall) |
| Offshore Wind | **41.04%** | Essentially flat; 38-45% range throughout, no meaningful trend |
| Onshore Wind | **35.92%** | Clear, consistent upward trend from ~27-28% (+32% overall) |
| Solar PV | **16.17%** | Near-flat throughout; minor improvement from ~14% (+17% overall) |

- **Geothermal (82.11%)** and **Bioenergy (71.92%)** have the highest capacity factors - consistent baseload-like reliability. Geothermal's slight decline from ~86% to 82.11% reflects the geographic expansion into slightly lower-resource sites.
- **CSP** shows the largest net capacity factor change (+79%), but the path is highly non-linear. The global average began at ~30% in 2010 (parabolic trough plants in Spain and the U.S.), rose gradually to ~45% by 2018 as operational optimization accumulated, then spiked dramatically to approximately 80% in 2021 - almost certainly reflecting a composition shift as large Chinese molten-salt tower plants began dominating the global weighted average - then collapsed to ~35% in 2022 before recovering to 54.50% in 2023. This volatile trajectory is the mechanism behind the LCOE-installed cost gap: the same capital investment was producing dramatically more electricity in some years than others, and the 2023 capacity factor of 54.50% is itself a mid-recovery value, not a stable endpoint.
- **Onshore Wind** improved consistently and steadily from ~27-28% in 2010 to a peak near ~38-40% around 2020-2021, ending at 35.92% - the clearest and most sustained capacity factor improvement trend among non-CSP technologies. This steady improvement is the reason LCOE (-70.6%) fell consistently faster than installed cost (-48.9%) throughout the period.
- **Hydropower** improved gradually from ~44% to 53.31% - a clean, steady upward trend with a mid-period dip (~46%) around 2019-2020. This improvement partially offset the near-doubling of installed costs (+92.3%).
- **Offshore Wind** capacity factor (41.04%) has been essentially flat since 2010, oscillating in a 35-45% band with no discernible improvement trend. The LCOE reduction (-63.2%) relative to installed cost reduction (-48.2%) for offshore wind is therefore driven primarily by capital cost reductions and supply chain maturation rather than improving utilization.
- **Solar PV** has the lowest capacity factor (16.17%) and its trajectory is near-flat - minor improvement from ~14% to ~16-17% over 13 years. Confirming that Solar PV generation growth is almost entirely volume-driven: more panels deployed in sunnier geographies, not improved per-panel output.
- **Bioenergy** shows a notable spike to approximately 85% around 2017-2018 before returning to the 70-72% range by 2023. This spike is likely feedstock-driven - a period of high-quality fuel availability or plant dispatch decisions - rather than a technological improvement, consistent with the volatile installed cost trajectory.

### Geographic Spread of Technology Adoption

- **Hydropower** is near-saturated globally: present in all 17 subregions since 2000; country count rose slightly (158 → 163).
- **Solar PV** expanded from 52 → 220 countries; **Onshore Wind** from 60 → 156 countries - both achieving full subregional spread by 2012-2013.
- Niche or resource-limited technologies remain geographically sparse:
  - Offshore Wind: 3 → 19 countries, 6/17 subregions
  - Geothermal: 22 → 30 countries, 12/17 subregions
  - CSP: 1 → 19 countries, 11/17 subregions

### Regional Shift in Capacity Leadership

- In 2000, Northern America (21.6%), Latin America & Caribbean (17.9%), and Eastern Asia (14.1%) led global renewable capacity - each over 80% hydro-based.
- By 2023, **Eastern Asia surged to 42.3% of global renewable capacity** (Solar PV 44.8%, Wind 25.3%, Hydro 24.6%).
- Northern America dropped to 12.8%, with a more balanced mix: Wind 33.2%, Hydro 31.5%, Solar 29.2%.
- **Key shift: Asia replaced the Americas as the dominant region for renewable deployment.**

---

## 2b. Growth Dynamics & Velocity (Dashboard 3 - Electricity Generation)

> **Dashboard scope:** Electricity generation and installed capacity. CAGR periods available: 3-, 5-, 10-, and 23-year. Data covers 2000-2023.

### 23-Year CAGR by Technology - Electricity Generation (2000-2023)

| Technology | Category | 23-Yr CAGR | Net GWh Added (2000-2023) |
|---|---|---|---|
| Solar PV | Renewables | **39.27%** | +1,609.9K GWh |
| Offshore Wind | Renewables | **37.76%** | +185.1K GWh |
| Onshore Wind | Renewables | 20.19% | +2,087.9K GWh |
| CSP | Renewables | 14.97% | +12.5K GWh |
| Bioenergy | Renewables | 6.56% | +485.1K GWh |
| Geothermal | Renewables | 2.75% | +45.6K GWh |
| Marine Energy | Renewables | 2.28% | +0.4K GWh |
| Hydropower | Renewables | 2.15% | +1,651.1K GWh |
| Other non-renewables | Nuclear & Other | 4.57% | +114.1K GWh |
| Pumped Storage | Nuclear & Other | 2.28% | +59.7K GWh |
| Nuclear | Nuclear & Other | 0.25% | +150.4K GWh |
| Natural Gas | Fossil Fuels | 3.85% | +3,813.6K GWh |
| Coal and Peat | Fossil Fuels | 2.34% | +4,197.2K GWh |
| Oil | Fossil Fuels | **-1.13%** | -245.4K GWh |

**Renewables - All (23-year aggregate):** CAGR 5.09% · net +6,077.5K GWh added

### 5-Year CAGR by Technology - Electricity Generation (2018-2023)

| Technology | Category | 5-Yr CAGR | Net GWh Added (2018-2023) |
|---|---|---|---|
| Solar PV | Renewables | **24.05%** | +1,062.5K GWh |
| Offshore Wind | Renewables | **22.07%** | +116.9K GWh |
| Onshore Wind | Renewables | 12.22% | +928.3K GWh |
| Bioenergy | Renewables | 4.08% | +114.4K GWh |
| Geothermal | Renewables | 1.87% | +8.7K GWh |
| CSP | Renewables | 1.59% | +1.0K GWh |
| Hydropower | Renewables | 0.30% | +63.0K GWh |
| Marine Energy | Renewables | **-2.11%** | -0.1K GWh |
| Other non-renewables | Nuclear & Other | 5.04% | +38.7K GWh |
| Pumped Storage | Nuclear & Other | 4.67% | +30.1K GWh |
| Nuclear | Nuclear & Other | 0.22% | +29.8K GWh |
| Natural Gas | Fossil Fuels | 1.75% | +546.7K GWh |
| Coal and Peat | Fossil Fuels | 0.83% | +413.5K GWh |
| Oil | Fossil Fuels | **-0.95%** | -40.3K GWh |

**Renewables - All (5-year aggregate):** CAGR 6.12% · net +2,294.7K GWh added  
**Fossil Fuels - All (5-year aggregate):** CAGR 0.92% · net +801.3K GWh added  
**Nuclear & Other - All (5-year aggregate):** CAGR 0.66% · net +98.7K GWh added

### Year-over-Year Volatility - 2023 Category Endpoints

| Category | 2023 Generation | YoY Growth | Annual Change |
|---|---|---|---|
| Renewables | 8,928K GWh | +5.57% | +471K GWh |
| Nuclear & Other | 3,064K GWh | +2.26% | +68K GWh |
| Fossil Fuels | 17,875K GWh | +1.00% | +176K GWh |

- **Peak renewable YoY growth:** +7.77% (~2011) - the fastest single-year expansion of the renewables aggregate
- **Trough fossil YoY growth:** -5.87% (2011) - the steepest single-year fossil decline, pandemic-adjacent and transient

### Technology Trajectory Narratives

**Solar PV - Textbook maturing exponential**
- 23-yr CAGR 39.27%, highest of any technology; 5-yr CAGR 24.05%
- Peak YoY: +94.38% in 2011 (62K GWh total, +30K GWh absolute) - enormous rate from a tiny base
- Peak 5-yr rolling CAGR: **67.04% (2007-2012)** - added only 88.8K GWh net despite the extraordinary rate
- Current 5-yr rolling CAGR: **24.05% (2018-2023)** - added 1,062.5K GWh net
- 2023: 1,611K GWh · YoY +25.41% · +326K GWh absolute
- The rate has fallen by more than half from its peak, but absolute annual additions have grown dramatically - +326K GWh added in 2023 alone vs. +30K GWh in the peak-rate year of 2011. The CAGR deceleration is pure base-effect arithmetic, not a slowdown in deployment momentum.

**Offshore Wind - A decade behind Solar PV in its maturation arc**
- 23-yr CAGR 37.76%; 5-yr CAGR 22.07%
- Peak YoY: +183.0% in 2002 - generation was effectively 0K GWh, a statistical artifact of near-zero base
- High early volatility (20-75% swings 2004-2011) as each new project represented a large share of the tiny installed base
- Peak 5-yr rolling CAGR: **65.23% (2000-2005)** - added only 1.3K GWh net
- Current 5-yr rolling CAGR: **22.07% (2018-2023)** - added 116.9K GWh net
- 2023: 185K GWh · YoY +14.4% · +23K GWh absolute
- Unlike Solar PV, Offshore Wind's CAGR descent is slower and more linear - it is still building absolute scale and the deceleration reflects the capital-intensive, geographically constrained nature of offshore deployment rather than market maturity.

**Onshore Wind - Most advanced maturation among wind technologies**
- 23-yr CAGR 20.19%; 5-yr CAGR 12.22%
- Peak YoY: +38.31% in 2002 (52K GWh, +14K GWh absolute)
- Unlike Solar PV's volatile early years, Onshore Wind shows a remarkably smooth, near-linear decline from ~38% in 2002 to single digits today
- Peak 5-yr rolling CAGR: **~27.84% (2003-2008)** - added 151.0K GWh net
- Current 5-yr rolling CAGR: **12.22% (2018-2023)** - added 928.3K GWh net
- 2023: 2,119K GWh · YoY +9.46% · +183K GWh absolute
- The deceleration is structural rather than arithmetic: onshore wind deployment is constrained by land availability, grid connection limits, and permitting - not cost. At 2,119K GWh it is the second-largest renewable by generation, and still the largest absolute contributor to recent renewable growth (+928K GWh over 5 years), but the rate of expansion has clearly peaked.

**Bioenergy - Policy-driven plateau followed by near-stall**
- 23-yr CAGR 6.56%; 5-yr CAGR 4.08%
- Peak YoY: +12.65% in 2010 (317K GWh, +36K GWh)
- Peak 5-yr rolling CAGR: **~8.87% (2002-2007)** - added 84.9K GWh
- Current 5-yr rolling CAGR: **4.08% (2018-2023)** - added 114.4K GWh
- 2023: 632K GWh · YoY +1.45% · +9K GWh absolute - near-stalled
- Bioenergy's rolling CAGR plateau lasted nearly a decade (roughly 8-9% from 2002 to 2014) before declining - a uniquely flat trajectory suggesting policy-driven rather than market-driven deployment. The near-stall in 2023 (+9K GWh) at a scale of 632K GWh is notable; sustainability concerns and feedstock competition constraints are likely contributors.

**CSP - Deployment collapse, not gradual maturation**
- 23-yr CAGR 14.97%; 5-yr CAGR 1.59%
- Peak YoY: +93.4% in 2011 (3K GWh total, +2K GWh absolute)
- Peak 5-yr rolling CAGR: **58.14% (2009-2014)** - added 8.2K GWh net
- Current 5-yr rolling CAGR: **1.59% (2018-2023)** - added only 1.0K GWh net
- 2023: 13K GWh · YoY +1.4% · 0K GWh absolute
- CSP is the only renewable that experienced a genuine deployment collapse rather than gradual maturation. The rolling CAGR fell from 58% to effectively 0% in under a decade. Solar PV's cost collapse made CSP economically uncompetitive for most applications after ~2015, and the new project pipeline dried up almost entirely. At 13K GWh total generation, CSP is a rounding error in the global mix. It serves as the cautionary counterexample - a technology that appeared to be a major growth story and was displaced before reaching scale.

**Geothermal - No growth phase; geographically locked**
- 23-yr CAGR 2.75%; 5-yr CAGR 1.87%
- Only renewable to record negative YoY in 2001 (-1.698%, 52K GWh, -1K GWh)
- Peak YoY: +6.816% in 2014 (77K GWh, +5K GWh)
- 5-yr rolling CAGR oscillated between 2-4% for the entire 23-year period with no identifiable growth phase; peak 5-yr CAGR ~4.32% (2013-2018) added only 17.1K GWh
- Current 5-yr rolling CAGR: **1.87% (2018-2023)** - added 8.7K GWh
- 2023: 98K GWh · YoY +0.906% · +1K GWh - near-stagnant
- Geothermal moved sideways throughout the entire 2000-2023 period, constrained by its fundamental requirement for specific tectonic conditions. It illustrates why not all renewables are globally scalable: unlike solar and wind, geothermal deployment cannot be democratized by falling manufacturing costs.

**Hydropower - Fully saturated; now climate-volatile**
- 23-yr CAGR 2.15%; 5-yr CAGR 0.30%
- Negative YoY in 2001 (-2.342%, 2,558K GWh, -61K GWh) and in 2023 (-1.650%, 4,270K GWh, **-72K GWh**)
- Peak YoY: +6.647% in 2004 (2,802K GWh, +175K GWh)
- Peak 5-yr rolling CAGR: **~4.13% (2003-2008)** - added 589.5K GWh net - the largest absolute 5-year addition of any hydropower period
- Current 5-yr rolling CAGR: **0.30% (2018-2023)** - added only 63.0K GWh net
- 2023: 4,270K GWh · YoY -1.650% · **-72K GWh** - largest absolute annual decline of any renewable
- The rolling CAGR has declined continuously since 2008 and is now approaching zero. Hydropower remains the largest single renewable source (47.8% of RE generation in 2023) but cannot be counted on to grow. Its recent negative years are likely drought-driven - climate variability affecting reservoir levels - adding a new vulnerability layer to the global renewable mix. The entire growth burden for renewables now falls on wind and solar.

**Marine Energy - Pre-commercial; not a global-scale technology**
- 23-yr CAGR 2.28%; 5-yr CAGR -2.11%
- Entire generation history rounds to 0-1K GWh; peak 5-yr rolling CAGR ~16.06% (2012-2017) added only 0.6K GWh
- 2023: 1K GWh · YoY -4.00% · 0K GWh - in decline
- Not a material contributor to global generation at any point in the dataset period.

**Natural Gas - Sustained structural deceleration**
- 23-yr CAGR 3.85%; 5-yr CAGR 1.75%
- Peak YoY: +10.6% in 2010 (4,735K GWh, +454K GWh) - post-financial crisis demand rebound
- Peak 5-yr rolling CAGR: **5.89% (2003-2008)** - added 1,071.5K GWh net
- Current 5-yr rolling CAGR: **1.75% (2018-2023)** - added 546.7K GWh net; rolling CAGR continuously declining throughout the period
- 2023: 6,572K GWh · YoY +1.61% · +104K GWh absolute
- Natural gas shows the clearest and most sustained deceleration of any fossil fuel - rolling CAGR down from ~6% to ~2% over two decades with no interruption. Gas was once framed as the "transition fuel" growth story; that story is now clearly fading. At 6,572K GWh it remains the second-largest electricity source globally.

**Coal and Peat - Decelerating but at enormous absolute scale**
- 23-yr CAGR 2.34%; 5-yr CAGR 0.83%
- Peak YoY: +7.84% in 2009; pandemic trough: **-4.30% in 2020**; post-pandemic rebound: **+7.25% in 2021**
- Peak 5-yr rolling CAGR: **5.25% (2002-2007)** - China's industrialization boom era
- Current 5-yr rolling CAGR: **0.83% (2018-2023)** - added 413.5K GWh net
- 2023: 10,171K GWh · YoY +1.30% · +130K GWh absolute
- Coal generates more electricity than all renewables combined (10,171K GWh vs. 8,928K GWh). The 5-yr rolling CAGR has declined from 5.25% to 0.83% since its 2002-2007 peak - a genuine structural slowdown. But the 2021 post-pandemic rebound to +7.25% YoY demonstrates that coal demand remains highly elastic and will surge when economic conditions allow. Even at 0.83% CAGR, the absolute 5-year addition (413.5K GWh) is comparable to the entire bioenergy sector's total output. This is the single clearest explanation for why global CO₂ emissions have not yet peaked.

**Oil - The only fossil fuel in confirmed structural decline**
- 23-yr CAGR -1.13%; 5-yr CAGR -0.95%
- Peak YoY: +9.33% in 2011; trough: **-8.56% in 2016** - sharpest single-year fossil decline in the dataset
- Post-trough rebounds: ~+7% in both 2021 and 2022 - pandemic recovery spikes
- Peak 5-yr rolling CAGR: **1.95% (2010-2015)**; deepest trough: **-5.75% (~2020)**
- Current 5-yr rolling CAGR: **-0.95% (2018-2023)** - net impact -40.3K GWh
- 2023: 822K GWh · YoY -3.83% · -33K GWh - back in decline after pandemic rebound
- Oil is the only fossil fuel with a negative CAGR over both the full period and the recent 5-year window - making it the one source where the energy transition is visibly and structurally working. The extreme YoY volatility (swings from -8.56% to +9.33%) reflects oil's role as a residual/peaking fuel subject to price shocks and gas substitution. At 822K GWh it is already a minor electricity source globally.

**Nuclear - Fukushima-scarred but stabilizing**
- 23-yr CAGR 0.25%; 5-yr CAGR 0.22%
- Fukushima signature: **-6.31% YoY in 2011** (2,577K GWh, -174K GWh) - the largest single-year absolute decline of any non-renewable in the dataset
- Post-Fukushima recovery peak: +4.48% in 2021 (2,799K GWh, +120K GWh)
- 5-yr rolling CAGR: started ~1.5%, dipped to **-2.0% (~2012)**, recovered to ~2% by 2018, now declining toward zero again
- Peak recovery period: **1.88% (2014-2019)** - added 247.1K GWh net
- Current 5-yr rolling CAGR: **0.22% (2018-2023)** - added only 29.8K GWh net
- 2023: 2,739K GWh · YoY +2.23% · +60K GWh
- Nuclear's W-shaped CAGR curve - positive, then sharply negative post-Fukushima, then recovering, now flattening - is the clearest single-technology signature of a real-world policy shock in the dataset. At 2,739K GWh it remains a major low-carbon source (larger than all offshore wind, CSP, geothermal, and marine combined), but the growth trajectory is effectively flat. New builds are barely offsetting retirements.

### Cross-Cutting Observations

- **The CAGR vs. net impact divergence** is the central analytical lesson of Dashboard 3. The highest-CAGR technologies (Solar PV 39%, Offshore Wind 38%) added far less absolute generation than lower-CAGR technologies at larger bases. Onshore Wind's 20% CAGR translated into the largest net GWh addition of any renewable (+2,087.9K GWh), and Hydropower's 2.15% CAGR still added +1,651.1K GWh because of its enormous base.
- **Coal added more absolute GWh than all renewables combined** over the 23-year period (+4,197.2K GWh vs. +6,077.5K GWh for all renewables combined - but natural gas added +3,813.6K GWh on top of that). The fossil expansion is the primary reason global emissions have not peaked despite rapid renewable growth.
- **Only two sources show negative 23-year CAGRs:** Oil (-1.13%) and Marine Energy (2.28% but rounding to near-zero net impact). All other fossil fuels are still growing in absolute terms.
- **The renewable growth rate is accelerating at the aggregate level:** the 5-year CAGR for all renewables (6.12%) exceeds the 23-year CAGR (5.09%), driven by Solar PV and Offshore Wind scaling rapidly. This is the opposite of what maturation would typically produce and reflects a transition that is genuinely accelerating.
- **Fossil fuel growth rate is converging toward zero:** the 5-year fossil CAGR (0.92%) is well below the 23-year CAGR (implied ~2.5%), with Coal and Gas both showing sustained multi-decade deceleration and Oil in outright decline.

---

### Installed Capacity CAGR (2000-2023 and 2018-2023)

#### 23-Year CAGR by Technology - Installed Capacity (2000-2023)

| Technology | Category | 23-Yr CAGR | Net GW Added (2000-2023) |
|---|---|---|---|
| Solar PV | Renewables | **38.38%** | +1.4K GW |
| Offshore Wind | Renewables | **35.64%** | +0.1K GW |
| Onshore Wind | Renewables | 19.12% | +0.9K GW |
| CSP | Renewables | 12.93% | +0.0K GW |
| Bioenergy | Renewables | 6.96% | +0.1K GW |
| Marine Energy | Renewables | 3.20% | +0.0K GW |
| Hydropower | Renewables | 2.57% | +0.6K GW |
| Geothermal | Renewables | 2.65% | +0.0K GW |
| Other non-renewables | Nuclear & Other | **11.31%** | +0.1K GW |
| Pumped Storage | Nuclear & Other | 2.47% | +0.1K GW |
| Nuclear | Nuclear & Other | 0.45% | +0.0K GW |
| Natural Gas | Fossil Fuels | **4.93%** | +1.0K GW |
| Coal and Peat | Fossil Fuels | **4.15%** | +1.2K GW |
| Oil | Fossil Fuels | 1.30% | +0.1K GW |

#### 5-Year CAGR by Technology - Installed Capacity (2018-2023)

| Technology | Category | 5-Yr CAGR | Net GW Added (2018-2023) |
|---|---|---|---|
| Offshore Wind | Renewables | **25.81%** | +0.1K GW |
| Solar PV | Renewables | **23.95%** | +0.9K GW |
| Onshore Wind | Renewables | 11.82% | +0.4K GW |
| Bioenergy | Renewables | 4.58% | +0.0K GW |
| CSP | Renewables | 3.39% | +0.0K GW |
| Geothermal | Renewables | 2.72% | +0.0K GW |
| Hydropower | Renewables | 1.55% | +0.1K GW |
| Marine Energy | Renewables | **-1.36%** | -0.0K GW |
| Other non-renewables | Nuclear & Other | **24.86%** | +0.0K GW |
| Pumped Storage | Nuclear & Other | 3.33% | +0.0K GW |
| Nuclear | Nuclear & Other | **-0.32%** | -0.0K GW |
| Coal and Peat | Fossil Fuels | 1.88% | +0.2K GW |
| Natural Gas | Fossil Fuels | 1.79% | +0.1K GW |
| Oil | Fossil Fuels | **-0.22%** | -0.0K GW |

**Ranking note:** In the 5-year window, Offshore Wind (25.81%) overtakes Solar PV (23.95%) as the highest-CAGR technology by installed capacity - a ranking flip that does not occur in the generation data, where Solar PV retains the top spot at 24.05%.

#### Aggregate Capacity Dynamics - YoY and Rolling CAGR

The category-level YoY and rolling CAGR charts for installed capacity (Dashboard 3, Installed Capacity view) reveal patterns that the bar charts alone do not capture and that have no equivalent in the generation analysis.

**Renewable capacity YoY has accelerated monotonically - the opposite of generation volatility**
- Electricity generation YoY oscillated throughout the period, ranging from the +7.77% peak (2011) down to deeply negative territory for fossil and nuclear in the same year
- Renewable installed capacity YoY, by contrast, rose from approximately 2-3% in 2000 on a near-unbroken upward trajectory to **14.39% in 2023** - the highest point in the entire series, and still rising at the endpoint
- The only meaningful dip for Nuclear & Other capacity YoY was **-0.77%** (around 2011), reflecting Fukushima-related decommissioning; renewable capacity YoY never went negative across the full 2000-2023 period
- **Interpretation:** Capacity additions are driven by investment pipeline decisions made 2-5 years in advance. The monotonic acceleration means the commitment to renewable build-out was not interrupted by the 2008-2009 financial crisis, the 2011 Fukushima shock, or the 2020 pandemic - investment cycles are fully decoupled from short-term demand and generation signals.

**The 5-year rolling CAGR for renewable capacity is re-accelerating to a new high**
- Renewable generation rolling CAGR stabilized at approximately 6% from 2016 onward and was essentially flat for 8 years through 2024
- Renewable capacity rolling CAGR ended at approximately **10%** at the 2024 endpoint - still rising steeply, and the highest level in the rolling series
- Fossil fuel capacity rolling CAGR has remained in the 2-4% range throughout, with a slight uptick near 2023 (driven by ongoing coal and gas builds in developing Asia)
- **Interpretation:** The transition is genuinely accelerating on the deployment side, even as the generation growth rate has plateaued. The divergence between a flat generation rolling CAGR and a rising capacity rolling CAGR is the quantitative basis for the widening capacity share vs. generation share gap documented in Section 1.

**The 2023 divergence between capacity and generation YoY is the largest in the dataset**
- 2023: renewable capacity YoY **+14.39%** vs. renewable generation YoY **+5.57%** - a ~9 pp single-year gap
- This directly quantifies what Section 1 describes structurally: the 13.2 pp gap between capacity share (43%) and generation share (29.9%) reflects exactly this kind of sustained year-on-year divergence
- At the current trajectory - capacity rolling CAGR rising while generation rolling CAGR holds flat - this gap will widen further before it narrows

#### Capacity vs. Generation Divergence - Where the Gap Is Analytically Significant

Comparing the generation and capacity CAGR tables across both time windows identifies six cases where the divergence reveals something structurally important beyond either dataset alone.

**1. Solar PV and Onshore Wind - generation-leading: capacity factors are improving**
Solar PV generation CAGR (39.27%) exceeds its capacity CAGR (38.38%) by ~0.9 pp over 23 years; Onshore Wind shows a similar ~1 pp gap (20.19% vs 19.12%). The same physical assets produce progressively more electricity per unit of installed capacity. For onshore wind this reflects genuine technological improvement - larger rotors, better siting, improved forecasting. For solar PV it partly reflects a geographic shift toward sunnier markets and improvements in inverter efficiency and panel degradation rates. This directly contradicts any narrative that rapid renewable build-out is producing diminishing utilization returns.

**2. Offshore Wind (5-yr: cap 25.81% vs gen 22.07%, gap +3.74 pp) - deployment pipeline outrunning current output**
Offshore wind is the only high-growth renewable where capacity is growing *faster* than generation over the recent 5-year window. This is a commissioning lag signal: large offshore projects enter the capacity register before completing full-year operation, inflating near-term capacity CAGR relative to generation. The 23-year gap runs the other direction (cap 35.64% vs gen 37.76%, -2.12 pp), confirming that over the long run generation efficiency is higher - the recent 5-year positive gap reflects the current wave of new builds in the ramp-up phase. This is not a performance concern; it is a leading indicator of near-term generation growth.

**3. CSP (5-yr: cap 3.39% vs gen 1.59%, gap +1.80 pp) - new capacity not translating to output**
CSP capacity grew more than twice as fast as generation over the recent 5-year period. China has continued commissioning CSP projects against the backdrop of global deployment collapse elsewhere - but these plants appear to be generating at lower-than-expected rates, consistent with curtailment or underperformance. Combined with the near-zero absolute output (13K GWh total in 2023), this finding adds nuance to the "CSP collapse" narrative: the technology still receives investment in China, but output tells a bleaker story than capacity figures suggest.

**4. Hydropower (5-yr: cap 1.55% vs gen 0.30%, gap +1.25 pp) - new dams, climate-suppressed output**
Hydropower capacity CAGR is more than 5x its generation CAGR over the recent 5-year window. New dams continue to be commissioned - primarily in Africa and South/Southeast Asia - but generation is near-stagnant and 2023 saw an absolute generation decline of -72K GWh. This is the clearest quantified evidence that climate-driven hydrological variability is suppressing returns on new hydropower investment: infrastructure is being built, but the resource (rainfall, reservoir levels) is not keeping pace. The gap is a risk signal, not an efficiency signal.

**5. Coal (+1.81 pp over 23 years, +1.05 pp over 5 years) and Natural Gas (+1.08 pp over 23 years) - falling fleet utilization**
Both major fossil fuels show consistent, sustained gaps where capacity additions outpace generation growth. Coal's 23-year capacity CAGR (4.15%) is nearly double its generation CAGR (2.34%); natural gas shows a similar pattern (4.93% vs 3.85%). New thermal plants are still being commissioned - predominantly in developing Asia - while the existing fleet operates at declining utilization rates as renewables increasingly displace thermal generation during lower-demand periods. Over 23 years, coal added +1.2K GW of capacity and natural gas +1.0K GW - comparable in scale to Solar PV's +1.4K GW - but their generation growth rates are a fraction of their capacity growth rates. This is the earliest quantified stranded-asset signal in the global power sector dataset.

**6. Oil (23-yr: cap +1.30% vs gen -1.13%, gap +2.43 pp) - infrastructure retained while output declines**
The most extreme fossil divergence. Oil power capacity still grew at +1.30% CAGR over 23 years - plants retained or added - while generation fell at -1.13%. Oil infrastructure is being kept in place (presumably as backup or peaking capacity) while being run progressively less. The 5-year capacity CAGR flipping to -0.22% indicates that even this "retained for optionality" dynamic is now reversing - oil power infrastructure is beginning to be retired rather than merely underutilized.

**7. Other non-renewables (5-yr: cap 24.86% vs gen 5.04%, gap ~+20 pp) - the storage build-out**
The largest divergence in the dataset by a wide margin. A 24.86% capacity CAGR against a 5.04% generation CAGR, with net GW added rounding to +0.0K GW at the precision shown, almost certainly reflects the rapid global build-out of grid-scale storage and grid infrastructure - primarily pumped hydro and battery storage in China - classified outside standard generation categories. Storage assets carry large rated capacity but contribute near-zero or negative net generation by design (they consume electricity on balance). This is not a generation story; it is a grid infrastructure story, and the scale of the 5-year divergence signals that storage deployment is already operating at a pace that will structurally reshape generation utilization patterns in the near term.

---

## 3. Technology Cost Trends (LCOE & Installed Costs, 2010-2023)

### Global LCOE Declines

| Technology | LCOE Change (2010→2023) | LCOE 2010 (USD/kWh) | LCOE 2023 (USD/kWh) | vs Fossil Band (0.07-0.18) |
|---|---|---|---|---|
| Solar PV | **-90.4%** | $0.46 | $0.04 | Above (2010) → Below (2023) |
| Onshore Wind | **-70.6%** | $0.11 | $0.03 | Within (2010) → Below (2023) |
| CSP | -70.4% | $0.40 | $0.12 | Above (2010) → Within (2023) |
| Offshore Wind | -63.2% | $0.20 | $0.07 | Above (2010) → Within (2023) |
| Geothermal | +30.8% | $0.05 | $0.07 | Below (2010) → Within (2023) |
| Hydropower | +32.3% | $0.04 | $0.06 | Below (2010) → Below (2023) |
| Bioenergy | **+15.2%** | $0.08 | $0.07 | Within (2010) → Within (2023) |

> **Note on Bioenergy:** An earlier version of this table listed Bioenergy LCOE change as -15%; the correct figure confirmed from dashboard data is **+15.2%** - a modest cost *increase*, not a decrease.

- **Onshore wind and Solar PV are now cheaper than the cheapest fossil fuel** on a levelized cost basis.
- Hydropower and geothermal cost increases reflect aging assets, fewer remaining low-cost sites, and rising regulatory/environmental compliance costs - not technology regression.

### Installed Cost Declines (2010-2023)

| Technology | Inst. Cost 2010 (USD/kW) | Inst. Cost 2023 (USD/kW) | Change |
|---|---|---|---|
| Solar PV | $5,310 | $758 | **-85.7%** |
| CSP | $10,642 | $6,589 | -38.1% |
| Offshore Wind | $5,409 | $2,800 | -48.2% |
| Onshore Wind | $2,272 | $1,160 | -48.9% |
| Bioenergy | $3,010 | $2,730 | -9.3% |
| Geothermal | $3,011 | $4,589 | **+52.4%** |
| Hydropower | $1,459 | $2,806 | **+92.3%** |
| **All Renewables (weighted avg.)** | - | **$3,062** | **-12.2%** |

- Solar PV's installed cost fell -85.7% - manufacturing scale economies are the primary driver, tracking closely with its -90.4% LCOE reduction.
- Geothermal installed cost rose +52.4% - the only renewable with both LCOE and installed cost increasing. Combined with the shift from below to within the fossil fuel range, it is the only technology to have become *less competitive* against fossil fuels on a cost basis since 2010.
- Hydropower installed cost nearly doubled (+92.3%, $1,459 → $2,806/kW). The LCOE increase (+32.3%) was substantially smaller than the installed cost increase - the gap is partially explained by hydropower's improving capacity factor (+21% since 2010), which offset some of the capital cost surge. Despite this, hydropower remains below the fossil fuel cost range ($0.06/kWh vs $0.07-0.18 band).
- **Portfolio-level finding:** Across all renewables combined, the weighted-average installed cost fell only -12.2% while LCOE fell -35.2% - a 23 pp gap. Roughly two-thirds of the improvement in per-kWh competitiveness came from sources other than capital cost reduction: capacity factor improvements, better siting, and operational learning. Renewable energy is substantially more economically competitive in 2023 than installed cost trends alone would suggest.

### Country & Regional Cost Leaders (2023)

**Offshore Wind LCOE:**
- Cheapest: Denmark ($0.048/kWh), UK ($0.059), Netherlands ($0.061)
- Northern Europe leads regionally (~$0.054/kWh avg, -72% since 2010)

**Onshore Wind LCOE:**
- Cheapest: Brazil ($0.025/kWh), China ($0.026), UK ($0.031)
- North America leads regionally (~$0.037/kWh)

**Solar PV LCOE:**
- Cheapest: China ($0.036/kWh), Australia ($0.038), Chile ($0.041)
- Australia & NZ leads regionally (~$0.038/kWh, -92% since 2010)

**Installed Cost Leaders (2023):**
- Solar PV: Greece ($626/kW), Spain ($671/kW), China ($671/kW)
- Onshore Wind: China ($986/kW), Brazil ($1,079/kW), Spain ($1,158/kW)
- Offshore Wind: China ($2,370/kW), Netherlands ($2,564/kW), Germany ($2,895/kW)

> **Data caveat:** Country-level cost analysis covers up to 58 countries. Results represent "spotlights" rather than a comprehensive global picture and should be interpreted as supplements to global trends.

---

## 3b. LCOE Trajectory Analysis (Dashboard 4 - Visual Layer)

> **Dashboard scope:** Global weighted-average LCOE and installed costs, 2010-2023. Each technology has a selector-driven line chart showing LCOE and installed cost % change over time. The trajectories reveal how costs evolved - not just where they started and ended.

### Technology Trajectory Shapes

The line charts track % change from 2010 baseline for both LCOE and installed cost simultaneously. The *gap between the two lines* is diagnostic: when LCOE falls faster than installed cost, capacity factor improvement and operational learning are absorbing the difference. When they track together, manufacturing scale economies dominate.

**All Renewables aggregate - LCOE fell nearly 3x more than installed costs**
At the portfolio level, the LCOE line declines steeply and steadily from 0% to -35.2%, while the installed cost line is far shallower, ending at only -12.2%. The gap widens consistently throughout the period - not driven by any single year or event. This 23 pp aggregate divergence means that across the full renewable mix, operational improvements (capacity factor gains, better siting, dispatch optimization) contributed roughly twice as much to cost competitiveness as capital cost reductions. Installed cost data alone would significantly understate how competitive renewables have become.

**Solar PV - Tightest line pairing of any technology; manufacturing dominates**
The LCOE and installed cost lines decline steeply together with the smallest gap of any technology - the two curves are nearly overlapping throughout. LCOE ends at -90.4%, installed cost at -85.7%. This close tracking is the strongest confirmation in the dataset that manufacturing scale economies are the near-exclusive driver of Solar PV cost reductions. The curve has no plateaus or reversals - a textbook uninterrupted learning curve.

**Onshore Wind - Consistent gap maintained throughout; steady operational improvement**
Both lines decline smoothly, with the LCOE line running persistently below the installed cost line from the very start of the period. The gap opens early and is maintained consistently through 2023, ending at -70.6% (LCOE) vs -48.9% (installed cost). The ~22 pp gap reflects steady ongoing capacity factor improvement throughout the period - larger rotors and improved siting translated into continuous operational gains alongside capital cost reductions.

**Offshore Wind - Installed cost rose before it fell; LCOE led from the start**
Offshore wind's installed cost is the only renewable trajectory where costs went *above* the 2010 baseline - rising through 2011-2012 before reversing. This initial increase likely reflects the commissioning of the first large-scale U.K. and northern European projects, which were more expensive than the smaller Danish installations that defined the 2010 benchmark. LCOE began declining immediately from 2010 with only a minor uptick around 2013-2014. The divergence between early trajectories - LCOE falling while installed costs were still rising - shows operational learning outpacing capital cost control during the technology's first major scaling phase. Final gap: LCOE -63.2%, installed cost -48.2%.

**CSP - Two distinct decline phases; capacity factor spike explains LCOE-installed cost gap**
LCOE and installed cost track closely from 2010 through roughly 2016, both declining to around -35% to -40%. Then they diverge. LCOE continues descending steeply after 2018, reaching -70.4% by 2023. Installed cost reverses sharply around 2021-2022 - spiking back toward 0% - before recovering to end at -38.1%. The full explanation requires the capacity factor chart: in 2021, CSP's global weighted-average capacity factor spiked to approximately 80% - almost certainly driven by large Chinese molten-salt tower plants entering service and dominating the global sample - before collapsing to ~35% in 2022 and recovering to 54.50% in 2023. The same Chinese projects that drove the 2021-2022 installed cost spike were simultaneously producing far more electricity per kW, temporarily pulling LCOE down dramatically. After that cohort normalized into the sample, both the capacity factor and the installed cost settled at new levels. The net trajectory - capacity factor +79% since 2010, LCOE -70.4% vs installed cost -38.1% - is real, but the mechanism was volatile and compositionally driven by a specific technology shift, not a smooth operational learning curve.

**Bioenergy - Both lines highly volatile; no discernible trend in either direction**
Bioenergy is the most volatile chart in the dashboard. The installed cost line surged dramatically - peaking at roughly +40% above the 2010 baseline around 2012-2013 - before collapsing and oscillating. The LCOE line zigzags similarly with slightly lower amplitude. Both lines end near their starting points (installed cost -9.3%, LCOE -15.2%), but the overall trajectory shows no trend in either direction. The extreme volatility of both lines, driven by feedstock price swings and local supply-chain conditions, confirms that bioenergy has no manufacturing learning curve at the global scale. Its costs are commodity-driven, not technology-driven.

**Geothermal - No 2010 data; both costs rising; LCOE briefly improved before reversing**
The chart has no data point at 2010 - the first observations appear around 2011-2012, and both lines jump upward immediately. The installed cost line surges sharply to roughly +50-60% by 2012, partially retreats, then rises again near 2022-2023 to end at +52.4%. The LCOE line is more volatile, oscillating substantially year-to-year, and notably dipped *below* 0% around 2022 - a temporary improvement - before rebounding to +30.8% in 2023. The absence of 2010 data likely reflects limited global sample coverage in that year, making the "2010 baseline" an extrapolation. The volatile trajectory and rising costs on both measures confirm that geothermal project economics are site-specific and non-scalable.

**Hydropower - Installed cost acceleration steepening post-2020; trend worsening, not plateauing**
The installed cost line rises gradually from 2010 with some oscillation, then accelerates sharply after 2020, ending at +92.3% with the line still steep at the 2023 endpoint. The LCOE line rises more gently and erratically, ending at +32.3%. The gap between the two - installed costs rising ~3x faster than LCOE - reflects the capacity factor improvement buffer (+21% since 2010). Critically, the installed cost acceleration is recent and steepening, not a historical artefact. This is an ongoing and worsening trend.

### Capacity Factor Trajectory Shapes

> **Note:** This section revisits capacity factors from a cost-economics angle - specifically, how each technology's utilization trend explains the gap between its LCOE and installed cost trajectories. The performance baseline (2023 values, directional trends) is documented in [Section 2](#2-technology-adoption-capacity-generation--performance). The analysis here focuses on the *shape* of each trend over time and what it means for cost competitiveness.

Each technology's capacity factor trend tells a distinct story about where utilization improvements are coming from - or aren't.

**Onshore Wind - Clearest improvement trend**: Steady, near-linear rise from ~27-28% in 2010 to a peak of ~38-40% around 2020-2021, then a slight pullback to 35.92% in 2023. The most consistent upward trend of any technology. Directly explains why LCOE (-70.6%) fell persistently faster than installed cost (-48.9%) throughout the period.

**Hydropower - Gradual improvement with mid-period dip**: Clean rise from ~44-45% to a plateau of ~50-52% by 2015-2016, a dip to ~46% around 2019-2020 (likely drought-related), then recovery to 53.31% in 2023. The improvement is real and consistent, partially offsetting the near-doubling of installed costs.

**CSP - Spike-and-recover; not a smooth improvement story**: Gradual rise from ~30% to ~45% (2010-2018), then a dramatic spike to approximately 80% in 2021, collapse to ~35% in 2022, recovery to 54.50% in 2023. The spike is almost certainly a weighted-average composition artifact - large Chinese molten-salt tower plants entering the sample in one year and dominating the global average. The 2023 value of 54.50% is a mid-recovery reading, not a stable plateau, and the overall +79% net improvement reflects a volatile path rather than accumulated operational learning.

**Geothermal - Slight decline from a high plateau**: Starts at approximately 86% in 2010, oscillates in the 78-88% range throughout, ends at 82.11%. The trend is a gentle decline - geographic expansion into slightly lower-resource sites pulling the global average marginally downward. The "near-flat" characterization is approximately correct, but the 2010 starting level was notably higher than the 2023 endpoint.

**Bioenergy - Stable with one unexplained spike**: Oscillates in the 66-75% range for most of the period, with a notable spike to approximately 85% around 2017-2018 before returning to 70-72% by 2023. Likely feedstock-quality or dispatch-related rather than a structural improvement. Confirms the commodity-driven nature of bioenergy operations.

**Offshore Wind - Flat throughout**: Starts ~38-39% in 2010, oscillates in a 35-45% band, ends at 41.04%. No meaningful improvement trend. The LCOE reduction for offshore wind (-63.2%) is therefore driven almost entirely by capital cost reduction, not improved utilization. The improvement seen in onshore wind from turbine technology gains (larger rotors, better siting) has not materialized at the same scale offshore.

**Solar PV - Near-flat throughout; geographic-mix effect only**: Starts ~14%, rises marginally to ~17% by 2013-2014, oscillates in the 14-17% range, ends at 16.17%. There is no technology-driven improvement trend - the minor increase reflects deployment expanding into sunnier markets (Middle East, Latin America, Australia), a geographic-mix effect. Per-panel performance improvement is not visible in the global weighted average.

### Cross-Cutting Observations - Cost Structure and Competitive Positioning

- **The LCOE vs. installed cost gap as a diagnostic tool:** When LCOE falls faster than installed cost (CSP: -70.4% vs -38.1%; Onshore Wind: -70.6% vs -48.9%; portfolio average: -35.2% vs -12.2%), the difference is absorbed by capacity factor improvement - the same capital produces more electricity over time. When the two lines track closely (Solar PV: -90.4% vs -85.7%), manufacturing scale economies dominate. Technologies with a large and persistent LCOE-to-installed-cost gap have cost reduction headroom independent of supply-chain scale.

- **Geothermal is the cautionary counterpoint to the cost revolution narrative:** Every other technology either fell in LCOE or ended near its starting level. Geothermal rose on both measures, crossed from below the fossil fuel range to within it, and shows no convergence. Resource-constrained, site-specific technologies with no manufacturing learning curve do not benefit from the same forces that drove solar and wind costs down.

- **Two technologies are now cheaper than the cheapest fossil fuel:** Onshore Wind ($0.03/kWh) and Solar PV ($0.04/kWh) sit below the $0.07 fossil floor. Hydropower ($0.06/kWh) also sits below it but its cost trajectory is upward. All other renewables are within or above the fossil range - including Offshore Wind, which despite a -63.2% reduction, only just reached the fossil floor at $0.07 in 2023.

- **Installed cost reversals in Offshore Wind (2010-2012) and CSP (2021-2022)** are reminders that learning curves are not monotonic in capital-intensive industries. Early scale-up and technology/geography shifts can temporarily push costs upward before renewed learning resumes the downward trend.

---

## 4. Public Investment in Renewable Energy (2000-2020)

> **Important scope note:** This analysis covers **public finance only** (government and development finance institutions). Private investment - which represents the majority of total energy investment - is not included. Public finance plays a strategic role in enabling early-stage deployment and supporting technologies not yet commercially attractive. A full investment picture would require private investment data.

> **Why this analysis was excluded from Tableau dashboards:** Public investment data alone does not paint a complete picture of capital flows into the energy sector. Without private investment data - which accounts for the large majority of total energy investment - visualizing only the public finance share risks creating a misleading impression of overall investment alignment. A dedicated investment dashboard would require integrating private finance data (e.g., BloombergNEF, IEA World Energy Investment) to tell the full story responsibly.

### Global Investment Composition (2000-2020)

- Total public energy investment: **~$531 billion**
- Renewables: **$263.3B (49.6%)** - slightly ahead of fossil fuels
- Fossil fuels: **$245B (46.1%)**
- Nuclear + other non-renewables: **$22.9B (4.3%)**

### Trends Over Time

- **2016:** Fossil fuel share spiked to 57% before collapsing by >50% the following year.
- **Since 2017:** Renewables consistently attracted 60-75% of public finance.
- **By 2020:** Renewables ~75% of public investment vs fossil ~25%.
- 3-year moving average of renewable investment exceeded fossil every year since 2012.

### Technology Distribution

- **Hydropower dominated** renewable funding: $107.3B (~20% of total public investment).
- Within fossil fuels: Oil $83.5B (15.7%), Coal $13.9%, Gas $11.1%.
- Wind: ~8.9% of total; Solar: ~7.8%; "Multiple renewables": ~8.9%
- Bioenergy (1.9%) and Geothermal (1.8%) received limited funding. Marine energy: $4.1M total.

### Top Public Energy Donors (2000-2020)

~70% of public energy finance came from the top 5 donors:

1. **China (~44% of global total, ~$233B):** ~$161B fossil, ~$55B renewables, ~$17B nuclear
2. **Brazil (~10%, ~$53B):** renewables-heavy (~$43B renewables vs ~$10B fossil)
3. **Japan (~6%, ~$34B):** ~$21B fossil, ~$13B renewables
4. **EU Institutions (~6%):** ~$27B renewables, ~$3.5B fossil
5. **World Bank/IBRD (~4%):** ~$11.7B renewables, ~$10B fossil

### Alignment Between Public Investment and Cost Declines

- **Well-aligned:** Solar PV and Onshore Wind received major funding and achieved the largest LCOE reductions (-87% and -64% by 2020), becoming the cheapest renewables.
- **Hydropower anomaly:** Largest share of public investment but LCOE rose ~18% - reflecting aging assets and site constraints, not funding inefficiency.
- **CSP outlier:** Only ~$2.3B public investment yet achieved ~69% LCOE reduction - largely driven by private innovation and early deployment in Spain and the US.

### Subregional Investment Patterns

- **Latin America & Caribbean** received the most public renewable investment (~33%, ~$82B) - hydropower ~46%.
- **Sub-Saharan Africa:** ~19% of global renewables (~$49B), hydro ~66%.
- **Fossil-heavy recipients:** Eastern Europe ($46B total, ~87% fossil), Central Asia ($19B, ~83% fossil), South-Eastern Asia ($55B, ~62% fossil).
- **Small but renewable-heavy:** Western Europe (~1.6% of total, ~98% renewables), North America (~0.1% of total, ~99% renewables).

---

## 5. Renewables & CO2 Emissions

> **Why this analysis was excluded from Tableau dashboards:** The emissions dataset has limited country coverage (79 countries with full data) and the available data did not support the granular visualization story planned for Tableau. The SQL analysis below remains valid at the global and aggregated country level.

### Global Emissions vs Renewable Growth (2000-2023)

- Global CO2 emissions rose **~48% since 2000**, while renewables' share in electricity generation grew ~63%.
- Emissions grew +31% between 2000-2010, but only +13% between 2010-2023 - signaling early decoupling.
- From 2008 onward, renewable generation share expanded every year while fossil share mostly declined.
- **2020:** Emissions dropped -5% while renewables grew +6.7% (pandemic effect accelerated the trend).
- **2022:** Renewables grew +7.3% vs fossil +1.5%, keeping emissions growth to just +1.7%.
- **2023:** Renewables grew +6% while fossil grew ~1%, emissions +1.6%.
- **Conclusion:** Renewables now offset most new electricity demand growth, stabilizing emissions - but sustained global declines have not yet been achieved.

### Emissions Intensity vs Renewable Share (2010-2023, Country Level)

Normalizing CO2 by total primary energy consumption (MtCO2/EJ) reveals clear patterns:

- **Low-intensity leaders** pair high RE and/or nuclear:
  - Iceland (12 MtCO2/EJ), Norway (18.7) - near-100% hydro/geothermal
  - Sweden (19.7), France (31.3), Switzerland (32.3) - large nuclear + RE
  - Brazil (36, ~81% RE), Canada (38.3, 65% RE + 15% nuclear)

- **High-intensity cluster** maps to fossil-heavy systems with little nuclear:
  - South Africa (89), Estonia (84.2, oil shale), Kazakhstan (77.2), India (72.6), Poland (72.4)

- **Large economies diverge:**
  - Coal-heavy (China, India): ~70-80 MtCO2/EJ
  - Balanced mix (US, Germany, Russia): ~50-55 MtCO2/EJ
  - Hydro + nuclear (Canada): ~38 MtCO2/EJ

- **Conclusion:** Higher RE share - especially combined with nuclear - strongly correlates with lower CO2 intensity. Where fossil fuels dominate, intensity remains high even as RE grows.

---

## 6. Regional Electricity Profiles (2023)

### Africa
| Subregion | RE Share | Dominant RE Tech | Fossil Share | Fossil Mix |
|---|---|---|---|---|
| Sub-Saharan Africa | 36.8% | Hydro (81.9%), Solar PV (10.4%) | 60.4% | Coal (65%), Gas (25%) |
| Northern Africa | 10.8% | Hydro (54%), Wind (28%), Solar (15.5%) | 89.2% | Gas (86%) |

Sub-Saharan Africa has meaningful renewable penetration through hydropower. Northern Africa is among the most fossil-dependent subregions globally despite exceptional solar resources.

### Americas
| Subregion | RE Share | Dominant RE Tech | Fossil Share | Nuclear Share |
|---|---|---|---|---|
| Latin America & Caribbean | 57.8% | Hydro (68.9%), Wind (13.8%), Solar (9.4%) | 39.7% | 2.5% |
| Northern America | 27.2% | Hydro (44%), Wind (33.7%), Solar (16%) | 54.4% | 18.5% |

LAC generates nearly 58% from renewables - more than double Northern America's 27% - but Northern America partially offsets that gap with 18.5% nuclear.

### Asia
| Subregion | RE Share | Dominant RE Tech | Fossil Share |
|---|---|---|---|
| Eastern Asia | 27.6% | Hydro (42%), Wind (26%), Solar PV (23%) | 64.6% (coal 84%) |
| South-eastern Asia | 27.2% | Hydro (59%), Bioenergy (17%), Solar (11%), Geothermal (8%) | 72.6% |
| Central Asia | 21.4% | Hydro (88.7%) | 78.6% |
| Southern Asia | 18.6% | Hydro (52%), Solar PV (24%), Wind (17%) | 78% (coal 72%) |
| Western Asia | 13.8% | Hydro (40%), Solar PV (30%), Wind (19%) | 83.6% |

Eastern Asia's sheer scale defines the global picture - it generates more electricity than all of the Americas combined, but 64.6% is fossil-fuelled and coal accounts for 84% of that. South-eastern Asia is notable for geothermal energy (8% of its renewables - unique among all global subregions).

### Europe
| Subregion | RE Share | Dominant RE Tech | Fossil Share | Nuclear Share |
|---|---|---|---|---|
| Northern Europe | **65.1%** | Hydro (46.7%), Wind (23.3%), Bioenergy (13%), Offshore Wind (11.3%) | 17.7% | 17.2% |
| Southern Europe | 48.9% | Hydro (33.8%), Wind (31.2%), Solar PV (24.4%) | 40.8% | 10.3% |
| Western Europe | 43.0% | Wind (33.6%), Hydro (25.9%), Solar PV (20.8%), Bioenergy (12.4%) | 25.1% | 31.9% |
| Eastern Europe | 20.2% | Hydro (70%), Wind (12.6%), Solar (11.2%) | 57.2% | 22.5% |

Europe has the most differentiated regional picture globally. Northern Europe leads the world at 65% renewables. Western Europe achieves ~75% low-carbon total (43% RE + 32% nuclear). Southern Europe has the most balanced wind/hydro/solar split of any subregion. Eastern Europe lags significantly at 20% renewables.

### Oceania
| Subregion | RE Share | Dominant RE Tech | Fossil Share |
|---|---|---|---|
| Australia & New Zealand | 41.2% | Hydro (32.2%), Solar PV (32.2%), Wind (26.4%) | 58.6% (coal 69%) |
| Melanesia | 31.8% | Hydro (73%) | 68.2% (oil 65%) |
| Micronesia | ~9.8% | - | 90.2% (100% oil) |
| Polynesia | ~26% | - | 74% (100% oil) |

Australia & NZ is the only subregion globally with a near-perfect three-way split between hydro, solar, and wind. The Pacific island subregions (Micronesia, Polynesia) are almost entirely oil-dependent - highlighting the energy access and transition challenge for small island developing states.

---

*Insights document produced as part of the renewable-energy-analytics project.*


