# src/main_classify.R
# Main script for classification and evaluation.

source('src/config.R')
source('src/alg_nb_classify.R')

if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table")
}
library(data.table)

model_input_path <- file.path(paths$output_dir, paths$model_output_file)
classification_data_dir <- paths$classify_data_dir

# 1. Load Models.
if (!file.exists(model_input_path)) {
  stop("Model file not found. Please run the training script first.")
}
load(model_input_path)
cat("1. Models loaded from", model_input_path, "\n")

# 2. Preprocess Data with Perl.
# Use a temporary file to exchange data between Perl and R.
temp_classify_data <- tempfile(fileext = ".tsv")

# Execute the Perl script to convert text files into a TSV format for efficient loading.
system_status <- system2(
  'perl',
  args = c(
    'src/util_classify.pl',
    classification_data_dir,
    temp_classify_data
  ),
  stdout = FALSE, 
  stderr = FALSE
)

if (system_status != 0) {
  stop("Perl preprocessing failed with status ", system_status, ".")
}

# Load the preprocessed data using fread.
dt_test <- fread(temp_classify_data, sep = "\t", header = TRUE, encoding = "UTF-8", quote = "")
unlink(temp_classify_data)

if (nrow(dt_test) == 0) {
  stop("No data found for classification.")
}

# Extract unique document metadata for evaluation.
docs_metadata <- unique(dt_test[, .(doc_id, true_class)])
total_files <- nrow(docs_metadata)
cat("2. Data loaded.", total_files, "documents found.\n")

model_names <- names(models)
correct_counts <- setNames(rep(0, length(model_names)), model_names)

# 3. Classify Documents and Evaluate.
cat("3. Classify Documents and Evaluate\n")

# Helper function to dispatch the appropriate classification logic.
apply_classification <- function(words, model, model_name) {
  if (grepl("multinomial", model_name)) {
    return(classify_with_multinomial(words, model))
  } else if (grepl("bernoulli", model_name)) {
    return(classify_with_bernoulli(words, model))
  }
  return(NA_character_)
}

for (model_name in model_names) {
  cat("   ...evaluating", model_name, "\n")
  model_obj <- models[[model_name]]
  
  # Apply classification for each document group.
  predictions <- dt_test[, .(
    predicted_class = apply_classification(word, model_obj, model_name)
  ), by = doc_id]
  
  # Compare predictions with true classes.
  results <- merge(predictions, docs_metadata, by = "doc_id")
  num_correct <- nrow(results[predicted_class == true_class])
  correct_counts[model_name] <- num_correct
}

# 4. Display Final Results.
cat("4. Display Final Accuracy Results\n")
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

# 5. Update Result Matrix.
source('src/save_result.R')
cat("Classification process complete.\n")