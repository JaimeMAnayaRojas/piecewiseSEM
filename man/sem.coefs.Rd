\name{sem.coefs}

\alias{sem.coefs}

\title{
Retrieves path coefficients for structural equation model
}

\description{
Extracts path coefficients for a piecewise structural equation model (SEM).
}

\usage{
sem.coefs(modelList, data, standardize = "none", corr.errors)
}

\arguments{

  \item{modelList}{
a list of regressions representing the structural equation model. 
}

\item{data}{
a \code{data.frame} used to construct the structured equations.
}

  \item{standardize}{
specifies the type of standardization to perform: \code{"none"}, \code{"scale"}, \code{"range"}.
}

  \item{corr.errors}{
a vector of variables with correlated errors (separated by \code{~~}).
}

}

\details{
Unstandardized coefficients are extracted directly from model output. 

When \code{standardize = "scale"}, variables are scaled by mean and variance using the function \code{scale}. When \code{standardize = "range"}, variables are scaled by subtracting the minimum and dividing by the difference of the range.

If predictors are factors or dummy variables, then they are left in their original units. If the response is not normally distributed, then it is left untransformed even when \code{standardize = "scale"} or \code{standardize = "range"}. Predictors in these models are transformed, unless they meet the previous criteria.

Variables with correlated errors have no direct relationship but rather are hypothesized to be driven by the same underlying factor. This covariance should be reflected as correlated errors (double-headed arrow in a path diagram). Correlated errors are specified using the syntax from the \code{lavaan} package: \code{var1 ~~ var2}. If two exogenous variables are listed, then the  Spearman correlation between the two is given, otherwise the correlation between the partial residuals is returned. Significance tests (i.e., P-values) for correlated errors are derived from a t-distribution using the transformation in Shipley, 2000 (p.76).

Standardized variables involved in an interaction will throw a warning and ask the user to interpret significance using the unstandardized variables. However, the standardized coefficients are still interpretable because they have been standardized before their product is calculated (as opposed to standardization of the product, which is incorrect, see Bollen 1989).
}

\value{
Returns a \code{data.frame} with the causal path (response, predictor), the coefficient estimate, the standard error, and associated p-value.
}

\references{
Shipley, Bill. Cause and correlation in biology: a user's guide to path analysis, structural equations and causal inference. Cambridge University Press, 2002.

Bollen, K. A. Structural equations with latent variables. New York: John Wiley & Sons, 1989.
}

\author{
Jon Lefcheck
}

\note{
}

\seealso{
\code{\link{scale}}, \code{\link{lm.beta}}
}

\examples{
# Load example data
data(shipley2009)

# Load model packages
library(lmerTest)
library(nlme)

# Create list of models 
shipley2009.modlist = list(
  
  lme(DD ~ lat, random = ~1|site/tree, na.action = na.omit, 
      data = shipley2009),
  
  lme(Date ~ DD, random = ~1|site/tree, na.action = na.omit, 
      data = shipley2009),
  
  lme(Growth ~ Date, random = ~1|site/tree, na.action = na.omit, 
      data = shipley2009),
  
  glmer(Live ~ Growth+(1|site)+(1|tree), 
        family=binomial(link = "logit"), data = shipley2009) 
  
)
  
# Get raw path coefficients
sem.coefs(shipley2009.modlist, shipley2009)

# Scale by mean and variance
sem.coefs(shipley2009.modlist, shipley2009, standardize = "scale")

# Scale by range
sem.coefs(shipley2009.modlist, shipley2009, standardize = "range")
}