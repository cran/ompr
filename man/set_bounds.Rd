% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model-api.R
\name{set_bounds}
\alias{set_bounds}
\alias{set_bounds_}
\title{Set the bounds of a variable}
\usage{
set_bounds(.model, .variable, ..., lb = NULL, ub = NULL)

set_bounds_(.model, .variable, ..., lb = NULL, ub = NULL, .dots)
}
\arguments{
\item{.model}{the model}

\item{.variable}{the variable name/definition or a linear constraint}

\item{...}{quantifiers for the indexed variable}

\item{lb}{the lower bound of the variable.}

\item{ub}{the upper bound of the variable

For \code{MIPModel} you can also pass (in)equalities to define bounds. Please
look at the examples.}

\item{.dots}{Used to work around non-standard evaluation.}
}
\description{
Change the lower and upper bounds of a named variable,
indexed variable or a group of variables.
}
\examples{
library(magrittr)
MIPModel() \%>\%
  add_variable(x[i], i = 1:5) \%>\%
  add_constraint(x[i] >= 1, i = 1:5) \%>\% # creates 5 constraints
  set_bounds(x[i], lb = 3, i = 1:3) \%>\%
  variable_bounds()

MIPModel() \%>\%
  add_variable(x[i], i = 1:5) \%>\%
  set_bounds(x[i] <= i, i = 1:5) \%>\% # upper bound
  set_bounds(x[i] >= 0, i = 1:5) \%>\% # lower bound
  set_bounds(x[5] == 45) \%>\%
  variable_bounds()
}
