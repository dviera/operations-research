# STOCHASTIC PROGRAMMING
# Birge & Louveaux example

using JuMP
using GLPK

##################################
# MODEL WITHOUT UNCERTAINTY
##################################

m1 = Model(GLPK.Optimizer)

# acres of land used for wheat, corn, sugar beat
@variable(m1, acres[1:3] >= 0)

# tons of wheat, corn, sugar beat @$36 and sugar beat @10 sold
@variable(m1, sold[1:4] >= 0)

# tons of wheat and corn purchased
@variable(m1, purch[1:2] >= 0)

# constraints
@constraint(m1, 2.5 * acres[1] + purch[1] - sold[1] >= 200)
@constraint(m1, 3 * acres[2] + purch[2] - sold[2] >= 240)

@constraint(m1, sum(acres[i] for i in 1:3) <= 500)

@constraint(m1, sold[3] + sold[4] <= 20 * acres[3])

@constraint(m1, sold[3] <= 6000)

revenues = 170 * sold[1] + 150 * sold[2] + 36 * sold[3] + 10 * sold[4]
planting_cost = 150 * acres[1] + 230 * acres[2] + 260 * acres[3]
purch_cost = 238 * purch[1] + 210 * purch[2]

@objective(m1, Max, revenues - planting_cost - purch_cost)

JuMP.optimize!(m1)

JuMP.getobjectivevalue(m1)

JuMP.getvalue.(acres)

##################################
# MODEL WITH UNCERTAINTY
##################################

# Yield depends on the weather conditions
# average :: previous model (scenario 1)
# good :: yield increases 20% (scnerario 2)
# bad :: yield drops 20% (scenario 3)


# How much acres to assign :: decision now
# Sales and  purchases depends on the yields

# the 3 scenarios are equally possible

m2 = Model(GLPK.Optimizer)

# i = 1:4 -> sales of different products
# j = 1:3 -> three (3) different scenarios
@variable(m2, sales[1:4, 1:3] >= 0)

# i = 1:2 -> purchase of different products
# j = 1:3 -> three (3) different scenarios
@variable(m2, purchases[1:2, 1:3] >= 0)
@variable(m2, acres[1:3] >= 0)

# purchases depends on the weather
purch_cost_sc1 = 238 * purchases[1, 1] + 210 * purchases[2, 1]
purch_cost_sc2 = 238 * purchases[1, 2] + 210 * purchases[2, 2]
purch_cost_sc3 = 238 * purchases[1, 3] + 210 * purchases[2, 3]

# revenues depends on the weather
revenue_sc1 = sales[:, 1]' * [170, 150, 36, 10]
revenue_sc2 = sales[:, 2]' * [170, 150, 36, 10]
revenue_sc3 = sales[:, 3]' * [170, 150, 36, 10]

planting_cost = 150 * acres[1] + 230 * acres[2] + 260 * acres[3]

@objective(m2, Max, 1 / 3 * (revenue_sc1 + revenue_sc2 + revenue_sc3) - 1 / 3 * (purch_cost_sc1 + purch_cost_sc2 + purch_cost_sc3) - planting_cost)

# constraints
@constraint(m2, 2.5 * acres[1] + purchases[1, 1] - sales[1, 1] >= 200)
@constraint(m2, 2.5 * 1.2 * acres[1] + purchases[1, 2] - sales[1, 2] >= 200)
@constraint(m2, 2.5 * 0.8 * acres[1] + purchases[1, 3] - sales[1, 3] >= 200)


@constraint(m2, 3 * acres[2] + purchases[2, 1] - sales[2, 1] >= 240)
@constraint(m2, 3 * 1.2 * acres[2] + purchases[2, 2] - sales[2, 2] >= 240)
@constraint(m2, 3 * 0.8 * acres[2] + purchases[2, 3] - sales[2, 3] >= 240)

@constraint(m2, sum(acres[i] for i in 1:3) <= 500)

@constraint(m2, sales[3, 1] + sales[4, 1] <= 20 * acres[3])
@constraint(m2, sales[3, 2] + sales[4, 2] <= 20 * 1.2 * acres[3])
@constraint(m2, sales[3, 3] + sales[4, 3] <= 20 * 0.8 * acres[3])

@constraint(m2, sales[3, 1] <= 6000)
@constraint(m2, sales[3, 2] <= 6000)
@constraint(m2, sales[3, 3] <= 6000)

JuMP.optimize!(m2)

JuMP.getobjectivevalue(m2)

JuMP.getvalue.(sales)
