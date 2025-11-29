# src/save_result.R
# Updates the result matrix with current classification accuracies.
# The matrix format is Rows: TrainData, Columns: Models.

if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table")
}
library(data.table)

# Define file paths and training data name.
matrix_file <- file.path(paths$output_dir, "result_matrix.csv")
train_data_name <- basename(paths$train_data_dir)

# Create a data.table for the current run with TrainData as the first column.
current_row <- data.table(TrainData = train_data_name)

# Calculate accuracy for each model and add as columns.
for (m in model_names) {
  acc <- (correct_counts[m] / total_files) * 100
  current_row[, (m) := acc]
}

# Load existing matrix or initialize if missing.
if (file.exists(matrix_file)) {
  final_matrix <- fread(matrix_file)
  
  # Remove existing entry for this training data to allow update.
  final_matrix <- final_matrix[TrainData != train_data_name]
  
  # Append new result row.
  final_matrix <- rbind(final_matrix, current_row, fill = TRUE)
} else {
  final_matrix <- current_row
}

# Reorder columns to ensure TrainData is first, followed by specific model order.
desired_cols <- c("TrainData", "bernoulli_mle", "bernoulli_map", "multinomial_mle", "multinomial_map")
existing_cols <- intersect(desired_cols, names(final_matrix))
setcolorder(final_matrix, existing_cols)

# Save the updated matrix.
fwrite(final_matrix, matrix_file)
cat(sprintf("   ...Updated result matrix at %s.\n", matrix_file))