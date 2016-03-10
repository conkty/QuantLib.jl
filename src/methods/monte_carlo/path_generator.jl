type PathGenerator{RSG <: AbstractRandomSequenceGenerator, I <: Integer, S <: StochasticProcess1D}
  brownianBridge::Bool
  generator::RSG
  dimension::I
  timeGrid::TimeGrid
  process::S
  nextSample::Sample
  temp::Vector{Float64}
  bb::BrownianBridge
end

function PathGenerator(process::StochasticProcess, tg::TimeGrid, generator::AbstractRandomSequenceGenerator, brownianBridge::Bool)
  generator.dimension == length(tg.times) - 1 || error("wrong dimensions")

  return PathGenerator(brownianBridge, generator, generator.dimension, tg, process, Sample(Path(tg), 1.0), zeros(generator.dimension), BrownianBridge(tg))
end

get_next!(pg::PathGenerator) = get_next!(pg, false)
get_antithetic!(pg::PathGenerator) = get_next!(pg, true)

function get_next!(pg::PathGenerator, antithetic::Bool)
  sequenceVals, sequenceWeight = antithetic ? last_sequence(pg.generator) : next_sequence!(pg.generator)

  # TODO Brownian Bridge
  pg.temp = copy(sequenceVals)

  pg.nextSample.weight = sequenceWeight
  path = pg.nextSample.value # TODO check to see if this is just a pass by reference

  path[1] = get_x0(pg.process)

  for i = 2:length(path)
    t = pg.timeGrid[i-1]
    dt = pg.timeGrid.dt[i - 1]
    path[i] = evolve(pg.process, t, path[i-1], dt, antithetic ? -pg.temp[i-1] : pg.temp[i-1])
  end

  return pg.nextSample
end
