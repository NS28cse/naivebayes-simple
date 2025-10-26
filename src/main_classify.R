# src/main_classify.R
# Main script for classification and evaluation.

source('src/config.R') # Load configuration
source('src/alg_nb_classify.R')

model_input_path <- file.path(paths$output_dir, paths$model_output_file)
classification_data_dir <- paths$classify_data_dir

# 1. Load Models.
cat("1. Load Models\n")
if (!file.exists(model_input_path)) {
  stop("Model file not found. Please run the training script (main_train.R) first.")
}
load(model_input_path) # Loads the 'models' list object.
cat("   ...loaded", length(models), "models from", model_input_path, "\n")

# 2. Find Files and Prepare for Evaluation.
cat("2. Find Files and Prepare for Evaluation\n")
# Recursively find all .txt files in the test directory.
files_to_classify <- list.files(
  path = classification_data_dir,
  pattern = "\\.txt$",
  recursive = TRUE,
  full.names = TRUE
)
if (length(files_to_classify) == 0) {
  stop("No text files found in the classification directory.")
}
cat("   ...", length(files_to_classify), "files found for classification.\n")

model_names <- names(models)
correct_counts <- setNames(rep(0, length(model_names)), model_names)

# 3. Classify Documents and Evaluate.
cat("3. Classify Documents and Evaluate\n")
# Loop through each file, classify it, and check against the true label.
for (filepath in files_to_classify) {
  # The true class is the parent directory name.
  true_class <- basename(dirname(filepath))
  
  words_in_doc <- get_words_from_doc(filepath)
  
  # Classify with each available model.
  for (model_name in model_names) {
    model_obj <- models[[model_name]]
    predicted_class <- NA
    
    # Choose the correct classification function based on model name.
    if (grepl("multinomial", model_name)) {
      predicted_class <- classify_with_multinomial(words_in_doc, model_obj)
    } else if (grepl("bernoulli", model_name)) {
      predicted_class <- classify_with_bernoulli(words_in_doc, model_obj)
    }
    
    # Check if the prediction was correct.
    if (!is.na(predicted_class) && predicted_class == true_class) {
      correct_counts[model_name] <- correct_counts[model_name] + 1
    }
  }
}
cat("   ...classification and evaluation complete.\n")

# 4. Display Final Results.
cat("4. Display Final Accuracy Results\n")
total_files <- length(files_to_classify)
cat("----------------------------------------\n")
cat("Model Accuracy on", total_files, "documents:\n")

for (model_name in model_names) {
  accuracy <- (correct_counts[model_name] / total_files) * 100
  cat(sprintf(
    " - %-18s: %5.1f%% (%d / %d)\n",
    model_name,
    accuracy,
    correct_counts[model_name],
    total_files
  ))
}
cat("----------------------------------------\n")
cat("Classification process complete.\n")
