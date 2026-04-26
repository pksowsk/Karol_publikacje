# Plan przejscia na pelna metode LMM

## Cel

Celem prac jest przejscie z obecnego, mieszanego trybu analiz RM-ANOVA/LMM na jedna spojna metode glowna oparta na liniowych modelach mieszanych (LMM), zgodna z raportem `Raport_LMM_metody_i_wyniki.docx`.

Docelowa analiza dla kazdej zmiennej:

```r
y ~ grupa * czas + (1 | ID_uczestnika)
```

Model ma wykorzystywac wszystkie dostepne obserwacje niebrakujace dla danej zmiennej, estymacje ML (`REML = FALSE`), testy omnibus przez porownania modeli zagniezdzonych (LRT), porownania post hoc przez `emmeans` oraz korekte Holma w ramach rodzin porownan.

## Diagnoza stanu obecnego

- Repo zawiera starsze szablony RM-ANOVA dla ukladu `3 grupy x 4 pomiary`.
- Aktywny batch `2025-11/obliczenia_zbiorcze.Rmd` renderuje obecnie `szablon_anova_poprawiony_gemini.Rmd`, czyli raport oparty glownie na RM-ANOVA i kompletnych przypadkach.
- Istnieje plik `szablony_analiz/anova_rm/3gr_4pomiary/lmm_pipeline_2025_11.R`, ktory jest blizszy metodzie z raportu, ale nie jest jeszcze w pelni gotowy:
  - wymaga stabilizacji jako glowny modul analityczny,
  - nie laduje samodzielnie wymaganych pakietow/operatorow,
  - zawiera niedokonczony fragment diagnostyki wykresow,
  - nie jest wpiety w batch.
- Raport `.docx` odnosi sie do nowszego pliku danych `Publikacja5_dane_po_korektach_przygotowane_2026-03-21_do_pobrania.xlsx`, ktorego nie ma w repo. Repo korzysta obecnie glownie z `Dane/2025_11_23_publikacja.xlsx`.

## Zakres docelowej metody

1. Dane sa przygotowywane w formacie dlugim: jedna obserwacja = jedna osoba w jednym punkcie czasu.
2. Grupy sa kodowane jako trzy poziomy: aerobowa, silowa, kontrolna.
3. Czas jest kodowany jako cztery poziomy: T1, T2, T3, T4.
4. Jednostka powtarzalnosci to stabilny identyfikator uczestnika.
5. Dla kazdej zmiennej stosowana jest jawna mapa transformacji:
   - `ln(y)` dla zmiennych dodatnich i prawostronnie skosnych, gdy logarytmowanie poprawia symetrie,
   - skala surowa dla pozostalych zmiennych.
6. Efekty globalne sa testowane przez LRT:
   - efekt grupy,
   - efekt czasu,
   - interakcja grupa x czas.
7. Post hoc:
   - przy istotnej interakcji: porownania czasu w obrebie grup oraz grup w obrebie czasu,
   - przy braku istotnej interakcji: porownania istotnych efektow glownych,
   - korekta Holma oddzielnie dla kazdej zmiennej i rodziny porownan.
8. Dla zmiennych logarytmowanych raportowane sa wyniki na skali modelu oraz po eksponentacji jako ilorazy srednich geometrycznych.
9. Statystyki opisowe sa liczone na obserwacjach faktycznie uzytych w modelu dla danej zmiennej.

## Etap 1: Ustalenie zrodla danych

### Zadania

- Potwierdzic, ktory plik danych jest finalnym zrodlem do publikacji.
- Jesli finalnym plikiem jest `Publikacja5_dane_po_korektach_przygotowane_2026-03-21_do_pobrania.xlsx`, dodac go do repo lub zapisac jasna instrukcje, skad ma byc pobierany.
- Zweryfikowac, czy finalny plik zawiera stabilny identyfikator uczestnika.
- Jesli nie zawiera, utworzyc jednoznaczna regule budowy `ID_uczestnika` i sprawdzic duplikaty.
- Porownac liczbe osob i obserwacji z raportem `.docx`.

### Kryteria gotowosci

- W dokumentacji wskazany jest jeden finalny plik danych.
- Pipeline nie wymaga zgadywania, czy `id_osoby` oznacza osobe czy grupe.
- Dla kazdej obserwacji da sie jednoznacznie wskazac: uczestnika, grupe i czas.

## Etap 2: Slownik zmiennych i mapa transformacji

### Zadania

- Utworzyc lub uzupelnic centralny slownik zmiennych, najlepiej w pliku konfiguracyjnym lub arkuszu `meta`.
- Dla kazdej zmiennej zapisac:
  - nazwe kolumny w danych,
  - etykiete publikacyjna,
  - jednostke,
  - transformacje (`raw` albo `log`),
  - uzasadnienie transformacji,
  - informacje, czy zmienna musi byc dodatnia.
- Odtworzyc regule z raportu:
  - wszystkie obserwacje dodatnie,
  - skosnosc na skali surowej > 1,
  - logarytmowanie zmniejsza bezwzgledna skosnosc.
- Wygenerowac tabele kontrolna: skosnosc przed log, skosnosc po log, decyzja o transformacji.

### Kryteria gotowosci

- Mapa transformacji jest kompletna dla wszystkich zmiennych analizowanych w raporcie.
- Decyzje transformacyjne sa reprodukowalne i nie sa zaszyte w kilku roznych miejscach kodu.
- Zmienna z transformacja `log` zatrzymuje pipeline, jesli zawiera wartosci `<= 0`.

## Etap 3: Stabilizacja pipeline LMM

### Zadania

- Przeniesc `lmm_pipeline_2025_11.R` z wersji roboczej do stabilnego modulu analitycznego.
- Dodac jawne ladowanie wymaganych pakietow albo jedna funkcje sprawdzajaca zaleznosci.
- Usunac lub poprawic niedokonczony fragment diagnostyki w `build_plots_2025_11()`.
- Ujednolicic nazwy czynnikow:
  - `grupa` albo `interwencja`, ale konsekwentnie w calym pipeline,
  - `czas` jako `T1`, `T2`, `T3`, `T4`,
  - `ID_uczestnika` albo `id_osoby`, ale bez zmiany znaczenia w trakcie analizy.
- Dodac obsluge bledow dla zmiennych:
  - brak kolumny,
  - same braki,
  - niedodatnie wartosci przy log,
  - brak wystarczajacej liczby obserwacji w komorkach.
- Dodac informacje o modelach osobliwych (`isSingular`) i ostrzezeniach konwergencji.

### Kryteria gotowosci

- `source(".../lmm_pipeline_2025_11.R")` dziala w czystej sesji R.
- `run_lmm_analysis_2025_11(var, data_path)` zwraca komplet wynikow dla jednej zmiennej.
- Pipeline przechodzi przez wszystkie zmienne z finalnego slownika bez recznej interwencji albo jasno raportuje, ktore zmienne odpadly i dlaczego.

## Etap 4: Wyniki omnibus i post hoc

### Zadania

- Zweryfikowac sposob budowy modeli zagniezdzonych:
  - model pelny: `grupa * czas`,
  - model addytywny: `grupa + czas`,
  - model bez grupy,
  - model bez czasu.
- Potwierdzic, ze wszystkie modele do LRT sa estymowane przez ML (`REML = FALSE`).
- Upewnic sie, ze LRT dla efektu grupy i czasu jest liczony wzgledem modelu addytywnego, a interakcja przez porownanie modelu addytywnego z pelnym.
- Ujednolicic prog decyzyjny `alpha = 0.05`.
- Dla post hoc zapisac wszystkie wyniki, nie tylko istotne.
- Dla zmiennych logarytmowanych dodac kolumny:
  - estymata na skali log,
  - CI na skali log,
  - iloraz po eksponentacji,
  - CI ilorazu.

### Kryteria gotowosci

- Tabela zbiorcza zawiera `p_grupa`, `p_czas`, `p_interakcja`, `n_obs`, `n_osob`, skale analizy i status modelu.
- Tabele post hoc sa kompletne, rozdzielone wedlug rodzin porownan i maja korekte Holma.
- Wyniki da sie bezposrednio wykorzystac w raporcie publikacyjnym.

## Etap 5: Raport jednostkowy dla zmiennej

### Zadania

- Przygotowac nowy szablon raportu jednostkowego LMM zamiast adaptowac stary raport RM-ANOVA.
- Raport powinien zawierac:
  - opis zmiennej i transformacji,
  - liczbe obserwacji oraz liczbe osob,
  - kompletność danych w ukladzie grupa x czas,
  - statystyki opisowe na danych uzytych w modelu,
  - tabele LRT,
  - tabele EMM,
  - tabele post hoc,
  - diagnostyke reszt,
  - wykres surowych trajektorii,
  - wykres srednich modelowych.
- Wyraznie oznaczyc, ze RM-ANOVA nie jest juz analiza glowna.

### Kryteria gotowosci

- Jeden raport HTML dla jednej zmiennej mozna zrenderowac parametrem `var`.
- Raport nie filtruje danych do kompletnych przypadkow.
- Wnioski tekstowe sa generowane z wynikow LMM, nie z `anova_test()`.

## Etap 6: Batch i eksport wynikow

### Zadania

- Przepiac `2025-11/obliczenia_zbiorcze.Rmd` na nowy szablon/pipeline LMM.
- Usunac zaleznosc od niezdefiniowanych obiektow takich jak `col_list`.
- Zmienic dobor zmiennych na centralny slownik.
- Eksportowac wyniki do jednego skoroszytu Excel:
  - mapa transformacji,
  - opisowki,
  - LMM omnibus,
  - EMM,
  - post hoc,
  - diagnostyka/status modeli,
  - log bledow i ostrzezen.
- Opcjonalnie wygenerowac indeks HTML z linkami do raportow jednostkowych.

### Kryteria gotowosci

- Jedno uruchomienie batch generuje wszystkie raporty i zbiorczy Excel.
- Wyniki batch sa deterministyczne i nie wymagaja recznych zmian sciezek.
- W katalogu wynikowym nie mieszaja sie raporty RM-ANOVA z raportami LMM.

## Etap 7: Walidacja przeciwko raportowi `.docx`

### Zadania

- Dla kazdej zmiennej porownac z raportem:
  - liczbe obserwacji,
  - liczbe osob,
  - zastosowana skale,
  - `p_grupa`,
  - `p_czas`,
  - `p_interakcja`,
  - liste istotnych post hoc.
- Rozbieznosci sklasyfikowac jako:
  - inny plik danych,
  - inna identyfikacja osoby,
  - inna transformacja,
  - inna metoda testowania,
  - blad w pipeline.
- Zapisac raport walidacyjny w `dokumentacja/` albo `wyniki_robocze/`.

### Kryteria gotowosci

- Wiadomo, czy repo odtwarza wyniki z dokumentu.
- Kazda rozbieznosc ma wyjasnienie.
- Finalny raport metodyczny mozna powiazac z konkretnym commitem i konkretnym plikiem danych.

## Etap 8: Porzadki w repo

### Zadania

- Oznaczyc stare szablony RM-ANOVA jako archiwalne lub referencyjne.
- Zaktualizowac `readme.md`, zeby wskazywal nowy glowny workflow.
- Zaktualizowac `dokumentacja/ANOVA_manual.md` albo dodac osobny manual `LMM_manual.md`.
- Dopisac minimalna instrukcje uruchomienia:

```r
rmarkdown::render("2025-11/obliczenia_zbiorcze_LMM.Rmd")
```

- Dodac informacje o wymaganych pakietach R i wersji R.

### Kryteria gotowosci

- Nowa osoba otwierajaca repo wie, ktory plik uruchomic.
- Stare wyniki nie wygladaja jak aktualny workflow.
- Dokumentacja i kod opisuja te sama metode.

## Etap 9: Kontrola jakosci

### Zadania

- Dodac szybki test smoke:
  - wczytanie danych,
  - analiza jednej zmiennej surowej,
  - analiza jednej zmiennej logarytmowanej,
  - zapis wynikow.
- Dodac walidacje liczby poziomow czynnikow.
- Dodac walidacje, ze kazdy uczestnik nalezy tylko do jednej grupy.
- Dodac walidacje, ze dla jednej osoby nie ma duplikatu pomiaru w tym samym czasie.
- Zachowac `sessionInfo()` albo `renv.lock` dla odtwarzalnosci.

### Kryteria gotowosci

- Przed publikacyjnym uruchomieniem da sie wykonac szybki test integralnosci.
- Pipeline konczy sie bledem przy powaznym problemie danych, zamiast cicho generowac bledne wyniki.

## Proponowana kolejnosc prac

1. Ustalic finalny plik danych i identyfikator uczestnika.
2. Ukompletnic slownik zmiennych i mape transformacji.
3. Naprawic `lmm_pipeline_2025_11.R`, tak aby dzialal w czystej sesji.
4. Zbudowac nowy raport jednostkowy LMM.
5. Przepiac batch na LMM.
6. Wygenerowac pelne wyniki i skoroszyt Excel.
7. Porownac wyniki z raportem `.docx`.
8. Zaktualizowac dokumentacje i oznaczyc stare szablony jako archiwalne.

## Minimalny wariant wdrozenia

Jesli trzeba szybko przejsc na metode LMM, minimalny zakres to:

- naprawic `lmm_pipeline_2025_11.R`,
- dodac pelna mape transformacji,
- przygotowac jeden batch generujacy zbiorcza tabele LMM i post hoc,
- porownac liczebnosci oraz p-value z raportem `.docx`,
- dopiero potem regenerowac pelne raporty HTML.

## Ryzyka

- Brak finalnego pliku danych z raportu moze uniemozliwic dokladne odtworzenie wynikow.
- Budowa `ID_uczestnika` z imienia/nazwiska/grupy jest krucha i moze tworzyc bledy przy literowkach.
- Wyniki RM-ANOVA i LMM moga sie roznic, zwlaszcza przy brakach danych.
- Przy wielu zmiennych trzeba jasno rozdzielic korekte Holma dla post hoc od ewentualnej korekty FDR/BH dla efektow omnibus miedzy zmiennymi.
- Modele z samym losowym interceptem moga byc za proste dla niektorych zmiennych, ale sa rozsadnym i stabilnym punktem wyjscia przy malej probie.

## Definicja zakonczenia prac

Przejscie na pelna metode LMM mozna uznac za zakonczone, gdy:

- repo ma jeden wskazany workflow LMM,
- batch generuje komplet wynikow bez recznych poprawek,
- wyniki sa eksportowane do jednego skoroszytu,
- raporty jednostkowe nie uzywaja kompletnych przypadkow jako podstawy analizy glownej,
- dokumentacja opisuje te sama metode, ktora wykonuje kod,
- rozbieznosci wzgledem `Raport_LMM_metody_i_wyniki.docx` sa wyjasnione.
