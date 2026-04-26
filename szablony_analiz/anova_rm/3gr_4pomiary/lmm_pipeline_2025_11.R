required_packages_2025_11 <- c(
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

check_required_packages_2025_11 <- function(packages = required_packages_2025_11) {
  missing <- packages[!vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]

  if (length(missing) > 0) {
    stop(
      "Brakuje wymaganych pakietow R: ",
      paste(missing, collapse = ", "),
      ". Zainstaluj je przed uruchomieniem pipeline LMM.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

check_required_packages_2025_11()

`%>%` <- magrittr::`%>%`

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || all(is.na(x))) {
    y
  } else {
    x
  }
}

analysis_dictionary_2025_11 <- tibble::tribble(
  ~variable, ~label, ~unit, ~transform, ~transform_note,
  "calkowite_wydatki_energetyczne_kcal_day", "Calkowite wydatki energetyczne", "kcal/day", "log", "Skala ln(y) zgodna z ustalona mapa transformacji.",
  "homa_tg", "HOMA/TG", NA_character_, "raw", "Analiza na skali surowej; zmienna nie byla jawnie wskazana do logarytmowania w raporcie LMM.",
  "homa_ad", "HOMA-AD", NA_character_, "raw", "Analiza na skali surowej; zmienna nie byla jawnie wskazana do logarytmowania w raporcie LMM.",
  "quicki", "QUICKI", NA_character_, "raw", "Analiza na skali surowej.",
  "insulina_u_iu_ml", "Insulina", "uIU/ml", "raw", "Analiza na skali surowej; decyzja do rewizji po audycie skosnosci.",
  "insulina_m_iu_ml", "Insulina", "mIU/ml", "raw", "Analiza na skali surowej; decyzja do rewizji po audycie skosnosci.",
  "glukoza_mmol_l", "Glukoza", "mmol/l", "raw", "Analiza na skali surowej.",
  "obwod_pasa_cm", "Obwod pasa", "cm", "raw", "Analiza na skali surowej.",
  "masa_ciala_kg", "Masa ciala", "kg", "raw", "Analiza na skali surowej.",
  "gynoid", "Gynoid", "%", "raw", "Analiza na skali surowej.",
  "gynoid_percent", "Gynoid", "%", "raw", "Analiza na skali surowej.",
  "android", "Android", "%", "raw", "Analiza na skali surowej.",
  "android_percent", "Android", "%", "raw", "Analiza na skali surowej.",
  "dexa_fat_kg", "DEXA fat", "kg", "raw", "Analiza na skali surowej.",
  "dexa_ffm_kg", "DEXA FFM", "kg", "raw", "Analiza na skali surowej.",
  "fat_bh", "FAT/BH", NA_character_, "raw", "Analiza na skali surowej.",
  "ffm_bh", "FFM/BH", NA_character_, "raw", "Analiza na skali surowej.",
  "android_bh", "ANDROID/BH", NA_character_, "raw", "Analiza na skali surowej.",
  "fg_i", "FG/I", NA_character_, "log", "Skala ln(y) zgodna z ustalona mapa transformacji.",
  "adipo_crp", "ADIPO/CRP", NA_character_, "log", "Skala ln(y) zgodna z ustalona mapa transformacji.",
  "mets_ir", "METS-IR", NA_character_, "raw", "Analiza na skali surowej.",
  "homa_b", "HOMA-B", NA_character_, "log", "Skala ln(y) zgodna z ustalona mapa transformacji.",
  "skurczowe", "Cisnienie skurczowe", "mmHg", "raw", "Analiza na skali surowej.",
  "rozkurczowe", "Cisnienie rozkurczowe", "mmHg", "raw", "Analiza na skali surowej.",
  "crp_mg_l", "CRP", "mg/l", "log", "Skala ln(y) zgodna z ustalona mapa transformacji.",
  "adiponektyna_ng_ml", "Adiponektyna", "ng/ml", "raw", "Analiza na skali surowej zgodna z raportem LMM.",
  "adipo_asp", "Adipo/asp", NA_character_, "log", "Skala ln(y) zgodna z ustalona mapa transformacji.",
  "tyg", "TyG", NA_character_, "raw", "Analiza na skali surowej zgodna z raportem LMM.",
  "wskaznik_aterogenezy_aip", "Wskaznik aterogenezy AIP", NA_character_, "raw", "Analiza na skali surowej zgodna z raportem LMM.",
  "wskaznik_wisceralnej_tkanki_tluszczowej_vai", "Wskaznik wisceralnej tkanki tluszczowej VAI", NA_character_, "raw", "Analiza na skali surowej zgodna z raportem LMM.",
  "wskaznik_akumulacji_produktow_lipidowych_lap", "Wskaznik akumulacji produktow lipidowych LAP", NA_character_, "log", "Skala ln(y) zgodna z ustalona mapa transformacji."
)

default_variable_label_2025_11 <- function(var) {
  pretty <- var %>%
    stringr::str_replace_all("_", " ") %>%
    stringr::str_squish() %>%
    stringr::str_to_title()

  replacements <- c(
    "Fg I" = "FG/I",
    "Adipo Crp" = "ADIPO/CRP",
    "Homa B" = "HOMA-B",
    "Homa Tg" = "HOMA/TG",
    "Homa Ad" = "HOMA-AD",
    "Mets Ir" = "METS-IR",
    "Fat Bh" = "FAT/BH",
    "Ffm Bh" = "FFM/BH",
    "Android Bh" = "ANDROID/BH",
    "Crp Mg L" = "CRP",
    "Obwod Pasa Cm" = "Obwod pasa",
    "Dxa Fat Kg" = "DEXA fat",
    "Dxa Ffm Kg" = "DEXA FFM"
  )

  if (pretty %in% names(replacements)) {
    replacements[[pretty]]
  } else {
    pretty
  }
}

get_variable_meta_2025_11 <- function(var) {
  meta <- analysis_dictionary_2025_11 %>%
    dplyr::filter(.data$variable == var)

  if (nrow(meta) == 0) {
    meta <- tibble::tibble(
      variable = var,
      label = default_variable_label_2025_11(var),
      unit = NA_character_,
      transform = "raw",
      transform_note = "Analiza na skali surowej (brak jawnej reguly transformacji dla tej zmiennej)."
    )
  }

  meta %>%
    dplyr::slice(1) %>%
    dplyr::mutate(
      display_label = dplyr::if_else(
        is.na(.data$unit),
        .data$label,
        paste0(.data$label, " [", .data$unit, "]")
      ),
      analysis_scale = dplyr::if_else(.data$transform == "log", "ln(y)", "y")
    )
}

resolve_existing_path_2025_11 <- function(path, base_dirs = c(".", "..", "../..", "../../..")) {
  if (file.exists(path)) {
    return(normalizePath(path, mustWork = TRUE))
  }

  candidates <- file.path(base_dirs, path)
  existing <- candidates[file.exists(candidates)]

  if (length(existing) == 0) {
    stop("Nie znaleziono pliku: ", path, call. = FALSE)
  }

  normalizePath(existing[[1]], mustWork = TRUE)
}

normalise_group_2025_11 <- function(x) {
  x_chr <- stringr::str_to_lower(trimws(as.character(x)))

  dplyr::case_when(
    x_chr %in% c("1", "aerobowa", "aerobowy", "trening aerobowy") ~ "Aerobowa",
    x_chr %in% c("2", "silowa", "silowy", "siłowa", "siłowy", "trening silowy", "trening siłowy") ~ "Silowa",
    x_chr %in% c("3", "kontrolna", "kontrola", "grupa kontrolna") ~ "Kontrolna",
    TRUE ~ NA_character_
  )
}

normalise_time_2025_11 <- function(x) {
  x_chr <- stringr::str_to_lower(trimws(as.character(x)))

  dplyr::case_when(
    x_chr %in% c("1", "t1", "0", "poczatek", "początek", "baseline") ~ "T1",
    x_chr %in% c("2", "t2", "6", "6_tygodni", "6 tygodni") ~ "T2",
    x_chr %in% c("3", "t3", "12", "12_tygodni", "12 tygodni") ~ "T3",
    x_chr %in% c("4", "t4", "16", "16_tygodni", "16 tygodni", "follow_up", "follow-up") ~ "T4",
    TRUE ~ NA_character_
  )
}

pick_first_existing_column_2025_11 <- function(df, candidates) {
  existing <- candidates[candidates %in% names(df)]

  if (length(existing) == 0) {
    NA_character_
  } else {
    existing[[1]]
  }
}

build_person_id_2025_11 <- function(df, group_col) {
  explicit_id <- pick_first_existing_column_2025_11(
    df,
    c("id_uczestnika", "uczestnik_id", "id_badanej", "id_badanego", "participant_id")
  )

  if (!is.na(explicit_id)) {
    return(as.character(df[[explicit_id]]))
  }

  if ("id_osoby" %in% names(df) && group_col != "id_osoby") {
    return(as.character(df$id_osoby))
  }

  if (all(c("nazwisko", "imie") %in% names(df)) && any(!is.na(df$imie) & nzchar(trimws(df$imie)))) {
    return(paste0(df$nazwisko, "_", df$imie, "_", df[[group_col]]))
  }

  if ("nazwisko" %in% names(df)) {
    return(paste0(df$nazwisko, "_", df[[group_col]]))
  }

  stop(
    "Nie da sie jednoznacznie zbudowac ID uczestnika. Dodaj kolumne id_uczestnika albo kolumny nazwisko/imie.",
    call. = FALSE
  )
}

validate_panel_data_2025_11 <- function(df) {
  duplicated_rows <- df %>%
    dplyr::count(.data$id_osoby, .data$czas, name = "n") %>%
    dplyr::filter(.data$n > 1)

  if (nrow(duplicated_rows) > 0) {
    stop("W danych sa duplikaty dla tej samej osoby i punktu czasu.", call. = FALSE)
  }

  multi_group <- df %>%
    dplyr::distinct(.data$id_osoby, .data$interwencja) %>%
    dplyr::count(.data$id_osoby, name = "n_grup") %>%
    dplyr::filter(.data$n_grup > 1)

  if (nrow(multi_group) > 0) {
    stop("Co najmniej jeden uczestnik wystepuje w wiecej niz jednej grupie.", call. = FALSE)
  }

  invisible(TRUE)
}

load_2025_11_data <- function(path, sheet = 1) {
  data_path <- resolve_existing_path_2025_11(path)

  df_raw <- openxlsx::read.xlsx(data_path, sheet = sheet) %>%
    janitor::clean_names(replace = c("\u00b5" = "u")) %>%
    dplyr::mutate(dplyr::across(where(is.character), ~ trimws(.x, which = "both")))

  time_col <- pick_first_existing_column_2025_11(df_raw, c("id_pomiaru", "czas", "pomiar", "time"))
  if (is.na(time_col)) {
    stop("W pliku danych nie znaleziono kolumny czasu, np. id_pomiaru.", call. = FALSE)
  }

  group_col <- pick_first_existing_column_2025_11(df_raw, c("id_grupy", "grupa", "interwencja", "group"))
  if (is.na(group_col) && "id_osoby" %in% names(df_raw)) {
    id_values <- unique(stats::na.omit(df_raw$id_osoby))
    if (all(as.character(id_values) %in% c("1", "2", "3"))) {
      group_col <- "id_osoby"
    }
  }

  if (is.na(group_col)) {
    stop("W pliku danych nie znaleziono kolumny grupy, np. id_grupy albo interwencja.", call. = FALSE)
  }

  person_id <- build_person_id_2025_11(df_raw, group_col = group_col)
  group_raw <- df_raw[[group_col]]
  time_raw <- df_raw[[time_col]]

  df <- df_raw %>%
    dplyr::mutate(
      id_grupy = group_raw,
      id_osoby = factor(person_id),
      interwencja = factor(
        normalise_group_2025_11(group_raw),
        levels = c("Aerobowa", "Silowa", "Kontrolna")
      ),
      czas = factor(
        normalise_time_2025_11(time_raw),
        levels = c("T1", "T2", "T3", "T4")
      ),
      .before = 1
    ) %>%
    dplyr::filter(!is.na(.data$id_osoby), !is.na(.data$interwencja), !is.na(.data$czas))

  validate_panel_data_2025_11(df)
  df
}

get_batch_variables_2025_11 <- function(df) {
  excluded <- c("id_grupy", "id_osoby", "id_pomiaru", "nazwisko", "imie", "wysokosc_cm")

  variables <- df %>%
    dplyr::select(where(is.numeric)) %>%
    names() %>%
    setdiff(excluded)

  preferred_order <- analysis_dictionary_2025_11$variable
  ordered <- c(preferred_order[preferred_order %in% variables], setdiff(variables, preferred_order))

  unique(ordered)
}

skewness_2025_11 <- function(x) {
  x <- stats::na.omit(as.numeric(x))

  if (length(x) < 3 || isTRUE(all.equal(stats::sd(x), 0))) {
    return(NA_real_)
  }

  mean((x - mean(x))^3) / stats::sd(x)^3
}

build_transform_audit_2025_11 <- function(df, variables = get_batch_variables_2025_11(df)) {
  tibble::tibble(variable = variables) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      all_positive = all(df[[.data$variable]] > 0, na.rm = TRUE),
      skew_raw = skewness_2025_11(df[[.data$variable]]),
      skew_log = if (all_positive) skewness_2025_11(log(df[[.data$variable]])) else NA_real_,
      suggested_transform = dplyr::case_when(
        isTRUE(all_positive) &&
          !is.na(.data$skew_raw) &&
          !is.na(.data$skew_log) &&
          abs(.data$skew_raw) > 1 &&
          abs(.data$skew_log) < abs(.data$skew_raw) ~ "log",
        TRUE ~ "raw"
      ),
      dictionary_transform = get_variable_meta_2025_11(.data$variable)$transform[[1]],
      transform_mismatch = .data$suggested_transform != .data$dictionary_transform
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(dplyr::across(where(is.numeric), ~ round(.x, 4)))
}

build_sample_summary_2025_11 <- function(df, var) {
  observed <- df %>%
    dplyr::transmute(id_osoby = .data$id_osoby, wartosc = .data[[var]], czas = .data$czas) %>%
    dplyr::filter(!is.na(.data$wartosc))

  expected_timepoints <- nlevels(df$czas)
  counts_by_person <- observed %>%
    dplyr::count(.data$id_osoby, name = "n_obs")

  tibble::tibble(
    liczba_obserwacji = nrow(observed),
    liczba_osob_z_danymi = dplyr::n_distinct(observed$id_osoby),
    osoby_kompletne = sum(counts_by_person$n_obs == expected_timepoints),
    osoby_niekompletne = sum(counts_by_person$n_obs < expected_timepoints)
  )
}

build_completeness_table_2025_11 <- function(df, var) {
  df %>%
    dplyr::group_by(.data$interwencja, .data$czas) %>%
    dplyr::summarise(
      liczba_wierszy = dplyr::n(),
      liczba_obserwacji = sum(!is.na(.data[[var]])),
      brakujace = sum(is.na(.data[[var]])),
      .groups = "drop"
    )
}

build_raw_descriptives_2025_11 <- function(df, var) {
  df %>%
    dplyr::transmute(
      interwencja = .data$interwencja,
      czas = .data$czas,
      wartosc = .data[[var]]
    ) %>%
    dplyr::filter(!is.na(.data$wartosc)) %>%
    dplyr::group_by(.data$interwencja, .data$czas) %>%
    dplyr::summarise(
      n = dplyr::n(),
      srednia = mean(.data$wartosc),
      sd = stats::sd(.data$wartosc),
      mediana = stats::median(.data$wartosc),
      q1 = stats::quantile(.data$wartosc, probs = 0.25),
      q3 = stats::quantile(.data$wartosc, probs = 0.75),
      .groups = "drop"
    ) %>%
    dplyr::mutate(dplyr::across(where(is.numeric), ~ round(.x, 3)))
}

prepare_analysis_data_2025_11 <- function(df, var, meta) {
  if (!var %in% names(df)) {
    stop("W danych nie ma zmiennej: ", var, call. = FALSE)
  }

  analysis_df <- df %>%
    dplyr::transmute(
      id_osoby = .data$id_osoby,
      interwencja = .data$interwencja,
      czas = .data$czas,
      value_raw = .data[[var]]
    ) %>%
    dplyr::filter(
      !is.na(.data$id_osoby),
      !is.na(.data$interwencja),
      !is.na(.data$czas),
      !is.na(.data$value_raw)
    ) %>%
    droplevels()

  if (nrow(analysis_df) == 0) {
    stop("Po odfiltrowaniu brakow nie zostaly zadne obserwacje dla zmiennej ", var, ".", call. = FALSE)
  }

  if (nlevels(analysis_df$interwencja) < 2 || nlevels(analysis_df$czas) < 2) {
    stop("Zmienna ", var, " nie ma wystarczajacej liczby poziomow grupy/czasu do modelu LMM.", call. = FALSE)
  }

  if (meta$transform[[1]] == "log") {
    if (any(analysis_df$value_raw <= 0, na.rm = TRUE)) {
      stop("Transformacja logarytmiczna wymaga dodatnich obserwacji dla zmiennej ", var, ".", call. = FALSE)
    }

    analysis_df <- analysis_df %>%
      dplyr::mutate(value_model = log(.data$value_raw))
  } else {
    analysis_df <- analysis_df %>%
      dplyr::mutate(value_model = .data$value_raw)
  }

  analysis_df
}

fit_lmm_models_2025_11 <- function(analysis_df) {
  control <- lme4::lmerControl(
    optimizer = "bobyqa",
    optCtrl = list(maxfun = 2e5)
  )

  full_model <- lme4::lmer(
    value_model ~ interwencja * czas + (1 | id_osoby),
    data = analysis_df,
    REML = FALSE,
    control = control
  )

  additive_model <- lme4::lmer(
    value_model ~ interwencja + czas + (1 | id_osoby),
    data = analysis_df,
    REML = FALSE,
    control = control
  )

  no_time_model <- lme4::lmer(
    value_model ~ interwencja + (1 | id_osoby),
    data = analysis_df,
    REML = FALSE,
    control = control
  )

  no_group_model <- lme4::lmer(
    value_model ~ czas + (1 | id_osoby),
    data = analysis_df,
    REML = FALSE,
    control = control
  )

  list(
    full = full_model,
    additive = additive_model,
    no_time = no_time_model,
    no_group = no_group_model
  )
}

extract_lrt_row_2025_11 <- function(smaller_model, larger_model, effect_key, effect_label) {
  comparison <- stats::anova(smaller_model, larger_model)

  tibble::tibble(
    effect_key = effect_key,
    efekt = effect_label,
    chisq = comparison$Chisq[2],
    df = comparison$Df[2],
    p_value = comparison$`Pr(>Chisq)`[2]
  )
}

build_omnibus_table_2025_11 <- function(fits) {
  dplyr::bind_rows(
    extract_lrt_row_2025_11(fits$no_group, fits$additive, "group", "Grupa"),
    extract_lrt_row_2025_11(fits$no_time, fits$additive, "time", "Czas"),
    extract_lrt_row_2025_11(fits$additive, fits$full, "interaction", "Grupa x czas")
  ) %>%
    dplyr::mutate(
      istotny = dplyr::if_else(.data$p_value < 0.05, "tak", "nie")
    )
}

get_effect_p_2025_11 <- function(omnibus, effect_key) {
  value <- omnibus %>%
    dplyr::filter(.data$effect_key == .env$effect_key) %>%
    dplyr::pull(.data$p_value)

  value[[1]] %||% NA_real_
}

add_response_scale_2025_11 <- function(tbl, meta) {
  if (!all(c("estimate", "lower.CL", "upper.CL") %in% names(tbl))) {
    return(tbl)
  }

  if (meta$transform[[1]] == "log") {
    tbl %>%
      dplyr::mutate(
        miara = "iloraz",
        estimate_response = exp(.data$estimate),
        lower_response = exp(.data$lower.CL),
        upper_response = exp(.data$upper.CL)
      )
  } else {
    tbl %>%
      dplyr::mutate(
        miara = "roznica",
        estimate_response = .data$estimate,
        lower_response = .data$lower.CL,
        upper_response = .data$upper.CL
      )
  }
}

tidy_pairs_2025_11 <- function(emm_grid, family_label, meta) {
  pairwise <- emmeans::contrast(emm_grid, method = "pairwise", adjust = "holm")
  pairwise_summary <- as.data.frame(summary(pairwise, infer = c(TRUE, TRUE), level = 0.95))

  if (!"lower.CL" %in% names(pairwise_summary) || !"upper.CL" %in% names(pairwise_summary)) {
    ci_tbl <- as.data.frame(confint(pairwise, level = 0.95))
    pairwise_summary <- pairwise_summary %>%
      dplyr::left_join(
        ci_tbl %>% dplyr::select("contrast", "lower.CL", "upper.CL"),
        by = "contrast"
      )
  }

  pairwise_summary %>%
    tidyr::separate(
      "contrast",
      into = c("porownanie_1", "porownanie_2"),
      sep = " - ",
      remove = FALSE,
      fill = "right"
    ) %>%
    dplyr::mutate(rodzina = family_label) %>%
    add_response_scale_2025_11(meta = meta) %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::any_of(c("estimate", "SE", "lower.CL", "upper.CL", "estimate_response", "lower_response", "upper_response", "p.value")),
        ~ round(.x, 4)
      )
    )
}

build_posthoc_tables_2025_11 <- function(fits, omnibus, meta) {
  p_interaction <- get_effect_p_2025_11(omnibus, "interaction")
  p_group <- get_effect_p_2025_11(omnibus, "group")
  p_time <- get_effect_p_2025_11(omnibus, "time")

  tables <- list()

  if (!is.na(p_interaction) && p_interaction < 0.05) {
    tables$between_by_time <- tidy_pairs_2025_11(
      emmeans::emmeans(fits$full, ~ interwencja | czas),
      "Grupy w obrebie czasu",
      meta
    )

    tables$time_by_group <- tidy_pairs_2025_11(
      emmeans::emmeans(fits$full, ~ czas | interwencja),
      "Czas w obrebie grupy",
      meta
    )

    strategy <- "interaction"
  } else {
    if (!is.na(p_group) && p_group < 0.05) {
      tables$group_main <- tidy_pairs_2025_11(
        emmeans::emmeans(fits$additive, ~ interwencja),
        "Efekt glowny grupy",
        meta
      )
    }

    if (!is.na(p_time) && p_time < 0.05) {
      tables$time_main <- tidy_pairs_2025_11(
        emmeans::emmeans(fits$additive, ~ czas),
        "Efekt glowny czasu",
        meta
      )
    }

    strategy <- "main_effects"
  }

  list(strategy = strategy, tables = tables)
}

build_model_means_2025_11 <- function(fits, meta) {
  emm <- emmeans::emmeans(fits$full, ~ interwencja * czas)
  emm_tbl <- as.data.frame(summary(emm, infer = c(TRUE, TRUE)))

  if (!"lower.CL" %in% names(emm_tbl) || !"upper.CL" %in% names(emm_tbl)) {
    ci_tbl <- as.data.frame(confint(emm))
    emm_tbl <- emm_tbl %>%
      dplyr::left_join(
        ci_tbl %>% dplyr::select("interwencja", "czas", "lower.CL", "upper.CL"),
        by = c("interwencja", "czas")
      )
  }

  emm_tbl <- emm_tbl %>%
    dplyr::mutate(
      dplyr::across(dplyr::any_of(c("emmean", "SE", "lower.CL", "upper.CL")), ~ round(.x, 4))
    )

  if (meta$transform[[1]] == "log") {
    emm_tbl %>%
      dplyr::mutate(
        mean_display = exp(.data$emmean),
        lower_display = exp(.data$lower.CL),
        upper_display = exp(.data$upper.CL),
        scale_note = "Srednie modelowe po eksponentacji do skali oryginalnej."
      )
  } else {
    emm_tbl %>%
      dplyr::mutate(
        mean_display = .data$emmean,
        lower_display = .data$lower.CL,
        upper_display = .data$upper.CL,
        scale_note = "Srednie modelowe na skali surowej."
      )
  }
}

extract_model_status_2025_11 <- function(model) {
  messages <- model@optinfo$conv$lme4$messages %||% character(0)

  tibble::tibble(
    singular = lme4::isSingular(model, tol = 1e-05),
    convergence_message = paste(messages, collapse = " | ") %||% "",
    optimizer = model@optinfo$optimizer %||% NA_character_
  )
}

build_diagnostics_2025_11 <- function(full_model) {
  residuals_model <- stats::resid(full_model)
  fitted_values <- stats::fitted(full_model)

  shapiro_res <- if (length(residuals_model) >= 3 && length(residuals_model) <= 5000) {
    stats::shapiro.test(residuals_model)
  } else {
    NULL
  }

  list(
    shapiro = shapiro_res,
    status = extract_model_status_2025_11(full_model),
    plot_data = tibble::tibble(
      fitted = fitted_values,
      residuals = residuals_model
    )
  )
}

build_measure_label_2025_11 <- function(meta) {
  meta$display_label[[1]]
}

build_plots_2025_11 <- function(analysis_df, model_means, meta) {
  palette <- c("Aerobowa" = "#2B6CB0", "Silowa" = "#C05621", "Kontrolna" = "#2F855A")
  y_label <- build_measure_label_2025_11(meta)

  raw_plot <- ggplot2::ggplot(
    analysis_df,
    ggplot2::aes(x = .data$czas, y = .data$value_raw, color = .data$interwencja)
  ) +
    ggplot2::geom_line(ggplot2::aes(group = .data$id_osoby), alpha = 0.15, linewidth = 0.35) +
    ggplot2::geom_point(alpha = 0.35, size = 1.2) +
    ggplot2::stat_summary(ggplot2::aes(group = .data$interwencja), fun = mean, geom = "line", linewidth = 1.1) +
    ggplot2::stat_summary(ggplot2::aes(group = .data$interwencja), fun = mean, geom = "point", size = 2.8) +
    ggplot2::facet_wrap(~interwencja, nrow = 1) +
    ggplot2::scale_color_manual(values = palette) +
    ggplot2::labs(
      title = "Dane surowe",
      subtitle = "Cienkie linie pokazują przebiegi osobnicze, grubsza linia oznacza srednia w grupie.",
      x = "Punkt czasowy",
      y = y_label,
      color = "Grupa"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "none",
      panel.grid.minor = ggplot2::element_blank(),
      plot.title.position = "plot"
    )

  emm_plot <- ggplot2::ggplot(
    model_means,
    ggplot2::aes(x = .data$czas, y = .data$mean_display, color = .data$interwencja, group = .data$interwencja)
  ) +
    ggplot2::geom_line(linewidth = 1.2) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = .data$lower_display, ymax = .data$upper_display), width = 0.12, linewidth = 0.8) +
    ggplot2::scale_color_manual(values = palette) +
    ggplot2::labs(
      title = "Srednie modelowe (EMM)",
      subtitle = model_means$scale_note[[1]],
      x = "Punkt czasowy",
      y = y_label,
      color = "Grupa"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank(),
      plot.title.position = "plot"
    )

  list(raw = raw_plot, emm = emm_plot)
}

build_diagnostic_plots_2025_11 <- function(diagnostics) {
  qq_plot <- ggplot2::ggplot(
    diagnostics$plot_data,
    ggplot2::aes(sample = .data$residuals)
  ) +
    ggplot2::stat_qq(alpha = 0.5, size = 1) +
    ggplot2::stat_qq_line(color = "#C05621", linewidth = 0.8) +
    ggplot2::labs(
      title = "Q-Q plot reszt",
      x = "Kwantyle teoretyczne",
      y = "Kwantyle empiryczne"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  resid_plot <- ggplot2::ggplot(
    diagnostics$plot_data,
    ggplot2::aes(x = .data$fitted, y = .data$residuals)
  ) +
    ggplot2::geom_point(alpha = 0.5, size = 1.4, color = "#2B6CB0") +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "#718096") +
    ggplot2::geom_smooth(se = FALSE, method = "loess", color = "#C05621", linewidth = 0.8) +
    ggplot2::labs(
      title = "Reszty vs dopasowanie",
      x = "Wartosci dopasowane",
      y = "Reszty"
    ) +
    ggplot2::theme_minimal(base_size = 11)

  qq_plot + resid_plot + patchwork::plot_layout(ncol = 2)
}

run_lmm_analysis_2025_11 <- function(var, data_path, sheet = 1) {
  df <- load_2025_11_data(data_path, sheet = sheet)
  meta <- get_variable_meta_2025_11(var)
  analysis_df <- prepare_analysis_data_2025_11(df, var, meta)
  fits <- fit_lmm_models_2025_11(analysis_df)
  omnibus <- build_omnibus_table_2025_11(fits)
  posthoc <- build_posthoc_tables_2025_11(fits, omnibus, meta)
  model_means <- build_model_means_2025_11(fits, meta)
  diagnostics <- build_diagnostics_2025_11(fits$full)
  plots <- build_plots_2025_11(analysis_df, model_means, meta)

  list(
    meta = meta,
    data = df,
    analysis_df = analysis_df,
    sample_summary = build_sample_summary_2025_11(df, var),
    completeness = build_completeness_table_2025_11(df, var),
    descriptives = build_raw_descriptives_2025_11(df, var),
    fits = fits,
    omnibus = omnibus,
    posthoc = posthoc,
    model_means = model_means,
    diagnostics = diagnostics,
    plots = list(
      raw = plots$raw,
      emm = plots$emm,
      diagnostics = build_diagnostic_plots_2025_11(diagnostics)
    )
  )
}

safe_run_lmm_analysis_2025_11 <- function(var, data_path, sheet = 1) {
  warnings <- character(0)

  result <- tryCatch(
    withCallingHandlers(
      run_lmm_analysis_2025_11(var, data_path, sheet = sheet),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )

  if (inherits(result, "error")) {
    list(
      variable = var,
      status = "error",
      error = conditionMessage(result),
      warnings = warnings,
      analysis = NULL
    )
  } else {
    list(
      variable = var,
      status = "success",
      error = NA_character_,
      warnings = warnings,
      analysis = result
    )
  }
}

fmt_p_2025_11 <- function(p_value) {
  dplyr::case_when(
    is.na(p_value) ~ NA_character_,
    p_value < 0.001 ~ "< 0.001",
    TRUE ~ formatC(p_value, format = "f", digits = 3)
  )
}

build_result_summary_2025_11 <- function(analysis) {
  p_group <- get_effect_p_2025_11(analysis$omnibus, "group")
  p_time <- get_effect_p_2025_11(analysis$omnibus, "time")
  p_interaction <- get_effect_p_2025_11(analysis$omnibus, "interaction")

  lines <- character(0)

  if (!is.na(p_interaction) && p_interaction < 0.05) {
    lines <- c(
      lines,
      paste0("Najwazniejszy wynik: istotna interakcja grupa x czas (p = ", fmt_p_2025_11(p_interaction), ")."),
      "Interpretacja powinna opierac sie glownie na porownaniach prostych, a nie na samych efektach glownych."
    )
  } else {
    lines <- c(
      lines,
      paste0("Nie stwierdzono istotnej interakcji grupa x czas (p = ", fmt_p_2025_11(p_interaction), ").")
    )
  }

  c(
    lines,
    paste0("Efekt grupy: p = ", fmt_p_2025_11(p_group), "."),
    paste0("Efekt czasu: p = ", fmt_p_2025_11(p_time), ".")
  )
}

build_lmm_summary_row_2025_11 <- function(batch_item) {
  if (batch_item$status != "success") {
    return(tibble::tibble(
      variable = batch_item$variable,
      status = batch_item$status,
      error = batch_item$error
    ))
  }

  analysis <- batch_item$analysis
  p_group <- get_effect_p_2025_11(analysis$omnibus, "group")
  p_time <- get_effect_p_2025_11(analysis$omnibus, "time")
  p_interaction <- get_effect_p_2025_11(analysis$omnibus, "interaction")

  tibble::tibble(
    variable = batch_item$variable,
    label = analysis$meta$display_label[[1]],
    scale = analysis$meta$analysis_scale[[1]],
    transform = analysis$meta$transform[[1]],
    n_obs = analysis$sample_summary$liczba_obserwacji[[1]],
    n_people = analysis$sample_summary$liczba_osob_z_danymi[[1]],
    complete_people = analysis$sample_summary$osoby_kompletne[[1]],
    incomplete_people = analysis$sample_summary$osoby_niekompletne[[1]],
    p_group = p_group,
    p_time = p_time,
    p_interaction = p_interaction,
    singular = analysis$diagnostics$status$singular[[1]],
    shapiro_resid_p = analysis$diagnostics$shapiro$p.value %||% NA_real_,
    warnings = paste(unique(batch_item$warnings), collapse = " | "),
    status = batch_item$status,
    error = NA_character_
  )
}

flatten_table_2025_11 <- function(batch_results, table_name) {
  dplyr::bind_rows(lapply(batch_results, function(item) {
    if (item$status != "success") {
      return(NULL)
    }

    tbl <- item$analysis[[table_name]]
    if (is.null(tbl) || nrow(tbl) == 0) {
      return(NULL)
    }

    dplyr::mutate(tbl, variable = item$variable, .before = 1)
  }))
}

flatten_omnibus_2025_11 <- function(batch_results) {
  dplyr::bind_rows(lapply(batch_results, function(item) {
    if (item$status != "success") {
      return(NULL)
    }

    item$analysis$omnibus %>%
      dplyr::mutate(variable = item$variable, .before = 1)
  }))
}

flatten_model_means_2025_11 <- function(batch_results) {
  dplyr::bind_rows(lapply(batch_results, function(item) {
    if (item$status != "success") {
      return(NULL)
    }

    item$analysis$model_means %>%
      dplyr::mutate(variable = item$variable, .before = 1)
  }))
}

flatten_posthoc_2025_11 <- function(batch_results) {
  dplyr::bind_rows(lapply(batch_results, function(item) {
    if (item$status != "success") {
      return(NULL)
    }

    tables <- item$analysis$posthoc$tables
    if (length(tables) == 0) {
      return(NULL)
    }

    dplyr::bind_rows(lapply(names(tables), function(name) {
      tables[[name]] %>%
        dplyr::mutate(
          variable = item$variable,
          posthoc_table = name,
          strategy = item$analysis$posthoc$strategy,
          .before = 1
        )
    }))
  }))
}

build_batch_tables_2025_11 <- function(batch_results, transform_audit = NULL) {
  summary <- dplyr::bind_rows(lapply(batch_results, build_lmm_summary_row_2025_11))

  list(
    summary = summary,
    omnibus = flatten_omnibus_2025_11(batch_results),
    descriptives = flatten_table_2025_11(batch_results, "descriptives"),
    completeness = flatten_table_2025_11(batch_results, "completeness"),
    model_means = flatten_model_means_2025_11(batch_results),
    posthoc = flatten_posthoc_2025_11(batch_results),
    transform_audit = transform_audit %||% tibble::tibble(),
    errors = summary %>% dplyr::filter(.data$status != "success")
  )
}

write_lmm_workbook_2025_11 <- function(batch_tables, output_file) {
  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)

  workbook <- openxlsx::createWorkbook()

  for (sheet_name in names(batch_tables)) {
    table <- batch_tables[[sheet_name]]
    if (is.null(table) || nrow(table) == 0) {
      table <- tibble::tibble(info = "Brak danych dla tej tabeli.")
    }

    safe_sheet <- substr(sheet_name, 1, 31)
    openxlsx::addWorksheet(workbook, safe_sheet)
    openxlsx::writeDataTable(workbook, safe_sheet, table)
  }

  openxlsx::saveWorkbook(workbook, output_file, overwrite = TRUE)
  output_file
}

run_lmm_batch_2025_11 <- function(data_path,
                                  variables = NULL,
                                  sheet = 1,
                                  output_dir = "2025-11/raporty_batch/raporty_lmm",
                                  workbook_name = "wyniki_lmm_2025_11.xlsx",
                                  write_workbook = TRUE) {
  df <- load_2025_11_data(data_path, sheet = sheet)

  if (is.null(variables)) {
    variables <- get_batch_variables_2025_11(df)
  }

  variables <- variables[variables %in% names(df)]
  transform_audit <- build_transform_audit_2025_11(df, variables = variables)
  batch_results <- lapply(variables, safe_run_lmm_analysis_2025_11, data_path = data_path, sheet = sheet)
  batch_tables <- build_batch_tables_2025_11(batch_results, transform_audit = transform_audit)

  workbook_file <- NA_character_
  if (isTRUE(write_workbook)) {
    workbook_file <- write_lmm_workbook_2025_11(batch_tables, file.path(output_dir, workbook_name))
  }

  list(
    data = df,
    variables = variables,
    results = batch_results,
    tables = batch_tables,
    workbook_file = workbook_file
  )
}
