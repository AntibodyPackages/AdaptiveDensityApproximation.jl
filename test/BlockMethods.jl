@testset "Operations on OneDimBlock" begin

	# Define Blocks for the tests.
	left = ADA.OneDimBlock("left",ADA.Interval(1,2),["right"],1)
	right = ADA.OneDimBlock("right",ADA.Interval(2,3),["left"],1)
	isolated = ADA.OneDimBlock("isolated",ADA.Interval(5,6),[],1)

	@testset "Center" begin
		@test ADA.center(left) == 1.5
		@test ADA.center(left, logarithmic = true) ≈ 10.0^((log(10,1)+log(10,2))/2)
		@test ADA.center(left, logarithmic = true, base = exp(1)) ≈ exp((log(1)+log(2))/2)
	end

	@testset "Corner points" begin
		@test ADA.corners(left) == [1,2]
	end

	@testset "Volume" begin
		@test ADA.volume(left) == 1
	end
	
	@testset "Intermediate points" begin
		@test ADA.intermediate_points(left,3) == [1,1.5,2]
	end

	@testset "Point contained" begin
		@test ADA.in_block(1.2,left)
		@test !ADA.in_block(0.9,left)
		@test !ADA.in_block(2.1,left)
	end

	@testset "Point above" begin
		@test !ADA.above_block(1.2,left)
		@test !ADA.above_block(0.9,left)
		@test ADA.above_block(2.1,left)
	end

	@testset "Neighboring" begin
		@test symmetric_test(true, ADA.check_neighboring,left,right)
		@test symmetric_test(false, ADA.check_neighboring,left,isolated)
	end

end






@testset "Operations on Block" begin

	# Define Blocks for the tests.
	middle = ADA.Block("middle",ADA.Cuboid([ADA.Interval(1,2),ADA.Interval(1,2)]), ["top", "right"],1)
	top = ADA.Block("top",ADA.Cuboid([ADA.Interval(1,2),ADA.Interval(2,3)]), ["middle"],1)
	right = ADA.Block("right",ADA.Cuboid([ADA.Interval(2,3),ADA.Interval(1,2)]), ["middle"],1)
	isolated = ADA.Block("right",ADA.Cuboid([ADA.Interval(4,5),ADA.Interval(4,5)]), ["middle"],1)

	@testset "Center" begin
		@test ADA.center(middle) == [1.5,1.5]
		@test ADA.center(middle, logarithmic = true) ≈ [10.0^((log(10,1)+log(10,2))/2), 10.0^((log(10,1)+log(10,2))/2)]
		@test ADA.center(middle, logarithmic = true, base = exp(1)) ≈ [exp(((log(1)+log(2))/2)),exp(((log(1)+log(2))/2))]
	end

	@testset "Corners" begin
		@test Set(ADA.corners(middle)) ==  Set([[i,j] for i in 1:2 for j in 1:2])
	end

	@testset "Volume" begin
		@test ADA.volume(middle) == 1
	end

	@testset "Intermediate points" begin
		@test Set(ADA.intermediate_points(middle,3)) ==  Set([[i,j] for i in [1,1.5,2] for j in [1,1.5,2]])
	end

	@testset "Point contained" begin
		@test ADA.in_block([1.5,1.5],middle)  # contained
		@test !ADA.in_block([0.5,1.5],middle) # left
		@test !ADA.in_block([2.5,1.5],middle) # right
		@test !ADA.in_block([1.5,0.5],middle) # below
		@test !ADA.in_block([1.5,2.5],middle) # top
		@test !ADA.in_block([2.5,2.5],middle) # top right
		@test !ADA.in_block([0.5,2.5],middle) # top left
		@test !ADA.in_block([0.5,0.5],middle) # bottom left
		@test !ADA.in_block([2.5,0.5],middle) # bottom right
	end

	@testset "Point above" begin
		# above_block is true only if for every dimension the component of the point is above the respective interval.
		@test !ADA.above_block([1.5,1.5],middle) # contained
		@test !ADA.above_block([0.5,1.5],middle) # left
		@test !ADA.above_block([2.5,1.5],middle) # right
		@test !ADA.above_block([1.5,0.5],middle) # bottom
		@test !ADA.above_block([1.5,2.5],middle) # top
		@test !ADA.above_block([0.5,2.5],middle) # top left
		@test ADA.above_block([2.5,2.5],middle)  # top right
		@test !ADA.above_block([0.5,0.5],middle) # bottom left
		@test !ADA.above_block([2.5,0.5],middle) # bottom right
	end

	@testset "Neighboring" begin
		# neighboring blocks
		@test symmetric_test(true, ADA.check_neighboring, middle,top)
		@test symmetric_test(true, ADA.check_neighboring, middle,right)
		
		# non-neighboring blocks
		@test symmetric_test(false, ADA.check_neighboring, middle,isolated)
		@test symmetric_test(false, ADA.check_neighboring, top,isolated)
		@test symmetric_test(false, ADA.check_neighboring, right,isolated)
		@test symmetric_test(false, ADA.check_neighboring, top,right)
	end

end