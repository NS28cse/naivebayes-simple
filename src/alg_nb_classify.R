# Implementation of the standard classification logic.

if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table")
}
library(data.table)

# Initialization hook for the standard algorithm.
init_bernoulli_model <- function(model) {
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

# Classifies a document using the Bernoulli model with standard addition logic.
classify_with_bernoulli <- function(words_in_doc, model) {
  log_priors <- model$log_priors
  
  log_likelihoods_dt <- copy(model$log_likelihoods)
  setkey(log_likelihoods_dt, word)
  
  suppressWarnings({
    log_neg_likelihoods_dt <- copy(log_likelihoods_dt)
    log_neg_likelihoods_dt[, (names(log_likelihoods_dt)[-1]) := lapply(.SD, function(x) log1p(-exp(x))), .SDcols = -1]
  })
  
  class_scores <- log_priors
  all_model_vocab <- log_likelihoods_dt$word
  
  doc_vocab_present <- unique(words_in_doc)
  doc_vocab_present <- doc_vocab_present[doc_vocab_present %in% all_model_vocab]
  
  if (length(doc_vocab_present) > 0) {
    present_scores <- log_likelihoods_dt[doc_vocab_present, !"word"]
    class_scores <- class_scores + colSums(present_scores, na.rm = TRUE)
  }
  
  doc_vocab_absent <- setdiff(all_model_vocab, doc_vocab_present)
  if (length(doc_vocab_absent) > 0) {
    absent_scores <- log_neg_likelihoods_dt[doc_vocab_absent, !"word"]
    class_scores <- class_scores + colSums(absent_scores, na.rm = TRUE)
  }
  
  return(names(which.max(class_scores)))
}