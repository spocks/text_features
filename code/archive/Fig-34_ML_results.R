# NOTE: this figure was modified from the old script to include the new
# results (REF, MRMR, and GA)
library(readxl)
library(ggplot2)
library(ggpubr)
library(writexl)
# library(gridExtra)
# library(readr); library(tidyr)
# library(tools); library(Hmisc) ; library(plyr); library(RColorBrewer)
# library(reshape2); ; library(ggrepel)

# source("https://gist.githubusercontent.com/benmarwick/2a1bb0133ff568cbe28d/raw/fb53bd97121f7f9ce947837ef1a4c65a73bffb3f/geom_flat_violin.R")
source("./code/geom_flat_violin.R")

size <- 12
raincloud_theme <- theme(
  text = element_text(size = 10),
  axis.title.x = element_text(size = size),
  axis.title.y = element_text(size = size),
  axis.text = element_text(size = size),
  # axis.text.x = element_text(angle = 45, vjust = 0.95, hjust = 1, color = "black"),
  axis.text.x = element_text(angle = 0, vjust = 0.5, hjust = 0.5, color = "black", size = 10),
  legend.title = element_text(size = size),
  legend.text = element_text(size = size),
  legend.position = "right",
  plot.title = element_text(lineheight = .8, , size = 15), # face = "bold"
  panel.border = element_blank(),
  panel.grid.minor = element_blank(),
  panel.grid.major = element_blank(),
  axis.line.x = element_line(colour = "black", size = 0.5, linetype = "solid"),
  axis.line.y = element_line(colour = "black", size = 0.5, linetype = "solid")
)

## -------------------------------------------------------------

create_plot <- function(dft, title = NA, ylab = "Pearson correlation") {
  # fetMeth <- colnames(df)[colnames(df) != "drug"]
  dft <- as.data.frame(dft)
  #   fetMeth <- c("var-100", "var-500", "L1000-tm", "L1000", "cor-500", "text-mining")
  fetMeth <- c(
    "var-100", "var-500", "L1000", "L1000-tm", "cor-500",
    "RFE", "MRMR", "GA",
    "text-mining"
  )
  keep <- fetMeth %in% dft$Type
  fetMeth <- fetMeth[keep]

  dft$Type <- factor(dft$Type, levels = fetMeth)

  cl <- c(
    "#B09C85FF", "#91D1C2FF", "#4DBBD5FF", "#3C5488FF", "#00A087FF",
    "#85469d", "#bf4aa5", "#446e35", "#DC0000FF"
  )
  cl <- cl[keep]
  names(cl) <- fetMeth

  my_comparisons <- lapply(
    rev(fetMeth[1:(length(fetMeth) - 1)]),
    function(i) c(i, fetMeth[length(fetMeth)])
  )

  # df$drug <- rownames(df)

  # dft <- reshape2::melt(df, id.vars = "drug", variable.name = "Type")
  # print(head(dft))
  # stop()

  g <- ggplot(data = dft, aes(y = value, x = Type, fill = Type)) +
    geom_flat_violin(position = position_nudge(x = .2, y = 0), alpha = .95) +
    geom_point(aes(y = value, color = Type),
      position = position_jitter(width = .15), size = .5, alpha = 0.45
    ) +
    geom_boxplot(
      width = .1, # guides = "none",
      outlier.shape = NA, alpha = 0.5
    ) +
    expand_limits(x = 5.25) +
    guides(fill = "none") +
    guides(color = "none") +
    theme_bw() +
    theme(plot.title = element_text(hjust = 0.5)) +
    raincloud_theme +
    xlab("") + # xlab("Feature Selection Method") +
    ylab(ylab)

  g <- g + scale_color_manual(values = cl) + scale_fill_manual(values = cl)
  g <- g + stat_compare_means(
    comparisons = my_comparisons, method = "wilcox.test", paired = TRUE,
    # label.y = 0.7,
    size = 2.5
  )
  minVal <- round(floor(min(dft$value) / 2 * 10) / 5, 1)
  maxVal <- (round(ceiling(max(dft$value) / 2 * 10) / 5, 1))
  g <- g + scale_y_continuous(breaks = seq(minVal, maxVal, 0.2))
  g <- g + theme(
    axis.text.x = element_text(
      # face = "bold", # color="#993333",
      color = "black",
      size = 7.5, angle = -0
    ),
    axis.text.y = element_text(
      face = "bold", # color="#993333",
      color = "black",
      size = 9, angle = 0
    ),
    axis.title.y = element_text(face = "bold", size = 10)
  )
  return(g)
}

## --------------------------------------------------------------
## ---- Random-forest training and test plot --------------------

# f <- "./mlModelMetrics.xlsx"
# f <- "./result/Supplementary-data-2-performance-indexes.xlsx"
# f <- "./File2check.xlsx"
formatXLSX <- function(x, valCol = "pearsonCor") {
  x <- x[, c("drug", "feature selection method", valCol)]
  colnames(x) <- c("drug", "Type", "value")
  return(x)
}
h <- 3.5
# pdf("./result/ML_results.pdf", width = h * 1.4 * 2, height = h * 2)
pdf("./tmp.pdf", width = h * 1.4 * 2, height = h * 2)

methods <- c("pearsonCor") # , "spearmanCor", "kendallCor", "RMSE", "MSE", "MAE")
ylabs <-
  c(
    "pearsonCor" = "Pearson correlation",
    "spearmanCor" = "Spearman correlation",
    "kendallCor" = "Kendall correlation",
    "RMSE" = "RMSE",
    "MSE" = "MSE",
    "MAE" = "MAE"
  )
for (i in methods) {
  print(i)
  trRF <- read_xlsx(f, sheet = "RandomForest perf metrics-train")
  trRF <- formatXLSX(trRF, valCol = i)
  pltTRRF <- create_plot(trRF, ylab = ylabs[i])
  ## ------------------------------------------------------------
  tsRF <- read_xlsx(f, sheet = "RandomForest perf metrics-test")
  tsRF <- formatXLSX(tsRF, valCol = i)
  pltTSRF <- create_plot(tsRF, ylab = ylabs[i])
  ## ------------------------------------------------------------
  ## ---- Elastic-Net training and test plot --------------------
  trEN <- read_xlsx(f, sheet = "ElasticNet perf metrics-train")
  trEN <- formatXLSX(trEN, valCol = i)
  pltTREN <- create_plot(trEN, ylab = ylabs[i])
  ## ------------------------------------------------------------

  tsEN <- read_xlsx(f, sheet = "ElasticNet perf metrics-test")
  tsEN <- formatXLSX(tsEN, valCol = i)
  pltTSEN <- create_plot(tsEN, ylab = ylabs[i])
  ## ------------------------
  print(ggarrange(pltTRRF, pltTSRF, pltTREN, pltTSEN,
    # labels = c("train_RF", "test_RF", "train_EN", "test_EN"),
    labels = c("A", "B", "C", "D"),
    ncol = 2, nrow = 2
  ))
}
dev.off()
## ------------------------------------------------------------
## ---- Elastic-Net training and test plot --------------------
## ------------------------------------------------------------

pdf("./result/DNN_results.pdf", width = h * 1.4 * 2, height = h * 2)
for (i in methods) {
  print(i)
  dnn <- read_xlsx(f, sheet = "DeepLearning perf metrics")
  dnn <- formatXLSX(dnn, valCol = i)
  pltDNN <- create_plot(dnn, ylab = ylabs[i])
  plot(pltDNN)
}
dev.off()
print("done")
