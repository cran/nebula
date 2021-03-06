#' Extract Pearson residuals from the results of NEBULA
#'
#' @param nebula An object of the result obtained from running the function nebula.
#' @param count A raw count matrix of the single-cell data. The rows are the genes, and the columns are the cells. The matrix can be a matrix object or a sparse dgCMatrix object.
#' @param id A vector of subject IDs. The length should be the same as the number of columns of the count matrix.
#' @param pred A design matrix of the predictors. The rows are the cells and the columns are the predictors. If not specified, an intercept column will be generated by default.
#' @param offset A vector of the scaling factor. The values must be strictly positive. If not specified, a vector of all ones will be generated by default. 
#' @return residuals: A matrix of Pearson residuals. The number of columns is the number of cells in the count matrix. The rows correspond to gene IDs reported in the result from nebula.
#' @return gene: Gene names corresponding to the row names of the count matrix.
#' @export
#' @examples
#' library(nebula)
#' data(sample_data)
#' pred = model.matrix(~X1+X2+cc,data=sample_data$pred)
#' re = nebula(count=sample_data$count,id=sample_data$sid,pred=pred)
#' resid = nbresidual(re,count=sample_data$count,id=sample_data$sid,pred=pred)
#' 


nbresidual = function(nebula, count, id, pred = NULL, offset = NULL)
{
  type='marginal'
  
  ncell = ncol(count)
  ngene = nrow(nebula$summary)
  
  if (is.null(pred)) {
    pred = matrix(1, ncol = 1, nrow = ncell)
    nb = 1
  }else{
    pred = as.matrix(pred)
    nb = ncol(pred)
  }
  
  sds = apply(pred,2,sd)
  intercept = which(sds==0)
  if(nb>1)
  {pred[,-intercept] = scale(pred[,-intercept],scale=FALSE)}
  pred[,intercept] = 1
  
  if (is.null(offset)) {
    offset = rep(1,ncell)
  }
  logoff = log(offset)
  
  # nbres = matrix(NA,ngene,ncell)
  subod = as.matrix(nebula$overdispersion)[,1]
  residuals = sapply(1:ngene, function(x) {
    sigma2ind = subod[x]
    if(nebula$algorithm[x]!='PGMM')
    {sigma2cell = nebula$overdispersion[x,2]}else{
      sigma2cell = 0
    }
    ey = exp(pred%*%t(nebula$summary[x,1:nb]) + logoff + sigma2ind/2)
    vary = ey + ey*ey*(exp(sigma2ind)*(1+sigma2cell)-1)
    (count[nebula$summary[x,'gene_id'],] - ey)/sqrt(vary)
  }
  )
  
  residuals = t(residuals)
  rownames(residuals) = nebula$summary[,'gene_id']
  colnames(residuals) = colnames(count)
  
  return(list(residuals=residuals,gene=rownames(count)[nebula$summary[,'gene_id']]))
}

