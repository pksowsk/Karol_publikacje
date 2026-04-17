# Manual użytkownika – regresja wieloraka w **tidymodels** dla zmiennej *adiponektyna\_ng\_ml*

> Ten manual prowadzi krok‑po‑kroku przez notebook **„Regresja wieloraka – tidymodels (adiponektyna\_ng\_ml) z interpretacją”** umieszczony na canvasie. Obejmuje aspekty **techniczne** (jak uruchamiać, jakie są parametry, co robi każdy blok kodu) oraz **merytoryczne** (dlaczego takie decyzje, jak interpretować wyniki, kiedy wybrać dany model).

---

## Spis treści

1. [Cel i założenia analizy](#cel)
2. [Wymagania i przygotowanie środowiska](#wymagania)
3. [Dane wejściowe i strategie ich użycia](#dane)

   * 3.1 [Strategia `baseline`](#baseline)
   * 3.2 [Strategia `mean_by_id`](#mean_by_id)
   * 3.3 [Strategia `mixed`](#mixed)
   * 3.4 [Dobór predyktorów i lista `exclude`](#exclude)
4. [Parametry notebooka](#parametry)
5. [Podział danych i resampling](#resampling)
6. [Recipe – przygotowanie cech](#recipe)
7. [Modele i ich rola](#modele)

   * 7.1 [OLS (`lm`)](#lm)
   * 7.2 [Modele regularizowane (`glmnet`): ridge, lasso, elastic net](#glmnet)
   * 7.3 [Model mieszany (`lmer`) – opcjonalny](#lmer)
8. [Strojenie hiperparametrów](#strojenie)
9. [Ranking modeli i wybór najlepszego](#ranking)
10. [Finalizacja i ocena na zbiorze testowym](#finalizacja)
11. [Współczynniki, ważność zmiennych i kolinearność](#wspolczynniki)
12. [Diagnostyka reszt](#diagnostyka)
13. [Narracja i raportowanie wyników](#raport)
14. [Drzewko decyzyjne – który model wybrać?](#drzewko)
15. [Analizy wrażliwości i sanity‑checks](#sens)
16. [Najczęstsze problemy i rozwiązania](#problemy)
17. [Słowniczek](#slownik)
18. [Dalszy rozwój](#rozwoj)

---

## 1. Cel i założenia analizy <a id="cel"></a>

Celem jest wyjaśnienie zmienności biomarkera **`adiponektyna_ng_ml`** z użyciem zestawu innych zmiennych (antropometria, lipidy, cytokiny, dieta itd.). Notebook porównuje modele:

* klasyczny **OLS** (regresja liniowa),
* **ridge / lasso / elastic net** (regresje regularizowane),
* opcjonalnie **model mieszany** z efektem losowym `(1|id_osoby)` dla danych z wieloma pomiarami na osobę.

Założenia główne:

* dane mogą mieć braki, które imputujemy (medianowo/trybowo),
* rozkłady mogą być skośne → stosujemy transformację **Yeo–Johnson** dla predyktorów,
* możliwa kolinearność predyktorów → filtr korelacji i/lub regularizacja,
* oceniamy modele przez **grupowany CV** (gdy są powtórzenia) oraz końcową ocenę na zbiorze **testowym** odłożonym na początku.

---

## 2. Wymagania i przygotowanie środowiska <a id="wymagania"></a>

* R ≥ 4.x, pakiety: **tidymodels**, **glmnet**, **multilevelmod**, **vip**, **performance**, **broom.mixed**, **readxl**, **here**, **janitor**.
* Rekomendowane użycie **`renv`** dla replikowalności.
* Struktura katalogów jak w notebookach analizy ANOVA/LMM (katalog `Dane/`, `wyniki/`).

---

## 3. Dane wejściowe i strategie ich użycia <a id="dane"></a>

Dane wczytywane są z Excela. Tworzymy czynniki: **`czas`** (początek/koniec) i **`interwencja`** (trening, trening\_dieta, grupa\_kontrolna).

### 3.1 Strategia `baseline` <a id="baseline"></a>

Używamy tylko rekordów z `czas == "początek"`.

**Zalety:**

* unikamy wpływu interwencji i powtórzeń,
* prosta interpretacja predyktorów względem stanu bazowego.

**Wady:**

* tracimy informację z drugiego pomiaru.

### 3.2 Strategia `mean_by_id` <a id="mean_by_id"></a>

Uśredniamy wszystkie kolumny numeryczne w obrębie `id_osoby` i dołączamy jedną etykietę `interwencja`.

**Zalety:** redukcja szumu, kompletne wiersze.

**Wady:** spłaszczamy dynamikę, ryzyko rozmycia efektów interwencji.

### 3.3 Strategia `mixed` <a id="mixed"></a>

Wykorzystujemy wszystkie wiersze (początek i koniec) i budujemy **model mieszany** `(1|id_osoby)` (sekcja 11).

**Zalety:** maksymalne wykorzystanie informacji i poprawne modelowanie korelacji między powtórzeniami.

**Wady:** większa złożoność, dłuższy czas liczenia.

### 3.4 Dobór predyktorów i lista `exclude` <a id="exclude"></a>

Parametr `params$exclude` przyjmuje wektor nazw kolumn do wykluczenia z puli predyktorów (np. identyfikatory, `id_pomiaru`, sama zmienna celu, pochodne niemające sensu jako predyktory).

**Zalecenia:**

* wyklucz wskaźniki silnie „z definicji” skorelowane z celem (redukcja ryzyka „przeuczenia” biologicznego),
* wyklucz zmienne tworzone jako proste przekształcenia celu,
* rozważ stworzenie whitelisty predyktorów opartych na wiedzy dziedzinowej (feature selection guided by domain knowledge).

---

## 4. Parametry notebooka <a id="parametry"></a>

Najważniejsze w YAML:

* `data_path`, `sheet` – źródło danych,
* `target` – nazwa zmiennej zależnej (domyślnie `adiponektyna_ng_ml`),
* `strategy` – `baseline` | `mean_by_id` | `mixed`,
* `exclude` – nazwy kolumn do pominięcia,
* `vfolds`, `repeats` – konfiguracja walidacji krzyżowej,
* `save_plots`, `plots_dir` – zapis wykresów.

Zmiana parametrów pozwala szybko replikować analizę dla innego celu (np. `leptyna_ng_lml`).

---

## 5. Podział danych i resampling <a id="resampling"></a>

* Przy `mixed` używamy **`group_initial_split()`** i **`group_vfold_cv()`** z `group = id_osoby` – te same osoby nie trafiają jednocześnie do trenowania i walidacji.
* Przy `baseline`/`mean_by_id` – klasyczne `initial_split()` + `vfold_cv()` (można stratyfikować po celu).

**Dlaczego to ważne?** Przy powtórzeniach ryzykujemy „wyciek informacji” – model uczy się właściwości osoby, a nie ogólnej zależności. Grupowanie temu zapobiega.

---

## 6. Recipe – przygotowanie cech <a id="recipe"></a>

Kroki w notebooku:

1. `step_impute_median()` – braki w numerycznych,
2. `step_impute_mode()` – braki w kategorycznych,
3. `step_yeo_johnson()` – transformacja rozkładów (działa dla wartości ≤ 0),
4. `step_zv()` – usunięcie zmiennych stałych,
5. `step_lincomb()` – eliminacja kombinacji liniowych,
6. `step_corr(threshold = 0.9)` – usunięcie zmiennych o bardzo wysokiej korelacji (redukcja kolinearności),
7. `step_normalize()` – standaryzacja numerycznych,
8. `step_dummy(one_hot = TRUE)` – kodowanie czynników.

> **Uwaga:** Gdy chcesz zachować wszystkie predyktory i zdać się w pełni na **ridge/lasso**, możesz **pominąć** `step_corr()`. Wtedy regularizacja rozwiąże kolinearność, a lasso zrobi selekcję cech.

---

## 7. Modele i ich rola <a id="modele"></a>

### 7.1 OLS (`lm`) <a id="lm"></a>

Punkt odniesienia. Łatwy do interpretacji (współczynniki). Wymaga dobrej jakości danych i umiarkowanej kolinearności. Współczynniki można testować i korygować FDR.

### 7.2 Ridge / Lasso / Elastic Net (`glmnet`) <a id="glmnet"></a>

* **Ridge (mixture = 0)**: silny przy kolinearności, **nie** zeruje współczynników.
* **Lasso (mixture = 1)**: robi **selekcję** – część współczynników = 0 (sparse model).
* **Elastic Net (0 < mixture < 1)**: łączy zalety obu; często najlepszy kompromis.

Hiperparametry:

* `penalty` (λ): siła regularyzacji; większa → mocniejsze kurczenie.
* `mixture` (α): proporcja lasso (1) vs ridge (0).

### 7.3 Model mieszany (`lmer`) – opcjonalny <a id="lmer"></a>

Dla danych z wieloma wierszami na osobę. Uogólnia OLS o efekt losowy `(1|id_osoby)`. Lepiej modeluje strukturę błędu i zwykle daje bardziej wiarygodne wnioski, jeśli zależy nam na generalizacji poza badane osoby.

---

## 8. Strojenie hiperparametrów <a id="strojenie"></a>

* OLS nie stroimy.
* Ridge/Lasso: stroimy `penalty` na siatce log‑skali (np. 50 wartości).
* Elastic Net: stroimy `penalty × mixture` (siatka dwuwymiarowa).

Miary oceny w CV: **RMSE** (niższy lepszy), **R²** (wyższy lepszy), **MAE**. W notebooku jako główne kryterium wyboru użyty jest **RMSE**.

> **Wskazówka:** Przy dużej liczbie predyktorów rozważ powiększenie siatki lub użycie `tune_bayes()` (optymalizacja bayesowska).

---

## 9. Ranking modeli i wybór najlepszego <a id="ranking"></a>

Po zebraniu metryk z CV budujemy tabelę `rank_tbl` i wybieramy model o **najmniejszym RMSE**. Dla kontekstu pokazujemy także RMSE modelu OLS i relatywną poprawę.

**Interpretacja:** jeżeli różnice RMSE są niewielkie i w granicach błędu standardowego, preferuj **model prostszy** (OLS lub lasso z małą liczbą cech), chyba że racje merytoryczne mówią inaczej.

---

## 10. Finalizacja i ocena na zbiorze testowym <a id="finalizacja"></a>

Dla wybranego modelu dopasowujemy workflow na całym **train** i raportujemy metryki na **test** (RMSE, R², MAE). Ten krok najtrafniej ocenia zdolność generalizacji.

**Dobre praktyki:**

* Jeżeli RMSE\_test ≫ RMSE\_CV → możliwe przeuczenie. Rozważ silniejszą regularyzację lub mniej predyktorów.
* Jeżeli R²\_test < 0 → model gorszy niż średnia; sprawdź dane i dobór predyktorów.

---

## 11. Współczynniki, ważność zmiennych i kolinearność <a id="wspolczynniki"></a>

* **OLS:** tabela `broom::tidy()` zawiera estymatory, SE, p‑value. Notebook dodaje **`p_adj_bh`** (korekcja FDR). Lista predyktorów z q<0.05 to „najpewniejsi kandydaci” przy wielu testach. Dodatkowo raportujemy **VIF** – jeśli >10, to sygnał problemu kolinearności.
* **glmnet:** nie ma klasycznych p‑value. Interpretujemy **znaki** współczynników, siłę regularyzacji i wykres **VIP** (ważność zmiennych). W LASSO liczba **niezerowych współczynników** wskazuje, jak agresywna była selekcja.
* **lmer:** `broom.mixed::tidy(..., effects = "fixed")` daje współczynniki części stałej. Dla pełnej oceny uwzględnij wariancję składową efektu losowego (różnice między osobami).

---

## 12. Diagnostyka reszt <a id="diagnostyka"></a>

Na zbiorze testowym sprawdzamy:

* wykres **reszty vs przewidywane** (brak wzorca → homoscedastyczność),
* **QQ‑plot reszt** (przybliżona liniowość → normalność),
* test **Shapiro–Wilka** (czuły; drobne odchylenia zwykle akceptowalne).

W razie problemów:

* transformuj cel (np. log),
* rozważ **robust regression** (M-estymatory) lub **quantile regression**,
* sprawdź, które obserwacje mają duży **leverage** / **Cook’s distance**.

---

## 13. Narracja i raportowanie wyników <a id="raport"></a>

### Przykładowy akapit dla OLS

> Zbudowano model regresji liniowej dla *adiponektyna\_ng\_ml*. Walidacja krzyżowa (v = `r params$vfolds`) dała RMSE\_CV ≈ **X**, R²\_CV ≈ **Y**. Na zbiorze testowym uzyskano RMSE\_test ≈ **X\_t**, R²\_test ≈ **Y\_t**, co wskazuje na \[dobrą/umiarkowaną/słabą] zdolność predykcyjną. Po korekcji FDR istotnymi predyktorami okazały się: **A**, **B**, **C** (q < 0.05). Wzrost **A** wiąże się z \[wzrostem/spadkiem] adiponektyny o **β\_A** jednostek (95% CI: …), przy pozostałych zmiennych stałych. Wskaźniki VIF były \[akceptowalne/podwyższone]; w razie wartości >10 zaleca się zastosowanie modeli regularizowanych.

### Przykładowy akapit dla LASSO/ENET

> Najlepszym modelem wg RMSE był **elastic net** z `λ = …`, `α = …`. W porównaniu z OLS uzyskano poprawę RMSE o **P%**. Model wybrał **k** aktywnych predyktorów. Najwyższą ważność (VIP) miały: **A**, **B**, **C**. Współczynniki tych zmiennych były \[dodatnie/ujemne], co sugeruje \[związek kierunkowy]. Brak klasycznych p‑value; znaczenie predyktorów oceniano przez VIP oraz stabilność wyboru w CV.

### Przykładowy akapit dla modelu mieszanego

> W modelu mieszanym z efektem losowym `(1|id_osoby)` uzyskano RMSE\_CV ≈ **X**, R²\_CV ≈ **Y**. Wariancja efektu losowego wyniosła **σ²\_id**, co wskazuje na \[istotne/umiarkowane] zróżnicowanie poziomów bazowych między osobami. Najsilniejsze efekty stałe zaobserwowano dla **A**, **B**. W porównaniu do modeli bez efektów losowych, model mieszany lepiej uwzględnia korelację powtórzeń i jest rekomendowany, jeśli zależy nam na uogólnieniu poza osoby w próbie.

---

## 14. Drzewko decyzyjne – który model wybrać? <a id="drzewko"></a>

1. **Są powtórzenia na osobę i chcesz je wykorzystać?** → **`strategy = mixed`** + **lmer**.
2. **Brak powtórzeń / używasz baseline:**

   * **Dużo predyktorów, kolinearność?** → zacznij od **elastic net**.
   * **Chcesz łatwe p‑value i FDR?** → **OLS**, ale sprawdź VIF i porównaj z enet.
3. **Różnice RMSE minimalne** → wybierz **model prostszy** (parsimonia), chyba że względy merytoryczne sugerują inaczej.

---

## 15. Analizy wrażliwości i sanity‑checks <a id="sens"></a>

* **Zmiana strategii danych** (`baseline` ↔ `mixed`) i porównanie metryk.
* **Inne progi `step_corr()`** (0.8; 0.95) vs. brak tego kroku + silniejsza regularyzacja.
* **Inny cel** (np. log(adiponektyna)), ocena poprawy normalności reszt.
* **Stabilność selekcji**: powtórz CV z innym seed/repeats i sprawdź, czy te same cechy są wybierane.
* **Wykluczenie obserwacji o największym wpływie** (duży Cook’s distance) – czy wnioski pozostają takie same?

---

## 16. Najczęstsze problemy i rozwiązania <a id="problemy"></a>

* **Błędy przy `group_vfold_cv`:** upewnij się, że `id_osoby` istnieje i nie ma pustych wartości.
* **„Model matrix is rank deficient” w OLS:** zbyt silna kolinearność – usuń zmienne albo użyj ridge/enet.
* **Brak konwergencji w lmer:** zbyt złożony model; zacznij od `(1|id_osoby)` bez dodatkowych efektów.
* **Różnice między CV a testem:** możliwe przeuczenie – zwiększ λ, ogranicz pulę cech, użyj prostszego modelu.
* **VIP pokazuje zmienne techniczne (dummy):** to normalne; interpretuj grupami (np. wszystkie dummy dla `interwencja_*`).

---

## 17. Słowniczek <a id="slownik"></a>

* **RMSE** – pierwiastek z MSE; jednostki jak zmienna zależna.
* **MAE** – średni błąd bezwzględny; mniej wrażliwy na odstające.
* **R²** – część wariancji wyjaśniona; na zbiorze testowym bywa niższa/ujemna.
* **λ (penalty)** – siła regularyzacji w glmnet.
* **α (mixture)** – udział lasso (1) w elastic net.
* **VIP** – miara ważności zmiennych.
* **VIF** – wskaźnik inflacji wariancji; >10 to silna kolinearność.

---

## 18. Dalszy rozwój <a id="rozwoj"></a>

* **tune\_bayes()** dla efektywniejszego strojenia.
* **Stacking** (ensemble) – połączenie prognoz kilku modeli.
* **Modele odporne** (quantile regression, robustbase).
* **Interpretowalność lokalna** – SHAP/LIME (pakiety `iml`, `DALEX`).
* **Ekspansja o predyktory nieliniowe/interakcje** – `step_interact()`, splajny (`splines`), GAM (`mgcv`).

---

Jeśli chcesz, mogę przygotować wariant notebooka, który automatycznie:

* porównuje transformacje celu (brak vs log),
* testuje obecność interakcji wybranych predyktorów (np. `interwencja` × `bmi`),
* wykonuje **tune\_bayes()** i zapisuje najlepsze parametry do pliku konfiguracyjnego.
