#------------------------------------------------------------------------------
# Probabilistic variation graphing
#------------------------------------------------------------------------------

graph_prob_var <- function(
  df, varied, descriptions, graph_save_dir, graph_device
) {

  VE_true_1 <- length(unique(unlist(df[, "VE_true"]))) == 1
  if (!VE_true_1) df$bias <- df$VE_est_mean - df$VE_true

  # Graph individual parameters vs outcome
  save_dimensions <- c(6, 6)
  save_units <- "in"
  for (var in varied) {
    cat("graphing", var, "\n")
    gr <- graph_prob_unit(df, var, descriptions[var], VE_true_1)
    save_graph(
      gr, paste0(graph_save_dir,"--",var), graph_device,
      save_units, save_dimensions
    )
  }

  # Graph impact measurements of the parameters
  cat("graphing tornados\n")
  save_dimensions <- c(6,3)

  coeffs_all <- get_coeffs(df, varied, VE_true_1)
  ind <- 0
  for (coeffs_name in names(coeffs_all)) {
    ind <- ind + 1
    gr <- graph_coeffs(coeffs_all[[coeffs_name]], coeffs_name)
    save_graph(
      gr, paste0(graph_save_dir,"--tornado","--",ind), graph_device, 
      save_units, save_dimensions
    )
  }  
}

# Returns coefficients associated with parameters
get_coeffs <- function(df, varied, VE_true_1) {

  coeffs_full <- list()

  # Adjusted linear coefficients
  right_side <- paste0(varied, collapse = " + ")
  if (VE_true_1) left_side <- "VE_est_mean"
  else left_side <- "bias"
  form <- paste0(left_side, " ~ ", right_side)
  coeffs <- data.frame()
  for (dtype in unique(df$type)) {
    type_entry <- data.frame(parameter = varied, type = dtype)
    lin_fit <- lm(
      data = df[df$type == dtype, ], formula = as.formula(form)
    )
    su <- summary(lin_fit)
    type_entry$lin_coef_est <- su$coefficients[-1, "Estimate"]
    type_entry$lin_coef_sd <- su$coefficients[-1, "Std. Error"]
    coeffs <- rbind(coeffs, type_entry)
  }
  coeffs_full[['Adjusted linear coefficient estimate']] <- coeffs
  
  return(coeffs_full)
}

 # Graphs one set of coefficients
 graph_coeffs <- function(coeffs, xlab) {
   gr <- ggplot(coeffs, aes(x = parameter, y = lin_coef_est)) + theme_bw() +
    geom_bar(position = "identity", stat = "identity") + 
    ylab(xlab) + xlab("Parameter") +
    coord_flip() +
    facet_wrap(vars(type))
  return(gr)
 }

# Graphs one variant against outcome
graph_prob_unit <- function(df, var, desc, VE_true_1) {
    
  # Frequency of the varied parameter
  freq <- ggplot(df, aes(x=get(var), y = stat(density))) + theme_bw() +
    geom_freqpoly(binwidth = 0.01) + xlab(desc)
  
  # Scatter of VE_est vs varied parameter
  
  if (VE_true_1) {
    scat <- ggplot(df, aes_string(x = var, y = "VE_est_mean")) 
    scat <- scat + 
      geom_hline(aes(yintercept = VE_true), linetype = 5, lwd = 1) + 
      ylab("VE estimated")
  } else {
    scat <- ggplot(df, aes_string(x = var, y = "bias")) + 
      ylab("VE estimate bias")
  }
  scat <- scat +
    geom_point(alpha = 0.3, size = 0.7, stroke = 0) + 
    geom_smooth(method = "lm", lwd = 0.5, color = "blue", se = FALSE) + 
    xlab(desc) + 
    facet_wrap(vars(type), nrow = 2) +
    theme_bw() +
    theme(
      panel.spacing = unit(0,"lines"),
      plot.margin = unit(c(0,1,1,1), "lines")
    )

  # Strippled polygon for marginal
  freq_stripped <- freq +
    theme(
      panel.grid = element_blank(),
      axis.title = element_blank(),
      axis.ticks = element_blank(), 
      axis.ticks.length = unit(0,"mm"),
      axis.text = element_blank(),
      plot.margin = unit(c(0,0,0,0),"lines")
    )
  
  # Full graph
  full <- ggarrange(
    freq_stripped, scat,
    ncol=1,nrow=2,align="v",heights=c(1,2)
  )

  return(full)
}

#------------------------------------------------------------------------------
# Fixed variation graphing
#------------------------------------------------------------------------------

graph_fixed_var <- function(
  df, varied, descriptions, errors, sample_size, ylims, graph_save_dir, 
  graph_device
) {

  varied <- get_varied(df, varied)
  
  if (length(varied) > 2) stop("don't know how to graph more than 2 variants")
  
  x_axis <- varied[1]

  if (length(varied) > 1) {
    
    facet_variable <- varied[2]
    
    # Never facet by p_test_nonari
    if (facet_variable == "p_test_nonari") {
      facet_variable <- varied[1]
      x_axis <- varied[2]
    }

    var_og <- df[, facet_variable]
    if (!is.vector(var_og)) var_og <- unlist(var_og)
    var_conv <- as.character(var_og)
    var_conv <- paste0(facet_variable, " = ", var_conv)
    var_conv <- as.factor(var_conv)
    df[, facet_variable] <- var_conv
  } else facet_variable <- NULL
  
  y_axis <- "VE_est_mean"
  
  cat("Graphing", x_axis, "on x;", y_axis, "on y")
  
  if (!is.null(facet_variable)) {
    cat("; faceting by", facet_variable,"\n")
  } else cat("\n")
  
  if (length(unique(df$name)) > 1) {
    pl <- graph_base_1_mixed(
      df, descriptions, errors, sample_size, x_axis, y_axis, ylims
    )
    save_dimensions <- c(15, 15)
  } else {
    pl <- graph_base_1(
      df, descriptions, errors, sample_size, x_axis, y_axis, ylims
    )
    save_dimensions <- c(10, 6)
  }

  if (!is.null(facet_variable)) {
    pl <- add_facets(pl, facet_variable)
    save_dimensions <- c(20, 20)
  }

  save_units <- "cm"

  save_graph(
    pl, graph_save_dir, graph_device, save_units, save_dimensions
  )
}

# Base graph for 1 varied parameter
graph_base_1 <- function(
  df, descriptions, errors, sample_size, x, y, ylims=c(NA,NA)
) {
  x_name <- descriptions[x]

  pl <- ggplot(df, aes_string(x = x, y = y)) + theme_bw() + 
    geom_hline(aes(yintercept = df$VE_true), linetype = 5, lwd = 1) + 
    geom_line(mapping = aes(col = type), na.rm=T) +
    geom_point(aes(fill = type, shape = type),size = 4,na.rm = T) +
    scale_x_continuous(name = x_name) +
    scale_y_continuous(name = "Estimated VE", limits = ylims) + 
    scale_color_manual(
      name = "Data type", values = c(4,2),
      labels = c("Administrative","Surveillance")
    ) + 
    scale_fill_manual(
      name = "Data type", values=c(4,2), 
      labels = c("Administrative","Surveillance")
    ) +
    scale_shape_manual(
      name = "Data type", values = c(21,24),
      labels = c("Administrative","Surveillance")
    ) +
    theme(legend.position = "bottom", panel.grid.minor = element_blank())
    
  if(errors) {
    pl <- pl +
      geom_errorbar(
        aes(
          ymin = VE_est_mean - VE_est_sd,
          ymax = VE_est_mean + VE_est_sd,
          x = p_test_nonari,
          col = type
        ),
        width = 0.025
      )
  } 
  
  if(sample_size) {
    
    pl <- remove_geom(pl, "point")
    
    pl <- pl +
      geom_point(
        aes(
          x = p_test_nonari,
          y = VE_est_mean,
          fill = type,
          size = n_study_mean,
          shape = type
        )
      ) +
      scale_size_continuous(range = c(2,6), name="Sample size") +
      theme(legend.position = "right")
  }

  if(x == "VE") {
    pl <- remove_geom(pl, "hline")
    pl <- pl + 
      geom_abline(intercept = 0, slope = 1)
  }
    
  return(pl)
}

# Base graph for 1 varied parameter with multiple age groups present
graph_base_1_mixed <- function(
  df, descriptions, errors, sample_size, x, y, ylims=c(NA,NA)
) {
  x_name <- descriptions[x]
  
  pl <- ggplot(df, aes_string(x = x, y = y)) + theme_bw() + 
    geom_hline(aes(yintercept = VE_true), linetype = "3333") + 
    geom_hline(yintercept = 0, color = "magenta", linetype = "3111") +
    geom_point(aes(shape = type, color = type)) + 
    geom_hline(aes_string(yintercept = y, linetype = "type", color = "type")) + 
    facet_grid(cols = vars(name), rows = vars(ncall)) +
    xlab(x_name) + ylab("VE estimate") +
    theme(
      legend.position = "bottom", 
      legend.box.spacing = unit(0, "mm"),
      panel.grid.minor = element_blank(),
      panel.spacing.x = unit(4, "points"),
      panel.spacing.y = unit(0, "points"),
      axis.text.x = element_text(angle = 90, hjust = 1)
    )
  
  return(pl)
}

# Additional facets for two varied parameters
add_facets <- function(pl, facet_variable) {
  
  pl_facets <- pl + 
    facet_wrap(c(facet_variable))
  
  return(pl_facets)
}

#------------------------------------------------------------------------------
# Saves the graph
#------------------------------------------------------------------------------

save_graph <- function(
  pl, filename, graph_device, save_units, save_dimensions
) {
  ggsave(pl, 
        filename = paste0(filename, '.', graph_device),
        device =  graph_device,
        units=save_units, 
        width = save_dimensions[1], height = save_dimensions[2])
  cat("saved to",filename,"\n")
}