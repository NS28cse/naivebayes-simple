# Configuration to enable or disable specific models.

active_models <- list(
  "bernoulli_mle"   = TRUE,
  "bernoulli_map"   = TRUE,
  "multinomial_mle" = TRUE,
  "multinomial_map" = TRUE
)

# Configuration for file paths.
paths <- list(
  "train_data_dir"  = "data/learnU",
  "classify_data_dir" = "data/correctU",
  "output_dir" = "output",
  "model_output_file" = "model_nb_trained.RData",
  "class_stats_output_file" = "stats_class.csv",
  "word_stats_output_file" = "stats_word.csv",
  
  # Path to the algorithm implementation file.
  # Use src/alg_nb_classify.R for the standard addition method.
  # Use src/alg_nb_classify_negative.R for the optimized subtraction method.
  "bernoulli_impl_file" = "src/alg_nb_classify.R"
)