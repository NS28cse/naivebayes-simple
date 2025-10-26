# src/alg_nb_classify.R
# Implements the classification (inference) logic.

# Reads a document and returns its words.
get_words_from_doc <- function(filepath) {
  # Assumes UTF-8 encoded files.
  text_content <- readLines(filepath, encoding = "UTF-8", warn = FALSE)
  words <- unlist(strsplit(text_content, "\\s+"))
  return(words[words != ""])
}

# Classifies a document using a Multinomial Naive Bayes model.
classify_with_multinomial <- function(words_in_doc, model) {
  log_priors <- model$log_priors
  
  # FIX 2: Use copy() to prevent modifying the original model object (side effect).
  log_likelihoods_dt <- copy(model$log_likelihoods)
  setkey(log_likelihoods_dt, word)
  
  class_scores <- log_priors
  
  # Filter to words present in the model's vocabulary.
  doc_vocab <- words_in_doc[words_in_doc %in% log_likelihoods_dt$word]
  
  if (length(doc_vocab) > 0) {
    # Sum the log likelihoods for all word occurrences.
    word_probs_dt <- log_likelihoods_dt[doc_vocab, !"word"]
    class_scores <- class_scores + colSums(word_probs_dt)
  }
  
  return(names(which.max(class_scores)))
}

# Classifies a document using a Bernoulli Naive Bayes model.
classify_with_bernoulli <- function(words_in_doc, model) {
  log_priors <- model$log_priors
  
  # FIX 2: Use copy() to prevent modifying the original model object (side effect).
  log_likelihoods_dt <- copy(model$log_likelihoods)
  setkey(log_likelihoods_dt, word)
  
  # FIX 1: Reworked logic to prevent NaN bug (Inf - Inf).
  # We will use the formula:
  # Score = log(P(c)) + SUM_words_IN_doc[log(P(w|c))] + SUM_words_NOT_in_doc[log(1-P(w|c))]
  
  # Calculate log(1 - P(w|c)) for all words. Use log1p for numerical stability.
  suppressWarnings({
    log_neg_likelihoods_dt <- copy(log_likelihoods_dt)
    log_neg_likelihoods_dt[, (names(log_likelihoods_dt)[-1]) := lapply(.SD, function(x) log1p(-exp(x))), .SDcols = -1]
  })
  
  # Initialize score with priors.
  class_scores <- log_priors
  
  # Get unique words from the document that are in our vocabulary.
  all_model_vocab <- log_likelihoods_dt$word
  doc_vocab_present <- unique(words_in_doc)
  doc_vocab_present <- doc_vocab_present[doc_vocab_present %in% all_model_vocab]
  
  # 1. Add scores for words PRESENT in the document: SUM[log(P(w|c))]
  if (length(doc_vocab_present) > 0) {
    present_scores <- log_likelihoods_dt[doc_vocab_present, !"word"]
    class_scores <- class_scores + colSums(present_scores, na.rm = TRUE)
  }
  
  # 2. Add scores for words ABSENT from the document: SUM[log(1-P(w|c))]
  doc_vocab_absent <- setdiff(all_model_vocab, doc_vocab_present)
  
  if (length(doc_vocab_absent) > 0) {
    absent_scores <- log_neg_likelihoods_dt[doc_vocab_absent, !"word"]
    # In the case of P(w|c)=1, log(1-P) = -Inf. 
    # na.rm=TRUE handles missing words (though shouldn't happen here),
    # but the -Inf sum is correct and will dominate, as it should.
    class_scores <- class_scores + colSums(absent_scores, na.rm = TRUE)
  }
  
  return(names(which.max(class_scores)))
}