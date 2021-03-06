auxI1 <- function(ft) {
  # This function constructs the I1 objects taking a
  # a class or a list containing at least Z0,Z1,Z2, alpha
  # and beta. FOr models with short run elements, it also
  # has to contain Psi.
  # 
  # Args
  #   List or object containing a minimum set of information
  #
  # Return
  #   I1 Object
  #
  
  if (ncol(ft$beta) > 0)
  {
    colnames(ft$beta)  <- paste('beta(', 1:ncol(ft$beta), ')', sep = '')
    colnames(ft$alpha) <- paste('alpha(', 1:ncol(ft$alpha), ')', sep = '')
  }
  rownames(ft$beta)  <- colnames(ft$Z1)
  rownames(ft$alpha) <- colnames(ft$Z0)
  
  if (!is.null(ft$Z2))
  {
    tmpfit           <- with(ft, lm.fit(Z2, Z0 - Z1 %*% tcrossprod(beta, alpha)))
    ft$Psi           <- t(tmpfit$coef)
    colnames(ft$Psi) <- colnames(ft$Z2)
    if(!is.matrix(tmpfit$fitted.values)) {tmpfit$fitted.values <- vec2mat.xts(tmpfit$fitted.values)}
    ft$fitted.values <- xts(tmpfit$fitted.values, index(ft$Z0))
    ft$residuals     <- vec2mat.xts(tmpfit$residuals)
  }
  else
  {
    ft$fitted.values <- with(ft, as.xts(Z1 %*% tcrossprod(beta, alpha), index(Z0)))
    ft$residuals     <- with(ft, as.xts(Z0 - fitted.values, index(Z0)))
  }
  
  ft$Omega               <- crossprod(ft$residuals) / nrow(ft$residuals)
  colnames(ft$residuals) <- colnames(ft$Z0)
  class(ft$residuals)    <- c('I1res', class(ft$residuals))
  
  class(ft) <- 'I1'
  return(ft)
}

auxI2 <- function(ft, r) {
  p0   <- ncol(ft$R0)
  p1   <- ncol(ft$R1)
  Time <- nrow(ft$R0)
  s1   <- if (is.null(ft$tau)) 0
  else ncol(ft$tau) - r
  s2       <- p0 - r - s1
  ft$beta  <- ft$tau %*% ft$rho
  kSi      <- -crossprod(ft$kappa, Null(ft$rho))
  eTa	     <- crossprod(Null(ft$beta), ft$tau %*% Null(ft$rho))
  ft$delta <-	tcrossprod(Null(ft$tau)) %*% ft$psi
  tmpfit   <- lm.fit(cbind(ft$R2 %*% ft$beta + ft$R1 %*% ft$delta, ft$R1 %*% ft$tau), ft$R0)
  tmpcoef  <- t(matrix(tmpfit$coef, 2 * r + s1, p0))
  ft$alpha <-	tmpcoef[, seq_len(r), drop = FALSE]
  ft$zeta  <- tmpcoef[, seq(r + 1, 2 * r + s1, len = r + s1), drop = FALSE]
  
  if (!is.null(ncol(ft$Z3))) {
    ft$Psi <- t(lm.fit(ft$Z3, ft$Z0 - tcrossprod(ft$Z2 %*% ft$beta +
                                                   ft$Z1 %*% ft$delta, ft$alpha) -
                         ft$Z1 %*% tcrossprod(ft$tau, ft$zeta))$coef)
    colnames(ft$Psi) <- colnames(ft$Z3)
    ft$fitted.values <- with(ft, xts(tcrossprod(Z2 %*% beta + Z1 %*% delta, alpha) +
                                       Z1 %*% tcrossprod(tau, zeta) +
                                       tcrossprod(Z3, Psi),
                                     index(Z0)
    )
    )
  }
  else ft$fitted.values <- with(ft, xts(tcrossprod(Z2 %*% beta + Z1 %*% delta, alpha) +
                                          ft$Z1 %*% tcrossprod(ft$tau, ft$zeta),
                                        index(Z0)
  )
  )
  
  if (s1 != 0) {
    ft$beta1 <- Null(ft$beta) %*% eTa
    ft$alpha1 <- Null(ft$alpha) %*% kSi
    rownames(ft$beta1) <- colnames(ft$R2)
    colnames(ft$beta1) <- paste('beta1(', 1:ncol(ft$beta1), ')', sep = '')
    rownames(ft$alpha1)	<- colnames(ft$R0)
    colnames(ft$alpha1) <- paste('alpha1(', 1:ncol(ft$alpha1), ')', sep = '')
  }
  if (s2 != 0) {
    ft$beta2 <- Null(ft$beta) %*% Null(eTa)
    ft$alpha2 <- Null(ft$alpha) %*% Null(kSi)
    rownames(ft$beta2) <- colnames(ft$R2)
    colnames(ft$beta2) <- paste('beta2(', 1:ncol(ft$beta2), ')', sep = '')
    rownames(ft$alpha2) <- colnames(ft$R0)
    colnames(ft$alpha2) <- paste('alpha2(', 1:ncol(ft$alpha2), ')', sep = '')
  }
  
  if (r > 0) {
    colnames(ft$beta) <- paste('beta(', 1:ncol(ft$beta), ')', sep = '')
    colnames(ft$alpha) <- paste('alpha(', 1:ncol(ft$alpha), ')', sep = '')
    rownames(ft$beta) <- c(colnames(ft$R2))
  }
  
  ft$residuals <- ft$Z0 - ft$fitted.values
  colnames(ft$residuals) <- colnames(ft$Z0)
  class(ft$residuals) <- c('I2res', class(ft$residuals))
  
  class(ft) <- c('I2', 'I1')
  
  return(ft)
}
