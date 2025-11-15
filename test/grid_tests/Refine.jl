@testset "Refine: 1-dim" begin

	grid = named_1d_grid()

	# Test both custom block_variation and custom selection.
	custom_variation = (center,volume,weight,centers,volumes,weights) -> weight 
	returned_grid, change_indices = refine!(grid, block_variation = custom_variation, selection = minimum) 

	# selection = minimum -> replace block with smallest weight.
	@test !("b_left" in collect(keys(grid)))
	@test length(grid) == 3


	# Test return values.
	@test returned_grid == grid
	@test change_indices == [1,2]
	
	# Test properties of the subdivided grid.
	target_centers = [1.25,1.75,2.5]
	target_volumes = [0.5,0.5,1]
	target_weights = [1,1,2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)


	# Test weight_splitting and logarithmic keywords.
	grid = named_1d_grid()
	refine!(grid, block_variation = custom_variation, selection = minimum, split_weights = true) 
	target_weights = [0.5,0.5,2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)

	grid = named_1d_grid()
	refine!(grid, block_variation = custom_variation, selection = minimum, split_weights = true, logarithmic = true, base = exp(1)) 
	new_center = exp((log(1)+log(2))/2)
	target_centers = [(1+new_center)/2,(2+new_center)/2,2.5]
	target_volumes = [new_center-1,2-new_center,1]
	target_weights = [target_volumes[1],target_volumes[2],2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)



	# Test default block variation (should replace both blocks).
	grid = named_1d_grid()
	refine!(grid)
	@test !("b_left" in collect(keys(grid))) && !("a_right" in collect(keys(grid)) )
	@test length(grid) == 4


	# Test volume arguments (should replace both blocks in this case).
	custom_variation =(center,volume,weight,centers,volumes,weights) -> maximum(volumes) - volume
	grid = named_1d_grid()
	refine!(grid, block_variation = custom_variation)
	@test !("b_left" in collect(keys(grid))) && !("a_right" in collect(keys(grid)) )
	@test length(grid) == 4

	# Test center arguments (should replace left block).
	custom_variation = (center,volume,weight,centers,volumes,weights) -> maximum(centers) - center
	grid = named_1d_grid()
	refine!(grid, block_variation = custom_variation)
	@test !("b_left" in collect(keys(grid)))
	@test length(grid) == 3
end



@testset "Refine: 2-dim" begin

	grid = named_2d_grid()

	# Test both custom block_variation and custom selection.
	custom_variation = (center,volume,weight,centers,volumes,weights) -> weight
	returned_grid, change_indices = refine!(grid, block_variation = custom_variation, selection = minimum)

	# Block "top_left" should be replaced by 4 smaller blocks.
	@test !("b_top_left" in collect(keys(grid)))
	@test length(grid) == 7

	# Test return values.
	@test returned_grid == grid
	# Test change_indices based on block weights, which remain unchanged by refine/subdivide.
	@test export_weights(grid)[change_indices] == [1,1,1,1]

	
	# Test properties of the subdivided grid.
	target_centers = [[1.25,2.25],[1.25,2.75],[1.5,1.5],[1.75,2.25],[1.75,2.75],[2.5,1.5],[2.5,2.5]]
	target_volumes = [0.25,0.25,1,0.25,0.25,1,1]
	target_weights = [1,1,3,1,1,4,2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)

	# Test weight_splitting and logarithmic keywords.
	grid = named_2d_grid()
	refine!(grid, block_variation = custom_variation, selection = minimum, split_weights = true)
	target_weights = [0.25,0.25,3,0.25,0.25,4,2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)

	grid = named_2d_grid()
	refine!(grid, block_variation = custom_variation, selection = minimum, split_weights = true, logarithmic = true, base = exp(1))
	new_center = [exp((log(1)+log(2))/2),exp((log(2)+log(3))/2)]
	target_centers = [[(1+new_center[1])/2,(2+new_center[2])/2],[(1+new_center[1])/2,(3+new_center[2])/2],[1.5,1.5],[(2+new_center[1])/2,(2+new_center[2])/2],[(2+new_center[1])/2,(3+new_center[2])/2],[2.5,1.5],[2.5,2.5]]
	target_volumes = [abs(1-new_center[1])*abs(2-new_center[2]),abs(1-new_center[1])*abs(3-new_center[2]),1,abs(2-new_center[1])*abs(2-new_center[2]),abs(2-new_center[1])*abs(3-new_center[2]),1,1]
	target_weights = [target_volumes[1],target_volumes[2],3,target_volumes[4],target_volumes[5],4,2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)


	# Test default block variation (should replace all blocks).
	grid = named_2d_grid()
	refine!(grid)
	@test !("b_top_left" in collect(keys(grid))) && !("a_top_right" in collect(keys(grid))) && !("y_bottom_left" in collect(keys(grid))) && !("x_bottom_right" in collect(keys(grid)))
	@test length(grid) == 16
end