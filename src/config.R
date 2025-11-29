# Configuration to enable or disable specific models.
active_models <- list(
  "bernoulli_mle"   = TRUE,
  "bernoulli_map"   = TRUE,
  "multinomial_mle" = TRUE,
  "multinomial_map" = TRUE
)

# Hyperparameters for the models.
params <- list(
  "alpha" = 100.0
)

# Configuration for file paths.
paths <- list(
  "train_data_dir"  = "data/learnU",
  "classify_data_dir" = "data/correctU",
  "output_dir" = "output",
  "model_output_file" = "model_nb_trained.RData",
  "class_stats_output_file" = "stats_class.csv",
  "word_stats_output_file" = "stats_word.csv",
  "bernoulli_impl_file" = "src/alg_nb_classify.R"
)