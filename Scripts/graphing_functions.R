#------------------------------------------------------------------------------
# Base graph for 1 varied parameter
#------------------------------------------------------------------------------

graph_fixed_var <- function(
  df, descriptions, errors, sample_size, varied, ylims,
  save_directory, graph_filename
) {
  x_axis <- varied[1]
  if(x_axis == "p_test_ari") varied <- varied[varied != "p_test_nonari"]
  
  if(length(varied)>1) {
    facet_variable <- varied[2]
  } else facet_variable <- NULL
  
  y_axis <- "VE_est_mean"
  
  save_units <- "in"
  
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
  filename = file.path(save_directory,graph_filename)
  ggsave(pl, 
        filename = filename, 
        units=save_units, 
        width = save_dimensions[1], height = save_dimensions[2])
  cat("saved to",filename,"\n")
}

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

#------------------------------------------------------------------------------
# Additional facets for two varied parameters
#------------------------------------------------------------------------------

add_facets <- function(pl, facet_variable) {
  
  pl_facets <- pl + 
    facet_wrap(c(facet_variable))
  
  return(pl_facets)
}