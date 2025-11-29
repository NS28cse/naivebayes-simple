# Configuration to enable or disable specific models.

active_models <- list(
  "bernoulli_mle"   = TRUE,
  "bernoulli_map"   = TRUE,
  "multinomial_mle" = TRUE,
  "multinomial_map" = TRUE
)

# Configuration for file paths.
paths <- list(
  # Input directories
  "train_data_dir"  = "data/learnU",
  "classify_data_dir" = "data/correctU",
  
  # Output directory
  "output_dir" = "output",
  
  # Artifact filenames
  "model_output_file" = "model_nb_trained.RData",
  "class_stats_output_file" = "stats_class.csv",
  "word_stats_output_file" = "stats_word.csv"
)