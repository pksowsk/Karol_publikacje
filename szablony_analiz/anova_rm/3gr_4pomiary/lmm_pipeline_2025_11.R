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
  "fat_bh", "FAT/BH", NA_character_, "raw", "Analiza na skali surowej.",
  "ffm_bh", "FFM/BH", NA_character_, "raw", "Analiza na skali surowej.",
  "android_bh", "ANDROID/BH", NA_character_, "raw", "Analiza na skali surowej.",
  "fg_i", "FG/I", NA_character_, "log", "Skala ln(y) zgodna z ustalona mapa transformacji.",
  "adipo_crp", "ADIPO/CRP", NA_character_, "log", "Skala ln(y) zgodna z ustalona mapa transformacji.",
  "mets_ir", "METS-IR", NA_character_, "raw", "Analiza na skali surowej.",
  "homa_b", "HOMA-B", NA_character_, "log", "Skala ln(y) zgodna z ustalona mapa transformacji.",
  "obwod_pasa_cm", "Obwod pasa", "cm", "raw", "Analiza na skali surowej.",
  "skurczowe", "Cisnienie skurczowe", "mmHg", "raw", "Analiza na skali surowej.",
  "rozkurczowe", "Cisnienie rozkurczowe", "mmHg", "raw", "Analiza na skali surowej.",
  "crp_mg_l", "CRP", "mg/L", "log", "Skala ln(y) zgodna z ustalona mapa transformacji."
)

default_variable_label <- function(var) {
  pretty <- var %>%
    stringr::str_replace_all("_", " ") %>%
    stringr::str_squish()

  replacements <- c(
    "Fg I" = "FG/I",
    "Adipo Crp" = "ADIPO/CRP",
    "Homa B" = "HOMA-B",
    "Mets Ir" = "METS-IR",
    "Fat Bh" = "FAT/BH",
    "Ffm Bh" = "FFM/BH",
    "Android Bh" = "ANDROID/BH",
    "Crp Mg L" = "CRP",
    "Obwod Pasa Cm" = "Obwod pasa"
  )

  pretty <- stringr::str_to_title(pretty)
  dplyr::coalesce(replacements[[pretty]], pretty)
}

get_variable_meta_2025_11 <- function(var) {
  meta <- analysis_dictionary_2025_11 %>%
    dplyr::filter(.data$variable == var)

  if (nrow(meta) == 0) {
    meta <- tibble::tibble(
      variable = var,
      label = default_variable_label(var),
      unit = NA_character_,
      transform = "raw",
      transform_note = "Analiza na skali surowej (brak jawnej reguly transformacji dla tej zmiennej)."
    )
  }

  meta %>%
    dplyr::slice(1) %>%
    dplyr::mutate(
      display_label = ifelse(
        is.na(.data$unit),
        .data$label,
        paste0(.data$label, " [", .data$unit, "]")
      ),
      analysis_scale = dplyr::if_else(.data$transform == "log", "ln(y)", "y")
    )
}

load_2025_11_data <- function(path) {
  df_raw <- openxlsx::read.xlsx(path, sheet = 1) %>%
    janitor::clean_names()

  if (!"id_osoby" %in% names(df_raw)) {
    stop("W pliku danych nie znaleziono kolumny id_osoby.")
  }

  df <- df_raw %>%
    dplyr::filter(!is.na(.data$id_osoby)) %>%
    dplyr::rename(id_grupy = .data$id_osoby) %>%
    dplyr::mutate(
      interwencja = dplyr::case_when(
        .data$id_grupy == 1 ~ "Aerobowa",
        .data$id_grupy == 2 ~ "Silowa",
        .data$id_grupy == 3 ~ "Kontrolna",
        TRUE ~ NA_character_
      ),
      czas = dplyr::case_when(
        .data$id_pomiaru == 1 ~ "T1",
        .data$id_pomiaru == 2 ~ "T2",
        .data$id_pomiaru == 3 ~ "T3",
        .data$id_pomiaru == 4 ~ "T4",
        TRUE ~ NA_character_
      ),
      .before = .data$id_grupy
    ) %>%
    dplyr::mutate(
      dplyr::across(
        where(is.character),
        ~ trimws(.x, which = "both")
      )
    )

  person_id <- if ("imie" %in% names(df) && any(!is.na(df$imie) & nzchar(df$imie))) {
    paste0(df$nazwisko, "_", df$imie, "_", df$id_grupy)
  } else {
    paste0(df$nazwisko, "_", df$id_grupy)
  }

  df %>%
    dplyr::mutate(
      id_osoby = factor(person_id),
      czas = factor(.data$czas, levels = c("T1", "T2", "T3", "T4")),
      interwencja = factor(.data$interwencja, levels = c("Aerobowa", "Silowa", "Kontrolna"))
    )
}

get_batch_variables_2025_11 <- function(df) {
  excluded <- c("id_grupy", "id_pomiaru", "wysokosc_cm")

  variables <- df %>%
    dplyr::select(where(is.numeric)) %>%
    names() %>%
    setdiff(excluded)

  preferred_order <- analysis_dictionary_2025_11$variable
  ordered <- c(preferred_order[preferred_order %in% variables], setdiff(variables, preferred_order))

  unique(ordered)
}

build_sample_summary_2025_11 <- function(df, var) {
  observed <- df %>%
    dplyr::transmute(.data$id_osoby, wartosc = .data[[var]], czas = .data$czas) %>%
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
    dplyr::mutate(
      dplyr::across(where(is.numeric), ~ round(.x, 3))
    )
}

prepare_analysis_data_2025_11 <- function(df, var, meta) {
  analysis_df <- df %>%
    dplyr::transmute(
      id_osoby = .data$id_osoby,
      interwencja = .data$interwencja,
      czas = .data$czas,
      value_raw = .data[[var]]
    ) %>%
    dplyr::filter(!is.na(.data$value_raw))

  if (nrow(analysis_df) == 0) {
    stop("Po odfiltrowaniu brakow nie zostaly zadne obserwacje dla zmiennej ", var, ".")
  }

  if (meta$transform[[1]] == "log") {
    if (any(analysis_df$value_raw <= 0, na.rm = TRUE)) {
      stop("Transformacja logarytmiczna wymaga dodatnich obserwacji dla zmiennej ", var, ".")
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
  full_model <- lme4::lmer(
    value_model ~ interwencja * czas + (1 | id_osoby),
    data = analysis_df,
    REML = FALSE
  )

  additive_model <- lme4::lmer(
    value_model ~ interwencja + czas + (1 | id_osoby),
    data = analysis_df,
    REML = FALSE
  )

  no_time_model <- lme4::lmer(
    value_model ~ interwencja + (1 | id_osoby),
    data = analysis_df,
    REML = FALSE
  )

  no_group_model <- lme4::lmer(
    value_model ~ czas + (1 | id_osoby),
    data = analysis_df,
    REML = FALSE
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
  omnibus %>%
    dplyr::filter(.data$effect_key == effect_key) %>%
    dplyr::pull(.data$p_value) %>%
    .[[1]] %||% NA_real_
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
  pairwise <- emmeans::pairs(emm_grid, adjust = "holm")
  pairwise_summary <- as.data.frame(
    summary(pairwise, infer = c(TRUE, TRUE), level = 0.95)
  )

  if (!"lower.CL" %in% names(pairwise_summary) || !"upper.CL" %in% names(pairwise_summary)) {
    ci_tbl <- as.data.frame(confint(pairwise, level = 0.95))
    pairwise_summary <- pairwise_summary %>%
      dplyr::left_join(
        ci_tbl %>% dplyr::select(.data$contrast, .data$lower.CL, .data$upper.CL),
        by = "contrast"
      )
  }

  pairwise_summary %>%
    tidyr::separate(
      .data$contrast,
      into = c("porownanie_1", "porownanie_2"),
      sep = " - ",
      remove = FALSE,
      fill = "right"
    ) %>%
    dplyr::mutate(rodzina = family_label) %>%
    add_response_scale_2025_11(meta = meta) %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::any_of(c("estimate", "SE", "lower.CL", "upper.CL", "estimate_response", "lower_response", "upper_response")),
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
  emm_tbl <- as.data.frame(
    summary(emmeans::emmeans(fits$full, ~ interwencja * czas), infer = c(TRUE, TRUE))
  )

  if (!"lower.CL" %in% names(emm_tbl) || !"upper.CL" %in% names(emm_tbl)) {
    ci_tbl <- as.data.frame(confint(emmeans::emmeans(fits$full, ~ interwencja * czas)))
    emm_tbl <- emm_tbl %>%
      dplyr::left_join(
        ci_tbl %>% dplyr::select(.data$interwencja, .data$czas, .data$lower.CL, .data$upper.CL),
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
        scale_note = "Wykres pokazuje srednie modelowe po eksponentacji do skali oryginalnej."
      )
  } else {
    emm_tbl %>%
      dplyr::mutate(
        mean_display = .data$emmean,
        lower_display = .data$lower.CL,
        upper_display = .data$upper.CL,
        scale_note = "Wykres pokazuje srednie modelowe na skali surowej."
      )
  }
}

build_diagnostics_2025_11 <- function(full_model) {
  residuals_model <- resid(full_model)
  fitted_values <- fitted(full_model)

  shapiro_res <- if (length(residuals_model) >= 3 && length(residuals_model) <= 5000) {
    stats::shapiro.test(residuals_model)
  } else {
    NULL
  }

  list(
    shapiro = shapiro_res,
    singular = lme4::isSingular(full_model, tol = 1e-05),
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
    ggplot2::geom_line(
      ggplot2::aes(group = .data$id_osoby),
      alpha = 0.15,
      linewidth = 0.35
    ) +
    ggplot2::geom_point(alpha = 0.35, size = 1.2) +
    ggplot2::stat_summary(
      ggplot2::aes(group = .data$interwencja),
      fun = mean,
      geom = "line",
      linewidth = 1.1
    ) +
    ggplot2::stat_summary(
      ggplot2::aes(group = .data$interwencja),
      fun = mean,
      geom = "point",
      size = 2.8
    ) +
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
    ggplot2::aes(
      x = .data$czas,
      y = .data$mean_display,
      color = .data$interwencja,
      group = .data$interwencja
    )
  ) +
    ggplot2::geom_line(linewidth = 1.2) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_errorbar(
      ggplot2::aes(ymin = .data$lower_display, ymax = .data$upper_display),
      width = 0.12,
      linewidth = 0.8
    ) +
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

  diagnostics_plot <- {
    qq_plot <- ggplot2::ggplot(
      build_diagnostics_2025_11(lme4::getME(full_model = NULL)),
      ggplot2::aes(sample = .data$residuals)
    )
  }

  list(
    raw = raw_plot,
    emm = emm_plot
  )
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

run_lmm_analysis_2025_11 <- function(var, data_path) {
  df <- load_2025_11_data(data_path)
  meta <- get_variable_meta_2025_11(var)
  analysis_df <- prepare_analysis_data_2025_11(df, var, meta)
  fits <- fit_lmm_models_2025_11(analysis_df)
  omnibus <- build_omnibus_table_2025_11(fits)
  posthoc <- build_posthoc_tables_2025_11(fits, omnibus, meta)
  model_means <- build_model_means_2025_11(fits, meta)
  diagnostics <- build_diagnostics_2025_11(fits$full)

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
      raw = build_plots_2025_11(analysis_df, model_means, meta)$raw,
      emm = build_plots_2025_11(analysis_df, model_means, meta)$emm,
      diagnostics = build_diagnostic_plots_2025_11(diagnostics)
    )
  )
}

fmt_num_2025_11 <- function(x, digits = 3) {
  ifelse(is.na(x), NA_character_, formatC(x, format = "f", digits = digits))
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

  lines <- c()

  if (!is.na(p_interaction) && p_interaction < 0.05) {
    lines <- c(
      lines,
      paste0(
        "Najwazniejszy wynik: istotna interakcja grupa x czas (p = ",
        fmt_p_2025_11(p_interaction),
        ")."
      ),
      "Interpretacja powinna opierac sie glownie na porownaniach prostych, a nie na samych efektach glownych."
    )
  } else {
    lines <- c(
      lines,
      paste0(
        "Nie stwierdzono istotnej interakcji grupa x czas (p = ",
        fmt_p_2025_11(p_interaction),
        ")."
      )
    )
  }

  lines <- c(
    lines,
    paste0("Efekt grupy: p = ", fmt_p_2025_11(p_group), "."),
    paste0("Efekt czasu: p = ", fmt_p_2025_11(p_time), ".")
  )

  lines
}
