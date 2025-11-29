# Update the result matrix with classification accuracy and configuration details.

if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table")
}
library(data.table)

# Identify configuration identifiers.
matrix_file <- file.path(paths$output_dir, "result_matrix.csv")
train_data_name <- basename(paths$train_data_dir)
classify_data_name <- basename(paths$classify_data_dir)
bernoulli_alg_name <- tools::file_path_sans_ext(basename(paths$bernoulli_impl_file))
alpha_value <- if (exists("params") && !is.null(params$alpha)) params$alpha else NA

# Create a data table for the current execution results.
current_row <- data.table(
  TrainData = train_data_name,
  ClassifyData = classify_data_name,
  Bernoulli_alg = bernoulli_alg_name,
  Alpha = alpha_value
)

# Append accuracy scores to the current row.
for (m in model_names) {
  acc <- (correct_counts[m] / total_files) * 100
  current_row[, (m) := acc]
}

# Load existing results and update or append the current run.
if (file.exists(matrix_file)) {
  final_matrix <- fread(matrix_file)
  
  # Define specific keys to identify a unique experiment run.
  id_cols <- c("TrainData", "ClassifyData", "Bernoulli_alg", "Alpha")
  
  # If the existing matrix has the ID columns, remove the old entry for this run.
  if (all(id_cols %in% names(final_matrix))) {
    final_matrix <- final_matrix[!current_row, on = id_cols]
  }
  
  final_matrix <- rbind(final_matrix, current_row, fill = TRUE)
} else {
  final_matrix <- current_row
}

# Reorder columns to place identifiers first.
id_cols <- c("TrainData", "ClassifyData", "Bernoulli_alg", "Alpha")
model_cols <- c("bernoulli_mle", "bernoulli_map", "multinomial_mle", "multinomial_map")
desired_cols <- c(id_cols, model_cols)

# Retain existing columns that are not in the desired list.
existing_cols <- names(final_matrix)
final_order <- c(intersect(desired_cols, existing_cols), setdiff(existing_cols, desired_cols))
setcolorder(final_matrix, final_order)

# Save the updated result matrix.
fwrite(final_matrix, matrix_file)
cat(sprintf("   ...Updated result matrix at %s.\n", matrix_file))