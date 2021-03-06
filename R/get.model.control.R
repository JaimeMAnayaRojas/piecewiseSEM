get.model.control = function(model, model.control) {
  
  control.classes = lapply(model.control, function(i) gsub("(.*)Control", "\\1", class(i))[1] )
  
  model.class = ifelse("merModLmerTest" %in% class(model), "lmerMod", class(model))
  
  # Match model control list with appropriate model class for basis model
  if(is.null(model.control)) {
    
    if(any(class(model) %in% "glm")) glm.control() else
      
      if(any(class(model) %in% "gls")) glsControl() else
      
        if(any(class(model) %in% c("lme", "glmmPQL"))) lmeControl() else 
        
          if(any(class(model) %in% c("lmerMod", "merModLmerTest"))) lmerControl() else
            
            if(class(model) %in% c("glmerMod")) glmerControl()
          
  } else {
    
    if(any(control.classes %in% gsub("(.*)Mod", "\\1", model.class)))
      
      model.control[[which(control.classes %in% gsub("(.*)Mod", "\\1", model.class))]] else
        
        if(class(model) == "glm")
          
          model.control[[which(sapply(model.control, length) == 3)]] else
            
            if(class(model) == "gls")
              
              model.control[[which(sapply(model.control, length) == 13)]] else
                
                if(any(class(model) %in% c("lme", "glmmPQL")))
                  
                  model.control[[which(sapply(model.control, length) == 15)]]
            
  }

}