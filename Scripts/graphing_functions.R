#------------------------------------------------------------------------------
# Probabilistic variation graphing
#------------------------------------------------------------------------------

graph_prob_var <- function(
  df, varied, descriptions, graph_save_dir, graph_device
) {
  save_dimensions <- c(6,6)
  save_units <- "in"
  for (var in varied) {
    cat("graphing",var,"\n")
    gr <- graph_prob_unit(df, var, descriptions[var])
    save_graph(
      gr, paste0(graph_save_dir,"--",var), graph_device, 
      save_units, save_dimensions
    )
  }
  cat("graphing tornado\n")
  save_dimensions <- c(6,6)
  gr <- graph_tornado(df, varied)
  save_graph(
      gr, paste0(graph_save_dir,"--tornado"), graph_device, 
      save_units, save_dimensions
    )
}

# Tornado plot
graph_tornado <- function(df, varied) {
  
  # Unadjusted linear coefficients
  # Should probably look at the bias...
  coeffs <- data.frame()
  for (var in varied) {
    for (dtype in unique(df$type)) {
      var_entry <- data.frame(parameter = var, type = dtype)

      lin_fit <- lm(
        data = df[df$type == dtype , ], formula = VE_est_mean ~ get(var)
      )
      su <- summary(lin_fit)
      
      coeff <- su$coefficients['get(var)' , 'Estimate']
      coeff_sd <- su$coefficients['get(var)' , 'Std. Error']

      var_entry$lin_coef_est <- coeff
      var_entry$lin_coef_sd <- coeff_sd
      
      coeffs <- rbind(coeffs, var_entry)
    }
  }

  gr <- ggplot(coeffs, aes(x = parameter, y = lin_coef_est)) + theme_bw() +
    geom_bar(position = "identity", stat = "identity") + 
    ylab("Unadjusted linear coefficient estimate") +
    facet_wrap(vars(type))
  return(gr)
}

# Graphs one variant against outcome
graph_prob_unit <- function(df, var, desc) {
  
  # Frequency of the varied parameter
  freq <- ggplot(df, aes(x=get(var), y = stat(density))) + theme_bw() +
    geom_freqpoly(binwidth = 0.01) + xlab(desc)
  
  # Scatter of VE_est vs varied parameter
  scat <- ggplot(df, aes_string(x = var, y = "VE_est_mean")) + theme_bw() +
    geom_hline(aes(yintercept = VE_true), linetype = 5, lwd = 1) +
    geom_point(alpha = 0.3, size = 0.7, stroke = 0) + 
    xlab(desc) + ylab("VE estimated") +
    facet_wrap(vars(type), nrow = 2) +
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
  
  x_axis <- varied[1]
  if(x_axis == "p_test_ari") varied <- varied[varied != "p_test_nonari"]

  if (length(varied) > 2) stop("don't know how to graph more than 2 variants")

  if (length(varied) > 1) {
    facet_variable <- varied[2]
  } else facet_variable <- NULL
  
  y_axis <- "VE_est_mean"
  
  cat("Graphing",x_axis,"on x;",y_axis,"on y")
  
  if (!is.null(facet_variable)) {
    cat("; faceting by", facet_variable,"\n")
  } else { cat("\n") }

  pl <- graph_base_1(
    df, descriptions, errors, sample_size, x_axis, y_axis, ylims
  )
  
  if (!is.null(facet_variable)) {
    pl <- add_facets(pl,facet_variable)
    save_dimensions = c(10,10)
  } else {
    save_dimensions <- c(7,4)
  }

  save_units <- "in"

  save_graph(
    pl, graph_save_dir, graph_device, save_units, save_dimensions
  )
}

# Base graph for 1 varied parameter
graph_base_1 <- function(
  df, descriptions, errors, sample_size, x, y, ylims=c(NA,NA)
) {
  x_name <- descriptions[x]

  pl <- ggplot(
    data = df, 
    mapping = aes_string(x = x, y = y)
    ) + theme_bw() + 
    
    geom_hline(
      aes(yintercept = df$VE_true), 
      linetype = 5,
      lwd = 1
    ) + 
    
    geom_line(mapping = aes(col = type), na.rm=T) +
    
    geom_point(
      aes(fill = type, shape = type),
      size = 4,
      na.rm = T
    ) +
    
    scale_x_continuous(name = x_name, breaks = seq(0,1,0.1)) +
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