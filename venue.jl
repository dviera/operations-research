using DataFrames

################################
# Base info
################################

maxgroup = 4
safety = 150
seat_width = 46
seat_depth = 65
maxdist = safety
# maxdist = safety / seat_width
# depth_to_width_ratio = seat_depth / seat_width

################################
# Prepare data
################################

# Generate data :: row and seat n°
data = reduce(vcat, [DataFrame(row=i, seat_no=j) for i in 1:5 for j in 0:9])

# Generate pretty seat names
function seat_names(data)
    """
    input :: row of the dataset
    output :: pretty name seat
    """
    return string("L", 0, data[:row], 0, data[:seat_no])
end

# Generate all pretty seat names
data[:seats] = seat_names.(eachrow(data))

# Function to create groups of size maxgroup
function groups_k(data, k)
    groups = []
    n = length(data)
    for i = 1:n
        if i + k - 1 <= n
            push!(groups, data[i:i + k - 1])
        end
    end
    return groups
end


# Generate all groups of size maxgroup or less
function generate_groups(data)
    all_groups = []
    for i in 1:maxgroup
        for j in 1:maximum(data[:row])
            push!(all_groups, groups_k(groupby(data, :row)[j][:seats], i))
        end
    end
    return join.([i for j in all_groups for i in j], "n")
end

all_groups = generate_groups(data)

# Make pairs from groups
function generate_pair_group(all_groups)
    comb = []
    n_groups = length(all_groups)

    for i in 1:n_groups
        for j in 1:n_groups
            if i < j
                push!(comb, [all_groups[i], all_groups[j]])
            end
        end
    end
    return comb
end

comb = generate_pair_group(all_groups)
    
# Calculate distance between groups
function distance(g1, g2)
    dist = 1e+15

    g1_seats = split(g1, "n")
    g2_seats = split(g2, "n")

    len_g1 = length(g1_seats)
    len_g2 = length(g2_seats) 

    for i in 1:len_g1
        _g1 = g1_seats[i]
        _g1_x = parse(Float64, SubString(_g1, 2, 3))
        _g1_y = parse(Float64, SubString(_g1, 4, 5))
        
        for j in 1:len_g2
            _g2 = g2_seats[j]
            _g2_x = parse(Float64, SubString(_g2, 2, 3))
            _g2_y = parse(Float64, SubString(_g2, 4, 5))
            newdist = sqrt(( (_g1_x - _g2_x) * seat_depth )^2 + ( (_g1_y - _g2_y) * seat_width)^2)
            dist = min(dist, newdist)
        end
    end
    return dist
end

# Function to generate conflicting pairs

function conflicting_pairs(comb)
    conf_pairs = []
    for c in comb
        if distance(c[1], c[2]) < maxdist
            push!(conf_pairs, c)
        end
    end
    conf_pairs
end

conf_pairs = conflicting_pairs(comb)

#################################
# Graph
#################################
using LightGraphs
using MetaGraphs
using GraphPlot

m = length(all_groups)
v_graph = Graph(m)
venue_graph = MetaGraph(v_graph)

for (i, v) in enumerate(vertices(venue_graph))
    set_prop!(venue_graph, v, :name, all_groups[i])
end

set_indexing_prop!(venue_graph, :name)

# Very slow.....
# Build graph
for c in conf_pairs
    for v1 in vertices(venue_graph)
        for v2 in vertices(venue_graph)
            if venue_graph[v1, :name] == c[1] && venue_graph[v2, :name] == c[2]
                add_edge!(venue_graph, v1, v2)
            end
        end
    end
end

# Plot graph
gplot(venue_graph)

# Get maximal_cliques
max_cli = maximal_cliques(venue_graph)

# index to name and reverse
idx_to_name = Dict()
for i in 1:m
    idx_to_name[i] = venue_graph[i, :name]
end

name_to_idx = Dict()
for i in 1:m
    name_to_idx[venue_graph[i, :name]] = i
end

####################
# JuMP Optimization
####################
using JuMP
using GLPK

# helper function
function countn(str, n='n')
    count(i -> (i == n), str)
end

mod = Model(GLPK.Optimizer)
@variable(mod, x[1:m], Bin)

for cli in max_cli
    @constraint(mod, sum(x[i] for i in cli) <= 1)
end

@objective(mod, Max, sum(x[i] * (countn(idx_to_name[i], 'n') + 1) for i in 1:m))

optimize!(mod)

# checking status and results
JuMP.termination_status(mod)
JuMP.objective_value(mod)

df_res = DataFrame(idx=1:length(all_groups), dv=JuMP.value.(x))
df_res = df_res[df_res.dv .== 1.0, :]

for i in df_res.idx
    println(idx_to_name[i])
end