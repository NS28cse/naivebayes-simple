# Implement training logic for Naive Bayes classifiers.

if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table")
}
library(data.table)

# Train a Multinomial Naive Bayes model using MLE.
train_multinomial_nb_mle <- function(class_stats, word_stats) {
  # Calculate log priors based on class counts.
  N <- sum(class_stats$N_c)
  log_priors <- log(class_stats$N_c / N)
  names(log_priors) <- class_stats$class
  
  ws_dt <- as.data.table(word_stats)
  cs_dt <- as.data.table(class_stats)
  
  # Calculate log likelihoods from word counts.
  log_likelihoods <- ws_dt[, .(
    word = word,
    log_prob = ifelse(
      cs_dt[class == .BY[[1]], T_c] > 0,
      log(T_wc / cs_dt[class == .BY[[1]], T_c]),
      -Inf
    )
  ), by = class]
  
  log_likelihoods_wide <- dcast(log_likelihoods, word ~ class, value.var = "log_prob", fill = -Inf)
  
  return(list(log_priors = log_priors, log_likelihoods = log_likelihoods_wide))
}

# Train a Multinomial Naive Bayes model using MAP estimation with smoothing.
train_multinomial_nb_map <- function(class_stats, word_stats, alpha = 2.0) {
  smoothing_numerator <- alpha - 1
  
  # Calculate log priors with smoothing.
  N <- sum(class_stats$N_c)
  num_classes <- nrow(class_stats)
  log_priors <- log((class_stats$N_c + smoothing_numerator) / (N + num_classes * smoothing_numerator))
  names(log_priors) <- class_stats$class
  
  V <- length(unique(word_stats$word))
  
  ws_dt <- as.data.table(word_stats)
  cs_dt <- as.data.table(class_stats)
  
  # Calculate log likelihoods with smoothing.
  log_likelihoods <- ws_dt[, .(
    word = word,
    log_prob = log((T_wc + smoothing_numerator) / (cs_dt[class == .BY[[1]], T_c] + V * smoothing_numerator))
  ), by = class]
  
  # Handle unseen words using the smoothing term.
  unseen_word_log_prob <- cs_dt[, .(log_prob = log(smoothing_numerator / (T_c + V * smoothing_numerator))), by = class]
  
  all_words <- unique(ws_dt$word)
  all_classes <- unique(ws_dt$class)
  full_grid <- CJ(word = all_words, class = all_classes)
  
  merged_dt <- merge(full_grid, log_likelihoods, by = c("word", "class"), all.x = TRUE)
  merged_dt <- merge(merged_dt, unseen_word_log_prob, by = "class")
  merged_dt[is.na(log_prob.x), log_prob.x := log_prob.y]
  merged_dt[, log_prob.y := NULL]
  setnames(merged_dt, "log_prob.x", "log_prob")
  
  log_likelihoods_wide <- dcast(merged_dt, word ~ class, value.var = "log_prob")
  
  return(list(log_priors = log_priors, log_likelihoods = log_likelihoods_wide))
}

# Train a Bernoulli Naive Bayes model using MLE.
train_bernoulli_nb_mle <- function(class_stats, word_stats) {
  # Calculate log priors based on class counts.
  N <- sum(class_stats$N_c)
  log_priors <- log(class_stats$N_c / N)
  names(log_priors) <- class_stats$class
  
  ws_dt <- as.data.table(word_stats)
  cs_dt <- as.data.table(class_stats)
  
  # Calculate log likelihoods from document counts.
  log_likelihoods <- ws_dt[, .(
    word = word,
    log_prob = ifelse(
      cs_dt[class == .BY[[1]], N_c] > 0,
      log(N_wc / cs_dt[class == .BY[[1]], N_c]),
      -Inf
    )
  ), by = class]
  
  log_likelihoods_wide <- dcast(log_likelihoods, word ~ class, value.var = "log_prob", fill = -Inf)
  
  return(list(log_priors = log_priors, log_likelihoods = log_likelihoods_wide))
}

# Train a Bernoulli Naive Bayes model using MAP estimation with smoothing.
train_bernoulli_nb_map <- function(class_stats, word_stats, alpha = 2.0) {
  smoothing_numerator <- alpha - 1
  
  # Calculate log priors with smoothing.
  N <- sum(class_stats$N_c)
  num_classes <- nrow(class_stats)
  log_priors <- log((class_stats$N_c + smoothing_numerator) / (N + num_classes * smoothing_numerator))
  names(log_priors) <- class_stats$class
  
  ws_dt <- as.data.table(word_stats)
  cs_dt <- as.data.table(class_stats)
  
  # Calculate log likelihoods with smoothing.
  log_likelihoods <- ws_dt[, .(
    word = word,
    log_prob = log((N_wc + smoothing_numerator) / (cs_dt[class == .BY[[1]], N_c] + 2 * smoothing_numerator))
  ), by = class]
  
  # Handle unseen words using the smoothing term.
  unseen_word_log_prob <- cs_dt[, .(log_prob = log(smoothing_numerator / (N_c + 2 * smoothing_numerator))), by = class]
  
  all_words <- unique(ws_dt$word)
  all_classes <- unique(ws_dt$class)
  full_grid <- CJ(word = all_words, class = all_classes)
  
  merged_dt <- merge(full_grid, log_likelihoods, by = c("word", "class"), all.x = TRUE)
  merged_dt <- merge(merged_dt, unseen_word_log_prob, by = "class")
  merged_dt[is.na(log_prob.x), log_prob.x := log_prob.y]
  merged_dt[, log_prob.y := NULL]
  setnames(merged_dt, "log_prob.x", "log_prob")
  
  log_likelihoods_wide <- dcast(merged_dt, word ~ class, value.var = "log_prob")
  
  return(list(log_priors = log_priors, log_likelihoods = log_likelihoods_wide))
}