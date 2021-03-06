sem.coefs = function(modelList, data, standardize = "none", corr.errors = NULL) {
  
  if(any(class(modelList) != "list")) modelList = list(modelList)
  
  names(modelList) = NULL

  if(!standardize %in% c("none", "scale", "range")) stop("'standardize' must equal 'none', 'scale', or 'range'")
  
  # Scale variables, if indicated
  if(standardize != "none") {
    
    # Remove variables that are transformed
    if(any(unlist(lapply(modelList, function(i) grepl("log\\(|log10\\(|sqrt\\(|I\\(", deparse(formula(i)))))))
      
      stop("Transformations detected in the formula! This may produce invalid scaled values\nStore transformations as new variables, and re-specify the models")
     
    # Get variables to scale, ignoring variables that are modeled to non-normal distributions
    vars.to.scale = unlist(lapply(modelList, function(i) {
     
      err = try(family(i), TRUE)
      
      if(grepl("Error", err[1]) | grepl("gaussian", err[1]))
        
        all.vars(formula(i)) else {
          
          warning(
            paste("Reponse '", formula(i)[2], "' is not modeled to a gaussian distribution: keeping response on original scale")
          )
          
          NULL }

      }
    
    ) )
    
    # Remove variables that are factors
    vars.to.scale = vars.to.scale[!vars.to.scale %in% colnames(data)[sapply(data, is.factor)]]
    
    # Remove duplicated variables
    vars.to.scale = vars.to.scale[!duplicated(vars.to.scale)]
    
    # Scale those variables by mean and SD, or by range
    if(class(data) == "comparative.data")
      
      newdata = data$data else newdata = data
    
    newdata[, vars.to.scale] = apply(newdata[, vars.to.scale], 2, function(x) 
      
      if(standardize == "scale") scale(x) else
        
        if(standardize == "range") (x-min(x, na.rm = T)) / diff(range(x, na.rm = T))
      
      )
    
    if(class(data) == "comparative.data") {
      
      data$data = newdata
      
      newdata = data
    
      }
    
    }
  
  # Return coefficients
  ret = do.call(rbind, lapply(modelList, function(i) {
    
    if(standardize != "none") i = update(i, data = newdata)
    
    # Extract coefficients and return in a data.frame
    if(any(class(i) %in% c("lm", "glm", "pgls", "negbin", "glmerMod"))) {
      
      tab = summary(i)$coefficients
      
      data.frame(response = Reduce(paste, deparse(formula(i)[[2]])),
                 predictor = rownames(tab)[-1],
                 estimate = tab[-1, 1],
                 std.error = tab[-1, 2],
                 p.value = tab[-1, 4], 
                 row.names = NULL)
      
    } else if(any(class(i) %in% c("gls"))) {
      
      tab = summary(i)$tTable
      
      data.frame(response = Reduce(paste, deparse(formula(i)[[2]])),
                 predictor = rownames(tab)[-1],
                 estimate = tab[-1, 1],
                 std.error = tab[-1, 2],
                 p.value = tab[-1, 4], 
                 row.names = NULL)
      
    } else if(any(class(i) %in% c("lme", "glmmPQL"))) {
      
      tab = summary(i)$tTable
      
      data.frame(response = Reduce(paste, deparse(formula(i)[[2]])),
                 predictor = rownames(tab)[-1],
                 estimate = tab[-1, 1],
                 std.error = tab[-1, 2],
                 p.value = tab[-1, 5], 
                 row.names = NULL)
      
    } else if(any(class(i) %in% c("lmerMod", "merModLmerTest"))) {
      
      tab = summary(as(i, "merModLmerTest"))$coefficients
      
      data.frame(response = Reduce(paste, deparse(formula(i)[[2]])),
                 predictor = rownames(tab)[-1],
                 estimate = tab[-1, 1],
                 std.error = tab[-1, 2],
                 p.value = tab[-1, 5], 
                 row.names = NULL) 
      
      } 
    
    } ) )
  
  # Do significance tests for correlated errors
  if(!is.null(corr.errors)) 
    
    ret = rbind(ret, do.call(rbind, lapply(corr.errors, function(j) {
      
      # Pull out correlated variables
      corr.vars = gsub(" ", "", unlist(strsplit(j, "~~")))
      
      # Perform significance test and return in a data.frame
      data.frame(
        response = paste("~~", corr.vars[1]),
        predictor = paste("~~", corr.vars[2]),
        estimate = cor(data[, corr.vars[1]], 
                       data[, corr.vars[2]], 
                       use = "complete.obs"),
        std.error = NA,
        p.value = 1 - 
          pt((cor(data[, corr.vars[1]], data[, corr.vars[2]], use = "complete.obs") * sqrt(nrow(data) - 2))/
               (sqrt(1 - cor(data[, corr.vars[1]], data[, corr.vars[2]], use = "complete.obs")^2)), nrow(data)-2),
        row.names = NULL
        )
      
    } ) ) )
  
  # Order by response and p-value
  ret = ret[with(ret, order(response, p.value)),]
  
  # Round p-values
  ret$p.value = round(ret$p.value, 4)
  
  # If standardize != "none" and interactions present, set SEs and P-values to NA
  if(standardize != "none" & any(sapply(modelList, function(x) any(grepl("\\:|\\*", formula(x)))))) {
    
    # Return warning
    print("It is not correct to interpret significance of standardized variables involved in interactions!")
    print("Refer to unstandardized P-values to assess significance.") 
  
    # Remove SEs and P=values for rows with interactions
    ret[grepl("\\:|\\*", ret$predictor), 4:5] = NA
    
  }
    
  return(ret)

}