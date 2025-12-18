---
theme: dashboard
title: Popolazione residente
sql:
  residenti: ./data/residenti.parquet
---

# Popolazione residente da ANPR


```sql id=dati_residenti 
SELECT  "DATA_ELABORAZIONE", "REGIONE", "PROVINCIA", "COMUNE", RESIDENTI FROM residenti WHERE REGIONE=${filt_regione} 
 AND (PROVINCIA=${filt_provincia} OR ${filt_provincia} = '--TUTTE--') AND (COMUNE=${filt_comune} OR ${filt_comune} = '--TUTTI--') 
 ORDER BY "DATA_ELABORAZIONE", "REGIONE", "PROVINCIA", "COMUNE"
```

```sql id=dati_residenti_ratio_regioni 
WITH DATI_RESIDENTI AS (
  SELECT "DATA_ELABORAZIONE", "REGIONE", SUM(RESIDENTI) AS RESIDENTI
  FROM residenti
  GROUP BY "DATA_ELABORAZIONE", REGIONE
),
DATI_ITALIA AS (
  SELECT "DATA_ELABORAZIONE", SUM(RESIDENTI) AS RESIDENTI_IT
  FROM residenti
  GROUP BY "DATA_ELABORAZIONE"
),
FIRST_REG AS (
  SELECT REGIONE, FIRST(RESIDENTI ORDER BY "DATA_ELABORAZIONE") AS F_REG
  FROM DATI_RESIDENTI
  GROUP BY REGIONE
),
FIRST_IT AS (
   SELECT FIRST(RESIDENTI_IT ORDER BY "DATA_ELABORAZIONE") AS F_IT
   FROM DATI_ITALIA
),
COMBINED AS (
    SELECT
      R."DATA_ELABORAZIONE",
      R."REGIONE",
      R.RESIDENTI,
      R.RESIDENTI / FR.F_REG - 1.0 AS RATIO_RESIDENTI,
      (R.RESIDENTI / FR.F_REG - 1.0) - (I.RESIDENTI_IT / FI.F_IT - 1.0) AS RATIO_DIFF
    FROM DATI_RESIDENTI R
    JOIN DATI_ITALIA I ON R."DATA_ELABORAZIONE" = I."DATA_ELABORAZIONE"
    JOIN FIRST_REG FR ON R.REGIONE = FR.REGIONE
    CROSS JOIN FIRST_IT FI

    UNION ALL

    SELECT
      I."DATA_ELABORAZIONE",
      'Italia' AS "REGIONE",
      I.RESIDENTI_IT AS RESIDENTI,
      I.RESIDENTI_IT / FI.F_IT - 1.0 AS RATIO_RESIDENTI,
      0.0 AS RATIO_DIFF
    FROM DATI_ITALIA I
    CROSS JOIN FIRST_IT FI
)
SELECT * FROM COMBINED
ORDER BY "DATA_ELABORAZIONE", "REGIONE"
```



```js
const parseDate = (d) => d3.timeFormat("%Y-%m-%d")(new Date(d));
```

```js
const region_diff_mode = view(Inputs.toggle({label: "Sottrai andamento Italia", value: false}));
```

```js
const plotRegioni = resize((width) => Plot.plot({
      color: {legend: true},
      title: region_diff_mode ? "Andamento relativo della popolazione totale delle regioni - Differenza rispetto alla media nazionale" : "Andamento relativo della popolazione totale delle regioni",
      width,
      marginRight: 80,
      y: {grid: true, label: "Variazione Residenti (%)", percent: true},
      marks: [
        Plot.ruleY([]),
        Plot.lineY(dati_residenti_ratio_regioni, {
            x: "DATA_ELABORAZIONE",
            interval: "day",
            y: region_diff_mode ? "RATIO_DIFF" : "RATIO_RESIDENTI",
            stroke: "REGIONE",
            strokeWidth: 1,
            tip: false
        }),
        Plot.lineY(dati_residenti_ratio_regioni, {
            filter: (d) => d.REGIONE === "Italia",
            x: "DATA_ELABORAZIONE",
            interval: "day",
            y: region_diff_mode ? "RATIO_DIFF" : "RATIO_RESIDENTI",
            stroke: "black",
            strokeWidth: 3,
            tip: false
        }),
        Plot.text(dati_residenti_ratio_regioni, Plot.selectLast({
            filter: (d) => d.REGIONE === "Italia",
            x: "DATA_ELABORAZIONE",
            y: region_diff_mode ? "RATIO_DIFF" : "RATIO_RESIDENTI",
            text: "REGIONE",
            textAnchor: "start",
            dx: 5
        })),
        Plot.tip(dati_residenti_ratio_regioni, Plot.pointerX({
            x: "DATA_ELABORAZIONE",
            y: region_diff_mode ? "RATIO_DIFF" : "RATIO_RESIDENTI",
            title: (d) => [parseDate(d["DATA_ELABORAZIONE"]), d["REGIONE"], d["RESIDENTI"]].join("\n")
        }))
      ]
    }));
display(plotRegioni);
```

```sql id=regioni
SELECT DISTINCT REGIONE FROM residenti
```

```js
const filt_regione = view(Inputs.select(regioni.toArray().map(x=>x["REGIONE"]), {sort: "ascending", unique: true, label: "Regione"}));
```

```sql id=province 
SELECT DISTINCT PROVINCIA FROM residenti WHERE REGIONE=${filt_regione}
```

```js
const filt_provincia = view(Inputs.select(["--TUTTE--"].concat(province.toArray().map(x=>x["PROVINCIA"])), {sort: "ascending", unique: true, value: null, label: "Provincia"}));
```

```sql id=comuni 
SELECT DISTINCT COMUNE FROM residenti WHERE REGIONE=${filt_regione} AND PROVINCIA=${filt_provincia}
```

```js
const filt_comune = view(Inputs.select(["--TUTTI--"].concat(comuni.toArray().map(x=>x["COMUNE"])), {sort: "ascending", unique: true, value: null, label: "Comune"}));
```

```sql id=dati_residenti_ratio_province 
WITH DATI_PROVINCE AS (
  SELECT "DATA_ELABORAZIONE", "REGIONE", "PROVINCIA", SUM(RESIDENTI) AS RESIDENTI
  FROM residenti
  WHERE REGIONE=${filt_regione}
    AND (PROVINCIA=${filt_provincia} OR ${filt_provincia} = '--TUTTE--')
  GROUP BY "DATA_ELABORAZIONE", REGIONE, PROVINCIA
),
DATI_REGIONE AS (
  SELECT "DATA_ELABORAZIONE", SUM(RESIDENTI) AS RESIDENTI_REG
  FROM residenti
  WHERE REGIONE=${filt_regione}
  GROUP BY "DATA_ELABORAZIONE"
),
FIRST_PROV AS (
  SELECT PROVINCIA, FIRST(RESIDENTI ORDER BY "DATA_ELABORAZIONE") AS F_PROV
  FROM DATI_PROVINCE
  GROUP BY PROVINCIA
),
FIRST_REG AS (
   SELECT FIRST(RESIDENTI_REG ORDER BY "DATA_ELABORAZIONE") AS F_REG
   FROM DATI_REGIONE
),
COMBINED AS (
    SELECT
      P."DATA_ELABORAZIONE",
      P."PROVINCIA",
      P.RESIDENTI,
      P.RESIDENTI / FP.F_PROV - 1.0 AS RATIO_RESIDENTI,
      (P.RESIDENTI / FP.F_PROV - 1.0) - (R.RESIDENTI_REG / FR.F_REG - 1.0) AS RATIO_DIFF
    FROM DATI_PROVINCE P
    JOIN DATI_REGIONE R ON P."DATA_ELABORAZIONE" = R."DATA_ELABORAZIONE"
    JOIN FIRST_PROV FP ON P.PROVINCIA = FP.PROVINCIA
    CROSS JOIN FIRST_REG FR

    UNION ALL

    SELECT
      R."DATA_ELABORAZIONE",
      ${"Regione " + filt_regione} AS "PROVINCIA",
      R.RESIDENTI_REG AS RESIDENTI,
      R.RESIDENTI_REG / FR.F_REG - 1.0 AS RATIO_RESIDENTI,
      0.0 AS RATIO_DIFF
    FROM DATI_REGIONE R
    CROSS JOIN FIRST_REG FR
)
SELECT * FROM COMBINED
ORDER BY "DATA_ELABORAZIONE", "PROVINCIA"
```

```js
const province_diff_mode = view(Inputs.toggle({label: "Sottrai andamento Regione", value: false}));
```

```js
    resize((width) => Plot.plot({
      color: {legend: true},
      title: province_diff_mode ? "Andamento relativo della popolazione totale delle Province - Differenza rispetto alla media regionale" : "Andamento relativo della popolazione totale delle Province",
      subtitle: "Regione " + filt_regione + ((filt_provincia != "--TUTTE--")?" | Provincia " + filt_provincia:""),
      width,
      marginRight: 240,
      y: {grid: true, label: "Variazione Residenti (%)", percent: true},
      marks: [
        Plot.ruleY([]),
        Plot.lineY(dati_residenti_ratio_province, {
            x: "DATA_ELABORAZIONE",
            interval: "day",
            y: province_diff_mode ? "RATIO_DIFF" : "RATIO_RESIDENTI",
            stroke: "PROVINCIA",
            strokeWidth: 1,
            tip: false
        }),
        Plot.lineY(dati_residenti_ratio_province, {
            filter: (d) => d.PROVINCIA === "Regione " + filt_regione,
            x: "DATA_ELABORAZIONE",
            interval: "day",
            y: province_diff_mode ? "RATIO_DIFF" : "RATIO_RESIDENTI",
            stroke: "black",
            strokeWidth: 3,
            tip: false
        }),
        Plot.text(dati_residenti_ratio_province, Plot.selectLast({
            filter: (d) => d.PROVINCIA === "Regione " + filt_regione,
            x: "DATA_ELABORAZIONE",
            y: province_diff_mode ? "RATIO_DIFF" : "RATIO_RESIDENTI",
            text: "PROVINCIA",
            textAnchor: "start",
            dx: 5
        })),
        Plot.tip(dati_residenti_ratio_province, Plot.pointerX({
            x: "DATA_ELABORAZIONE", 
            y: province_diff_mode ? "RATIO_DIFF" : "RATIO_RESIDENTI",
            title: (d) => [parseDate(d["DATA_ELABORAZIONE"]), d["PROVINCIA"], d["RESIDENTI"]].join("\n")
        }))
      ]
    }))
```


```sql id=dati_residenti_ratio 
WITH DATI_RESIDENTI AS (SELECT  "DATA_ELABORAZIONE", "REGIONE", "PROVINCIA", "COMUNE", RESIDENTI FROM residenti WHERE REGIONE=${filt_regione} 
 AND (PROVINCIA=${filt_provincia} OR ${filt_provincia} = '--TUTTE--') AND (COMUNE=${filt_comune} OR ${filt_comune} = '--TUTTI--') 
 ORDER BY "DATA_ELABORAZIONE", "REGIONE", "PROVINCIA", "COMUNE")
 SELECT *, RESIDENTI/FIRST_RESIDENTI - 1. AS RATIO_RESIDENTI FROM DATI_RESIDENTI JOIN (SELECT REGIONE, PROVINCIA, COMUNE, FIRST (RESIDENTI ORDER BY "DATA_ELABORAZIONE") AS FIRST_RESIDENTI FROM DATI_RESIDENTI
 GROUP BY REGIONE, PROVINCIA, COMUNE) AS DATI_RESIDENTI_FIRST ON DATI_RESIDENTI.REGIONE=DATI_RESIDENTI_FIRST.REGIONE AND DATI_RESIDENTI.PROVINCIA=DATI_RESIDENTI_FIRST.PROVINCIA AND
 DATI_RESIDENTI.COMUNE=DATI_RESIDENTI_FIRST.COMUNE
```



```js
if (filt_comune == "--TUTTI--") {
    const chart = resize((width) => Plot.plot({
      color: {legend: true},
      title: "Andamento relativo della popolazione dei Comuni",
      subtitle: "Regione " + filt_regione + ((filt_provincia != "--TUTTE--")?" | Provincia " + filt_provincia:"") + ((filt_comune != "--TUTTI--")?" | Comune " + filt_comune:""),
      width,
      y: {grid: true, label: "Variazione Residenti (%)", percent: true},
      marks: [
        Plot.ruleY([]),
        Plot.lineY(dati_residenti_ratio, {x: "DATA_ELABORAZIONE",interval: "day", y: "RATIO_RESIDENTI", stroke: "COMUNE", tip: false}),
        Plot.tip(dati_residenti_ratio, Plot.pointerX({x: "DATA_ELABORAZIONE", y: "RATIO_RESIDENTI", title: (d) => [parseDate(d["DATA_ELABORAZIONE"]), d["PROVINCIA"], d["COMUNE"], d["RESIDENTI"]].join("\n")}))
      ]
    }));
    display(chart);
} else {
    const chart = resize((width) => Plot.plot({
      title: "Andamento della popolazione",
      subtitle: "Regione " + filt_regione + ((filt_provincia != "--TUTTE--")?" | Provincia " + filt_provincia:"") + ((filt_comune != "--TUTTI--")?" | Comune " + filt_comune:""),
      width,
      y: {grid: true, label: "Residenti"},
      marks: [
        Plot.ruleY([]),
        Plot.lineY(dati_residenti, {x: "DATA_ELABORAZIONE", interval: "day", y: "RESIDENTI", z: "COMUNE", tip: true})
      ]
    }));
    display(chart);
} 

```