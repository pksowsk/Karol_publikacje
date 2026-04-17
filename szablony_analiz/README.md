# Szablony analiz

Folder zawiera pliki `.Rmd`, ktore warto traktowac jako baze do kolejnych analiz, a nie jako archiwalne wyniki.

## Uklad

- `anova_rm/2gr_2pomiary/`
  Starszy szablon dla ukladu 2 grupy x 2 pomiary.
- `anova_rm/3gr_2pomiary/`
  Szablony dla ukladu 3 grupy x 2 pomiary, w tym nowszy framework `new_version_*`.
- `anova_rm/3gr_4pomiary/`
  Szablony odpowiadajace najnowszej logice z analizy `2025-11`.
- `korelacje/`
  Szablon analiz korelacyjnych.
- `regresja/`
  Szablon regresji wielorakiej oparty o `tidymodels`.
- `wykresy/`
  Historyczny szablon wykresow.
- `legacy/`
  Najstarsze materialy referencyjne.

## Uwaga

Najbardziej praktyczne do dalszej pracy sa obecnie:

- `anova_rm/3gr_4pomiary/`
- `anova_rm/3gr_2pomiary/new_version_*`
- `korelacje/korelacje.Rmd`
- `regresja/regresja_new.Rmd`

Foldery `wykresy/` i `legacy/` zostaly zachowane glownie jako zapis ewolucji warsztatu i moga wymagac recznego dopasowania sciezek do danych.
