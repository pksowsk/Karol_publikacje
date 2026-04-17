# Karol_publikacje

Repo zostalo uporzadkowane tak, aby rozdzielic:

- aktualna analize,
- gotowe szablony analiz,
- dane zrodlowe,
- dokumentacje,
- archiwalne iteracje i wyniki.

## Glowny uklad

- `2025-11/`
  Najswiezsza analiza i wyniki dla ukladu 3 grupy x 4 pomiary. To od tego folderu warto zaczac dalszy przeglad merytoryczny.
- `Dane/`
  Zrodlowe pliki `.xlsx` wykorzystywane przez kolejne iteracje analiz.
- `szablony_analiz/`
  Zebrane i posegregowane szablony `.Rmd` wedlug typu analizy.
- `archiwum/`
  Starsze iteracje analiz oraz historyczne wyniki, ktore nie powinny juz zasmiecac katalogu glownego.
- `dokumentacja/`
  Manuale, opis projektu i przeniesiony historyczny brief zadania.
- `wyniki_robocze/`
  Domyslne miejsce na nowe wyniki generowane z folderu `szablony_analiz/`.

## Typy analiz

- `anova_rm`
  - `2gr_2pomiary`
  - `3gr_2pomiary`
  - `3gr_4pomiary`
- `korelacje`
- `regresja`
- `wykresy`
- `legacy`

## Co zostalo przeniesione do archiwum

- `archiwum/iteracje_analiz/`
  Starsze katalogi datowane: `2023-11`, `2024-07`, `2024-08`, `2025-01`, `2025-07`.
- `archiwum/wyniki_batch/2025-07_framework_wyniki/`
  Wczesniej osobny katalog `wyniki/`.
- `archiwum/legacy_root/`
  Starsze pliki robocze z katalogu glownego oraz duplikaty szablonow z `2025-11/`.

## Uwagi praktyczne

- `2025-11/obliczenia_zbiorcze.Rmd` zostal przepiety na szablon z `szablony_analiz/anova_rm/3gr_4pomiary/` oraz na katalog wynikow `2025-11/raporty_batch/raporty_anova/`.
- Szablony w `szablony_analiz/anova_rm/3gr_2pomiary/`, `korelacje/` i `regresja/` zapisują nowe wyniki do `wyniki_robocze/`, zeby nie odtwarzac dawnego chaosu w katalogu glownym.
- Czesc historycznych szablonow w `szablony_analiz/wykresy/` i `szablony_analiz/legacy/` nadal odwoluje sie do dawnych plikow danych, ktorych nie ma juz w repo. Te pliki zostaly zachowane jako material referencyjny, ale przed uruchomieniem wymagaja recznego wskazania danych.
- `ANOVA_manual.*` i `manual.html` w `dokumentacja/` opisuja starsze nazewnictwo plikow. Traktuj je jako dokumentacje merytoryczna, nie doslowna mape biezacej struktury.
