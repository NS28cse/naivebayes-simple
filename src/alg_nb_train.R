# src/alg_nb_train.R
# Implements the training logic for Naive Bayes classifiers.
# Contains functions for Multinomial and Bernoulli models, with both
# Maximum Likelihood Estimation (MLE) and MAP Estimation (with Laplace smoothing).

# Ensure data.table is available for efficient processing.
if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table")
}
library(data.table)

# 1. Multinomial Naive Bayes with Maximum Likelihood Estimation (MLE)
train_multinomial_nb_mle <- function(class_stats, word_stats) {
  # Calculate log priors.
  N <- sum(class_stats$N_c)
  log_priors <- log(class_stats$N_c / N)
  names(log_priors) <- class_stats$class
  
  # Use data.table for efficient aggregation.
  ws_dt <- as.data.table(word_stats)
  cs_dt <- as.data.table(class_stats)
  
  # Calculate log likelihoods.
  # If a class has no words (T_c = 0), probability is 0 (log prob is -Inf).
  log_likelihoods <- ws_dt[, .(
    word = word,
    log_prob = ifelse(
      cs_dt[class == .BY[[1]], T_c] > 0,
      log(T_wc / cs_dt[class == .BY[[1]], T_c]),
      -Inf
    )
  ), by = class]
  
  # Handle words never seen in a class: their probability is 0 (-Inf).
  # A wide format is necessary for classification.
  log_likelihoods_wide <- dcast(log_likelihoods, word ~ class, value.var = "log_prob", fill = -Inf)
  
  return(list(log_priors = log_priors, log_likelihoods = log_likelihoods_wide))
}

# 2. Multinomial Naive Bayes with MAP Estimation (Laplace Smoothing)
train_multinomial_nb_map <- function(class_stats, word_stats) {
  # Calculate log priors (same as MLE).
  N <- sum(class_stats$N_c)
  log_priors <- log(class_stats$N_c / N)
  names(log_priors) <- class_stats$class
  
  # Vocabulary size for smoothing.
  V <- length(unique(word_stats$word))
  
  ws_dt <- as.data.table(word_stats)
  cs_dt <- as.data.table(class_stats)
  
  # Calculate log likelihoods with Laplace smoothing (+1).
  log_likelihoods <- ws_dt[, .(
    word = word,
    log_prob = log((T_wc + 1) / (cs_dt[class == .BY[[1]], T_c] + V))
  ), by = class]
  
  # Calculate the log probability for unseen words in a class.
  unseen_word_log_prob <- cs_dt[, .(log_prob = log(1 / (T_c + V))), by = class]
  
  # Create a wide data.table, filling missing values with the unseen word probability.
  log_likelihoods_wide <- dcast(log_likelihoods, word ~ class, value.var = "log_prob")
  
  # This fill logic is a bit more complex with data.table dcast
  # We merge to get a full grid and then fill NAs.
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


# 3. Bernoulli Naive Bayes with Maximum Likelihood Estimation (MLE)
train_bernoulli_nb_mle <- function(class_stats, word_stats) {
  # Calculate log priors.
  N <- sum(class_stats$N_c)
  log_priors <- log(class_stats$N_c / N)
  names(log_priors) <- class_stats$class
  
  ws_dt <- as.data.table(word_stats)
  cs_dt <- as.data.table(class_stats)
  
  # Calculate log likelihoods.
  # If a class has no documents (N_c = 0), probability is 0 (log prob is -Inf).
  log_likelihoods <- ws_dt[, .(
    word = word,
    log_prob = ifelse(
      cs_dt[class == .BY[[1]], N_c] > 0,
      log(N_wc / cs_dt[class == .BY[[1]], N_c]),
      -Inf
    )
  ), by = class]
  
  # Handle words never seen in a class: their probability is 0 (-Inf).
  log_likelihoods_wide <- dcast(log_likelihoods, word ~ class, value.var = "log_prob", fill = -Inf)
  
  return(list(log_priors = log_priors, log_likelihoods = log_likelihoods_wide))
}

# 4. Bernoulli Naive Bayes with MAP Estimation (Laplace Smoothing)
train_bernoulli_nb_map <- function(class_stats, word_stats) {
  # Calculate log priors.
  N <- sum(class_stats$N_c)
  log_priors <- log(class_stats$N_c / N)
  names(log_priors) <- class_stats$class
  
  ws_dt <- as.data.table(word_stats)
  cs_dt <- as.data.table(class_stats)
  
  # Calculate log likelihoods with Laplace smoothing (+1 numerator, +2 denominator).
  log_likelihoods <- ws_dt[, .(
    word = word,
    log_prob = log((N_wc + 1) / (cs_dt[class == .BY[[1]], N_c] + 2))
  ), by = class]
  
  # Calculate log prob for unseen words
  unseen_word_log_prob <- cs_dt[, .(log_prob = log(1 / (N_c + 2))), by = class]
  
  # Create a wide data.table, filling missing values.
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