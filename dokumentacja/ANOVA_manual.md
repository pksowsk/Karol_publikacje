# Manual użytkownika

> **Cel**: Ten manual wyjaśnia krok po kroku, jak działa przygotowany zestaw notebooków RMarkdown do analizy danych z **dwoma czynnikami**: `interwencja` (międzyosobniczy; 3 grupy) i `czas` (wewnątrzosobniczy; 2 pomiary). Dokument opisuje podstawy teoretyczne, założenia, użyte testy i miary efektu oraz daje praktyczne wskazówki interpretacyjne – tak, aby nawet początkujący mógł poprawnie przeprowadzić analizę i zrozumieć wyniki.

---

## Spis treści

1. [Struktura projektu i plików](#struktura-projektu)
2. [Opis danych i metadanych](#opis-danych)
3. [Przepływ pracy (workflow)](#workflow)
4. [Modele i testy – teoria i praktyka](#modele)

   * 4.1 [Dwuczynnikowa ANOVA z powtarzanym pomiarem (afex)](#anova)
   * 4.2 [Liniowe modele mieszane – LMM](#lmm)
   * 4.3 [Porównania EMM (Estimated Marginal Means)](#emms)
   * 4.4 [ANCOVA jako alternatywa](#ancova)
5. [Założenia, diagnostyka i strategie, gdy są naruszone](#zalozenia)
6. [Miary efektu i ich interpretacja](#efekty)
7. [Wielokrotne porównania i kontrola błędu I rodzaju (FDR)](#fdr)
8. [Wizualizacje i jak je czytać](#wizualizacje)
9. [Jak czytać wyniki raportu jednostkowego](#czytanie-raportu)
10. [Jak czytać zestawienie zbiorcze (index i podsumowanie\_FDR)](#czytanie-zbiorcze)
11. [Szablony zdań do raportowania](#szablony)
12. [Najczęstsze problemy i rozwiązania](#troubleshooting)
13. [Słownik skrótów](#slownik)
14. [Polecana literatura](#literatura)

---

## 1. Struktura projektu i plików <a id="struktura-projektu"></a>

Kluczowe pliki:

* **`00_batch_analiza_biomarkery.Rmd`** – notebook zbiorczy (batch). Uruchamia analizy dla wielu zmiennych, tworzy raporty HTML, zbiera wyniki do CSV/XLSX, liczy FDR i generuje stronę indeksową.
* **`szablon_two_way_interwencja_czas.Rmd`** – raport jednostkowy dla pojedynczej zmiennej. Zawiera pełną analizę: diagnostyka, ANOVA (afex), LMM, EMM, wizualizacje, zapis skrótu wyników.
* **`Dane/2024_10_02_publikacja.xlsx`** – plik z danymi (przykładowy). Można wskazać inny plik przez parametry.
* **`Dane/meta.xlsx`** – metadane zmiennych (etykiety, jednostki, transformacje itd.). Jeśli brak, notebook batch wygeneruje szkic `meta_auto.xlsx`.
* Katalog wyjściowy **`wyniki/`** z podkatalogami:

  * `raporty/` – raporty HTML dla każdej zmiennej,
  * `_summary/` – krótkie CSV z p‑value i efektami,
  * `plots/` – zapis wykresów PNG,
  * pliki zbiorcze: `podsumowanie_FDR.csv`, `podsumowanie_FDR.xlsx`, `index.html`, `sessionInfo.txt`.

> **Wskazówka replikowalności**: zalecane jest użycie `renv` do zamrożenia wersji pakietów R oraz `here::i_am()` w notebookach, co już zostało wprowadzone.

---

## 2. Opis danych i metadanych <a id="opis-danych"></a>

### Minimalny układ kolumn w danych

* `id_osoby` – identyfikator osoby (stały między pomiarami).
* `id_pomiaru` – kod pomiaru (np. 0/1 dla interwencji „trening”, 2/3 dla „trening\_dieta”, 4/5 dla „grupa\_kontrolna”).
* Zmienne biomarkerów i wskaźników (kolumny numeryczne), które będą analizowane.

### Konstruowane czynniki

* `czas` – dwa poziomy: **początek** i **koniec** (within – powtarzany pomiar).
* `interwencja` – trzy poziomy: **trening**, **trening\_dieta**, **grupa\_kontrolna** (between – niezależne grupy).

### Metadane (`meta.xlsx`)

Zalecane kolumny:

* `nazwa_kolumny` – identyczna z nazwą w danych,
* `etykieta` – przyjazna nazwa do wykresów/raportu,
* `jednostka` – np. `ng/mL`, `mmol/L`, `kg`, `%` itp.,
* `transformacja` – `none`, `log10`, `loge` (naturalny log),
* `domena_dodatnia` – `TRUE` jeśli wartości muszą być > 0 (np. biomarkery, stężenia),
* `lod` – opcjonalnie granica oznaczalności (limit of detection).

> **Po co metadane?** Automatyzują podpisy wykresów, dobór transformacji i walidację wartości (np. ostrzeżenie, gdy są wartości ≤ 0 przy wymaganiu dodatniości).

---

## 3. Przepływ pracy (workflow) <a id="workflow"></a>

1. **Przygotuj dane i metadane.** Sprawdź, czy `id_osoby` i `id_pomiaru` są poprawne. Uzupełnij `meta.xlsx`.
2. **Uruchom notebook batch** `00_batch_analiza_biomarkery.Rmd`.

   * Możesz przełączyć `params$parallel` na `TRUE`, aby przyspieszyć renderowanie.
   * Notebook zrenderuje **raport dla każdej zmiennej**, zbierze wyniki do CSV i policzy **FDR**.
3. **Otwórz `wyniki/index.html`.** To strona z linkami do raportów oraz z p‑value i q‑value (FDR) dla każdej zmiennej.
4. **Wejdź w raporty jednostkowe** interesujących zmiennych, aby zobaczyć szczegóły (diagnostyka, wykresy, EMM, d, η²g).
5. **Podejmij decyzje** (wnioski, które efekty są istotne statystycznie i praktycznie) z uwzględnieniem **q‑value (FDR)** i **rozmiarów efektów** z CI.

---

## 4. Modele i testy – teoria i praktyka <a id="modele"></a>

### 4.1 Dwuczynnikowa ANOVA z powtarzanym pomiarem (afex) <a id="anova"></a>

Analiza wariancji (ANOVA) bada, czy średnie różnią się między poziomami czynników. W naszym układzie:

* **Czas** – czynnik **wewnątrzosobniczy** (within-subject): każdy uczestnik ma dwa pomiary – `początek` i `koniec`.
* **Interwencja** – czynnik **międzyosobniczy** (between-subject): uczestnicy należą do jednej z trzech grup.
* Najważniejsze pytanie: **czy zmiana w czasie zależy od rodzaju interwencji?** – to **interakcja** `interwencja × czas`.

Model w `afex::aov_car`:

```
zmienna ~ interwencja * czas + Error(id_osoby/czas)
```

* Składnik `Error(id_osoby/czas)` modeluje strukturę powtarzanych pomiarów (wariancję osobniczą oraz wariancję zależną od czasu).
* Pakiet **afex** automatycznie raportuje korekcje **GG** (Greenhouse–Geisser) i **HF** (Huynh–Feldt) przy naruszonej **sferyczności** (przy ≥3 poziomach czynnika within). Dla **2 poziomów** sferyczność jest spełniona, ale afex nadal zapewnia spójny reporting.
* Jako miarę efektu raportujemy **η²g** (generalized eta squared) – dobrze porównywalną między projektami złożonymi.

**Interpretacja efektów ANOVA**:

* **Interakcja** istotna → „wzorzec zmiany w czasie różni się między grupami”. Wnioskuj na podstawie porównań warunkowych.
* **Interakcja nieistotna**:

  * **Czas** istotny → „średnio (po grupach) występuje zmiana w czasie”.
  * **Interwencja** istotna → „średnio (po czasach) grupy różnią się między sobą”.

### 4.2 Liniowe modele mieszane – LMM <a id="lmm"></a>

**LMM** rozszerzają klasyczną ANOVA o **efekty losowe**, pozwalając modelować korelację powtórzeń w obrębie osoby i radzić sobie z **brakującymi danymi** (MNAR/MAR – w granicach przyjętych założeń).

Model podstawowy:

```
zmienna ~ interwencja * czas + (1 | id_osoby)
```

* `(1 | id_osoby)` – losowy wyraz wolny dla osób, modeluje różnice poziomu bazowego między osobami.
* Testy istotności oparte są na aproksymacji stopni swobody (np. **Satterthwaite**) zapewnianej przez `lmerTest`.
* Raportujemy tabelę ANOVA **Type III** (ważne przy interpretacji interakcji i efektów głównych).
* Dodatkowo można raportować **R² marginalne i całkowite** (Nakagawa):

  * `R²_marginal` – część wariancji wyjaśniona przez **efekty stałe** (interwencja, czas, interakcja),
  * `R²_conditional` – część wariancji wyjaśniona przez **cały model** (efekty stałe + losowe).

**Zalety LMM** w naszym kontekście:

* elastyczne podejście do braków danych (nie wymagają kompletnych par),
* możliwość rozszerzenia modelu (np. zróżnicowane wariancje, nachylenia losowe `(czas | id_osoby)`),
* lepsze dopasowanie do rzeczywistej struktury korelacji danych.

### 4.3 Porównania EMM (Estimated Marginal Means) <a id="emms"></a>

**EMM (estimated marginal means)** to średnie **predykowane z modelu**, „wycentrowane” względem innych czynników. Dzięki temu porównania są spójne ze zdefiniowanym modelem (ANOVA/LMM).

* Gdy **interakcja istotna**:

  * porównuj **grupy w ramach czasu**: `emmeans(fit, ~ interwencja | czas)` → `pairs(...)`,
  * porównuj **czas w ramach grup**: `emmeans(fit, ~ czas | interwencja)`.
* Gdy **interakcja nieistotna**:

  * porównaj **główny efekt interwencji**: `emmeans(fit, ~ interwencja)`,
  * porównaj **główny efekt czasu**: `emmeans(fit, ~ czas)`.

Wyniki zawierają **różnice średnich**, błędy standardowe, **CI** i skorygowane p‑value (np. Tukey dla wielu porównań między grupami).

### 4.4 ANCOVA jako alternatywa <a id="ancova"></a>

**ANCOVA** dla dwóch pomiarów (początek/koniec) modeluje **wartość końcową** jako funkcję **grupy** i **wartości początkowej**:

```
koniec ~ interwencja + początek
```

* Zmniejsza wariancję błędu, gdy `początek` silnie koreluje z `koniec`.
* Ułatwia interpretację „różnic skorygowanych o wartość bazową”.
* Zalecana jako uzupełnienie, szczególnie gdy są różnice bazowe między grupami.

---

## 5. Założenia, diagnostyka i strategie, gdy są naruszone <a id="zalozenia"></a>

### Główne założenia (modele Gaussa)

1. **Liniowość**: średnie efektów opisuje liniowa kombinacja zmiennych objaśniających.
2. **Niezależność**: reszty niezależne (w LMM – niezależne między osobami; powtarzalność w osobie modelowana przez efekt losowy).
3. **Normalność reszt**: rozkład reszt \~ Normalny(0, σ²).
4. **Jednorodność wariancji**: podobne wariancje w poziomach czynników.
5. **Sferyczność** (dla ≥3 poziomów within): wariancja różnic między poziomami stała. Przy 2 poziomach – spełniona z konstrukcji.

### Diagnostyka w notebooku

* **Shapiro–Wilk na resztach** wstępnego modelu liniowego.
* **Levene** dla jednorodności wariancji.
* **Outliery** per komórka układu (ostrożnie interpretować).
* **QQ‑plot reszt** (wizualna ocena normalności).

### Co zrobić, jeśli założenia są naruszone?

1. **Transformacja** (zgodnie z metadanymi): `log10` lub `loge` często stabilizuje wariancję i normalizuje rozkłady stężeń.
2. **LMM** – bardziej elastyczne niż ANOVA, toleruje braki danych.
3. **Modele odporne** (opcjonalnie do włączenia):

   * **WRS2** – testy odporne na odstające i heterogeniczność wariancji,
   * **ARTool** (aligned rank transform) – testowanie interakcji w układach nienormalnych, porządkujących.
4. **Permutacje** – testy nieparametryczne z permutacjami (np. `permuco`), kosztowne obliczeniowo, ale solidne.
5. **Cenzurowanie / LOD** – gdy część pomiarów < LOD:

   * rozważ **modele Tobita** (cenzurowane),
   * imputacje zależne od LOD (np. LOD/√2) – stosować świadomie.

> **Praktyka**: w większości przypadków po transformacji log i użyciu LMM wnioski są stabilne. Wyniki należy zawsze zestawiać z rozmiarami efektów i CI.

---

## 6. Miary efektu i ich interpretacja <a id="efekty"></a>

### Eta squared (η²) i generalized eta squared (η²g)

* **η² (eta squared)** – część wariancji przypisana do efektu: $\eta^2 = SS_{efekt} / SS_{całkowite}$.
* **η²g (generalized)** – zalecana w projektach mieszanych (within + between) – porównywalna między różnymi układami. Raportowana przez `effectsize::eta_squared(..., partial = FALSE)` na obiekcie z `afex`.
* **Interpretacja (orientacyjna)** – zależy od dziedziny; przykładowo (Cohen): 0.01 mały, 0.06 średni, 0.14 duży. Zawsze podawaj **CI**.

### Cohen’s d

* **d** – znormalizowana różnica średnich. Dla porównań zależnych (paired) używaj odpowiedniej definicji (z uwzględnieniem korelacji). W notebooku wyznaczamy **d** dla zmiany `koniec – początek` w każdej grupie.
* Reguły kciuka (Cohen): 0.2 mały, 0.5 średni, 0.8 duży – **tylko orientacyjnie**. Kluczowy jest **kontekst kliniczny/biologiczny**.

### R² marginalne i całkowite (Nakagawa)

* **R²\_marginal** – wariancja wyjaśniona przez **efekty stałe**.
* **R²\_conditional** – wariancja wyjaśniona przez **cały model** (stałe + losowe).

> **Zalecenie**: zawsze raportuj **efekty z CI** wraz z p‑value/q‑value.

---

## 7. Wielokrotne porównania i FDR <a id="fdr"></a>

Analizując **wiele zmiennych** jednocześnie, rośnie ryzyko fałszywie dodatnich wyników (błąd I rodzaju). Zamiast zaostrzać próg alfa dla każdej zmiennej, stosujemy kontrolę **FDR (False Discovery Rate)** metodą **Benjamini–Hochberg (BH)**.

* Dla każdej zmiennej mamy trzy główne p‑value: `p_interakcja`, `p_czas`, `p_interwencja`.
* Notebook batch tworzy kolumny `q_interakcja`, `q_czas`, `q_interwencja` – to p‑value skorygowane BH w skali **całego zestawu** analizowanych zmiennych.
* **Reguła decyzyjna**: jeżeli `q < 0.05`, uznaj efekt za istotny po korekcji FDR.

> **Ważne**: w raporcie jednostkowym p‑value odnoszą się do danej zmiennej. **Ostateczną istotność** w projekcie wielozmiennowym oceniaj przez odpowiadającą jej **q‑value** z zestawienia zbiorczego.

---

## 8. Wizualizacje i jak je czytać <a id="wizualizacje"></a>

* **Spaghetti plot** – cienkie linie to trajektorie **pojedynczych osób** między `początek` a `koniec`. Grube linie i słupki błędów pokazują **średnie i CI** w grupach. Najlepiej ilustruje **interakcję**.
* **EMM plot** – wartości **średnich marginalnych** z modelu (ANOVA/LMM) z **CI**. Pokazuje oczyszczone średnie (uwzględniające strukturę modelu), ułatwia porównania.
* **QQ‑plot reszt** – ocena zgodności rozkładu reszt z normalnością.

> **Praktyka**: Spaghetti pokazuje „surową” historię uczestników, EMM – „uśrednioną” odpowiedź modelową. Gdy oba przekazy są spójne, wnioski są bardziej wiarygodne.

---

## 9. Jak czytać wyniki raportu jednostkowego <a id="czytanie-raportu"></a>

1. **Nagłówek i parametry** – upewnij się, którą zmienną analizujesz, jaka transformacja została użyta i czy pojawiły się ostrzeżenia (np. wartości ≤ 0 przy wymaganej dodatniości).
2. **Diagnostyka** – sprawdź Levene (wariancje), Shapiro reszt, outliery. Drobne odchylenia zwykle nie zmieniają wniosków; silne naruszenia → rozważ transformacje lub modele odporne.
3. **Tabela ANOVA (afex)** – F, df, p oraz **η²g** z CI. Daje pełny obraz efektów i interakcji.
4. **Tabela LMM (Type III)** – kluczowa dla decyzji o istotności. Zapamiętaj `p` dla **interakcji**, **czasu** i **interwencji**.
5. **EMM i porównania** – jeśli interakcja istotna, czytaj porównania warunkowe (grupy w ramach czasu i/lub czasu w ramach grup). W przeciwnym razie – porównania głównych efektów.
6. **Rozmiary efektów** – sprawdź **η²g** oraz **Cohen’s d** z CI (dla zmian w czasie w każdej grupie). Duże d z wąskimi CI sugeruje silny i precyzyjny efekt.
7. **Wykresy** – czy EMM/CI pokrywają się z trajektoriami? Czy widać rozbieżne trendy między grupami (interakcja)?
8. **Podsumowanie CSV** – na końcu raport zapisuje się wiersz z `p_*` i `ges_*`. Zostanie później skorygowany o FDR w zestawieniu zbiorczym.

---

## 10. Jak czytać zestawienie zbiorcze (index i podsumowanie\_FDR) <a id="czytanie-zbiorcze"></a>

* **`index.html`** – tabela z linkami do raportów i kolumnami: `p_interakcja`, `p_czas`, `p_interwencja`, oraz ich odpowiednikami `q_*` po korekcji BH. Posortowana tak, by najniższe q były na górze.
* **`podsumowanie_FDR.xlsx/csv`** – ten sam zestaw w formie do dalszej obróbki.

**Decydowanie o istotności**:

1. Najpierw spójrz na **`q_interakcja`**. Jeśli `< 0.05`, to zmienna pokazuje różne trajektorie zmian między grupami – **kluczowy wynik**.
2. Jeśli interakcja nieistotna, spójrz na **`q_czas`** (zmiana w czasie, średnio po grupach) oraz **`q_interwencja`** (różnice między grupami, średnio po czasach).
3. Dla zmiennych z małym q sprawdź w raporcie jednostkowym **η²g**, **d** i **CI** – oceniaj znaczenie praktyczne.

---

## 11. Szablony zdań do raportowania <a id="szablony"></a>

### Gdy interakcja istotna

> Zaobserwowano **istotną interakcję** między interwencją a czasem dla *{etykieta}* (LMM Type III: F(df1, df2) = F, p = p\_int, η²g ≈ η, 95% CI \[CI\_low; CI\_high]). Oznacza to, że zmiana w czasie **różniła się** między grupami. Porównania EMM wykazały, że w czasie **początek → koniec** największą zmianę zaobserwowano w grupie **X** (d ≈ d\_X, 95% CI \[..; ..]), podczas gdy w grupie **Y** zmiana była niewielka/nieistotna. Różnice między grupami w **początku/końcu** były \[istotne/nieistotne] po korekcji (Tukey/Bonferroni).

### Gdy interakcja nieistotna, ale czas istotny

> **Interakcja nie była istotna**, natomiast stwierdzono **istotny główny efekt czasu** (LMM Type III: F(df1, df2) = F, p = p\_time, η²g ≈ η). Wskazuje to, że średnio po grupach, poziom *{etykieta}* **zmienił się** między początkiem a końcem. Średnia zmiana była dodatnia/ujemna i wyniosła Δ ≈ \[wartość], co potwierdzają porównania EMM (p\_adj < 0.05).

### Gdy interakcja nieistotna, ale interwencja istotna

> **Interakcja nie była istotna**, jednak wystąpił **istotny główny efekt interwencji** (LMM Type III: F(df1, df2) = F, p = p\_group, η²g ≈ η). Średnio po obu czasach, grupy różniły się wartościami *{etykieta}*. Porównania post‑hoc (Tukey) wskazują, że grupa **X** różni się od **Y** (p\_adj < 0.05), natomiast różnice **X–Z** i **Y–Z** były \[istotne/nieistotne].

### Gdy nic nie jest istotne

> Nie stwierdzono istotnych efektów ani interakcji dla *{etykieta}* (wszystkie p > 0.05, q > 0.05). Wartości efektów (η²g, d) były niewielkie, a przedziały ufności szerokie, co sugeruje brak dowodu na istotne różnice w tym układzie przy obecnej liczebności.

> **Uwaga**: ostateczne wnioskowanie opieraj na **q‑value (FDR)** w zestawieniu zbiorczym oraz na **efektach z CI**.

---

## 12. Najczęstsze problemy i rozwiązania <a id="troubleshooting"></a>

* **Brak metadanych / niepełne metadane**: notebook batch tworzy `meta_auto.xlsx`. Uzupełnij etykiety, jednostki, transformacje i ponów analizę.
* **Wartości ≤ 0 dla zmiennej wymagającej dodatniości**: sprawdź LOD, jednostki, ewentualne błędy w danych. Rozważ transformację log po wcześniejszej korekcie wartości (np. przesunięcie o stałą tylko jeśli uzasadnione).
* **Dużo braków danych**: preferuj interpretację wyników z **LMM**. Zastanów się nad przyczynami braków (mechanizm MAR/MNAR) i ewentualnymi analizami wrażliwości.
* **Silna heterogeniczność wariancji / odstające**: rozważ transformacje, modele odporne (WRS2), ewentualnie zmienne ważone. Odstające obserwacje traktuj indywidualnie – nie usuwaj automatycznie.
* **Sprzeczne wnioski ANOVA vs LMM**: priorytet daj **LMM** (lepszy dla braków i nierównych liczebności). Zweryfikuj diagnostykę i wykresy.
* **Powolne działanie**: włącz `params$parallel = TRUE` (furrr), ogranicz liczbę zmiennych lub wyłącz generowanie PNG.
* **Błędy renderu pojedynczych zmiennych**: sprawdź kolumnę `error` w logach batch. Często winne są nazwy kolumn, brak wartości liczbowych lub literówki w metadanych.

---

## 13. Słownik skrótów <a id="slownik"></a>

* **ANOVA** – Analysis of Variance (analiza wariancji).
* **Within-subject** – czynnik wewnątrzosobniczy (powtarzany pomiar u tych samych osób).
* **Between-subject** – czynnik międzyosobniczy (niezależne grupy osób).
* **LMM** – Linear Mixed Model (liniowy model mieszany) z efektami stałymi i losowymi.
* **EMM** – Estimated Marginal Means (szacowane średnie marginalne z modelu).
* **CI** – Confidence Interval (przedział ufności, np. 95%).
* **η², η²g** – miary udziału wariancji wyjaśnionej efektem; η²g = generalized eta squared.
* **Cohen’s d** – standaryzowany rozmiar różnicy średnich.
* **R²\_marginal / R²\_conditional** – wariancja wyjaśniona przez efekty stałe / przez cały model (stałe + losowe).
* **FDR** – False Discovery Rate (odsetek fałszywych odkryć) – kontrola wielokrotnych testów.
* **BH** – Benjamini–Hochberg (metoda korekcji FDR).
* **GG/HF** – Greenhouse–Geisser / Huynh–Feldt (korekcje stopni swobody przy naruszeniu sferyczności).
* **LOD** – Limit of Detection (granica oznaczalności).

---

## 14. Polecana literatura <a id="literatura"></a>

* Maxwell, S. E., Delaney, H. D. *Designing Experiments and Analyzing Data: A Model Comparison Perspective.*
* Field, A., Miles, J., Field, Z. *Discovering Statistics Using R.*
* West, B. T., Welch, K. B., Galecki, A. T. *Linear Mixed Models: A Practical Guide Using Statistical Software.*
* Benjamini, Y., Hochberg, Y. (1995). *Controlling the false discovery rate: a practical and powerful approach to multiple testing.*
* Vignettes pakietów: **afex**, **emmeans**, **lme4/lmerTest**, **effectsize**, **rstatix**.

---

### Kontakt / dalszy rozwój

Notebooki są przygotowane tak, by można je było łatwo rozbudować o:

* modele odporne (WRS2, ARTool),
* permutacyjne ANOVA,
* specjalne traktowanie danych cenzurowanych (Tobit),
* automatyczną diagnostykę i raportowanie rekomendacji dla każdej zmiennej.

Daj znać, które rozszerzenia są dla Ciebie priorytetem – przygotuję kolejną iterację szablonów.
