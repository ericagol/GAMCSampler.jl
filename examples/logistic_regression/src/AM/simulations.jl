using Distributions
using Klara

CURRENTDIR, CURRENTFILE = splitdir(@__FILE__)
ROOTDIR = splitdir(splitdir(CURRENTDIR)[1])[1]
OUTDIR = joinpath(ROOTDIR, "output")

# OUTDIR = "../output"

SUBOUTDIR = "AM"

nchains = 10
nmcmc = 110000
nburnin = 10000

covariates, = dataset("swiss", "measurements");
ndata, npars = size(covariates);

covariates = (covariates.-mean(covariates, 1))./repmat(std(covariates, 1), ndata, 1);

outcome, = dataset("swiss", "status");
outcome = vec(outcome);

function ploglikelihood(p::Vector{Float64}, v::Vector)
  Xp = v[2]*p
  dot(Xp, v[3])-sum(log.(1+exp.(Xp)))
end

plogprior(p::Vector{Float64}, v::Vector) = -0.5*(dot(p, p)/v[1]+npars*log(2*pi*v[1]))

pgradlogtarget(p::Vector{Float64}, v::Vector) = v[2]'*(v[3]-1./(1+exp.(-v[2]*p)))-p/v[1]

p = BasicContMuvParameter(:p, loglikelihood=ploglikelihood, logprior=plogprior, gradlogtarget=pgradlogtarget, nkeys=4)

model = likelihood_model([Hyperparameter(:λ), Data(:X), Data(:y), p], isindexed=false)

sampler = AM(0.02, 4, minorscale=0.001, c=0.01)

mcrange = BasicMCRange(nsteps=nmcmc, burnin=nburnin)

outopts = Dict{Symbol, Any}(:monitor=>[:value], :diagnostics=>[:accept])

times = Array{Float64}(nchains)
stepsizes = Array{Float64}(nchains)
i = 1

while i <= nchains
  v0 = Dict(:λ=>100., :X=>covariates, :y=>outcome, :p=>rand(Normal(0, 3), npars))

  job = BasicMCJob(model, sampler, mcrange, v0, outopts=outopts)

  tic()
  run(job)
  runtime = toc()

  chain = output(job)
  ratio = acceptance(chain)

  if 0.23 < ratio < 0.37
    writedlm(joinpath(OUTDIR, SUBOUTDIR, "chain"*lpad(string(i), 2, 0)*".csv"), chain.value, ',')
    writedlm(joinpath(OUTDIR, SUBOUTDIR, "diagnostics"*lpad(string(i), 2, 0)*".csv"), vec(chain.diagnosticvalues), ',')

    times[i] = runtime
    stepsizes[i] = job.sstate.tune.step

    println("Iteration ", i, " of ", nchains, " completed with acceptance ratio ", ratio)
    i += 1
  end
end

writedlm(joinpath(OUTDIR, SUBOUTDIR, "times.csv"), times, ',')
writedlm(joinpath(OUTDIR, SUBOUTDIR, "stepsizes.csv"), stepsizes, ',')
