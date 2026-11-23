# Power BI: Rebuild the Maison Aurelle Dashboard Yourself

Open `dashboard.html` in your browser next to Power BI. It is the **model**: your
goal is to rebuild those 3 pages in Power BI by following the steps below.

> Why rebuild it? In interviews they will ask *"How did you build this?"* or even
> ask you to share your screen and change something. The `.pbix` file you make
> yourself is what goes in your portfolio.

Time needed: about 2 days (day 4 and 5 of your plan).

---

## Part 1 · Load the data (20 min)

1. Open **Power BI Desktop** → **Blank report**.
2. **Home → Get data → Text/CSV**.
3. Go to `Documents → Luxury CRM Project → luxury-crm-project → data` and choose `transactions.csv` → **Load**.
4. Repeat for: `clients.csv`, `products.csv`, `boutiques.csv`, `sales_associates.csv`.
5. Repeat for two files from the `outputs` folder: `rfm.csv`, `call_list.csv`.
   (These are the results of your SQL queries 4.2 and 5.1.)
6. On the right, in the **Data** panel, you now see 7 tables.

**Check the data types** (very important):
- Click the **Table view** icon (2nd icon on the far left).
- Select `transactions` → click the `transaction_date` column → at the top,
  **Data type** must be **Date**. If not, change it.
- `amount_eur` must be **Whole number**.

## Part 2 · Connect the tables (15 min)

1. Click the **Model view** icon (3rd icon on the far left).
2. Drag and drop these columns onto each other (one line = one relationship):

| From (many side) | To (one side) |
|---|---|
| `transactions[client_id]` | `clients[client_id]` |
| `transactions[product_id]` | `products[product_id]` |
| `transactions[boutique_id]` | `boutiques[boutique_id]` |
| `transactions[associate_id]` | `sales_associates[associate_id]` |
| `rfm[client_id]` | `clients[client_id]` |
| `call_list[client_id]` | `clients[client_id]` |

3. Each line should show **1** on one end and **\*** on the other. This is a
   **star schema**: `transactions` is the "fact" table in the middle, the
   others are "dimension" tables around it. *Say this word in interviews.*

> Power BI may create some links automatically. Delete any link that is not in the table above
> (right-click the line → Delete).

## Part 3 · Create measures with DAX (20 min)

A **measure** is a calculation that updates when you filter (e.g. click Monaco).
Click the `transactions` table in the Data panel → **Home → New measure**, and paste
each line below, one measure at a time (press Enter after each):

```DAX
Total Revenue = SUM(transactions[amount_eur])
```
```DAX
Active Clients = DISTINCTCOUNT(transactions[client_id])
```
```DAX
Number of Transactions = COUNTROWS(transactions)
```
```DAX
Average Ticket = DIVIDE([Total Revenue], [Number of Transactions])
```

Now click the `rfm` table → **New measure**:

```DAX
Segment Clients = COUNTROWS(rfm)
```
```DAX
% of Clients = DIVIDE([Segment Clients], CALCULATE([Segment Clients], ALL(rfm[segment])))
```
```DAX
Segment Revenue = SUM(rfm[monetary_eur])
```
```DAX
% of Revenue = DIVIDE([Segment Revenue], CALCULATE([Segment Revenue], ALL(rfm[segment])))
```

**Format them:** click a measure → in the **Measure tools** ribbon at the top:
- revenue/ticket measures → **Currency** € and 0 decimals
- `%` measures → **Percentage**, 1 decimal

## Part 4 · Page 1, "Executive overview" (1.5 h)

Go back to **Report view** (1st icon on the left). Rename the page at the bottom:
double-click "Page 1" → `Executive overview`.

| Visual | How to build it |
|---|---|
| **4 KPI cards** | Visualizations panel → **Card**. Drag `Total Revenue` into *Fields*. Repeat for `Active Clients`, `Number of Transactions`, `Average Ticket`. Place them in a row at the top. |
| **Revenue by month** (line) | **Line chart**. X-axis: `transactions[transaction_date]` (keep *Year* and *Month* only in the hierarchy). Y-axis: `Total Revenue`. Click the "↓↓ Expand all down" arrow on the chart to see months. |
| **Revenue by boutique** | **Clustered bar chart**. Y-axis: `boutiques[city]`. X-axis: `Total Revenue`. Sort: `…` → Sort by Total Revenue, descending. |
| **Revenue by category** | Same, with `products[category]`. |
| **Average ticket by channel** | Bar chart, Y-axis `transactions[channel]`, X-axis `Average Ticket`. Highlight "Private Appointment": Format → Bars → Colors → *Show all* → set it to orange. |
| **2 slicers (filters)** | **Slicer** visual with `transactions[transaction_date]` (Year), and another with `boutiques[city]`. Format → Slicer settings → Style: *Dropdown*. |

**Test it:** pick "Monaco" in the slicer: every visual must change.

## Part 5 · Page 2, "Client segmentation" (1 h)

Click **+** at the bottom to add a page → rename `Client segmentation`.

| Visual | How to build it |
|---|---|
| **KPI cards** | Card with `Segment Clients`. In the **Filters pane** (right), drag `rfm[segment]` to *Filters on this visual* and tick only *VIC (Champions)*. Repeat for Loyal, Dormant. |
| **% clients vs % revenue** | **Clustered bar chart**. Y-axis: `rfm[segment]`. X-axis: `% of Clients` **and** `% of Revenue`. Turn on **Data labels**. This is the key chart of the project. |
| **Segment profiles table** | **Table** visual: `rfm[segment]`, `Segment Clients`, `% of Clients`, `Segment Revenue`, `% of Revenue`, plus `rfm[frequency]` and `rfm[recency_days]` set to **Average** (click the arrow next to the field → Average). |
| **Top 15 clients** | **Table**: `rfm[client_id]`, `rfm[segment]`, `rfm[monetary_eur]`, `rfm[frequency]`, `rfm[recency_days]`. Filters pane → `client_id` → Filter type: **Top N** → 15 → By value: `monetary_eur`. |

## Part 6 · Page 3, "CRM action plan" (1 h)

New page → `CRM action plan`.

| Visual | How to build it |
|---|---|
| **At-Risk KPI cards** | Card `Segment Clients` + card `Segment Revenue`, both filtered on `segment = At Risk`. Card with *Count of* `call_list[client_id]`. |
| **Retention by cohort** | Simplest: **Get data → Text/CSV** → `outputs/retention_by_cohort.csv`. Bar chart: Y = `first_year`, X = `retention_pct`. Filter out 2026. |
| **Cross-selling** | Load `outputs/cross_sell_leather.csv`. Bar chart: Y = `also_bought`, X = `pct_of_leather_buyers`. |
| **Recommendations** | **Insert → Text box**. Write the 5 recommendations (see README.md). |
| **Call list** | **Table** with all the columns of `call_list`. |

## Part 7 · Make it look professional (1 h)

1. **Apply the Maison Aurelle theme (1 click):** **View → Themes → ▾ (arrow) → Browse for themes**
   → choose `maison_aurelle_theme.json` in the project folder. All colors (blue `#2F5D9E`,
   gold `#B8893B`), fonts and the cream background are applied at once.
   *Tip: you can do this right at the start, before building the visuals.*
2. **Title bar** on each page: Insert → Shapes → Rectangle, navy `#14213D`, full width,
   with a thin gold `#B8893B` line underneath. On top, a text box in white, Georgia font,
   capitals with wide spacing: `MAISON AURELLE` and, smaller in gold, `CLIENT INTELLIGENCE`.
3. **Rename every chart title as a finding.** Select the visual → Format → General →
   Title. Copy the titles from `dashboard.html`, e.g.
   *"10% of clients (VICs) bring 50% of revenue"*.
4. Turn off gridlines you don't need; no 3D, no pie charts with many slices.
5. Align visuals: select several → **Format → Align → Align top / Distribute horizontally**.

## Part 8 · Save and export

- **File → Save as** → `Maison_Aurelle_Dashboard.pbix` in the project folder.
- **File → Export → Export to PDF** → for your portfolio and LinkedIn.
- Screenshots: `Windows + Shift + S`, one per page, saved in a `screenshots` folder.

---

### If something goes wrong
- **Numbers are huge/wrong in a chart** → the field is set to *Sum* when it should be
  *Average* (or the reverse): click the arrow next to the field in the visual.
- **Slicer doesn't filter a visual** → a relationship is missing (Part 2).
- **Dates show as text** → change data type to Date (Part 1).
- Anything else: take a screenshot and send it to Claude.
