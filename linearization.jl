using JuMP
using CPLEX
# using GLPK

flow = [0 5 2 0
    0 0 2 3
    3 4 0 0
    0 0 5 0]

distance = [0 5 10 4
    4 0 6 7
    8 5 0 5
    6 6 5 0]

nbFac, nbLoc = size(flow)

model = Model(CPLEX.Optimizer)
# model = Model(GLPK.Optimizer)

@variable(model, x[1:nbFac, 1:nbLoc], Bin)

# New binary variable to linearize
@variable(model, z[1:nbFac, 1:nbFac, 1:nbLoc, 1:nbLoc], Bin)

for j in 1:nbLoc
    @constraint(model, sum(x[i, j] for i in 1:nbFac) == 1)
end

for i in 1:nbFac
    @constraint(model, sum(x[i, j] for j in 1:nbLoc) == 1)
end

# Added constraints to linearize
for i in 1:nbFac
    for j in 1:nbFac
        for k in 1:nbLoc
            for l in 1:nbLoc
                @constraint(model, z[i, j, k, l] <= x[i, k])
                @constraint(model, z[i, j, k, l] <= x[j, l])
                @constraint(model, z[i, j, k, l] >= x[i, k] + x[j, l] - 1)
            end
        end
    end
end

@objective(model, Min, sum(flow[i, j] * distance[k, l] * z[i, j, k, l] for i = 1:nbFac for j = 1:nbFac for k = 1:nbLoc for l = 1:nbLoc))

print(model)

optimize!(model)

objective_value(model)

value.(x)