####################################################################################################
# Adaptive refinement
####################################################################################################

export subdivide!, refine!



# Internal functions
####################################################################################################


# Default function to calculate a variation.
@inline function default_block_variation(block_center,block_volume,block_weight, neighbor_centers,neighbor_volumes,neighbor_weights)
	return maximum(abs.(block_weight .- neighbor_weights))
end








# Exported functions
####################################################################################################


@doc raw"""
	subdivide!(grid::Union{OneDimGrid,Grid},block_name::AbstractString; 
		split_weights::Bool = false,
		logarithmic::Bool = false,
		base::Real = 10.0
	)

Split the block with name `block_name` into `2^dim` sub-blocks. Return the mutated grid.

**Changing the weight splitting**

By default, the subdividing blocks retain the weight of the original block. If `split_weights = true`, the weight of the original block is split up proportional to the volumes of the subdividing blocks.

**Logarithmic splitting**

By default, the subdividing blocks split up the original blocks into `2^dim` blocks, where the corners of the subdividing blocks meet at the center point of the original block. If `logarithmic=true`, the center point that would be visible in a logarithmic plot is used. If ``l_i`` and ``u_i`` denote the lower and upper boundary of the block in dimension ``i``, the logarithmic center is given by

```math
\text{log\_center}_i = \text{base}^{(\log_{\text{base}}(l_i)+ (\log_{\text{base}}(l_i))/2}
```

"""
function subdivide!(grid::Union{OneDimGrid,Grid},block_name::AbstractString; split_weights::Bool = false, args...)

	block_to_subdivide = grid[block_name]

	subdividing_grid = create_subdividing_grid(block_to_subdivide,collect(keys(grid)), split_weights; args...)

	# Add neighbors form the block_to_subdivide to the subdividing_blocks and vice versa.
	for subdividing_block in values(subdividing_grid)
		for neighbor_name in block_to_subdivide.neighbors
			if check_neighboring(subdividing_block,grid[neighbor_name])
				push!(subdividing_block.neighbors, neighbor_name)
				push!(grid[neighbor_name].neighbors,subdividing_block.name)
			end
		end
	end
	
	# Also remove the block_to_subdivide from neighbor lists.
	for neighbor_names in block_to_subdivide.neighbors
		deleteat!(grid[neighbor_names].neighbors, findall(x-> (x == block_name),grid[neighbor_names].neighbors ))
	end

	# Dict mutating functions not defined for grids -> explicitly call grid.grid.
	delete!(grid.grid,block_name)
	merge!(grid.grid,subdividing_grid.grid)
	return grid
end


"""
	refine!(grid::Union{OneDimGrid,Grid}; 
		block_variation::Function = default_block_variation, 
		selection::Function = maximum, 
		split_weights::Bool = false,
		logarithmic::Bool = false,
		base::Real = 10.0
	)

Subdivide intervals/blocks in a grid based on the respective variations. Return the mutated grid and the indices of subdivided (i.e. new) blocks (The index order is the order of [`export_weights`](@ref) and [`export_all`](@ref)).

By default the variation of a block is the largest difference of weights compared to the weights of the neighboring blocks. The blocks to be subdivided are those that have the largest variation. If several blocks have the same variation, all those blocks are subdivided.

**Changing the selection of blocks**

* `block_variation`: Function to calculate the variation value for a block. Must use the following signature `(block_center,block_volume, block_weight, neighbor_center,neighbor_volumes, neighbor_weights)`.
* `selection`: Function to select the the blocks based on the variation value. Must have the signature `(variations)`  where variations is a one-dim array of the variation values.


**Weight splitting and logarithmic subdivision**

The keywords `split_weights`, `logarithmic` and `base` affect the subdivision of blocks. See [`subdivide!`](@ref) for further information.

**Example**

Select the block(s) with the smallest possible weight difference to its neighbors:
```julia
min_difference(c,v,w,C,V,W) = minimum(abs.(w .- W))
refine!(grid, block_variation= min_difference, selection = minimum)
```

"""
function refine!(grid::Union{OneDimGrid,Grid}; block_variation::Function = default_block_variation, selection::Function = maximum, args...)
	# Get centers before refinements.
	old_centers = export_all(grid)[1]

	# Explicit array of keys to select names based on indices later on.
	block_names = collect(keys(grid))
	# Get variations associated to blocks (in the order of block_names).
	block_variations = [block_variation(center(grid[key]),volume(grid[key]), grid[key].weight, [center(grid[neighbor]) for neighbor in grid[key].neighbors], [volume(grid[neighbor]) for neighbor in grid[key].neighbors], [grid[neighbor].weight for neighbor in grid[key].neighbors]) for key in block_names]
	# Select the most appropriate variation (depending on implementation of `selection`).
	selected_variation = selection(block_variations)
	# Find the blocks to be refined by finding the positions where the selected variation occurs.
	blocks_to_refine = block_names[findall(x -> (x in selected_variation), block_variations)]
	
	for block in blocks_to_refine
		subdivide!(grid, block; args...)
	end

	# Get centers after refinements
	new_centers = export_all(grid)[1]

	return grid, findall(x-> !(x in old_centers), new_centers)
end

