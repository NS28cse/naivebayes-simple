# main_train_nb.R.
# Main script for the training pipeline.

if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table")
}
library(data.table)

source('src/config.R')
source('src/alg_nb_train.R')

# 1. Data Aggregation.
cat("1. Data Aggregation\n")
# Use temporary files for robust communication with the Perl script.
temp_class_stats_file <- tempfile(fileext = ".csv")
temp_word_stats_file  <- tempfile(fileext = ".csv")

train_data_dir <- file.path(getwd(), "data", "learnU")

# Execute the Perl script to aggregate statistics from text files.
system_status <- system2(
  'perl',
  args = c(
    'src/util_text_aggregate.pl',
    train_data_dir,
    temp_class_stats_file,
    temp_word_stats_file
  ),
  stdout = FALSE, 
  stderr = FALSE
)

if (system_status != 0) {
  stop("Perl script for data aggregation failed with status ", system_status, ".")
}
cat("   ...aggregation successful.\n")

# 2. Data Parsing.
cat("2. Data Parsing\n")
# Parse the aggregated statistics using fread for speed.
# quote = "" prevents errors if words contain quotation marks.
class_stats <- fread(temp_class_stats_file, sep = "\t", quote = "")
word_stats  <- fread(temp_word_stats_file, sep = "\t", quote = "")

unlink(c(temp_class_stats_file, temp_word_stats_file))
cat("   ...parsing complete.\n")

# 3. Model Training.
cat("3. Model Training (based on config.R)\n")
models <- list()

# Conditionally train models based on the config file.
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
output_dir <- "output"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

model_path <- file.path(output_dir, "model_nb_trained.RData")
class_stats_path <- file.path(output_dir, "stats_class.csv")
word_stats_path <- file.path(output_dir, "stats_word.csv")

# Save aggregated statistics for inspection.
cat("   ...saving aggregated statistics to CSV.\n")
write.csv(class_stats, class_stats_path, row.names = FALSE)
write.csv(word_stats, word_stats_path, row.names = FALSE)

# Save the trained model list for the classification script.
cat("   ...saving trained models to", model_path, "\n")
save(models, file = model_path)

cat("Training process complete.\n")