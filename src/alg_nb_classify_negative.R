# Implementation of the optimized classification logic using subtraction.
# This version handles finite and infinite values strictly without approximation.

if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table")
}
library(data.table)

# Initialization hook to pre-calculate scores.
init_bernoulli_model <- function(model) {
  log_lik <- copy(model$log_likelihoods)
  setkey(log_lik, word)
  class_cols <- setdiff(names(log_lik), "word")
  
  # 1. Calculate log(1 - P).
  # For MAP, this is always finite.
  # For MLE, if P=1, this becomes -Inf.
  log_neg <- copy(log_lik)
  for (col in class_cols) {
    # Use log1p(-exp(x)) for numerical precision.
    set(log_neg, j = col, value = log1p(-exp(log_lik[[col]])))
  }
  
  # 2. Identify "Must-Have" words for strictly infinite cases (MLE).
  # If log_neg is -Inf, it means P(w|c) = 1.
  # The document MUST contain this word, otherwise the score becomes -Inf.
  must_have_list <- list()
  for (col in class_cols) {
    # Find words where log(1-P) is -Inf.
    is_inf <- is.infinite(log_neg[[col]])
    if (any(is_inf)) {
      must_have_list[[col]] <- log_neg$word[is_inf]
    }
  }
  
  # 3. Create "Finite" versions for safe arithmetic.
  # We replace -Inf with 0 to perform the summation of the finite parts.
  log_neg_finite <- copy(log_neg)
  for (col in class_cols) {
    val <- log_neg_finite[[col]]
    val[is.infinite(val)] <- 0
    set(log_neg_finite, j = col, value = val)
  }
  
  # Base Score = Log Priors + Sum of Finite log(1-P).
  base_scores <- model$log_priors + colSums(log_neg_finite[, ..class_cols])
  
  # 4. Create Diff Table = log(P) - log(1-P).
  # If P=1, log(P)=0 and log(1-P)=-Inf. The Diff is Inf.
  # We replace Inf with 0 because logic relies on the "Must-Have" check instead.
  diff_dt <- copy(log_lik)
  for (col in class_cols) {
    val_lik <- log_lik[[col]]
    val_neg <- log_neg[[col]] 
    d <- val_lik - val_neg
    d[d == Inf] <- 0
    set(diff_dt, j = col, value = d)
  }
  
  model$base_class_scores <- base_scores
  model$diff_dt <- diff_dt
  model$must_have_list <- must_have_list
  model$vocab_index <- log_lik$word
  
  return(model)
}

# Reads a document and extracts words.
get_words_from_doc <- function(filepath) {
  text_content <- readLines(filepath, encoding = "UTF-8", warn = FALSE)
  words <- unlist(strsplit(text_content, "\\s+"))
  return(words[words != ""])
}

# Classifies a document using the Multinomial model.
classify_with_multinomial <- function(words_in_doc, model) {
  log_priors <- model$log_priors
  log_likelihoods_dt <- copy(model$log_likelihoods)
  setkey(log_likelihoods_dt, word)
  
  class_scores <- log_priors
  doc_vocab <- words_in_doc[words_in_doc %in% log_likelihoods_dt$word]
  
  if (length(doc_vocab) > 0) {
    word_probs_dt <- log_likelihoods_dt[doc_vocab, !"word"]
    class_scores <- class_scores + colSums(word_probs_dt)
  }
  return(names(which.max(class_scores)))
}

# Classifies a document using the Bernoulli model with strict logic.
classify_with_bernoulli <- function(words_in_doc, model) {
  # Start with the finite base score.
  class_scores <- model$base_class_scores
  
  valid_words <- unique(words_in_doc[words_in_doc %in% model$vocab_index])
  
  if (length(valid_words) > 0) {
    # Add differences for present words.
    diffs <- model$diff_dt[valid_words, !"word"]
    class_scores <- class_scores + colSums(diffs, na.rm = TRUE)
  }
  
  # Strict Veto Check for MLE correctness.
  # If a class expects a word with P=1 (must_have), and it is missing,
  # the term log(1-P) becomes -Inf, making the total score -Inf.
  if (length(model$must_have_list) > 0) {
    for (cls in names(model$must_have_list)) {
      needed_words <- model$must_have_list[[cls]]
      if (!is.null(needed_words) && length(needed_words) > 0) {
        # Check if any needed word is missing.
        if (!all(needed_words %in% valid_words)) {
          class_scores[cls] <- -Inf
        }
      }
    }
  }
  
  return(names(which.max(class_scores)))
}