% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cdh_utils.R
\name{readADMDatamartModelExport}
\alias{readADMDatamartModelExport}
\title{Read export of ADM model data.}
\usage{
readADMDatamartModelExport(
  srcFolder = ".",
  instancename = "Data-Decision-ADM-ModelSnapshot_pyModelSnapshots",
  latestOnly = F,
  tmpFolder = tempdir(check = T)
)
}
\arguments{
\item{srcFolder}{Optional folder to look for the file (defaults to the
current folder)}

\item{instancename}{Name of the file w/o the timestamp, in Pega format
<Applies To>_<Instance Name>, or the complete filename including timestamp
and zip extension as exported from Pega. Defaults to the Pega generated
name of the dataset: \code{Data-Decision-ADM-ModelSnapshot_pyModelSnapshots}.}

\item{latestOnly}{If TRUE only the most recent snapshot for every model
is read. Defaults to FALSE, so all model data over time is returned.}

\item{tmpFolder}{Optional folder to store the unzipped data (defaults to a
temp folder)}
}
\value{
A \code{data.table} with the ADM model data
}
\description{
This is a specialized version of \code{readDSExport}
that defaults the dataset name, leaves out the detailed model data (if present) and
other internal fields, returns the properties without the py prefixes and converts
date fields, and makes sure numeric fields are returned as numerics.
}
\examples{
\dontrun{readADMDatamartModelExport("~/Downloads")}
}
