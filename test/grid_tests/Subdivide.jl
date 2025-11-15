@testset "Subdivide: 1-dim" begin
	grid = named_1d_grid()
	returned_grid = subdivide!(grid,"b_left")
	# Test proper return value.
	@test returned_grid == grid

	# Block "left" should be replaced by two smaller blocks.
	@test !("b_left" in collect(keys(grid)))
	@test length(grid) == 3
	
	# Test properties of the subdivided grid.
	target_centers = [1.25,1.75,2.5]
	target_volumes = [0.5,0.5,1]
	target_weights = [1,1,2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)

	# Test weight_splitting.
	grid = named_1d_grid()
	returned_grid = subdivide!(grid,"b_left"; split_weights = true)

	# Test properties of the subdivided grid.
	target_weights = [0.5,0.5,2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)



	# Test logarithmic keyword and base keyword
	####################################################################################################
	grid = named_1d_grid()
	returned_grid = subdivide!(grid,"b_left"; logarithmic = true, base = exp(1))
	# Test proper return value.
	@test returned_grid == grid

	# Block "left" should be replaced by two smaller blocks.
	@test !("b_left" in collect(keys(grid)))
	@test length(grid) == 3
	
	# Test properties of the subdivided grid.
	new_center = exp((log(1)+log(2))/2)
	target_centers = [(1+new_center)/2,(2+new_center)/2,2.5]
	target_volumes = [new_center-1,2-new_center,1]
	target_weights = [1,1,2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)

	# Test weight_splitting.
	grid = named_1d_grid()
	returned_grid = subdivide!(grid,"b_left"; split_weights = true, logarithmic = true, base = exp(1))

	# Test properties of the subdivided grid.
	# initial volume and initial weight are 1 -> 1*target_volumes[i] / initial_volume = target_volumes[i]
	target_weights = [target_volumes[1],target_volumes[2],2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)
end


@testset "Subdivide: 2-dim" begin
	grid = named_2d_grid()
	returned_grid = subdivide!(grid,"b_top_left")
	# Test proper return value.
	@test returned_grid == grid

	# Block "top_left" should be replaced by two smaller blocks.
	@test !("b_top_left" in collect(keys(grid)))
	@test length(grid) == 7
	
	# Test properties of the subdivided grid.
	target_centers = [[1.25,2.25],[1.25,2.75],[1.5,1.5],[1.75,2.25],[1.75,2.75],[2.5,1.5],[2.5,2.5]]
	target_volumes = [0.25,0.25,1,0.25,0.25,1,1]
	target_weights = [1,1,3,1,1,4,2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)


	# Test weight_splitting.
	grid = named_2d_grid()
	returned_grid = subdivide!(grid,"b_top_left"; split_weights = true)

	# Test properties of the subdivided grid.
	target_weights = [0.25,0.25,3,0.25,0.25,4,2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)



	# Test logarithmic keyword and base keyword
	####################################################################################################

	grid = named_2d_grid()
	returned_grid = subdivide!(grid,"b_top_left", logarithmic = true, base = exp(1))
	# Test proper return value.
	@test returned_grid == grid

	# Block "top_left" should be replaced by two smaller blocks.
	@test !("b_top_left" in collect(keys(grid)))
	@test length(grid) == 7
	
	# Test properties of the subdivided grid.
	new_center = [exp((log(1)+log(2))/2),exp((log(2)+log(3))/2)]
	target_centers = [[(1+new_center[1])/2,(2+new_center[2])/2],[(1+new_center[1])/2,(3+new_center[2])/2],[1.5,1.5],[(2+new_center[1])/2,(2+new_center[2])/2],[(2+new_center[1])/2,(3+new_center[2])/2],[2.5,1.5],[2.5,2.5]]
	target_volumes = [abs(1-new_center[1])*abs(2-new_center[2]),abs(1-new_center[1])*abs(3-new_center[2]),1,abs(2-new_center[1])*abs(2-new_center[2]),abs(2-new_center[1])*abs(3-new_center[2]),1,1]
	target_weights = [1,1,3,1,1,4,2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)


	# Test weight_splitting.
	grid = named_2d_grid()
	returned_grid = subdivide!(grid,"b_top_left"; split_weights = true, logarithmic = true, base = exp(1))

	# Test properties of the subdivided grid.
	# initial volume and initial weight are 1 -> 1*target_volumes[i] / initial_volume = target_volumes[i]
	target_weights = [target_volumes[1],target_volumes[2],3,target_volumes[4],target_volumes[5],4,2]
	standard_gird_tests(grid,target_centers,target_volumes,target_weights)
end
