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
  log_likelihoods <- model$log_likelihoods
  
  setDT(log_likelihoods)
  setkey(log_likelihoods, word)
  
  class_scores <- log_priors
  
  # Filter to words present in the model's vocabulary.
  doc_vocab <- words_in_doc[words_in_doc %in% log_likelihoods$word]
  
  if (length(doc_vocab) > 0) {
    # Sum the log likelihoods for all word occurrences.
    word_probs_dt <- log_likelihoods[doc_vocab, !"word"]
    class_scores <- class_scores + colSums(word_probs_dt)
  }
  
  return(names(which.max(class_scores)))
}

# Classifies a document using a Bernoulli Naive Bayes model.
classify_with_bernoulli <- function(words_in_doc, model) {
  log_priors <- model$log_priors
  log_likelihoods <- model$log_likelihoods
  
  setDT(log_likelihoods)
  setkey(log_likelihoods, word)
  
  # Calculate log(1 - P(w|c)) for all words. Use log1p for numerical stability.
  suppressWarnings({
    log_neg_likelihoods <- copy(log_likelihoods)
    log_neg_likelihoods[, (names(log_likelihoods)[-1]) := lapply(.SD, function(x) log1p(-exp(x))), .SDcols = -1]
  })
  
  # Initialize score with priors + sum of log probs for ALL words NOT in doc.
  class_scores <- log_priors + colSums(log_neg_likelihoods[, !"word"], na.rm = TRUE)
  
  # Get unique words from the document that are in our vocabulary.
  doc_vocab_present <- unique(words_in_doc)
  doc_vocab_present <- doc_vocab_present[doc_vocab_present %in% log_likelihoods$word]
  
  if (length(doc_vocab_present) > 0) {
    # Correct the score for words that ARE present.
    # score += log(P(w|c)) - log(1-P(w|c)).
    corrections_present <- log_likelihoods[doc_vocab_present, !"word"]
    corrections_absent  <- log_neg_likelihoods[doc_vocab_present, !"word"]
    
    total_corrections <- colSums(corrections_present, na.rm = TRUE) - colSums(corrections_absent, na.rm = TRUE)
    class_scores <- class_scores + total_corrections
  }
  
  return(names(which.max(class_scores)))
}