# Usage: Configure active models, hyperparameters, and file paths.

# Usage: Set TRUE to enable the model, FALSE to disable.
active_models <- list(
  "bernoulli_mle"   = TRUE,
  "bernoulli_map"   = TRUE,
  "multinomial_mle" = TRUE,
  "multinomial_map" = TRUE
)

params <- list(
  # Set the smoothing parameter alpha for MAP estimation.
  "alpha" = 1.0
)

paths <- list(
  # Directory containing training text files organized by class folders.
  "train_data_dir"  = "data/learnU",
  
  # Directory containing test text files organized by class folders.
  "classify_data_dir" = "data/correctU",
  
  # Directory to store results and trained models.
  "output_dir" = "output",
  
  # File to save the trained R model object.
  "model_output_file" = "model_nb_trained.RData",
  
  # CSV file to save aggregated class statistics.
  "class_stats_output_file" = "stats_class.csv",
  
  # CSV file to save aggregated word statistics.
  "word_stats_output_file" = "stats_word.csv",
  
  # Source file containing the specific Bernoulli classification algorithm.
  "bernoulli_impl_file" = "src/alg_nb_classify.R"
)