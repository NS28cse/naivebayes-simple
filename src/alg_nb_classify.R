# src/alg_nb_classify.R
# Implements the classification (inference) logic for Naive Bayes classifiers.

# Helper function to read a document and return its words.
get_words_from_doc <- function(filepath) {
  # Assuming files are UTF-8 encoded.
  text_content <- readLines(filepath, encoding = "UTF-8", warn = FALSE)
  words <- unlist(strsplit(text_content, "\\s+"))
  return(words[words != ""]) # Remove empty strings
}

# Classifies a document using a Multinomial Naive Bayes model.
classify_with_multinomial <- function(words_in_doc, model) {
  log_priors <- model$log_priors
  log_likelihoods <- model$log_likelihoods
  
  # Set word column as rownames for fast lookup.
  # Using data.table for robustness and speed.
  setDT(log_likelihoods)
  setkey(log_likelihoods, word)
  
  # Initialize scores with log priors for each class.
  class_scores <- log_priors
  
  # Filter words in the document to those present in our model's vocabulary.
  doc_vocab <- words_in_doc[words_in_doc %in% log_likelihoods$word]
  
  if (length(doc_vocab) > 0) {
    # Sum the log likelihoods for all occurrences of words in the document.
    word_probs_dt <- log_likelihoods[doc_vocab, !"word"]
    # colSums efficiently adds up the log probabilities for each class.
    class_scores <- class_scores + colSums(word_probs_dt)
  }
  
  # Return the name of the class with the highest score.
  return(names(which.max(class_scores)))
}

# Classifies a document using a Bernoulli Naive Bayes model.
classify_with_bernoulli <- function(words_in_doc, model) {
  log_priors <- model$log_priors
  log_likelihoods <- model$log_likelihoods
  
  # Set up likelihood matrices for words present and absent.
  setDT(log_likelihoods)
  setkey(log_likelihoods, word)
  
  # Log probability of a word *NOT* appearing: log(1 - P(w|c)).
  # This can be calculated from log(1 - exp(log_likelihood)).
  # Use log1p for numerical stability: log1p(-exp(log_p)) is more accurate than log(1-exp(log_p))
  # Suppress warnings for -Inf cases where exp(-Inf) = 0.
  suppressWarnings({
    log_neg_likelihoods <- copy(log_likelihoods)
    log_neg_likelihoods[, (names(log_likelihoods)[-1]) := lapply(.SD, function(x) log1p(-exp(x))), .SDcols = -1]
  })
  
  # Initialize score with priors + sum of log probabilities for ALL vocabulary
  # words NOT being in the document.
  class_scores <- log_priors + colSums(log_neg_likelihoods[, !"word"], na.rm = TRUE)
  
  # Get the unique words from the document that are in our vocabulary.
  doc_vocab_present <- unique(words_in_doc)
  doc_vocab_present <- doc_vocab_present[doc_vocab_present %in% log_likelihoods$word]
  
  if (length(doc_vocab_present) > 0) {
    # For each word that IS present in the document, we correct the score.
    # We subtract the "not present" probability and add the "present" probability.
    # This is equivalent to: score += log(P(w|c)) - log(1-P(w|c))
    corrections_present <- log_likelihoods[doc_vocab_present, !"word"]
    corrections_absent  <- log_neg_likelihoods[doc_vocab_present, !"word"]
    
    # Calculate the total correction needed for each class.
    total_corrections <- colSums(corrections_present, na.rm = TRUE) - colSums(corrections_absent, na.rm = TRUE)
    class_scores <- class_scores + total_corrections
  }
  
  # Return the name of the class with the highest score.
  return(names(which.max(class_scores)))
}