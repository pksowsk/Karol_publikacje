# Manual metody LMM dla ukladu 3 grupy x 4 pomiary

> **Cel dokumentu:** opisac metode, ktora jest obecnie glownym workflow analitycznym w repo: liniowe modele mieszane dla ukladu `3 grupy x 4 pomiary`, z transformacjami, testami LRT, srednimi modelowymi `emmeans`, korekta Holma i eksportem wynikow do Excela. Manual laczy uzasadnienie teoretyczne z praktyczna instrukcja uruchamiania i modyfikowania obliczen.

## 1. Kiedy stosujemy te metode

Metoda jest przeznaczona dla danych, w ktorych:

- te same osoby sa mierzone wielokrotnie,
- kazda osoba nalezy do jednej z trzech grup interwencji,
- mamy cztery punkty czasowe,
- dla czesci osob lub zmiennych moga wystepowac braki danych,
- interesuje nas, czy przebieg zmian w czasie rozni sie miedzy grupami.

W tym projekcie czynniki sa kodowane jako:

- `interwencja`: `Aerobowa`, `Silowa`, `Kontrolna`,
- `czas`: `T1`, `T2`, `T3`, `T4`,
- `id_osoby`: stabilny identyfikator uczestnika.

Glowny model dla kazdej zmiennej ma postac:

```r
value_model ~ interwencja * czas + (1 | id_osoby)
```

gdzie `value_model` oznacza wartosc analizowana na skali surowej albo po transformacji `ln(y)`.

## 2. Dlaczego LMM, a nie klasyczna RM-ANOVA

Klasyczna ANOVA z powtarzanym pomiarem jest naturalna dla ukladow typu grupa x czas, ale ma wazne ograniczenie praktyczne: zwykle wymaga kompletnych przypadkow. Przy czterech pomiarach oznacza to, ze osoba z jednym brakujacym pomiarem moze wypasc z analizy danej zmiennej w calosci.

LMM, czyli liniowy model mieszany, wykorzystuje wszystkie obserwacje niebrakujace dla analizowanej zmiennej. Osoba z pomiarami `T1`, `T2` i `T4`, ale bez `T3`, nadal moze wniesc informacje do modelu. To jest szczegolnie wazne w danych biomedycznych i interwencyjnych, gdzie braki sa czeste.

Model mieszany robi dwie rzeczy naraz:

- modeluje sredni efekt grupy, czasu i interakcji jako efekty stale,
- uwzglednia zaleznosc pomiarow wewnatrz tej samej osoby przez losowy wyraz wolny `(1 | id_osoby)`.

Losowy wyraz wolny oznacza, ze kazda osoba moze miec wlasny poziom bazowy. Model nie zaklada wiec, ze wszyscy uczestnicy startuja z tego samego miejsca.

## 3. Pytania badawcze i efekty w modelu

Model:

```r
value_model ~ interwencja * czas + (1 | id_osoby)
```

odpowiada na trzy glowne pytania.

**Efekt grupy:** czy sredni poziom zmiennej rozni sie miedzy grupami, po uwzglednieniu czasu?

**Efekt czasu:** czy sredni poziom zmiennej zmienia sie miedzy punktami `T1`-`T4`, po uwzglednieniu grup?

**Interakcja grupa x czas:** czy wzorzec zmiany w czasie rozni sie miedzy grupami?

Najwazniejsza interpretacyjnie jest zwykle interakcja. Jesli interakcja jest istotna, nie wystarcza powiedziec, ze "czas jest istotny" albo "grupy sie roznia". Trzeba sprawdzic porownania proste, czyli np. ktore grupy roznia sie w konkretnym czasie albo w ktorej grupie zmiana miedzy punktami czasu jest istotna.

## 4. Struktura plikow w repo

Glowny workflow sklada sie z trzech plikow:

- `szablony_analiz/anova_rm/3gr_4pomiary/lmm_pipeline_2025_11.R`  
  Centralny pipeline z funkcjami do wczytania danych, transformacji, modelowania, diagnostyki, post hoc i eksportu.

- `szablony_analiz/anova_rm/3gr_4pomiary/raport_lmm_2025_11.Rmd`  
  Raport HTML dla jednej zmiennej.

- `2025-11/obliczenia_zbiorcze_LMM.Rmd`  
  Batch, ktory uruchamia analizy dla wszystkich zmiennych i zapisuje skoroszyt Excel.

Domyslny plik danych:

```r
Dane/2025_11_23_publikacja.xlsx
```

Domyslny katalog wynikow:

```r
2025-11/raporty_batch/raporty_lmm/
```

Domyslny skoroszyt wynikowy:

```r
2025-11/raporty_batch/raporty_lmm/wyniki_lmm_2025_11.xlsx
```

## 5. Wymagane pakiety R

Pipeline sprawdza obecność pakietow przy `source()`. Wymagane pakiety sa zapisane w `required_packages_2025_11`:

```r
c(
  "dplyr",
  "tidyr",
  "tibble",
  "stringr",
  "magrittr",
  "openxlsx",
  "janitor",
  "lme4",
  "emmeans",
  "ggplot2",
  "patchwork"
)
```

Jesli ktoregos pakietu brakuje, pipeline zatrzyma sie z komunikatem. Instalacja:

```r
install.packages(c(
  "dplyr", "tidyr", "tibble", "stringr", "magrittr",
  "openxlsx", "janitor", "lme4", "emmeans", "ggplot2", "patchwork"
))
```

## 6. Przygotowanie danych

Dane powinny byc w formacie dlugim: jeden wiersz to jedna osoba w jednym punkcie czasu.

Minimalnie potrzebne informacje:

- identyfikator osoby,
- grupa/interwencja,
- punkt czasu,
- zmienne numeryczne do analizy.

Pipeline probuje rozpoznac kolumny automatycznie.

Dla czasu szuka kolejno:

```r
c("id_pomiaru", "czas", "pomiar", "time")
```

Dla grupy szuka kolejno:

```r
c("id_grupy", "grupa", "interwencja", "group")
```

Dla osoby szuka m.in.:

```r
c("id_uczestnika", "uczestnik_id", "id_badanej", "id_badanego", "participant_id")
```

Jesli nie ma jawnego ID uczestnika, pipeline moze zbudowac `id_osoby` z kolumn `nazwisko`, `imie` i grupy. To jest rozwiazanie praktyczne, ale w finalnych danych publikacyjnych lepiej miec osobna, stabilna kolumne identyfikatora uczestnika.

Wczytanie danych:

```r
source("szablony_analiz/anova_rm/3gr_4pomiary/lmm_pipeline_2025_11.R")

df <- load_2025_11_data(
  path = "Dane/2025_11_23_publikacja.xlsx",
  sheet = 1
)
```

Funkcja `load_2025_11_data()` wykonuje:

- wczytanie Excela przez `openxlsx::read.xlsx()`,
- czyszczenie nazw kolumn przez `janitor::clean_names()`,
- normalizacje grup do `Aerobowa`, `Silowa`, `Kontrolna`,
- normalizacje czasu do `T1`, `T2`, `T3`, `T4`,
- utworzenie lub rozpoznanie `id_osoby`,
- walidacje duplikatow osoba-czas,
- walidacje, czy jedna osoba nie wystepuje w wielu grupach.

## 7. Slownik zmiennych i transformacje

Centralny slownik znajduje sie w obiekcie:

```r
analysis_dictionary_2025_11
```

Kazdy wiersz opisuje jedna zmienna:

- `variable`: nazwa kolumny po oczyszczeniu przez `janitor::clean_names()`,
- `label`: nazwa do raportu,
- `unit`: jednostka,
- `transform`: `raw` albo `log`,
- `transform_note`: uzasadnienie decyzji.

Przyklad wpisu:

```r
"homa_b", "HOMA-B", NA_character_, "log",
"Skala ln(y) zgodna z ustalona mapa transformacji."
```

### Regula transformacji

W podejsciu opisanym dla tego projektu transformacja logarytmiczna ma sens, gdy:

- zmienna jest dodatnia,
- rozklad na skali surowej jest wyraznie prawostronnie skosny,
- logarytmowanie zmniejsza bezwzgledna skosnosc,
- transformacja ma sens dziedzinowy.

Pipeline uzywa naturalnego logarytmu:

```r
log(y)
```

Nie jest to `log10`. Interpretacja wynikow po eksponentacji jest wtedy multiplikatywna: roznice na skali log staja sie ilorazami na skali oryginalnej.

Audyt transformacji:

```r
audit <- build_transform_audit_2025_11(df)
audit
```

Tabela audytu zawiera:

- `all_positive`: czy wszystkie obserwacje sa dodatnie,
- `skew_raw`: skosnosc na skali surowej,
- `skew_log`: skosnosc po `ln(y)`,
- `suggested_transform`: sugestia automatyczna,
- `dictionary_transform`: decyzja ze slownika,
- `transform_mismatch`: czy sugestia rozni sie od decyzji slownikowej.

Wazne: audyt nie zmienia automatycznie modelu. Model korzysta ze slownika. Jesli audyt wskazuje rozbieznosc, trzeba podjac decyzje metodologiczna i zmienic slownik.

## 8. Jak pipeline wybiera zmienne do batcha

Domyslna lista zmiennych jest tworzona przez:

```r
variables <- get_batch_variables_2025_11(df)
```

Funkcja wybiera kolumny numeryczne i wyklucza kolumny techniczne:

```r
c("id_grupy", "id_osoby", "id_pomiaru", "nazwisko", "imie", "wysokosc_cm")
```

Kolejnosc zmiennych jest brana najpierw ze slownika `analysis_dictionary_2025_11`, a dopiero potem dodawane sa ewentualne pozostale kolumny numeryczne.

Jesli chcesz uruchomic tylko wybrane zmienne:

```r
batch <- run_lmm_batch_2025_11(
  data_path = "Dane/2025_11_23_publikacja.xlsx",
  variables = c("homa_b", "fat_bh", "skurczowe"),
  sheet = 1
)
```

## 9. Obliczenia dla jednej zmiennej

Najprostsze uruchomienie:

```r
source("szablony_analiz/anova_rm/3gr_4pomiary/lmm_pipeline_2025_11.R")

analysis <- run_lmm_analysis_2025_11(
  var = "homa_b",
  data_path = "Dane/2025_11_23_publikacja.xlsx",
  sheet = 1
)
```

Obiekt `analysis` zawiera:

- `meta`: opis zmiennej i transformacji,
- `data`: pelne dane po normalizacji,
- `analysis_df`: obserwacje uzyte w modelu,
- `sample_summary`: liczba obserwacji, osob kompletnych i niekompletnych,
- `completeness`: kompletnosc w komorkach grupa x czas,
- `descriptives`: statystyki opisowe,
- `fits`: dopasowane modele LMM,
- `omnibus`: testy LRT dla grupy, czasu i interakcji,
- `posthoc`: porownania `emmeans`,
- `model_means`: srednie modelowe,
- `diagnostics`: diagnostyka,
- `plots`: wykresy.

Przyklady odczytu wynikow:

```r
analysis$omnibus
analysis$model_means
analysis$posthoc$tables
analysis$diagnostics$status
```

Raport HTML dla jednej zmiennej:

```r
rmarkdown::render(
  input = "szablony_analiz/anova_rm/3gr_4pomiary/raport_lmm_2025_11.Rmd",
  params = list(
    variable = "homa_b",
    data_path = "Dane/2025_11_23_publikacja.xlsx",
    sheet = 1
  )
)
```

## 10. Obliczenia zbiorcze

Najwazniejsze polecenie dla calego workflow:

```r
rmarkdown::render("2025-11/obliczenia_zbiorcze_LMM.Rmd")
```

Domyslnie raport batch:

- wczyta dane,
- wybierze zmienne numeryczne,
- wykona audyt transformacji,
- uruchomi LMM dla kazdej zmiennej,
- zapisze skoroszyt Excel,
- wyswietli podsumowanie p-value i bledow.

Mozna tez uruchomic batch bez RMarkdown:

```r
source("szablony_analiz/anova_rm/3gr_4pomiary/lmm_pipeline_2025_11.R")

batch <- run_lmm_batch_2025_11(
  data_path = "Dane/2025_11_23_publikacja.xlsx",
  variables = NULL,
  sheet = 1,
  output_dir = "2025-11/raporty_batch/raporty_lmm",
  workbook_name = "wyniki_lmm_2025_11.xlsx",
  write_workbook = TRUE
)
```

Jesli chcesz wygenerowac raporty HTML dla kazdej zmiennej, ustaw parametr:

```r
rmarkdown::render(
  "2025-11/obliczenia_zbiorcze_LMM.Rmd",
  params = list(render_reports = TRUE)
)
```

## 11. Modele zagniezdzone i testy omnibus

Pipeline dopasowuje cztery modele:

Model pelny:

```r
value_model ~ interwencja * czas + (1 | id_osoby)
```

Model addytywny, bez interakcji:

```r
value_model ~ interwencja + czas + (1 | id_osoby)
```

Model bez czasu:

```r
value_model ~ interwencja + (1 | id_osoby)
```

Model bez grupy:

```r
value_model ~ czas + (1 | id_osoby)
```

Wszystkie modele sa estymowane przez ML:

```r
REML = FALSE
```

To jest wazne, bo porownywanie modeli o roznych efektach stalych przez LRT powinno byc robione na modelach ML, nie REML.

Testy omnibus sa liczone jako porownania modeli zagniezdzonych:

| Efekt | Porownanie | Sens testu |
| --- | --- | --- |
| Grupa | `no_group` vs `additive` | czy dodanie grupy poprawia model ponad czas |
| Czas | `no_time` vs `additive` | czy dodanie czasu poprawia model ponad grupe |
| Grupa x czas | `additive` vs `full` | czy interakcja poprawia model ponad efekty glowne |

Wyniki sa zapisane w `analysis$omnibus` i w arkuszu `omnibus`.

Kolumny:

- `effect_key`: techniczny identyfikator efektu,
- `efekt`: etykieta efektu,
- `chisq`: statystyka testu LRT,
- `df`: roznica liczby parametrow,
- `p_value`: p-value,
- `istotny`: `tak` albo `nie` dla progu 0.05.

## 12. Porownania post hoc

Porownania post hoc sa oparte na `emmeans`, czyli srednich marginalnych estymowanych z modelu.

Strategia zalezy od wyniku omnibus.

Jesli interakcja `grupa x czas` jest istotna:

```r
emmeans(fits$full, ~ interwencja | czas)
emmeans(fits$full, ~ czas | interwencja)
```

Wtedy raportowane sa:

- roznice miedzy grupami w kazdym punkcie czasu,
- roznice miedzy czasami w kazdej grupie.

Jesli interakcja nie jest istotna, pipeline sprawdza efekty glowne:

```r
emmeans(fits$additive, ~ interwencja)
emmeans(fits$additive, ~ czas)
```

Wtedy raportowane sa tylko porownania dla istotnych efektow glownych.

Korekta wielokrotnosci:

```r
adjust = "holm"
```

Korekta Holma jest mniej konserwatywna niz Bonferroni, ale nadal kontroluje rodzinny blad I rodzaju. Korekta jest stosowana w ramach danej rodziny porownan, np. oddzielnie dla "grupy w obrebie czasu" i "czas w obrebie grupy".

## 13. Interpretacja skali surowej i logarytmicznej

Dla zmiennych bez transformacji:

- estymaty post hoc sa roznicami srednich,
- `estimate_response` oznacza te sama roznice,
- interpretacja jest addytywna.

Przyklad:

```text
estimate_response = -2.4
```

oznacza, ze pierwsza grupa ma srednio o 2.4 jednostki mniej niz druga.

Dla zmiennych logarytmowanych:

- model jest dopasowany do `ln(y)`,
- roznice na skali modelu sa roznicami logarytmow,
- po eksponentacji staja sie ilorazami.

Przyklad:

```text
estimate = -0.223
estimate_response = exp(-0.223) = 0.80
```

oznacza, ze pierwsza srednia geometryczna wynosi okolo 80% drugiej, czyli jest nizsza o okolo 20%.

Dla srednich modelowych:

- `emmean` to srednia na skali modelu,
- `mean_display` to wartosc do czytania na skali oryginalnej,
- dla `log` jest to `exp(emmean)`, czyli estymowana srednia geometryczna.

## 14. Statystyki opisowe

Statystyki opisowe sa liczone przez:

```r
build_raw_descriptives_2025_11(df, var)
```

Sa zawsze liczone na skali surowej i na obserwacjach niebrakujacych dla danej zmiennej.

Tabela zawiera:

- `interwencja`,
- `czas`,
- `n`,
- `srednia`,
- `sd`,
- `mediana`,
- `q1`,
- `q3`.

Wazne: statystyki opisowe i srednie modelowe nie musza byc identyczne. Opisowki sa prostym podsumowaniem danych surowych. Srednie modelowe pochodza z LMM i uwzgledniaja strukture modelu.

## 15. Diagnostyka modelu

Diagnostyka jest zapisana w:

```r
analysis$diagnostics
```

Pipeline sprawdza:

- czy model jest osobliwy przez `lme4::isSingular()`,
- czy optymalizator zwrocil komunikaty konwergencji,
- test Shapiro-Wilka dla reszt, jesli liczba reszt miesci sie w dopuszczalnym zakresie testu,
- wykres Q-Q reszt,
- wykres reszty vs wartosci dopasowane.

Interpretacja:

- `singular = TRUE` oznacza, ze struktura efektow losowych moze byc zbyt zlozona albo wariancja losowego efektu jest bliska zeru,
- komunikat konwergencji wymaga sprawdzenia, czy wynik jest stabilny,
- niski p-value Shapiro-Wilka sugeruje odchylenie od normalnosci reszt, ale przy wiekszych probach test jest bardzo czuly,
- Q-Q plot i reszty vs dopasowanie sa zwykle wazniejsze niz sam test formalny.

W obecnym modelu efekt losowy jest prosty: `(1 | id_osoby)`. Jesli nawet taki model jest osobliwy, najpierw sprawdzamy dane, liczebnosci i zmiennosc zmiennej.

## 16. Zawartosc skoroszytu Excel

Batch zapisuje plik:

```r
wyniki_lmm_2025_11.xlsx
```

Arkusze:

- `summary`: jeden wiersz na zmienna, najwazniejsze p-value i status modelu,
- `omnibus`: pelne testy LRT dla kazdej zmiennej,
- `descriptives`: statystyki opisowe w ukladzie grupa x czas,
- `completeness`: liczba obserwacji i brakow w kazdej komorce,
- `model_means`: srednie modelowe EMM,
- `posthoc`: wszystkie wygenerowane porownania post hoc,
- `transform_audit`: audyt skosnosci i decyzji transformacyjnych,
- `errors`: zmienne, dla ktorych analiza sie nie udala.

Najpierw warto czytac `summary`, potem `omnibus`, a dopiero pozniej `posthoc` i raporty jednostkowe dla wybranych zmiennych.

## 17. Jak czytac wyniki krok po kroku

Dla kazdej zmiennej:

1. Sprawdz `summary`.
   - Czy `status` to `success`?
   - Czy byly ostrzezenia w `warnings`?
   - Czy model jest osobliwy (`singular`)?

2. Sprawdz skale.
   - `transform = raw` oznacza analize na skali surowej.
   - `transform = log` oznacza analize na `ln(y)`.

3. Sprawdz interakcje.
   - Jesli `p_interaction < 0.05`, interpretuj glownie porownania proste.
   - Jesli `p_interaction >= 0.05`, przejdz do efektow glownych.

4. Sprawdz `posthoc`.
   - Dla interakcji szukaj rodzin `Grupy w obrebie czasu` i `Czas w obrebie grupy`.
   - Dla efektow glownych szukaj `Efekt glowny grupy` albo `Efekt glowny czasu`.

5. Sprawdz `model_means`.
   - Dla publikacji zwykle czytelniejsze sa `mean_display`, `lower_display`, `upper_display`.

6. Sprawdz opisowki i wykresy.
   - Czy kierunek efektu ma sens?
   - Czy wynik nie jest napedzany przez pojedyncze obserwacje?
   - Czy komorki maja wystarczajaca liczbe obserwacji?

## 18. Jak modyfikowac workflow

### Zmiana pliku danych

W RMarkdown batch zmien parametr:

```yaml
params:
  data_path: "Dane/nowy_plik.xlsx"
  sheet: 1
```

Albo w wywolaniu:

```r
rmarkdown::render(
  "2025-11/obliczenia_zbiorcze_LMM.Rmd",
  params = list(data_path = "Dane/nowy_plik.xlsx", sheet = 1)
)
```

### Zmiana listy analizowanych zmiennych

Najbezpieczniej podac liste jawnie:

```r
run_lmm_batch_2025_11(
  data_path = "Dane/2025_11_23_publikacja.xlsx",
  variables = c("homa_b", "fat_bh", "crp_mg_l")
)
```

Mozna tez zmienic `get_batch_variables_2025_11()`, jesli chcesz globalnie zmienic regule wyboru kolumn.

### Dodanie nowej zmiennej do slownika

W `analysis_dictionary_2025_11` dodaj wiersz:

```r
"nowa_zmienna", "Nazwa publikacyjna", "jednostka", "raw", "Analiza na skali surowej."
```

albo:

```r
"nowa_zmienna", "Nazwa publikacyjna", "jednostka", "log", "Skala ln(y), zmienna dodatnia i skosna."
```

Po zmianie uruchom:

```r
df <- load_2025_11_data("Dane/2025_11_23_publikacja.xlsx")
build_transform_audit_2025_11(df)
```

### Zmiana transformacji

Zmien kolumne `transform` w slowniku z `raw` na `log` albo odwrotnie.

Przed ustawieniem `log` sprawdz:

```r
all(df$nowa_zmienna > 0, na.rm = TRUE)
skewness_2025_11(df$nowa_zmienna)
skewness_2025_11(log(df$nowa_zmienna))
```

Jesli zmienna zawiera zera albo wartosci ujemne, obecny pipeline zatrzyma analize. Nie dodawaj stalej typu `+1` automatycznie bez uzasadnienia dziedzinowego, bo zmienia to interpretacje wynikow.

### Zmiana kodowania grup

Mapowanie grup jest w funkcji:

```r
normalise_group_2025_11()
```

Jesli w nowym pliku grupy sa zakodowane inaczej, dodaj odpowiednie warianty do `case_when()`.

Przyklad:

```r
x_chr %in% c("a", "aero", "aerobic") ~ "Aerobowa"
```

Po zmianie sprawdz:

```r
table(df$interwencja, useNA = "ifany")
```

### Zmiana kodowania czasu

Mapowanie czasu jest w funkcji:

```r
normalise_time_2025_11()
```

Jesli nowe dane maja np. `baseline`, `week_6`, `week_12`, `followup`, trzeba dopisac te nazwy do mapowania.

Po zmianie sprawdz:

```r
table(df$czas, useNA = "ifany")
```

### Zmiana korekty post hoc

Korekta jest ustawiona w `tidy_pairs_2025_11()`:

```r
emmeans::contrast(emm_grid, method = "pairwise", adjust = "holm")
```

Mozliwe alternatywy:

- `"bonferroni"`: bardziej konserwatywna,
- `"tukey"`: czesto stosowana dla wszystkich par grup,
- `"fdr"`: kontrola false discovery rate, mniej konserwatywna, ale odpowiada na inne pytanie.

Zmiana korekty powinna byc opisana w metodach publikacji.

### Zmiana progu istotnosci

Prog `0.05` jest obecnie zaszyty w:

- `build_omnibus_table_2025_11()`,
- `build_posthoc_tables_2025_11()`,
- `build_result_summary_2025_11()`.

Jesli chcesz miec inny prog, warto dodac argument `alpha = 0.05` do tych funkcji zamiast zmieniac liczbe w wielu miejscach.

### Zmiana struktury modelu

Obecny model:

```r
value_model ~ interwencja * czas + (1 | id_osoby)
```

Mozliwe rozszerzenie:

```r
value_model ~ interwencja * czas + (czas | id_osoby)
```

Taki model pozwala osobom roznic sie nie tylko poziomem bazowym, ale tez przebiegiem zmian w czasie. W praktyce przy malej probie i czterech punktach czasu moze byc niestabilny albo osobliwy. Dlatego obecny model z losowym interceptem jest konserwatywnym, sensownym wyborem startowym.

Jesli zmieniasz strukture modelu, trzeba zmienic wszystkie modele zagniezdzone w `fit_lmm_models_2025_11()`, nie tylko model pelny. Modele porownywane LRT musza miec spojna strukture efektow losowych.

### Dodanie wspolzmiennych

Przyklad modelu z wiekiem:

```r
value_model ~ wiek + interwencja * czas + (1 | id_osoby)
```

Wtedy modele zagniezdzone powinny zachowywac `wiek` w kazdym porownaniu:

```r
full:      value_model ~ wiek + interwencja * czas + (1 | id_osoby)
additive:  value_model ~ wiek + interwencja + czas + (1 | id_osoby)
no_time:   value_model ~ wiek + interwencja + (1 | id_osoby)
no_group:  value_model ~ wiek + czas + (1 | id_osoby)
```

Nie wolno porownywac modelu z wiekiem do modelu bez wieku, jesli pytanie dotyczy efektu grupy, czasu albo interakcji.

## 19. Kontrola jakosci i sanity checks

Po kazdej wiekszej zmianie wykonaj:

```r
source("szablony_analiz/anova_rm/3gr_4pomiary/lmm_pipeline_2025_11.R")
```

Sprawdz wczytanie danych:

```r
df <- load_2025_11_data("Dane/2025_11_23_publikacja.xlsx")
table(df$interwencja, df$czas)
```

Sprawdz audyt transformacji:

```r
build_transform_audit_2025_11(df)
```

Sprawdz jedna zmienna surowa i jedna logarytmowana:

```r
run_lmm_analysis_2025_11("fat_bh", "Dane/2025_11_23_publikacja.xlsx")
run_lmm_analysis_2025_11("homa_b", "Dane/2025_11_23_publikacja.xlsx")
```

Uruchom batch:

```r
rmarkdown::render("2025-11/obliczenia_zbiorcze_LMM.Rmd")
```

W skoroszycie sprawdz:

- czy `summary$status` wszedzie ma `success`,
- czy `errors` jest pusty,
- czy `transform_audit` nie pokazuje nierozwiazanych rozbieznosci,
- czy modele z `singular = TRUE` nie dominuja wynikow,
- czy liczebnosci w `completeness` zgadzaja sie z oczekiwaniami.

## 20. Najczestsze problemy

**Problem:** `Nie znaleziono pliku`.

Rozwiazanie: sprawdz sciezke w `params$data_path`. Funkcja `resolve_existing_path_2025_11()` szuka w kilku katalogach wzglednych, ale finalnie plik musi istniec.

**Problem:** `W danych sa duplikaty dla tej samej osoby i punktu czasu`.

Rozwiazanie: sprawdz, czy `id_osoby` jest rzeczywistym identyfikatorem uczestnika, a nie np. kodem grupy. Dla jednej osoby i jednego czasu powinien byc tylko jeden wiersz.

**Problem:** `Co najmniej jeden uczestnik wystepuje w wiecej niz jednej grupie`.

Rozwiazanie: sprawdz budowe `id_osoby`. Taka sytuacja moze znaczyc blad danych albo za malo precyzyjny identyfikator.

**Problem:** `Transformacja logarytmiczna wymaga dodatnich obserwacji`.

Rozwiazanie: sprawdz zera i wartosci ujemne. Decyzja moze wymagac korekty danych, zmiany transformacji albo uzasadnionego modelu alternatywnego.

**Problem:** model ma ostrzezenie konwergencji.

Rozwiazanie: sprawdz liczebnosci, wykresy, zmiennosc zmiennej i status `singular`. Jesli problem dotyczy pojedynczej zmiennej, nie interpretuj jej mechanicznie bez diagnostyki.

**Problem:** `transform_mismatch = TRUE`.

Rozwiazanie: to nie jest blad techniczny. To sygnal, ze automatyczna regula skosnosci sugeruje inna transformacje niz slownik. Trzeba zdecydowac, czy wazniejsza jest spojnosc z raportem, czy aktualny audyt danych.

## 21. Jak opisac metode w publikacji

Przykladowy opis:

```text
Dane analizowano za pomoca liniowych modeli mieszanych. Dla kazdej zmiennej dopasowano model z efektami stalymi grupy, czasu oraz interakcji grupa x czas, a takze losowym wyrazem wolnym dla uczestnika: y ~ grupa * czas + (1 | uczestnik). Modele estymowano metoda najwiekszej wiarygodnosci (ML). Efekty omnibus oceniano testami ilorazu wiarygodnosci przez porownanie modeli zagniezdzonych. Dla zmiennych dodatnich o rozkladzie prawostronnie skosnym stosowano transformacje logarytmem naturalnym. Porownania post hoc wykonano na srednich marginalnych modelu z wykorzystaniem pakietu emmeans, z korekta Holma dla wielokrotnych porownan.
```

Dla zmiennych logarytmowanych warto dodac:

```text
Dla zmiennych analizowanych na skali logarytmicznej srednie modelowe i przedzialy ufnosci raportowano rowniez po eksponentacji, co pozwala interpretowac wyniki jako srednie geometryczne lub ilorazy srednich geometrycznych.
```

## 22. Co wymaga decyzji metodologicznej przed finalnym raportem

Przed zamknieciem wynikow publikacyjnych trzeba potwierdzic:

- finalny plik danych,
- stabilny identyfikator uczestnika,
- kompletna mape transformacji,
- czy rozbieznosci w `transform_audit` sa akceptowane,
- czy raportujemy tylko p-value, czy dodajemy rowniez rozmiary efektow,
- czy korekta Holma jest stosowana tylko w ramach rodzin post hoc, czy dodatkowo kontrolujemy wielokrotnosc na poziomie wielu zmiennych,
- czy stare wyniki RM-ANOVA maja pozostac jedynie materialem historycznym.

## 23. Minimalna sciezka pracy

Najkrotszy poprawny workflow:

```r
source("szablony_analiz/anova_rm/3gr_4pomiary/lmm_pipeline_2025_11.R")

df <- load_2025_11_data("Dane/2025_11_23_publikacja.xlsx")
build_transform_audit_2025_11(df)

analysis <- run_lmm_analysis_2025_11(
  var = "homa_b",
  data_path = "Dane/2025_11_23_publikacja.xlsx"
)

analysis$omnibus
analysis$model_means
analysis$posthoc$tables

rmarkdown::render("2025-11/obliczenia_zbiorcze_LMM.Rmd")
```

To odtwarza pelny tok: dane, kontrola transformacji, analiza jednej zmiennej, interpretacja i batch dla wszystkich zmiennych.
