####################################################################################################
# Type definitions
####################################################################################################


mutable struct Interval{LeftType,RightType}
	left::LeftType
	right::RightType
	# Custom constructor to ensure left <= right.
	function Interval(left,right)
		if left < right
			return new{typeof(left),typeof(right)}(left,right)
		else
			return new{typeof(right),typeof(left)}(right,left)
		end
	end
end

# Combine useful information for a one-dimensional block that belongs to a one-dimensional grid.
# No parametric type: Otherwise, grid dict becomes too restrictive (intervals can change from Int64 to Float64, etc.).
mutable struct OneDimBlock
	name
	interval
	neighbors
	weight
end


# Define a cuboid as one-dimensional array of intervals.
mutable struct Cuboid{IntervalsType}
	intervals::IntervalsType
	function Cuboid(intervals::AbstractArray{I,N}) where {N, I <: Interval}
		# Rearrange intervals in a one-dimensional array.
		return new{typeof(intervals)}(vcat(intervals...))
	end
end



# Combine useful information for a block that belongs to a grid.
# No parametric type: Otherwise, grid dict becomes too restrictive (intervals can change from Int64 to Float64, etc.).
mutable struct Block
	name
	cuboid
	neighbors
	weight
end









####################################################################################################
# Associated functions
####################################################################################################


# Extension of Base methods
####################################################################################################

# Allows to use interval[1] for interval.left and interval[2] for interval.right.
function getindex(interval::Interval,ind::Integer)
	if ind == 1
		return interval.left
	elseif ind == 2
		return interval.right
	else
		throw(BoundsError)
	end
end

# Direct access to intervals in cuboid struct.
getindex(cuboid::Cuboid,ind) = cuboid.intervals[ind]

# Direct access to the number of intervals in cuboid struct.
length(cuboid::Cuboid) = length(cuboid.intervals)










# Functions for common properties of intervals/cuboids
####################################################################################################


@inline function center(interval::Interval; logarithmic = false, base = 10.0)
	if logarithmic
		return base ^ ((log(base,interval.left)+log(base,interval.right))/2)
	else
		return (interval.left + interval.right)/2
	end
end

@inline function center(cuboid::Cuboid; args...)
	return [center(interval; args...) for interval in cuboid.intervals]
end

@inline function corners(interval::Interval)
	return [interval.left,interval.right]
end

@inline function corners(cuboid::Cuboid)
	return [[cuboid[dim][corner_indices[dim]] for dim in 1:length(cuboid)] for corner_indices in CartesianIndices((2,length(cuboid)))]
end

@inline function intermediate_points(interval::Interval,n::Integer)
	return LinRange(interval.left,interval.right,n)
end

@inline function intermediate_points(cuboid::Cuboid,n::Integer)
	axis_ticks = [intermediate_points(cuboid[i],n) for i in 1:length(cuboid)]
	return [[axis_ticks[dim][ind[dim]] for dim in 1:length(axis_ticks)] for ind in CartesianIndices(Tuple(length.(axis_ticks)))]
end

@inline function volume(interval::Interval)
	return interval.right - interval.left
end

@inline function volume(cuboid::Cuboid)
	return prod(volume(cuboid[dim]) for dim in 1:length(cuboid))
end


@inline function in_interval(x::Real,interval::Interval)
	return interval.left <= x && interval.right >= x
end

@inline function in_cuboid(x::Vector{R},cuboid::Cuboid) where {R <: Real}
	if length(x) == length(cuboid)
		return prod(in_interval(x[dim], cuboid[dim]) for dim in eachindex(x))
	else
		return false
	end
end


@inline function above_interval(x::Real,interval::Interval)
	return interval.right <= x
end


@inline function above_cuboid(x::Vector{R},cuboid::Cuboid) where {R <: Real}
	if length(x) == length(cuboid)
		return prod(above_interval(x[dim], cuboid[dim]) for dim in eachindex(x))
	else
		return false
	end
end






# Comparisons of intervals/cuboids
####################################################################################################

# Check if two interval intersect non-degenerately.
@inline function intervals_overlapping(I::Interval,J::Interval)
	# I overlapping J from the right | including being enclosed.
	if I.left < J.right && I.right > J.left
		return true
	# I overlapping J from the left | including being enclosed.
	elseif J.left < I.right && J.right > I.left
		return true
	else
		return false
	end
end


# Check if intervals are neighboring, i.e.
# check if the start/endpoints of two intervals meet within floating point tolerance.
@inline function check_neighboring(I::Interval,J::Interval)
	if I.right ≈ J.left  || J.right ≈ I.left
		return true
	else
		return false
	end
end




# Check if the hyper-surfaces of two cuboids would overlap, ignoring one dimension.
# Allows to check if cuboids touch non-degenerately if the start/endpoints meet in the ignored dimension.
@inline function hypersurfaces_overlapping(cuboid_1::Cuboid,cuboid_2::Cuboid,skipped_dimension::Integer)
	# Skip length checking, assuming grids are only modified with exported methods.
	for i in 1:length(cuboid_1.intervals)
		# If not overlapping in one dimension that is not the skipped dimension, the hyper-surfaces do not overlap by definition.
		if i != skipped_dimension && !intervals_overlapping(cuboid_1.intervals[i], cuboid_2.intervals[i])
			return false
		end
	end
	return true
end


# Dispatch for cuboid. Concept of neighbor more complicated in higher dimensions.
@inline function check_neighboring(cuboid_1::Cuboid,cuboid_2::Cuboid)
	# Skip length checking, assuming grids are only modified with exported methods.
	for dim in 1:length(cuboid_1)
		# Neighbors, if one dimension matches and the corresponding hyper-surfaces overlap.
		if check_neighboring(cuboid_1[dim], cuboid_2[dim]) && hypersurfaces_overlapping(cuboid_1,cuboid_2,dim)
			return true
		end
	end
	return false
end













# Dispatch methods for blocks
####################################################################################################

function center(block::OneDimBlock; args...)
	return center(block.interval; args...)
end

function center(block::Block; args...)
	return center(block.cuboid; args...)
end

function corners(block::OneDimBlock)
	return corners(block.interval)
end

function corners(block::Block)
	return corners(block.cuboid)
end

function intermediate_points(block::OneDimBlock,n::Integer)
	return intermediate_points(block.interval,n)
end

function intermediate_points(block::Block,n::Integer)
	return intermediate_points(block.cuboid,n)
end

function volume(block::OneDimBlock)
	return volume(block.interval)
end

function volume(block::Block)
	return volume(block.cuboid)
end

function in_block(x::Real,block::OneDimBlock)
	return in_interval(x,block.interval)
end

function in_block(x::Vector{R},block::Block) where {R <: Real}
	return in_cuboid(x,block.cuboid)
end

function above_block(x::Real,block::OneDimBlock)
	return above_interval(x,block.interval)
end

function above_block(x::Vector{R},block::Block) where {R <: Real}
	return above_cuboid(x,block.cuboid)
end

function check_neighboring(block_1::OneDimBlock,block_2::OneDimBlock)
	return check_neighboring(block_1.interval,block_2.interval)
end

function check_neighboring(block_1::Block,block_2::Block)
	return check_neighboring(block_1.cuboid,block_2.cuboid)
end