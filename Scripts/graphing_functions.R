#------------------------------------------------------------------------------
# Base graph for 1 varied parameter
#------------------------------------------------------------------------------

graph_base_1 <- function(df, estimates, errors, sample_size, x, y, y_breaks) {
  x_name <- as.character(estimates[ estimates$Parameter==x, "Description"])
  
  pl <- ggplot(
    data = df, 
    mapping = aes(x = df[ , x], y = df[ , y])
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
    scale_y_continuous(name = "Estimated VE") + 
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