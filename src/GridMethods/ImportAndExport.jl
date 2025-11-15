####################################################################################################
# Import and export
####################################################################################################

export  export_weights, export_all, import_weights!






# Internal functions
####################################################################################################

# Use create_grid method to subdivide block.
@inline function create_subdividing_grid(block::OneDimBlock,exclude_strings,split_weights; args...)
	axis_ticks =  [block.interval.left, center(block; args...), block.interval.right]
	initial_volume = volume(block)
	if split_weights
		# length(axis_ticks) - 1, since there are n-1 intervals for n axis ticks.
		subdivided_block_grid = create_grid(axis_ticks, exclude_strings = exclude_strings, initial_weight = block.weight, string_length = length(block.name))
		for key in keys(subdivided_block_grid)
			subdivided_block_grid[key].weight = subdivided_block_grid[key].weight * volume(subdivided_block_grid[key]) / initial_volume
		end
		return subdivided_block_grid
	else
		return create_grid(axis_ticks, exclude_strings = exclude_strings, initial_weight = block.weight, string_length = length(block.name))
	end
end

# Dispatch version.
@inline function create_subdividing_grid(block::Block, exclude_strings, split_weights; args...)
	axis_ticks =  [[block.cuboid[dim].left, center(block;args...)[dim], block.cuboid[dim].right] for dim in 1:length(block.cuboid)]
	initial_volume = volume(block)
	if split_weights
		# length(axis_ticks) - 1, since there are n-1 intervals for n axis ticks.
		subdivided_block_grid = create_grid(axis_ticks..., exclude_strings = exclude_strings, initial_weight = block.weight, string_length = length(block.name))
		for key in keys(subdivided_block_grid)
			subdivided_block_grid[key].weight = subdivided_block_grid[key].weight * volume(subdivided_block_grid[key]) / initial_volume
		end
		return subdivided_block_grid
	else
		return create_grid(axis_ticks..., exclude_strings =  exclude_strings, initial_weight = block.weight, string_length = length(block.name))
	end
end














# Exported functions
####################################################################################################




"""
	export_all(grid::Union{OneDimGrid,Grid})
Return the vectors: `centers, volumes, weights`.

The vector elements are sorted according to the center points of the intervals/blocks.
"""
function export_all(grid::Union{OneDimGrid,Grid})
	grid_keys = collect(keys(grid))
	centers = [center(grid[key]) for key in grid_keys]
	volumes = [volume(grid[key]) for key in grid_keys]
	weights = [grid[key].weight for key in grid_keys]
	permutation = sortperm(centers)
	return centers[permutation], volumes[permutation], weights[permutation]
end



"""
	export_weights(grid::Union{OneDimGrid,Grid})
Return a vector that contains the weights of the intervals/blocks.

The weights are sorted according to the center points of the intervals/blocks.
"""
function export_weights(grid::Union{OneDimGrid,Grid})
	return export_all(grid)[3]
end




"""
	import_weights!(grid::Union{OneDimGrid,Grid}, weights)
Import weights and return the mutated grid.

For the import, the intervals/blocks are sorted according to their center points.
"""
function import_weights!(grid::Union{OneDimGrid,Grid}, weights)
	grid_keys = sort(collect(keys(grid)))
	if length(grid_keys) != length(weights)
		throw(DimensionMismatch("The number of blocks in the grid and the number of weights to be imported do not match"))
	end
	centers = [center(grid[key]) for key in grid_keys]
	permutation = sortperm(centers)
	for i in 1:length(permutation)
		grid[grid_keys[permutation[i]]].weight = weights[i]
	end
	return grid
end

