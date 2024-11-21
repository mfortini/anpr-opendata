---
theme: dashboard
title: Popolazione residente
sql:
  residenti: ./data/residenti.parquet
---

# Popolazione residente da ANPR


```sql id=dati_residenti 
SELECT  "DATA ELABORAZIONE", "REGIONE", "PROVINCIA", "COMUNE", RESIDENTI FROM residenti WHERE REGIONE=${filt_regione} 
 AND (PROVINCIA=${filt_provincia} OR ${filt_provincia} = '--TUTTE--') AND (COMUNE=${filt_comune} OR ${filt_comune} = '--TUTTI--') 
 ORDER BY "DATA ELABORAZIONE", "REGIONE", "PROVINCIA", "COMUNE"
```

```sql id=dati_residenti_ratio_regioni 
WITH DATI_RESIDENTI AS (SELECT  "DATA ELABORAZIONE", "REGIONE", SUM(RESIDENTI) AS RESIDENTI FROM residenti  GROUP BY "DATA ELABORAZIONE", REGIONE
 ORDER BY "DATA ELABORAZIONE", "REGIONE")
 SELECT *, RESIDENTI/FIRST_RESIDENTI - 1. AS RATIO_RESIDENTI FROM DATI_RESIDENTI JOIN (SELECT REGIONE, FIRST (RESIDENTI ORDER BY "DATA ELABORAZIONE" ) AS FIRST_RESIDENTI FROM DATI_RESIDENTI
 GROUP BY REGIONE) AS DATI_RESIDENTI_FIRST ON DATI_RESIDENTI.REGIONE=DATI_RESIDENTI_FIRST.REGIONE
```

```js
const parseDate = (d) => d3.timeFormat("%Y-%m-%d")(new Date(d));
```

```js
const plotRegioni = resize((width) => Plot.plot({
      color: {legend: true},
      title: "Andamento relativo della popolazione totale delle regioni",
      width,
      y: {grid: true, label: "Variazione Residenti (%)", percent: true},
      marks: [
        Plot.ruleY([]),
        Plot.lineY(dati_residenti_ratio_regioni, {x: "DATA ELABORAZIONE",interval: "day", y: "RATIO_RESIDENTI", stroke: "REGIONE", tip: false}),
        Plot.tip(dati_residenti_ratio_regioni, Plot.pointerX({x: "DATA ELABORAZIONE", y: "RATIO_RESIDENTI", title: (d) => [parseDate(d["DATA ELABORAZIONE"]), d["REGIONE"], d["RESIDENTI"]].join("\n")}))
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
WITH DATI_RESIDENTI AS (SELECT  "DATA ELABORAZIONE", "REGIONE", "PROVINCIA", SUM(RESIDENTI) AS RESIDENTI FROM residenti WHERE REGIONE=${filt_regione} 
 AND (PROVINCIA=${filt_provincia} OR ${filt_provincia} = '--TUTTE--') GROUP BY "DATA ELABORAZIONE", REGIONE, PROVINCIA
 ORDER BY "DATA ELABORAZIONE", "REGIONE", "PROVINCIA")
 SELECT *, RESIDENTI/FIRST_RESIDENTI - 1. AS RATIO_RESIDENTI FROM DATI_RESIDENTI JOIN (SELECT REGIONE, PROVINCIA, FIRST (RESIDENTI ORDER BY "DATA ELABORAZIONE" ) AS FIRST_RESIDENTI FROM DATI_RESIDENTI
 GROUP BY REGIONE, PROVINCIA) AS DATI_RESIDENTI_FIRST ON DATI_RESIDENTI.REGIONE=DATI_RESIDENTI_FIRST.REGIONE AND DATI_RESIDENTI.PROVINCIA=DATI_RESIDENTI_FIRST.PROVINCIA
```

```js
    resize((width) => Plot.plot({
      color: {legend: true},
      title: "Andamento relativo della popolazione totale delle Province",
      subtitle: "Regione " + filt_regione + ((filt_provincia != "--TUTTE--")?" | Provincia " + filt_provincia:""),
      width,
      y: {grid: true, label: "Variazione Residenti (%)", percent: true},
      marks: [
        Plot.ruleY([]),
        Plot.lineY(dati_residenti_ratio_province, {x: "DATA ELABORAZIONE",interval: "day", y: "RATIO_RESIDENTI", stroke: "PROVINCIA", tip: false}),
        Plot.tip(dati_residenti_ratio_province, Plot.pointerX({x: "DATA ELABORAZIONE", y: "RATIO_RESIDENTI", title: (d) => [parseDate(d["DATA ELABORAZIONE"]), d["PROVINCIA"], d["COMUNE"], d["RESIDENTI"]].join("\n")}))
      ]
    }))
```


```sql id=dati_residenti_ratio 
WITH DATI_RESIDENTI AS (SELECT  "DATA ELABORAZIONE", "REGIONE", "PROVINCIA", "COMUNE", RESIDENTI FROM residenti WHERE REGIONE=${filt_regione} 
 AND (PROVINCIA=${filt_provincia} OR ${filt_provincia} = '--TUTTE--') AND (COMUNE=${filt_comune} OR ${filt_comune} = '--TUTTI--') 
 ORDER BY "DATA ELABORAZIONE", "REGIONE", "PROVINCIA", "COMUNE")
 SELECT *, RESIDENTI/FIRST_RESIDENTI - 1. AS RATIO_RESIDENTI FROM DATI_RESIDENTI JOIN (SELECT REGIONE, PROVINCIA, COMUNE, FIRST (RESIDENTI ORDER BY "DATA ELABORAZIONE") AS FIRST_RESIDENTI FROM DATI_RESIDENTI
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
        Plot.lineY(dati_residenti_ratio, {x: "DATA ELABORAZIONE",interval: "day", y: "RATIO_RESIDENTI", stroke: "COMUNE", tip: false}),
        Plot.tip(dati_residenti_ratio, Plot.pointerX({x: "DATA ELABORAZIONE", y: "RATIO_RESIDENTI", title: (d) => [parseDate(d["DATA ELABORAZIONE"]), d["PROVINCIA"], d["COMUNE"], d["RESIDENTI"]].join("\n")}))
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
        Plot.lineY(dati_residenti, {x: "DATA ELABORAZIONE", interval: "day", y: "RESIDENTI", z: "COMUNE", tip: true})
      ]
    }));
    display(chart);
} 

```