# 2025-11

Najswiezszy etap pracy analitycznej w tym repo.

## Zawartosc

- `*.Rmd`
  Zrodla jednostkowych analiz dla poszczegolnych zmiennych.
- `*.html`
  Wyrenderowane raporty jednostkowe.
- `*_files/`
  Zasoby HTML wygenerowane przy renderowaniu raportow.
- `obliczenia_zbiorcze.Rmd`
  Batch render dla zestawu zmiennych z tego etapu.
- `obliczenia_zbiorcze_LMM.Rmd`
  Nowy batch dla glownej metody LMM. Generuje zbiorcze tabele, skoroszyt Excel i opcjonalnie raporty HTML dla poszczegolnych zmiennych.
- `raporty_batch/raporty_anova/`
  Zbiorcze raporty wygenerowane w trybie wsadowym.

## Aktualny workflow LMM

Uruchom z katalogu glownego repo:

```r
rmarkdown::render("2025-11/obliczenia_zbiorcze_LMM.Rmd")
```

Domyslnie batch zapisuje wyniki do `2025-11/raporty_batch/raporty_lmm/` i tworzy skoroszyt `wyniki_lmm_2025_11.xlsx`.

Szczegolowy opis teorii, obliczen, interpretacji i modyfikacji workflow znajduje sie w [`dokumentacja/LMM_manual.md`](../dokumentacja/LMM_manual.md).

To jest folder, od ktorego warto zaczac dalszy przeglad metodologiczny i merytoryczny.
