# src/combine.R
# This script combines text files within a target data directory.
# It processes class subdirectories (e.g., learnU/1) and combines
# files into larger chunks.

# --- Configuration ---

# 1. Define the number of files to combine into one chunk.
# learnU_x(CHUNK_SIZE).
CHUNK_SIZE <- 20

# 2. Define the base data directory.
BASE_DATA_DIR <- "data"

# 3. Get target directory name from command-line arguments.
# If no argument is provided, use "learnU" as the default.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  TARGET_NAME <- "learnU"
  cat("No target specified. Using default:", TARGET_NAME, "\n")
} else {
  TARGET_NAME <- args[1]
  cat("Target set to:", TARGET_NAME, "\n")
}

# --- Path Definitions ---

# 4. Define the full source path (e.g., "data/learnU").
BASE_SOURCE_DIR <- file.path(BASE_DATA_DIR, TARGET_NAME)

# 5. Define the output directory name and full path.
# Example: "data/learnU_x20".
OUTPUT_NAME <- paste0(TARGET_NAME, "_x", CHUNK_SIZE)
BASE_OUTPUT_DIR <- file.path(BASE_DATA_DIR, OUTPUT_NAME)

cat("Source directory:", BASE_SOURCE_DIR, "\n")
cat("Output directory:", BASE_OUTPUT_DIR, "\n")
cat("Chunk size:", CHUNK_SIZE, "\n")

# --- Main Processing Loop ---

# Find all class subdirectories within the source directory.
all_class_dirs <- list.dirs(BASE_SOURCE_DIR, full.names = TRUE, recursive = FALSE)

if (length(all_class_dirs) == 0) {
  stop("No class subdirectories found in '", BASE_SOURCE_DIR, "'. Check target name.")
}

# Process each class directory found (e.g., "data/learnU/1").
for (class_dir in all_class_dirs) {
  class_name <- basename(class_dir)
  cat("Processing class:", class_name, "\n")
  
  # Create the corresponding output directory (e.g., "data/learnU_x20/1").
  output_class_dir <- file.path(BASE_OUTPUT_DIR, class_name)
  if (!dir.exists(output_class_dir)) {
    dir.create(output_class_dir, recursive = TRUE)
  }
  
  # Find all .txt files to be combined.
  all_files <- sort(list.files(class_dir, pattern = "\\.txt$", full.names = TRUE))
  
  if (length(all_files) == 0) {
    cat("   ...No .txt files found. Skipping class.\n")
    next
  }
  
  # Calculate group indices to split files into chunks of CHUNK_SIZE.
  num_files <- length(all_files)
  group_indices <- ceiling((1:num_files) / CHUNK_SIZE)
  file_chunks <- split(all_files, group_indices)
  
  cat("   ...Found", num_files, "files, splitting into", length(file_chunks), "chunks.\n")
  
  # Loop through each chunk and perform the combination.
  for (i in 1:length(file_chunks)) {
    chunk_filepaths <- file_chunks[[i]]
    output_filename <- file.path(output_class_dir, paste0("combined_", i, ".txt"))
    
    # Read the content of all files in the current chunk.
    combined_content <- lapply(chunk_filepaths, readLines, warn = FALSE, encoding = "UTF-8")
    
    # Write the combined content to the new chunk file.
    writeLines(unlist(combined_content), output_filename, useBytes = TRUE)
  }
}

cat("Combining process complete.\n")