library(data.table)
library(stringr)

cmd_args <- commandArgs()
CURRENTDIR <- dirname(regmatches(cmd_args, regexpr("(?<=^--file=).+", cmd_args, perl=TRUE)))
ROOTDIR <- dirname(CURRENTDIR)
OUTDIR <- file.path(ROOTDIR, "output")

# OUTDIR <- "../output"

SAMPLERDIRS <- c("MALA", "AM", "SMMALA", "MAMALA")

nsamplerdirs <- length(SAMPLERDIRS)

npars <- 4

nchains <- 10
nmcmc <- 110000
nburnin <- 10000
npostburnin <- nmcmc-nburnin

maxlag <- 40
ci <- rep(4, npars)
pi <- 2

cors <- matrix(data=NA, nrow=maxlag+1, ncol=nsamplerdirs)

for (j in 1:nsamplerdirs) {
  chains <- t(fread(
    file.path(OUTDIR, SAMPLERDIRS[j], paste("chain", str_pad(ci[j], 2, pad="0"), ".csv", sep="")), sep=",", header=FALSE
  ))

  cors[, j] <- acf(chains[, pi], lag.max=maxlag, demean=TRUE, plot=FALSE)$acf
}

sqrtnpostburnin <- sqrt(npostburnin)

cols <- c("green", "blue", "orange", "red")

pdf(file=file.path(OUTDIR, "logit_acfplot.pdf"), width=10, height=6)

plot(
  0:maxlag,
  cors[, 1],
  type="o",
  ylim=c(-0.2, 1.),
  col=cols[1],
  lwd=2,
  pch=20,
  xlab="",
  ylab="",
  cex.axis=1.8,
  cex.lab=1.7,
  yaxt="n"
)

axis(
  2,
  at=seq(-0.2, 1, by=0.2),
  labels=seq(-0.2, 1, by=0.2),
  cex.axis=1.8,
  las=1
)

lines(
  0:maxlag,
  cors[, 2],
  type="o",
  col=cols[2],
  lwd=2,
  pch=20
)

lines(
  0:maxlag,
  cors[, 3],
  type="o",
  col=cols[3],
  lwd=2,
  pch=20
)

lines(
  0:maxlag,
  cors[, 4],
  type="o",
  col=cols[4],
  lwd=2,
  pch=20
)

legend(
  "topright",
  SAMPLERDIRS,
  lty=c(1, 1, 1),
  lwd=c(5, 5, 5),
  col=cols,
  cex=1.5,
  bty="n",
  text.width=8
)

sqrt(npostburnin)

abline(h=1.96/sqrtnpostburnin, lty=2)
abline(h=-1.96/sqrtnpostburnin, lty=2)

dev.off()