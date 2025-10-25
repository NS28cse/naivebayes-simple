# main_train_nb.R.
# This file is the main script to train the Naive Bayes models.
# It orchestrates the entire training pipeline, including:
# 1. Aggregating statistics from raw text data using a Perl script.
# 2. Parsing the aggregated statistics using the efficient fread function.
# 3. Training multiple Naive Bayes models based on the configuration.
# 4. Saving the trained models and statistics to the output directory.

# Load the data.table library to use the fread function for robust file reading.
if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table")
}
library(data.table)

# 0. Setup.
# Load the model configuration and the training algorithm implementations.
source('src/config.R')
source('src/alg_nb_train.R')

# 1. Data Aggregation.
cat("1. Data Aggregation\n")
# Define paths for temporary files where the Perl script will write its output.
# This file-based approach is more robust than capturing stdout.
temp_class_stats_file <- tempfile(fileext = ".csv")
temp_word_stats_file  <- tempfile(fileext = ".csv")

# Define the absolute path to the training data directory to avoid ambiguity.
train_data_dir <- file.path(getwd(), "data", "learnU")

# Execute the Perl script for data aggregation.
# We pass the data directory and output file paths as command-line arguments.
system_status <- system2(
  'perl',
  args = c(
    'src/util_text_aggregate.pl',
    train_data_dir,
    temp_class_stats_file,
    temp_word_stats_file
  ),
  stdout = FALSE, # We do not need to capture stdout.
  stderr = FALSE  # We do not need to capture stderr.
)

# Check if the Perl script executed successfully. A non-zero status indicates an error.
if (system_status != 0) {
  stop("Perl script for data aggregation failed with status ", system_status, ".")
}
cat("   ...aggregation successful.\n")

# 2. Data Parsing.
cat("2. Data Parsing\n")
# Use fread for fast and reliable parsing of the statistics files.
# fread automatically detects column types more accurately than base read.csv.
# Added quote = "" to treat double-quotes as part of the data, not as a quoting character.
# This resolves warnings caused by words containing quotation marks.
class_stats <- fread(temp_class_stats_file, sep = "\t", quote = "")
word_stats  <- fread(temp_word_stats_file, sep = "\t", quote = "")

# Clean up by removing the temporary files after they have been successfully read.
unlink(c(temp_class_stats_file, temp_word_stats_file))
cat("   ...parsing complete.\n")

# 3. Model Training.
cat("3. Model Training (based on config.R)\n")
# Initialize an empty list to store the trained model objects.
models <- list()

# Conditionally train each model if it is enabled in the config.R file.
if (active_models$multinomial_mle) {
  cat("   ...training Multinomial (MLE) model.\n")
  models$multinomial_mle <- train_multinomial_nb_mle(class_stats, word_stats)
}
if (active_models$multinomial_map) {
  cat("   ...training Multinomial (MAP) model.\n")
  models$multinomial_map <- train_multinomial_nb_map(class_stats, word_stats)
}
if (active_models$bernoulli_mle) {
  cat("   ...training Bernoulli (MLE) model.\n")
  models$bernoulli_mle <- train_bernoulli_nb_mle(class_stats, word_stats)
}
if (active_models$bernoulli_map) {
  cat("   ...training Bernoulli (MAP) model.\n")
  models$bernoulli_map <- train_bernoulli_nb_map(class_stats, word_stats)
}

# 4. Save Training Artifacts.
cat("4. Save Training Artifacts\n")
# Ensure the output directory exists before writing files to it.
output_dir <- "output"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Define the full paths for the output files.
model_path <- file.path(output_dir, "model_nb_trained.RData")
class_stats_path <- file.path(output_dir, "stats_class.csv")
word_stats_path <- file.path(output_dir, "stats_word.csv")

# Save the aggregated statistics as CSV files for inspection and debugging.
cat("   ...saving aggregated statistics to CSV.\n")
write.csv(class_stats, class_stats_path, row.names = FALSE)
write.csv(word_stats, word_stats_path, row.names = FALSE)

# Save the list of trained model objects to a single .RData file.
# This file will be loaded during the classification phase.
cat("   ...saving trained models to", model_path, "\n")
save(models, file = model_path)

cat("Training process complete.\n")