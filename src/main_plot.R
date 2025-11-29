# src/main_plot.R
# Generate high-quality plots for the report using ggplot2.
# Modified: Fixed label confusion between units and descriptions, cleaned up comments.

# Install ggplot2 if not installed.
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  cat("Installing ggplot2...\n")
  install.packages("ggplot2", repos = "https://cloud.r-project.org/")
}
library(data.table)
library(ggplot2)

source('src/config.R')
matrix_file <- file.path(paths$output_dir, "result_matrix.csv")
output_dir  <- file.path(paths$output_dir, "graph")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

if (!file.exists(matrix_file)) stop("Result matrix not found.")
df <- fread(matrix_file)

# Preprocessing.
measure_cols <- c("bernoulli_mle", "bernoulli_map", "multinomial_mle", "multinomial_map")
df[, (measure_cols) := lapply(.SD, as.numeric), .SDcols = measure_cols]
df[, Alpha := as.numeric(Alpha)]

# Style Definitions.

# Common theme definition.
bw_theme <- theme_bw() +
  theme(
    text = element_text(family = "sans", size = 12),
    plot.title = element_blank(), 
    
    # Remove Vertical Grids.
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    
    # Darker Horizontal Grids.
    panel.grid.major.y = element_line(color = "grey60", linewidth = 0.5),
    panel.grid.minor.y = element_blank(),
    
    # Axis text.
    axis.text = element_text(color = "black"),
    
    # Base Legend settings.
    legend.background = element_rect(fill = "white", color = "black", linewidth = 0.3),
    legend.title = element_blank(),
    legend.margin = margin(4, 4, 4, 4)
  )

# Function to add a bold zero line.
add_zero_line <- function() {
  geom_hline(yintercept = 0, color = "black", linewidth = 1.0)
}

# Helper to reshape data.
melt_models <- function(data) {
  melt(data, measure.vars = measure_cols, variable.name = "Model", value.name = "Accuracy")
}

# Define Line Types and Shapes.
model_levels <- c("bernoulli_mle", "bernoulli_map", "multinomial_mle", "multinomial_map")
model_labels <- c("Bernoulli (MLE)", "Bernoulli (MAP)", "Multinomial (MLE)", "Multinomial (MAP)")

scale_manual_settings <- list(
  scale_linetype_manual(values = c("bernoulli_mle" = "dotted", "bernoulli_map" = "solid", 
                                   "multinomial_mle" = "dotdash", "multinomial_map" = "dashed"),
                        labels = model_labels, breaks = model_levels),
  scale_shape_manual(values = c("bernoulli_mle" = 4, "bernoulli_map" = 16, 
                                "multinomial_mle" = 5, "multinomial_map" = 15), # 5 is diamond
                     labels = model_labels, breaks = model_levels),
  scale_color_manual(values = c("bernoulli_mle" = "black", "bernoulli_map" = "black", 
                                "multinomial_mle" = "grey40", "multinomial_map" = "grey40"),
                     labels = model_labels, breaks = model_levels)
)

# Helper to select best algorithm data.
get_data_for_datasets <- function(df, datasets, alpha_val = 2.0) {
  # Try standard first.
  sub <- df[TrainData %in% datasets & Alpha == alpha_val & Bernoulli_alg == "alg_nb_classify"]
  
  # If empty or missing some datasets, try negative.
  if (nrow(sub) == 0) {
    sub <- df[TrainData %in% datasets & Alpha == alpha_val & Bernoulli_alg == "alg_nb_classify_negative"]
  }
  
  return(sub)
}


# 1. Learning Curve Comparison by Data Size.
target_datasets <- c("learnU_10", "learnU_25", "learnU_50", "learnU_75", "learnU")
percentages <- c(10, 25, 50, 75, 100)
names(percentages) <- target_datasets

df_lc <- get_data_for_datasets(df, target_datasets)
df_lc[, X_Val := percentages[TrainData]]

if (!is.numeric(df_lc$X_Val)) df_lc[, X_Val := as.numeric(X_Val)]

long_lc <- melt_models(df_lc)
long_lc[, Model := factor(Model, levels = model_levels)]

p1 <- ggplot(long_lc, aes(x = X_Val, y = Accuracy, group = Model)) +
  add_zero_line() +
  geom_line(aes(linetype = Model, color = Model), linewidth = 0.8) +
  geom_point(aes(shape = Model, color = Model), size = 3) +
  scale_manual_settings +
  labs(x = "Training Data Size", y = "Accuracy [%]") +
  scale_x_continuous(breaks = percentages, labels = as.character(percentages)) +
  ylim(0, 100) +
  bw_theme +
  # Legend at Middle-Right.
  theme(legend.position = c(0.98, 0.50), legend.justification = c(1, 0.5))

ggsave(file.path(output_dir, "graph_learning_curve.pdf"), plot = p1, width = 7, height = 5)


# 2. Bias Effect Comparison.
datasets_bias <- c("learnU_50", "learnU_linear30to70", "learnU_linear0to100")
df_bias <- get_data_for_datasets(df, datasets_bias)
df_bias[, TrainData := factor(TrainData, levels = datasets_bias)]

long_bias <- melt_models(df_bias)
long_bias[, Model := factor(Model, levels = model_levels)]

p2 <- ggplot(long_bias, aes(x = TrainData, y = Accuracy, fill = Model)) +
  add_zero_line() +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7, color = "black") +
  scale_fill_grey(start = 0.9, end = 0.3, labels = model_labels) +
  labs(x = "Dataset", y = "Accuracy [%]") +
  ylim(0, 100) +
  bw_theme +
  # Legend at Top-Right.
  theme(legend.position = c(0.98, 0.93), legend.justification = c(1, 1))

ggsave(file.path(output_dir, "graph_bias_effect.pdf"), plot = p2, width = 7, height = 5)


# 3. Replication Effect with Same Total Volume.
datasets_repl_total <- c("learnU", "learnU_25x4", "learnU_5x20")
df_repl_total <- get_data_for_datasets(df, datasets_repl_total)
df_repl_total[, TrainData := factor(TrainData, levels = datasets_repl_total)]

long_repl_total <- melt_models(df_repl_total)
long_repl_total[, Model := factor(Model, levels = model_levels)]

p3 <- ggplot(long_repl_total, aes(x = TrainData, y = Accuracy, fill = Model)) +
  add_zero_line() +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7, color = "black") +
  scale_fill_grey(start = 0.9, end = 0.3, labels = model_labels) +
  labs(x = "Dataset", y = "Accuracy [%]") +
  ylim(0, 100) +
  bw_theme +
  # Legend at Top-Right.
  theme(legend.position = c(0.98, 0.93), legend.justification = c(1, 1))

ggsave(file.path(output_dir, "graph_replication_same_total.pdf"), plot = p3, width = 7, height = 5)


# 4. Replication Effect with Same Information Content.
datasets_repl_info <- c("learnU_25", "learnU_25x2", "learnU_25x4", "learnU_25x8")
df_repl_info <- get_data_for_datasets(df, datasets_repl_info)
df_repl_info[, TrainData := factor(TrainData, levels = datasets_repl_info)]

long_repl_info <- melt_models(df_repl_info)
long_repl_info[, Model := factor(Model, levels = model_levels)]

p4 <- ggplot(long_repl_info, aes(x = TrainData, y = Accuracy, fill = Model)) +
  add_zero_line() +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7, color = "black") +
  scale_fill_grey(start = 0.9, end = 0.3, labels = model_labels) +
  labs(x = "Dataset", y = "Accuracy [%]") +
  ylim(0, 100) +
  bw_theme +
  # Legend at Bottom.
  theme(legend.position = "bottom")

ggsave(file.path(output_dir, "graph_replication_same_info.pdf"), plot = p4, width = 7, height = 5)


# 5. Compression Effect Comparison.
datasets_comp <- c("learnU", "learnU_x4", "learnU_x20")
df_comp <- get_data_for_datasets(df, datasets_comp)
df_comp[, TrainData := factor(TrainData, levels = datasets_comp)]

long_comp <- melt_models(df_comp)
long_comp[, Model := factor(Model, levels = model_levels)]

p5 <- ggplot(long_comp, aes(x = TrainData, y = Accuracy, fill = Model)) +
  add_zero_line() +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7, color = "black") +
  scale_fill_grey(start = 0.9, end = 0.3, labels = model_labels) +
  labs(x = "Dataset", y = "Accuracy [%]") +
  ylim(0, 100) +
  bw_theme +
  # Legend at Left-Center.
  theme(legend.position = c(0.75, 0.8), legend.justification = c(0.5, 0.5))

ggsave(file.path(output_dir, "graph_compression_effect.pdf"), plot = p5, width = 7, height = 5)


# 6. Alpha Sensitivity Comparison.
df_alpha <- df[TrainData == "learnU" & Bernoulli_alg == "alg_nb_classify" & !is.na(Alpha)]
# Fallback if standard not found.
if (nrow(df_alpha) == 0) {
  df_alpha <- df[TrainData == "learnU" & Bernoulli_alg == "alg_nb_classify_negative" & !is.na(Alpha)]
}
df_alpha <- df_alpha[order(Alpha)]

long_alpha <- melt(df_alpha, measure.vars = c("bernoulli_map", "multinomial_map"), 
                   variable.name = "Model", value.name = "Accuracy")
long_alpha[, Model := factor(Model, levels = model_levels)]

p6 <- ggplot(long_alpha, aes(x = Alpha, y = Accuracy, group = Model)) +
  add_zero_line() +
  geom_line(aes(linetype = Model, color = Model), linewidth = 0.8) +
  geom_point(aes(shape = Model, color = Model), size = 3) +
  scale_manual_settings +
  labs(x = "Smoothing Parameter Alpha", y = "Accuracy [%]") +
  scale_x_continuous(breaks = unique(df_alpha$Alpha)) +
  bw_theme +
  # Legend at Lower-Right.
  theme(legend.position = c(0.98, 0.25), legend.justification = c(1, 0))

ggsave(file.path(output_dir, "graph_alpha_sensitivity.pdf"), plot = p6, width = 7, height = 5)

cat("All plots generated in output/graph/ directory.\n")