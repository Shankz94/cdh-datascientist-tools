library(testthat)
library(cdhtools)
library(lubridate)

context("check basic utilities")

test_that("dataset exports", {
  data <- readDSExport("Data-Decision-ADM-ModelSnapshot_All_20180316T134315_GMT.zip","dsexports")
  expect_equal(nrow(data), 15)
  expect_equal(ncol(data), 22)

  data <- readDSExport("dsexports/Data-Decision-ADM-ModelSnapshot_All_20180316T135038_GMT.zip")
  expect_equal(nrow(data), 30)
  expect_equal(ncol(data), 22)

  data <- readDSExport("Data-Decision-ADM-ModelSnapshot_All","dsexports")
  expect_equal(nrow(data), 30)
  expect_equal(ncol(data), 22)

  data <- readDSExport("Data-Decision-ADM-PredictorBinningSnapshot_All","dsexports")
  expect_equal(nrow(data), 1755)
  expect_equal(ncol(data), 35)
  expect_equal(length(unique(data$pyModelID)), 15)

  expect_error( readDSExport("Non existing non zip file",""))
  expect_error( readDSExport("Data-Decision-ADM-ModelSnapshot_All_20180316T134315_GMT.zip",""))
  readDSExport("Data-Decision-ADM-PredictorBinningSnapshot_All","dsexports", excludeComplexTypes = F)
})

test_that("specialized model data export", {
  data <- readADMDatamartModelExport(instancename="Data-Decision-ADM-ModelSnapshot_All",
                                     srcFolder="dsexports")
  expect_equal(nrow(data), 30)
  expect_equal(ncol(data), 16) # omits internal fields

  data <- readADMDatamartModelExport(instancename="Data-Decision-ADM-ModelSnapshot_All",
                                     srcFolder="dsexports",
                                     latestOnly=T)
  expect_equal(nrow(data), 15) # only latest snapshot
  expect_equal(ncol(data), 16)
})

test_that("specialized predictor data export", {
  data <- readADMDatamartPredictorExport(instancename="Data-Decision-ADM-PredictorBinningSnapshot_All",
                                         srcFolder="dsexports")
  expect_equal(nrow(data), 15) # binning skipped by default
  expect_equal(ncol(data), 15) # omits internal and binning fields

  # compare this to doing it "manually" using the "raw" readDSExport method
  data2 <- readDSExport("Data-Decision-ADM-PredictorBinningSnapshot_All","dsexports")[pyBinIndex == 1]

  expect_equal(nrow(data2), 425)
  expect_equal(ncol(data2), 35)
  expect_equal(sum(!grepl("^p[x|z]", names(data2))), 30) # w/o the internal fields

  data <- readADMDatamartPredictorExport(instancename="Data-Decision-ADM-PredictorBinningSnapshot_All",
                                         srcFolder="dsexports",
                                         noBinning = F,
                                         latestOnly = F)
  expect_equal(nrow(data), 1755) # binning and all timestamps included
  expect_equal(ncol(data), 30) # omits internal fields

  data <- readADMDatamartPredictorExport(instancename="Data-Decision-ADM-PredictorBinningSnapshot_All",
                                         srcFolder="dsexports",
                                         noBinning = F)
  expect_equal(nrow(data), 15) # binning but only latest snapshots
  expect_equal(ncol(data), 30) # omits internal fields

  data <- readADMDatamartPredictorExport(instancename="Data-Decision-ADM-PredictorBinningSnapshot_All",
                                         srcFolder="dsexports",
                                         latestOnly = F)
  expect_equal(nrow(data), 425) # no binning but all snapshots
  expect_equal(ncol(data), 15) # omits internal fields
})

# to add/update data:

dontrun_only_to_save_data <- function()
{
  admdatamart_models <- readADMDatamartModelExport(instancename="Data-Decision-ADM-ModelSnapshot_All",
                                                   srcFolder="tests/testthat/dsexports",
                                                   latestOnly = F)
  names(admdatamart_models) <- tolower(names(admdatamart_models))
  #devtools::use_data(admdatamart_models)
  save(admdatamart_models, file="data/admdatamart_models.rda", compress='xz')

  admdatamart_binning <- readADMDatamartPredictorExport(instancename="Data-Decision-ADM-PredictorBinningSnapshot_All",
                                                        srcFolder="tests/testthat/dsexports",
                                                        noBinning = F,
                                                        latestOnly = F)
  names(admdatamart_binning) <- tolower(names(admdatamart_binning))
  #devtools::use_data(admdatamart_binning)
  save(admdatamart_binning, file="data/admdatamart_binning.rda", compress='xz')
}
# admdatamart_models <- readDSExport("Data-Decision-ADM-ModelSnapshot_All", "~/Downloads")
# names(admdatamart_models) <- tolower(names(admdatamart_models))
# for(f in c("pyperformance")) admdatamart_models[[f]] <- as.numeric(admdatamart_models[[f]])
# devtools::use_data(admdatamart_models)
# save(admdatamart_models, file="data/admdatamart_models.rda", compress='xz')
#
# admdatamart_binning <- readDSExport("Data-Decision-ADM-ModelSnapshot_All", "~/Downloads")
# names(admdatamart_binning) <- tolower(names(admdatamart_binning))
# for(f in c("pyperformance")) admdatamart_binning[[f]] <- as.numeric(admdatamart_binning[[f]])
# devtools::use_data(admdatamart_binning)
# save(admdatamart_binning, file="data/admdatamart_binning.rda", compress='xz')
# + describe in R/data.R

# ihsampledata taken from IH in DMSample after initialization
#ihsampledata <- readDSExport("Data-pxStrategyResult_pxInteractionHistory", "~/Downloads")
#ihsampledata <- ihsampledata[ pyApplication=="DMSample"&pySubjectID %in% paste("CE", seq(1:10), sep="-")]
#devtools::use_data(ihsampledata)
#save(ihsampledata, file="data/ihsampledata.rda", compress='xz')
# + describe in R/data.R

test_that("AUC from binning", {
  expect_equal(auc_from_bincounts( c(3,1,0), c(2,0,1)), 0.75)

  # This actually is an example from the COC Mesh article
  positives <- c(50,70,75,80,85,90,110,130,150,160)
  negatives <- c(1440,1350,1170,990,810,765,720,675,630,450)

  expect_equal(auc_from_bincounts(positives, negatives), 0.6871)
  expect_equal(auc_from_bincounts(positives, rep(0, length(positives))), 0.5)
})

test_that("AUC from full arrays", {
  expect_equal(auc_from_probs( c("yes", "yes", "no"), c(0.6, 0.2, 0.2)), 0.75)

  # from https://www.r-bloggers.com/calculating-auc-the-area-under-a-roc-curve/
  category <- c(1, 1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0)
  prediction <- rev(seq_along(category))
  prediction[9:10] <- mean(prediction[9:10])
  expect_equal(auc_from_probs(category, prediction), 0.825)

  # This actually is an example from the COC Mesh article
  # these will be turned into a lengthy format of 10.000 responses
  positives <- c(50,70,75,80,85,90,110,130,150,160)
  negatives <- c(1440,1350,1170,990,810,765,720,675,630,450)

  truth <- unlist(sapply(seq(length(positives)), function(i){ return(c(rep(1, positives[i]), rep(0, negatives[i])))}))
  probs <- unlist(sapply(seq(length(positives)), function(i){ return(c(rep(positives[i]/(positives[i]+negatives[i]), positives[i]+negatives[i])))}))

  expect_equal(auc_from_probs(truth, probs), 0.6871)
  expect_equal(auc_from_probs(truth, rep(0, length(probs))), 0.5)
  expect_equal(auc_from_probs(rep("Accept, 10"), runif(n = 10)), 0.5)
})

test_that("GINI conversion", {
  expect_equal(auc2GINI(0.8232), 0.6464)
  expect_equal(auc2GINI(0.5), 0.0)
  expect_equal(auc2GINI(1.0), 1.0)
  expect_equal(auc2GINI(0.6), 0.2)
  expect_equal(auc2GINI(0.4), 0.2)
  expect_equal(auc2GINI(NA), 0.0)
})

test_that("Lift", {
  p <- c(0,119,59,69,0)
  n <- c(50,387,105,40,37)
  # see example http://techdocs.rpega.com/display/EPZ/2019/06/21/Z-ratio+calculation+in+ADM
  expect_equal( 100*lift(p,n), c(0, 82.456, 126.13, 221.94, 0), tolerance = 1e-3)
})

test_that("Z-Ratio", {
  p <- c(0,119,59,69,0)
  n <- c(50,387,105,40,37)
  # see example http://techdocs.rpega.com/display/EPZ/2019/06/21/Z-ratio+calculation+in+ADM
  expect_equal( zratio(p,n), c(-7.375207, -3.847732,  2.230442,  7.107804, -6.273136), tolerance = 1e-6)
})


test_that("Date conversion", {
  # not safe to test w/o timezone as this is locale dependent
  expect_equal(toPRPCDateTime(fromPRPCDateTime("20180316T134127.847 CET")), "20180316T124127.846 GMT")
  expect_equal(toPRPCDateTime(fromPRPCDateTime("20180316T000000.000 EST")), "20180316T050000.000 GMT")
})
