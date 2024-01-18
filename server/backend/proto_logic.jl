### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# ╔═╡ 6f0ad323-1776-4efd-bf1e-667e8a834f41
using Random

# ╔═╡ e68b41fc-cbf5-477f-b211-2462d835def0
using Combinatorics

# ╔═╡ c2797a4c-81d3-4409-9038-117fe50540a8
using StatsBase

# ╔═╡ 13cb8a74-8f5e-48eb-89c6-f7429d616fb9
using Dates

# ╔═╡ 70ecd4ed-cbb1-4ebd-85a8-42f7b072bee3
using HTTP, JSON3

# ╔═╡ bd7e7cdd-878e-475e-b2bb-b00c636ff26a
using HTTP.WebSockets

# ╔═╡ 1df30830-1a44-49f5-bb9a-309a8e9f2274
# ╠═╡ disabled = true
#=╠═╡
using JET
  ╠═╡ =#

# ╔═╡ 20bc797e-c99b-417d-8921-9b95c8e21679
using BenchmarkTools

# ╔═╡ 69c4770e-1091-4744-950c-ed23deb55661
# prod packages

# ╔═╡ f6dc2723-ab4a-42fc-855e-d74915b4dcbf
# dev packages

# ╔═╡ 43f89626-8583-11ed-2b3d-b118ff996f37
# ╠═╡ disabled = true
#=╠═╡
using PlutoUI
  ╠═╡ =#

# ╔═╡ 9505b0f0-91a2-46a8-90a5-d615c2acdbc1
# ╠═╡ disabled = true
#=╠═╡
using Plots, PlotThemes;  plotly() ; theme(:default)
  ╠═╡ =#

# ╔═╡ cd36abda-0f4e-431a-a4d1-bd5366c83b9b
begin
const row_m::Int = 19 
const col_m::Int = 11
end

# ╔═╡ 2d69b45e-d8e4-4505-87ed-382e45bebae7
function partOfBoard(row_id::Int64, col_id::Int64)
# checks if the point should be drawn or not

	num_rows = 19 #(10 * 2 -1)
	num_cols = 11

	to_return = true

	# first and last column
	if (col_id == 1 || col_id == 11) && ( row_id <= 6 || row_id > 13) 
		to_return = false 
	end

	# second and N-1 column
	if (col_id == 2 || col_id == 10) && ( row_id <= 3 || row_id > 16) 
		to_return = false 
	end

	# third and N -2 column
	if (col_id == 3 || col_id == 9) && ( row_id <= 2 || row_id > 17) 
		to_return = false 
	end

	# forth and N-3 column
	if (col_id == 4 || col_id == 8) && ( row_id <= 1 || row_id > 18) 
		to_return = false 
	end

	# column 5 keeps all points

	# central column
	if (col_id == 6) && ( row_id == 1 || row_id > 18)
		to_return = false 
	end

	return to_return

end

# ╔═╡ 48bbc7c2-ba53-41cd-9b3c-ab3faedfc6b0
function prep_base_matrix()

	# 0 -> not part of the board
	# 1 -> mid-point
	# 2 -> active point

	rows = 19
	cols = 11

	base_m = zeros(Int64, rows, cols)

	# populate 1s
	for i in 1:rows
		for j in 1:cols
			if partOfBoard(i,j) == true 
				base_m[i,j] = 1
			end
		end
	end

	# checks if point is active (can be used for placing rings/markers)
	# for each column, valid points are found each 2nd one

	for j in 1:cols

		# extract column array
		temp_array = view(base_m,:,j)

		# get index of first and last non-zero element
		start_index = findfirst(x -> x != 0, temp_array)
		end_index = findlast(x -> x != 0, temp_array)

		# every second element is the active one
		for k in start_index:2:end_index
			base_m[k,j] = 2
		end
		
	
	end
	

	return base_m
	
end

# ╔═╡ c96e1ee9-6d78-42d2-bfd6-2e8f88913b37
mm_yinsh = prep_base_matrix();

# ╔═╡ b6292e1f-a3a8-46d7-be15-05a74a5736de
# ╠═╡ disabled = true
#=╠═╡
draw_board()
  ╠═╡ =#

# ╔═╡ 55987f3e-aaf7-4d85-a6cf-11eda59cd066
function draw_board()

ps = scatter(legend = :none)

for i in 1:row_m
for j in 1:col_m

	# active points
	if mm_yinsh[i,j] == 2
		scatter!(ps,[j], [i], markersize = 2, markercolor = :lightblue, yflip = true, size = (500,600))

	#=
	# mid points
	elseif mm_yinsh[i,j] == 1
		scatter!(ps,[j], [i], markersize = 1, markercolor = :yellow, markerstrokecolor = :orange)

	# points that are not part of the board
	elseif mm_yinsh[i,j] == 0
		scatter!(ps,[j], [i], markersize =1, markercolor = :cyan, markerstrokecolor = :cyan)

	=#
	end
end
end

return ps
end

# ╔═╡ d996152e-e9e6-412f-b4db-3eacf5b7a5a6
function printable_base_m()

	# print matrix easy copying in js code
	mm_print_01 = ""
	
	for i in 1:row_m
		for j in 1:col_m

			# check if the point is active and print true (1), otherwise false
			print_val = (mm_yinsh[i,j] == 2 ) ? 1 : 0
			
			if j == 1 
				mm_print_01 *= "[" * string(print_val) * ", "
			
			elseif j == col_m 
				mm_print_01 *= string(print_val) * "] \n"
				
			else
				mm_print_01 *= string(print_val) * ", "
			end
		end
	end

print(mm_print_01)

end


# ╔═╡ ff94655f-3603-4553-9ca3-e1dec83361b8
#=
UX


>> matchmaking
- pick player
- pick color
- pick mode (normal or blitz)
- initial rings placement (random or manual)

>> setup
- place rings at random
-- place for both players
- place rings manually
- move/drag/snap to grid
- be aware of empty spots

>> game
- pick ring to activate
- see marker
- pick another ring
- see marker (previous one removed)
- see allowed moves 
-- only free intersection points
-- only moves in straight lines
-- can't jump over other rings
-- can jump on markers, but lands on first empty 
- move ring -> move completed
- markers in the way are flipped

-- other player turns
-- etc

>> resolutions
- spot 5 markers in a row(s)
- in case of multiple rows, let user pick which set
- let user pick which ring to store
- resume game
- first to 3 (1 for blitz) rings out wins


=#

# ╔═╡ dffecc3d-4737-4bf3-b109-882687b2e361
#=

DATA REQ

- map each point so to be able to query them about their occupancy status 
-- ring, marker, or both (temp status)
^ DONE

- how to move the ring?
-- only lands empty spots 
--- only ones reachable in straight lines
---- only previous spot available with respect to a ring
---- only first-after spot available with respect to markers

>> from each active point explore 6 directions
>>> idea: can pre-compute indexes of reachable points from each, so to have array of searchable coordinates
-- j-2, k = k > straight up
-- j+2, k = k > straight down  
-- j-1, k+1 > diag right up
-- j+1, K+1 > diag right down
-- j+1, k-1 > diag left down
-- j-1, k-1 > diag left up


from each location, I want (j,k) pairs of searchable space -> save in a dict by direction? -> later it might be easier to filter by line-based conditions

this gives me the allowable moves

=#

# ╔═╡ bfb15937-a3b0-434d-ac5e-0d6d6b42e92e
mm_yinsh_01 = map(x -> if x == 1 0 elseif x == 2 1 elseif x==0 0 end, mm_yinsh)

# ╔═╡ 856b71d6-130e-4312-9a51-62f04d97a02c
mm_states = fill("",19,11)

# ╔═╡ 5fcd1944-57c8-4923-8f04-fc9ed24cd25c
bounds_check(row::Int, col::Int)::Bool = mm_yinsh_01[row, col] == 1

# ╔═╡ b2387e60-5107-4f66-924f-ff56e6127037
locz = findall(x -> x==1, mm_yinsh_01);

# ╔═╡ 6ba97a86-9602-4291-9a78-1875ee80ddc4
# ╠═╡ disabled = true
#=╠═╡
@bind locz_index Slider(1:length(locz), show_value=true)
  ╠═╡ =#

# ╔═╡ e7afbb50-f343-47df-88c9-88a7ff336ea1
# ╠═╡ disabled = true
#=╠═╡
row_start = locz[locz_index][1]
  ╠═╡ =#

# ╔═╡ 37ff4698-4418-4abc-b726-c5f719b8f792
# ╠═╡ disabled = true
#=╠═╡
col_start = locz[locz_index][2]
  ╠═╡ =#

# ╔═╡ abb1848e-2ade-49e7-9b15-a4c94b2f9cb7
# ╠═╡ disabled = true
#=╠═╡
search_loc_graph(draw_board(), row_start, col_start, search_loc(mm_states, reshape_out(CartesianIndex(row_start,col_start))))
  ╠═╡ =#

# ╔═╡ 387eeec5-f483-48af-a27c-468683fe497b
# helper function to place how_many elem_type we need in free spots
function place_elem!(input_board, elem_type::String, how_many::Int)

	valid_spots = findall(x -> x==1, mm_yinsh_01)

	# keep trying to place elements as long as the spot is valid 
	placed_elem::Int = 0
	while placed_elem < how_many

		pick = rand(valid_spots)
		row_try = pick[1]
		col_try = pick[2]

		# if place is empty
		if input_board[row_try, col_try] == ""
			input_board[row_try, col_try] = elem_type
			placed_elem += 1
		end
	
	end
end

# ╔═╡ c1ae2819-974f-4209-8cf8-3fa98bc9cf93
function random_states_setup()
	
	temp_board = fill("",19,11)


	# element types and how many we want to place of each
	elems_typeNum = ("RW" => 4, "RB" => 4, "MW" => 9, "MB" => 12)

	
	# place all elements in board
	for (key, val) in elems_typeNum
		place_elem!(temp_board, key, val)	
	end

	return temp_board


end

# ╔═╡ f6811e34-8576-4e1f-9638-79652b30aef3
# ╠═╡ disabled = true
#=╠═╡
mm_setup = random_states_setup();
  ╠═╡ =#

# ╔═╡ 49ff65f9-8ead-448f-8a44-1a741c20bbc5
# ╠═╡ disabled = true
#=╠═╡
setup_graph = rings_marks_graph();
  ╠═╡ =#

# ╔═╡ 6e7ab4f4-7c52-45bc-a503-6bf9cb0d7932
#=╠═╡
function rings_marks_graph()
	# draw base board

	new_board = draw_board()
	Rw_locs = findall(x -> x=="RW", mm_setup)
	Rb_locs = findall(x -> x=="RB", mm_setup)
	Mw_locs = findall(x -> x=="MW", mm_setup)
	Mb_locs = findall(x -> x=="MB", mm_setup)

	ring_size = 11
	marker_size = 6


	# plot white rings
	for x in Rw_locs
		scatter!(new_board, [x[2]], [x[1]], msize = ring_size, mcolor = :white, shape = :dtriangle, mswidth = 2, mscolor = :black)
	end

	# plot black rings
	for x in Rb_locs
		scatter!(new_board, [x[2]], [x[1]], msize = ring_size, mcolor = :darkgray, shape = :dtriangle, mswidth = 2, mscolor = :black)
	end

	# plot black markers
	for x in Mb_locs
		scatter!(new_board, [x[2]], [x[1]], msize = marker_size, mcolor = :darkgray, shape = :circle, mswidth = 2, mscolor = :black)
	end


	# plot white markers
	for x in Mw_locs
		scatter!(new_board, [x[2]], [x[1]], msize = marker_size, mcolor = :white, shape = :circle, mswidth = 2, mscolor = :black)
	end

return new_board
end
  ╠═╡ =#

# ╔═╡ e767b0a7-282f-46c4-b2e7-1f737807a3cb
# ╠═╡ disabled = true
#=╠═╡
@bind locz_index_n Slider(1:length(locz), show_value=true, default=rand(1:length(locz)))
  ╠═╡ =#

# ╔═╡ edfa0b25-9132-4de9-bf11-3ea2f0952e4f
# ╠═╡ disabled = true
#=╠═╡
row_start_n = locz[locz_index_n][1]; col_start_n = locz[locz_index_n][2];
  ╠═╡ =#

# ╔═╡ ccbf567a-8923-4343-a2ff-53d81f2b6361
# ╠═╡ disabled = true
#=╠═╡
search_loc_graph(rings_marks_graph(), row_start_n, col_start_n, search_loc(mm_setup, reshape_out(CartesianIndex(row_start_n,col_start_n))))
  ╠═╡ =#

# ╔═╡ a3ae2bfe-41ea-4fe1-870b-2ac35153da5d
md"### Search spaces generation"

# ╔═╡ 29a93299-f577-4114-b77f-dbc079392090
begin
# global parameters for identifying rings and markers
const _W::String = "W"
const _B::String = "B"
const _R::String = "R"
const _M::String = "M"

const _MB::String = _M*_B
const _RB::String = _R*_B
const _MW::String = _M*_W
const _RW::String = _R*_W	

# reference player keys
const _B_key::Symbol = Symbol(_B)
const _W_key::Symbol = Symbol(_W)

# reference scoring arrays 
const _B_score::Vector{String} = fill(_MB, 5)
const _W_score::Vector{String} = fill(_MW, 5)

end

# ╔═╡ 003f670b-d3b1-4905-b105-67504f16ba19
# populate dictionary of locations search space 
function new_searchSpace()::Dict{CartesianIndex, Vector{Vector{CartesianIndex}}}

	_ret::Dict{CartesianIndex, Vector{Vector{CartesianIndex}}} = Dict()

	# board bounds 
	last_row = 19
	last_col = 11

	# keys mapping to valid board locations
	keys_loc = findall(x -> x==1, mm_yinsh_01)
	
	for key in keys_loc

		## Generate zip ranges for each direction
		# get row/col from each cart_index location
		row_start = key[1]
		col_start = key[2]
	
		# Init array for zip ranges
		zip_ranges = []

		## vertical line
		
			# straight up to first row, k stays the same (j-2, k = k)
			j_range = row_start-2:-2:1
			k_range = [col_start for _ in j_range]
		
				push!(zip_ranges, zip(j_range, k_range))
		
			# straight down to last row, k stays the same (j+2, k = k)
			j_range = row_start+2:2:last_row
			k_range = [col_start for _ in j_range]
		
				push!(zip_ranges, zip(j_range, k_range))

		## diagonal left to right up

			# diagonal down left (j+1, k-1)
			j_range = row_start+1:last_row
			k_range = col_start-1:-1:1
		
				push!(zip_ranges, zip(j_range, k_range))
			
			# diagonal up right (j-1, k+1)
			j_range = row_start-1:-1:1
			k_range = col_start+1:last_col
		
				push!(zip_ranges, zip(j_range, k_range))

		
		## diagonal left to right down

			# diagonal up left (j-1, k-1)
			j_range = row_start-1:-1:1
			k_range = col_start-1:-1:1
		
				push!(zip_ranges, zip(j_range, k_range))
			
			# diagonal down right (j+1, k+1)
			j_range = row_start+1:last_row
			k_range = col_start+1:last_col
		
				push!(zip_ranges, zip(j_range, k_range))
		

		## Convert locations to cart_index
		# Init array for zip ranges
		cartIndex_ranges::Vector{Vector{CartesianIndex}} = []

		for range in zip_ranges

			if !isempty(range)

				# convert to cart_index and only keep valid locations
				ci_range = [CartesianIndex(z[1], z[2]) for z in range]
				filter!(c -> c in keys_loc, ci_range)

				if !isempty(ci_range)
					push!(cartIndex_ranges, ci_range)
				end
			end
		end

		# append starting location as possible move option
		push!(cartIndex_ranges, [CartesianIndex(row_start, col_start)])

		
		## Write array of cartesian locations to dictionary
		setindex!(_ret, cartIndex_ranges, key)

	end

	return _ret

end

# ╔═╡ 1d811aa5-940b-4ddd-908d-e94fe3635a6a
# pre-populate dictionary with search space for each starting location
const _locs_searchSpace = new_searchSpace()

# ╔═╡ 9be19399-c7e6-4089-b746-1d4d749f7774
const _board_locs = Set(keys(_locs_searchSpace))

# ╔═╡ f0e9e077-f435-4f4b-bd69-f495dfccec27
function sub_spaces_split(input_array, key)

# array of search sub-spaces to be returned
to_return = []

len_array = length(input_array)

 
	if len_array >= 5

		# key is granted as part of the input_array + array is sorted
		key_index = findfirst(x -> x == key, input_array)

		# scroll over a window of 5 elements
		for j in 0:4

			start_index = key_index - j
			end_index = key_index + ( 4 - j )

			bounds_check = start_index >= 1 && end_index <= len_array
			length_check = (end_index - start_index + 1) == 5
			
			if (bounds_check && length_check)

				# save sliced array
				push!(to_return, input_array[start_index:end_index])

			end

		end

	end


	return to_return

end

# ╔═╡ a96a9a78-0aeb-4b00-8f3c-db61839deb5c
# populate dictionary of locations search space for SCORING
function new_searchSpace_scoring()::Dict{CartesianIndex, Vector{Vector{CartesianIndex}}}

	_ret::Dict{CartesianIndex, Vector{Vector{CartesianIndex}}} = Dict()

# first part of the function could be shared with other and bifurcated instead of duplicated

	# board bounds 
	last_row = 19
	last_col = 11

	# keys mapping to valid board locations
	keys_loc = findall(x -> x==1, mm_yinsh_01)
	
	for key in keys_loc

		## Generate zip ranges for each direction
		# get row/col from each cart_index location
		row_start = key[1]
		col_start = key[2]
	
		# Init array for zip ranges
		zip_ranges = []

		## Vertical line
	
			## vertical line
		
			# straight up to first row, k stays the same (j-2, k = k)
			j_range = row_start-2:-2:1
			k_range = [col_start for _ in j_range]
		
				temp = [z for z in zip(j_range, k_range)]
		
			# straight down to last row, k stays the same (j+2, k = k)
			j_range = row_start+2:2:last_row
			k_range = [col_start for _ in j_range]

				# unite ranges
				append!(temp, [z for z in zip(j_range, k_range)])

				push!(zip_ranges, temp)

		## diagonal left to right up

			# diagonal down left (j+1, k-1)
			j_range = row_start+1:last_row
			k_range = col_start-1:-1:1
		
				temp = [z for z in zip(j_range, k_range)]
			
			# diagonal up right (j-1, k+1)
			j_range = row_start-1:-1:1
			k_range = col_start+1:last_col

				# must leverage zipping to ensure ranges are correct
				# especially true on diagonals are starts/ends for row/col mismatch
				append!(temp, [z for z in zip(j_range, k_range)])
		
				push!(zip_ranges, temp)


		## diagonal left to right down

			# diagonal up left (j-1, k-1)
			j_range = row_start-1:-1:1
			k_range = col_start-1:-1:1
		
				temp = [z for z in zip(j_range, k_range)]
			
			# diagonal down right (j+1, k+1)
			j_range = row_start+1:last_row
			k_range = col_start+1:last_col
		
	
				append!(temp, [z for z in zip(j_range, k_range)])

				push!(zip_ranges, temp)

		
		## Convert locations to cart_index
		# Init array for zip ranges
		cartIndex_ranges::Vector{Vector{CartesianIndex}} = []

		for range in zip_ranges

			# if not included, add starting location range
			# the check shouldn't be needed but good practice
			if !((row_start, col_start) in range)
				append!(range, [(row_start, col_start)])
			end

			# sorted direction array (vertical, diag up, diag down) with cart indexes
			ci_range = sort([CartesianIndex(z[1], z[2]) for z in range])

			# keep only valid locations
			filter!(c -> c in keys_loc, ci_range)
			
			## split in subarrays of len=5 that contain the starting location
			sub_arrays = sub_spaces_split(ci_range, key)

			# save results of splitting
			for sub in sub_arrays
				push!(cartIndex_ranges, sub)
			end

			
		end

		
		## Write array of cartesian locations to dictionary
		setindex!(_ret, cartIndex_ranges, key)

	end

	return _ret

end

# ╔═╡ 2cee3e2b-5061-40f4-a205-94d80cfdc20b
# pre-populate dictionary with search space (scoring)
const _locs_searchSpace_scoring = new_searchSpace_scoring()

# ╔═╡ 989f8ecc-724d-4f80-a359-fb55d2e356d6
function search_legal_moves(gs::Matrix{String}, ring_loc::CartesianIndex)
# returns sub-array of valid moves
# using server types (matrix, cartesian indexes) both in input and output
	
	# checks that starting position/ring is a valid board loc -> early return if false
	# referencing pre-computed global const 
	if !(ring_loc in _board_locs)
		return [] 
	end

	# retrieve search space for the starting point
	@inbounds search_space = _locs_searchSpace[ring_loc]

	# array to be returned
	legal_moves::Vector{CartesianIndex} = []

	# check valid moves in each locations vector and append them to returning array
	for locs_vec in search_space		
		len::Int = length(locs_vec)
		for i in 1:len

			# read state at loc
			@inbounds loc::CartesianIndex = locs_vec[i]
			@inbounds s::String = gs[loc]
			
			# if there's a ring, stop w/ this range
			(s == _RW || s == _RB) && break

			# keep empty locations
			s == "" && push!(legal_moves, loc)

			# read state at next loc if we're not at the end
			if i < len
				@inbounds next_loc::CartesianIndex = locs_vec[i+1]
				@inbounds s_next::String = gs[next_loc]
	
				# next empty after marker here -> keep NEXT, but stop w/ this range
				if ( (s == _MW || s == _MB) && s_next == "" ) 
					push!(legal_moves, next_loc)
					break
				end
			end
			
		end
		
	end

	# append starting loc - allowed to drop the ring in-place
	push!(legal_moves, ring_loc) 

	return legal_moves

end

# ╔═╡ 9700ea30-a99c-4832-a181-7ef23c86030a
function _pick_rand_locsRow()
# used for generating starting points for replicating close-to-scoring scenarios
	
	return rand(rand(_locs_searchSpace_scoring).second)

end

# ╔═╡ bbabb049-9418-4a6b-9c1a-c5822d971aba
function search_markers_toFlip(gs::Matrix{String}, s_locs::Vector{CartesianIndex})
	
	# create array to be returned
	mk_flip_locs::Vector{CartesianIndex} = []

	for loc in s_locs
		@inbounds z::String = gs[loc] # read game state
		(z == _RW || z == _RB) && break # at the first ring (the one we moved)
		(z == _MW || z == _MB) && push!(mk_flip_locs, loc) # save markers locs
	end

	# returns true/false if markers flip (array non empty) and their locations 
	return !isempty(mk_flip_locs), mk_flip_locs

end

# ╔═╡ b56084e8-7286-404b-9088-094070331afe
function reshape_in(input::Dict)::Dict
# recursively reshapes dicts IN whenever their values are Int or Int[]
# !!! expects only julia types in input, type conversions must be done upstream

	_ret = Dict{Any, Any}() # keys can be symbols or int

	for (k,v) in input
		
		## checking which case we'll have to handle
			# INT 
			f_INT = isa(v, Int)
	
			# DICT
			f_DICT = isa(v, Dict) && !isempty(v)
	
			# non-empty array
			f_ne_ARR = isa(v, Array) && !isempty(v)
	
				# INT-array
				f_ne_ARR_INT = f_ne_ARR && isa(v[begin], Int)
	
				# DICT-array
				f_ne_ARR_DICT = f_ne_ARR && isa(v[begin], Dict)

		
		## handle possible cases
		if f_INT || f_ne_ARR_INT
			_new_v = reshape_in(v) # reshape works w/ both
			setindex!(_ret, _new_v, k)

		elseif f_DICT 
			_new_v = reshape_in(v) # recursion
			setindex!(_ret, _new_v, k)

		elseif f_ne_ARR_DICT 
			_new_v = reshape_in.(v) # recursion x broadcasting
			setindex!(_ret, _new_v, k)
			
		else # leave value as-is
			setindex!(_ret, v, k)
			
		end
	end

	return _ret

end

# ╔═╡ 2c1c4182-5654-46ad-b4fb-2c79727aba3d
function reshape_lookupDicts_create()
# create dictionaries for lookup-based conversion between linear and CI coordinates
	
	return_dict_IN = Dict()
	return_dict_OUT = Dict()

	# valid locations in CI
	keys_loc_ci = findall(x -> x==1, mm_yinsh_01)

	# this to save the same locations in linear coordinates
	keys_loc_linear = []

	# array comprhension on CI doesn't work, must iterate the old way
	len = length(keys_loc_ci)
	for j in 1:len

		row, col = Tuple(keys_loc_ci[j])
		push!(keys_loc_linear, (col-1)*19 + row - 1)

	end


	# map between the two 
	for j in 1:length(keys_loc_ci)

		
		setindex!(return_dict_IN, keys_loc_ci[j], keys_loc_linear[j])
		setindex!(return_dict_OUT, keys_loc_linear[j], keys_loc_ci[j])
				
	end

	return return_dict_IN, return_dict_OUT

end

# ╔═╡ 8e400909-8cfd-4c46-b782-c73ffac03712
const return_IN_lookup, return_OUT_lookup = reshape_lookupDicts_create();

# ╔═╡ 148d1418-76a3-462d-9049-d30e85a45f06
function reshape_out(input_array::AbstractVector)
# CartesianIndex -> LinearIndex reshaping for the client
# CARTESIAN to LINEAR > (col-1)*19 + row -1
# lookup table in previously created return_dict_OUT

	return_array = []

	# array comprhension on CI doesn't work, must iterate the old way

	len = length(input_array)
	for j in 1:len

		push!(return_array, return_OUT_lookup[input_array[j]])

	end

	return return_array

end

# ╔═╡ fc68fa36-e2ea-40fa-9d0e-722167a2506e
function reshape_out(input_ci::CartesianIndex)
# CartesianIndex -> LinearIndex reshaping for the client
# CARTESIAN to LINEAR > (col-1)*19 + row -1
# lookup table in previously created return_dict_OUT

	return return_OUT_lookup[input_ci]

	
end

# ╔═╡ 7fe89538-b2fe-47db-a961-fdbdd4278963
function reshape_in(input_array::AbstractVector)
# LinearIndex -> CartesianIndex reshaping for incoming calls from the client
# assumes vector of INTs

	_return_array = CartesianIndex[]

	for i in input_array

		push!(_return_array, return_IN_lookup[i])

	end

	return _return_array


end

# ╔═╡ c1fbbcf3-aeec-483e-880a-05d3c7a8a895
function reshape_in(input_linear::Int64)
# LinearIndex -> CartesianIndex reshaping for incoming calls from the client
# assumes single INTs

	return return_IN_lookup[input_linear]

end

# ╔═╡ 403d52da-464e-42df-8739-269eb5f98df1
function search_loc_graph(input_board, row_s::Int, col_s::Int, locs)
# function to plot possible moves

# plot starting point
	scatter!(input_board, [col_s], [row_s], msize = 12, mswidth = 2, mcolor = :darkblue, shape = :dtriangle)

	
# plot search locations
for (ind,loc) in enumerate(locs)
	loc_ci = reshape_in(loc)
	scatter!(input_board, [loc_ci[2]], [loc_ci[1]], msize = 4, mswidth = 2, mcolor = :darkblue)
	
end

return input_board
end

# ╔═╡ c334b67e-594f-49fc-8c11-be4ea11c33b5
function gen_random_gameState(near_score_rows = 0, num_mks = 0)
# generate a new random game state (server format)

	spots = [l for l in _board_locs] # sample doesn't work on sets, only arrays

	## pick 10 random starting locations from board(without replacement)
	ring_locs = sample(spots, 10, replace = false)

	# empty state (server format)
	server_game_state = fill("",19,11)

	# write down rings in those locations
	for (i, loc) in enumerate(ring_locs)

		# write each odd/even
		server_game_state[loc] = (i%2 == 0) ? _RW : _RB

	end

	# add a 4-markers row for a player
	taken_mk_locs::Vector{CartesianIndex} = []
	taken_scoring_locs::Vector{CartesianIndex} = []
	if near_score_rows != 0

		for r in 1:near_score_rows

			valid_mk_locs::Vector{CartesianIndex} = []
			locs_row::Vector{CartesianIndex} = []

			# pick random scoring row
			@label retry_row_pick
			locs_row = rand(rand(_locs_searchSpace_scoring).second) 

			if isdisjoint(taken_scoring_locs, locs_row)
				append!(taken_scoring_locs, locs_row)
			else
				@goto retry_row_pick
			end
	
	
			# subtract locations already taken for rings
			px_mks_locs = setdiff(locs_row, ring_locs)
			num = 5
	
			@label retry_scoring_mks
			try 
				valid_mk_locs = sample(px_mks_locs, num, replace = false)

				append!(taken_mk_locs, valid_mk_locs) # save all mks taken
			
				lucky_player = rand([_W, _B])
		
				for loc in valid_mk_locs
					server_game_state[loc] = (lucky_player == _W) ? _MW : _MB
				end
		
			catch # not enough markers available
				num -= 1
				@goto retry_scoring_mks
			end

		end
	end


	if num_mks != 0

		@label retry_filling_mks
		try 
			mks_pool = 	setdiff(spots, ring_locs) |> 
						v -> setdiff(v, taken_mk_locs) |>
						v -> sample(v, num_mks, replace = false)


			for loc in mks_pool
				server_game_state[loc] = rand([_MW, _MB])
			end
			
		catch 
			num_mks -=1
			@goto retry_filling_mks
		end

	end
	

	return server_game_state
end

# ╔═╡ bc19e42a-fc82-4191-bca5-09622198d102
const games_log_dict = Dict()

# ╔═╡ 57153574-e5ca-4167-814e-2d176baa0de9
function save_newGame!(games_log_ref, new_game_details)
# handles writing to dict (redis in the future?)

	# saves starting state of new game
	setindex!(games_log_ref, new_game_details, new_game_details[:identity][:game_id])


end

# ╔═╡ 1fe8a98e-6dc6-466e-9bc9-406c416d8076
function save_new_clientPkg!(games_log_ref, game_id, _client_pkg)
# handles writing to dict (redis in the future?)
# returns index to last saved package

	# saves starting state of new game
	push!(games_log_ref[game_id][:client_pkgs], _client_pkg)

	
end

# ╔═╡ 823ce280-15c4-410f-8216-efad03897282
function new_gs_only_rows(rows::Vector{Vector{CartesianIndex}}, id_h_row=-1)

	gs = fill("", (19,11))

	if !isempty(rows)
		for r in rows
			for loc in r
				gs[loc] = "MB" # black by default, so highlight can be seen better 
			end
		end
	end

	if id_h_row != -1 # highlight this row as color of opposite player

		for loc in rows[id_h_row]
			gs[loc] = "MW"
		end

	end

	return gs

end

# ╔═╡ c0c45548-9792-4969-9147-93f09411a71f
function remove_subsets!(vec::Vector)

	len::Int = length(vec)
	keep_mask::Vector{Bool} = fill(false, len)

	@inbounds for i in 1:len

		# compare against all elements (inclding itself)
		@inbounds superset_index = findfirst(s -> ⊊(vec[i], s), vec)

		# nothing -> v is not a subset of any other -> keep it
		if isnothing(superset_index)
			@inbounds keep_mask[i] = true 
		end
		
	end
	
	keepat!(vec, keep_mask)
	
end

# ╔═╡ dd941045-3b5f-4393-a6ae-b3d1f029a585
function remove_subsets!(set::Set)

	@inbounds for s in set
		
		for r in setdiff(set, s) # compare against all the others

			if ⊊(s, r) # -> s is a strict subset of r
				delete!(set, s)
				break
			end
		end
	end

end

# ╔═╡ 8348950a-11cb-4eaa-a639-fcd2b758fb3b
t_gs = gen_random_gameState(8, 15);

# ╔═╡ 39d81ecc-ecf5-491f-bb6e-1e545f10bfd0
function discover_scoring_sets(rows::Vector{Vector{CartesianIndex}}, max_ssize=0)::Set{Set{Int}}
#= 
Fn akes in input rows of locations (CI) and returns the possible sets representing groups of scoring actions: with multiple scoring and rows overlap, some scores preclude others having A/B/C, depending on their configuration, A/B/C, A/B, B/C, C/A might be available as different valid scoring sets

notes:
- we're using the 1-based index of row (in input array) as the ID for the row
- we make heavy use of sets for uniqueness and fast ops
- the additional parameter is passed to limit the size of the sets: propagated from sim_scenarioTrees > sim_new_gameState > search_scores_gs > here, represents the distance in rings a player has from winning

=#
	
	len::Int = length(rows)
	
	# base sets to be expanded, every row can be with itself
	base_sets = Set([ Set{Int}(r) for r in 1:len ]) # sets of size 1

	# final sets to be returned
	scoring_sets = Set{Set{Int}}() 

	if max_ssize == 1 # sets of size 1
		scoring_sets = base_sets
		@goto return_ss
	end

	# log who can be with who - each row can be in a set with itself
	matches_vec = [Set{Int}(r) for r in 1:len] 
	

	#= 	
		The general idea is to extend the sets in a bottom up way
		- iterate through all ids/rows pair-wise, log matches
		- on each pair, check which matches are possible (disjoint rows)
		- if is a match, update log for both rows involved in comparison
		- prune set, take our a set, and try extending it by-1
		- transfer to the final return_value that sets that can't be extended further
		- repeat until empty until there are no more sets to evaluate
		- strip the final array of subsets 
	=#

	
	# iterate over row indexes and build a matches reference 
	for j in 1:len, k in j:len

		if j != k
			
			# check for clashes/no_clashes 
			@inbounds if isdisjoint(rows[j], rows[k])

				# save matches for both rows
				@inbounds push!(matches_vec[j], k)
				@inbounds push!(matches_vec[k], j)

				# save set
				push!(base_sets, Set{Int}([j, k]))
				
			end
		end
	end

	if max_ssize == 2 # sets of max size 2
		scoring_sets = base_sets
		@goto return_ss
	end

	# extend each set to 2+ -> use ref to find other rows that can be added 
	# sets are extended by 1 at each loop
	while length(base_sets) > 0
		
		# prune 
		remove_subsets!(base_sets) 

		# take out a set to evaluate for extension
		# always delete 'starting branch' to avoid restarting from same set 
		# function never converges without this
		# also, we loop & prune after every set evaluation
		# instead of adding and keep iterating without pruning
		s = pop!(base_sets)

		# not extend set if it's at max_size, just save it and skip to the next
		if (max_ssize > 2 && length(s) == max_ssize)
			if !(s in scoring_sets)
				push!(scoring_sets, s) 
			end
			@goto skip_set
		end

		# ids of rows that match with all the others in set
		@inbounds ids = intersect( [ matches_vec[r] for r in s ]...)::Set{Int}

		# keep only potential new additions
		new_ids = setdiff(ids, s)::Set{Int}

		# this set can't be grown further
		if isempty(new_ids)
			
			if !(s in scoring_sets) # save it if new
				push!(scoring_sets, s) 
			end
			
		else # create N new sets for each new id
			for i in new_ids
				
				new_set = union(s, i)::Set{Int}
				
				if !(new_set in base_sets) # put it back for later if new
					push!(base_sets, new_set) 
				end					
			end
		end

		@label skip_set
		
	end

	
	@label return_ss # jump to before final pruning!
		
	# clean up results
	remove_subsets!(scoring_sets)

	return scoring_sets
	
end

# ╔═╡ 69b9885f-96bd-4f8d-9bde-9ac09521f435
function search_scores_gs(gs::Matrix{String})::Dict{Symbol, Dict}
# look at the game state as it is to check if there are scoring opportunities

	# to be returned -> returns empty vector if nothing found for player
	# :B/:W -> {:s_rows => [], :s_sets => []}
	scores_info::Dict{Symbol, Dict} = Dict()

	# helper vecs/dict to store found locations for scoring rows
	rows_B = Vector{CartesianIndex}[]
	rows_W = Vector{CartesianIndex}[]
	found_rows = Dict(_B_key => rows_B, _W_key => rows_W)

	# all markers locations
	all_mks::Vector{CartesianIndex} = findall(s -> contains(s, _M), gs)
	
	for mk_index in all_mks

		# for each marker retrieve search space for scoring ops
		@inbounds mk_search_locs::Vector{Vector{CartesianIndex}} = _locs_searchSpace_scoring[mk_index]

		for locs_vec in mk_search_locs

			# reading states for all locs in search array
			states_vec = String[]
			for loc in locs_vec
				@inbounds s::String = gs[loc]
				contains(s, _M) ? push!(states_vec, s) : @goto skip_vec
			end
	
			# search if a score was made within this search array
			black_scoring::Bool = states_vec == _B_score
			white_scoring::Bool = states_vec == _W_score

			# if a score was made
			if black_scoring || white_scoring
				# log who's the scoring player
				player_key::Symbol = black_scoring ? _B_key : _W_key

				# save the row but check that scoring row wasn't saved already
				if !(locs_vec in found_rows[player_key])
					@inbounds push!(found_rows[player_key], locs_vec)
				end					
			end	

			@label skip_vec
		end
	end

	
	# identify mk_sel for row selection within same groups
	mk_sel_taken = Vector{CartesianIndex}(undef,0) # keep track of ones already taken
	for player_k in keys(found_rows)

		# extract rows
		@inbounds rows::Vector{Vector{CartesianIndex}} = found_rows[player_k]

		# identify scoring sets among rows and save them in container
		scoring_sets::Set{Set{Int}} = discover_scoring_sets(rows)

		# prep containers
		s_rows = Dict[]
		s_player = Dict{Symbol,Union{Vector{Dict}, Set}}(:s_rows => s_rows, :s_sets => scoring_sets)

		# summary info for all markers across all rows
		mk_group::Vector{CartesianIndex} = vcat(rows...)
		mk_freq::Dict{CartesianIndex,Int64} = countmap(mk_group)

		# transform rows into scores data
		for r in rows

			# exclude from row mks already taken
			mk_sel_avail::Vector{CartesianIndex} = setdiff(r, mk_sel_taken)

			# find marker with min frequency and save it
			_, id::Int = findmin(i -> mk_freq[i], mk_sel_avail)
			@inbounds mk_sel::CartesianIndex = mk_sel_avail[id]
			push!(mk_sel_taken, mk_sel)

			# package score information
			score_row_info = Dict{Symbol,Union{CartesianIndex, Vector{CartesianIndex}}}(:mk_sel => mk_sel, :mk_locs => r)

			# save prepared scoring row
			@inbounds push!(s_rows, score_row_info)

		end

		# save player's data
		@inbounds setindex!(scores_info, s_player, player_k)
	end


	return scores_info

end

# ╔═╡ fd1b186d-b042-4e42-97ea-7e2338eaf75c
ss = search_scores_gs(t_gs)

# ╔═╡ c3ab8073-165e-4013-99bc-6d32cf9f4514
t_rows = [ row[:mk_locs] for row in ss[:B][:s_rows] ]

# ╔═╡ 5ea1985d-8788-445e-9c8c-f8ebab01ecf6
f_gs = new_gs_only_rows(t_rows);

# ╔═╡ 9b2123a3-12fb-4ebf-ad9b-1aa65ff9ee43
# ╠═╡ disabled = true
#=╠═╡
@benchmark discover_scoring_sets(t_rows)
  ╠═╡ =#

# ╔═╡ 00e20281-2046-487b-89a2-1a9f848c67fa
# ╠═╡ disabled = true
#=╠═╡
@benchmark discover_scoring_sets(t_rows)
  ╠═╡ =#

# ╔═╡ 60cb964f-1cd4-4dc4-bb6e-12e4be395fcd
# ╠═╡ disabled = true
#=╠═╡
discover_scoring_sets(t_rows)
  ╠═╡ =#

# ╔═╡ bff81fc8-bce9-4f45-8a2e-21f7d2c18648
discover_scoring_sets(t_rows,6) 

# ╔═╡ 9f1d770b-7c67-4b25-bf2b-0fbf6a29fb6a
function identify_scoring_sets_old(rows::Vector{Vector{CartesianIndex}})
# takes in input rows of locations (CI) and returns the possible sets representing groups of scoring actions
# with multiple scoring and rows overlap, some scores preclude others
# having A/B/C, depending on their configuration, A/B/C, A/B, B/C, C/A might be available for scoring
# using the 1-based index of row in input array as the ID for the row

	len_range::UnitRange{Int} = 1:length(rows)
	pair_sets::Set{Set{Int}} = Set([]) # using a set guarantees they're unique
	scoring_sets::Vector{Set{Int}} = [] # returning value
	
	ref::Dict{Int, Dict{Symbol, Vector{Int}}} = Dict(k => Dict() for k in len_range)

	#= 	the general idea is to grow the sets in a bottom up way
		- iterate through all ids/rows pair-wise, log clash or no_clash
		- update log for both rows involved in comparison
		- on each pair, check what the rows don't clash with that might be added
		- check those potential additions among themselves -> add what's left
		- strip the final array of dublicates and subsets 
	=#

	
	# iterate over row indexes and build a reference dictionary
	for i in len_range

		clash::Vector{Int} = []
		no_clash::Vector{Int} = [i] # each row can be in a set with itself

		# check against all other rows
		for k in len_range[i:end]
			
			if k != i # skip itself 

				# check for clashes/no_clashes 
				@inbounds if isdisjoint(rows[i], rows[k])
					
					push!(no_clash, k) 
					push!(pair_sets, Set([i, k]))
					
				else
					push!(clash, k) 
				end

			end
		end

		# save results in log
		setindex!(ref[i], clash, :c)
		setindex!(ref[i], no_clash, :nc)

	end

	#@info ref
	#@info pair_sets
	
	# grow each set -> use ref to find other rows that can be added to each
	for s in pair_sets

		# ids of rows that don't clash with either of the others in set
		@inbounds pot_new_ids = intersect([ ref[r][:nc] for r in s ]...)

		# cleaning up ids to ensure they don't clash among themselves
		@inbounds new_ids = intersect([ ref[r][:nc] for r in pot_new_ids ]...)
		
		if isempty(new_ids) # keep as-is
			push!(scoring_sets, s) 
		else # add ids to set
			push!(scoring_sets, union(s, new_ids...)) 
		end

	end

	# clean up results
	remove_subsets!(scoring_sets)

	return scoring_sets
	
end

# ╔═╡ fae1cebf-9355-4c4c-b0aa-0eab1f517785
function identify_scoringSets_old(rows::Vector{Vector{CartesianIndex}})::Vector{Set{Int}}
# takes in input rows of locations (CI) and returns the possible sets representing groups of scoring actions
# with multiple scoring and rows overlap, some scores preclude others
# having A/B/C, depending on their configuration, A/B/C, A/B, B/C, C/A might be available for scoring
# using the 1-based index of row in input array as the ID for the row

	len_range::UnitRange{Int} = 1:length(rows)
	c_grouped::Vector{Int} = [0 for i in len_range] # track times we group each
	scoring_sets::Vector{Set{Int}} = [] # set of row IDs that go together

	for j in len_range

		# stop when all have been grouped 1+
		count(>=(1), c_grouped) == len_range && break

		# start w/ its own lonely group
		v_locs::Vector{CartesianIndex} = []; append!(v_locs, rows[j])
		set_ids::Set{Int} = Set(j)
		
		@inbounds c_grouped[j] += 1  # increase counter for row
	
		# check against all other rows
		for k in len_range 

			# skip itself 
			if k != j 
				
				# add to set if disjoint from everything else in it 
				if isdisjoint(v_locs, rows[k])
					append!(v_locs, rows[k]) # save locs for next comparisons
					push!(set_ids, k) # save id of row
					
					@inbounds c_grouped[k] += 1 
				end
			end
		end

		# save found set ids, if not redundant
		!(set_ids in scoring_sets) && push!(scoring_sets, set_ids) 
		
	end

	return scoring_sets
	
end

# ╔═╡ 18f8a5d6-c775-44a3-9490-cd11352c4a63
function set_nested!(dict::Dict, val, first_key, second_key)
# adds values to a dictionary following a first_key -> second_key -> value structure
# checks if the first key exists before saving
# it doesn't return anything, it alters the input dictionary
	
	if haskey(dict, first_key) # test if start branch exists
		
		setindex!(dict[first_key], val, second_key)
		
	else # save while creating start branch
		
		setindex!(dict, Dict(second_key => val), first_key)

	end

end

# ╔═╡ 67b8c557-1cf2-465d-a888-6b77f3940f39
function reshape_out_fields(srv_dict::Dict)::Dict
# takes dict in input -> reshapes out any field that is of type CI or CI[]
# will reshape CI keys as well if it finds any
# used to translate any server-like coordinates to client format
# it also skips/omits some keys that are only used server-side, to lighten the payload

	_ret = Dict() 

	keys_to_skip = Symbol[:gs, :tree_summary]

	for (k,v) in srv_dict

		if isa(k, Symbol) && k in keys_to_skip
			@goto skip_key
		end

		## updating the key if it's a CI
		_nk = isa(k, CartesianIndex) ? reshape_out(k) : k
		
		## checking which case we'll have to handle
			# CI 
			f_CI::Bool = isa(v, CartesianIndex)
	
			# DICT
			f_DICT::Bool = isa(v, Dict)
	
			# non-empty ARRAY
			f_ne_ARR::Bool = isa(v, Array) && !isempty(v)
	
				# CI-array
				f_ne_ARR_CI::Bool = f_ne_ARR && isa(v[begin], CartesianIndex)
	
				# DICT-array
				f_ne_ARR_DICT::Bool = f_ne_ARR && isa(v[begin], Dict)

			# non-empty SET
			f_ne_SET::Bool = isa(v, Set) && !isempty(v)

				# CI-SET
				f_ne_SET_CI::Bool = f_ne_SET && isa(rand(v), CartesianIndex)

				# non CI-SET
				f_ne_SET_noCI::Bool = f_ne_SET && !isa(rand(v), CartesianIndex)

		
		## handle possible cases
		if f_CI || f_ne_ARR_CI
			_new_v = reshape_out(v) # reshape works w/ both
			setindex!(_ret, _new_v, _nk)

		elseif f_DICT # recursion
			_new_v = reshape_out_fields(v)
			setindex!(_ret, _new_v, _nk)

		elseif f_ne_ARR_DICT # recursion x broadcasting
			_new_v = reshape_out_fields.(v)
			setindex!(_ret, _new_v, _nk)

		elseif f_ne_SET_CI 
			_new_v = reshape_out.(v)
			setindex!(_ret, _new_v, _nk)

		elseif f_ne_SET_noCI
			_new_v = collect(v)
			setindex!(_ret, _new_v, _nk)
			
		else # leave value as-is
			setindex!(_ret, v, _nk)
			
		end
		

		@label skip_key
		
	end

	return _ret
	
end

# ╔═╡ cf587261-6193-4e7a-a3e8-e24ba27929c7
function getLast_clientPkg(game_id)
# looks in the games log and retrieves last client package

	try
		_client_packages = games_log_dict[game_id][:client_pkgs][end]
		
		println("LOG - Game data pkg retrieved - Game ID: $game_id")

		return _client_packages
	
	catch 
		throw(error("ERROR retrieving game data"))

	end

end

# ╔═╡ 439903cb-c2d1-49d8-a5ef-59dbff96e792
function getLast_clientDelta(game_id)
# looks in the games log and retrieves last client package

	try
		_client_delta = games_log_dict[game_id][:client_delta][end]
		
		println("LOG - Game data client delta retrieved - Game ID: $game_id")

		return _client_delta
	
	catch 
		throw(error("ERROR retrieving game data"))

	end

end

# ╔═╡ f86b195e-06a9-493d-8536-16bdcaadd60e
function print_gameState(gs, symbols = false)	
# print matrix easy copying in js code
# https://commons.m.wikimedia.org/wiki/Unicode_circle_shaped_symbols
# https://unicodeplus.com/U+20DD

	#〚 〛 〖 〗 〘 〙 ⃝  ⃟  ⃞ 
 	sym_map = Dict("MW" => "⏺", "MB" => "⚬", "RB" => " ⃟ ", "RW" => " ⃝ ") 
	empty_sym = "   "
	empty_txt = "    "
	
	mm_to_print = ""

	for i in 1:row_m
		for j in 1:col_m

			# prep values
			if gs[i,j] == ""
				print_val = symbols ? empty_sym : empty_txt
			else

				_val = symbols ? sym_map[gs[i,j]] : gs[i,j]
				
				print_val = symbols && contains(gs[i,j], "R") ? _val : " "*_val*" "
				
			end

			# build matrix
			if j == 1 
				mm_to_print *= "[" * string(print_val) * ""
			
			elseif j == col_m 
				mm_to_print *= string(print_val) * "] \n"
				
			else
				mm_to_print *= string(print_val) * ""
			end
		end
	end

print(mm_to_print)

end

# ╔═╡ c0881f04-40e5-4108-85e2-f3aca3420513
print_gameState(t_gs, true)

# ╔═╡ 74951f2f-1bc4-4d0f-a2ee-fd6862c6feec
print_gameState(f_gs, true)

# ╔═╡ 466eaa12-3a55-4ee9-9f2d-ac2320b0f6b1
function initRand_ringsLoc()
# returns random locations for 5 + 5 rings

	# keys mapping to valid board locations
	keys_loc = findall(x -> x==1, mm_yinsh_01)

	# sample 10 random starting locations (without replacement)
	sampled_locs = sample(keys_loc, 10, replace = false)

	# return the halved array of locations
	return sampled_locs[1:5], sampled_locs[6:10]
	
end

# ╔═╡ b170050e-cb51-47ec-9870-909ec141dc3d
md"### Running websocket server"

# ╔═╡ c9233e3f-1d2c-4f6f-b86d-b6767c3f83a2
begin
	const ws_servers_array = []; # array of server handles
	const ws_messages_log = []; # log for all received messages
	const ws_messages_log_OG = []; # log for all received messages (only parsing)
end

# ╔═╡ 0bb77295-be29-4b50-bff8-f712ebe08197
begin
	
	# ip and port to use for the server
	ws_ip = "0.0.0.0" # listen on every ip / host ip
	ws_port = 6091

end

# ╔═╡ f9949a92-f4f8-4bbb-81d0-650ff218dd1c
#HTTP.forceclose(ws_servers_ref[end])

# ╔═╡ 5e5366a9-3086-4210-a037-c56e1374a686
begin
	
	# client codes codes - used for different requests
	# server responds with these + _OK or _ERROR
	CODE_new_game_human = "new_game_vs_human"
	CODE_new_game_server = "new_game_vs_server"
	CODE_join_game = "join_game"
 	CODE_advance_game = "advance_game" # clients asking to progress the game
	CODE_resign_game = "resign_game" # clients asking to resign

	
	# server codes (only the server can use these)
	# client responds with these + _OK or _ERROR
	CODE_play = "play" # the other player has joined -> move
	CODE_wait = "wait" # the other player has yet to join -> wait 
	CODE_end_game = "end_game" # someone won


	# suffixes for code response type
	sfx_CODE_OK = "_OK"
	sfx_CODE_ERR = "_ERROR"

	# keys to access specific values
	key_nextActionCode = :next_action_code

	

end

# ╔═╡ ca522939-422f-482a-8658-452790c463f6
function dict_keys_to_sym(input::Dict)::Dict{Symbol, Any}
# swaps dict keys from String to Symbol
	
	_new = Dict()

	for (k,v) in input

		# is key a string ?
		_nkey = isa(k, String) ? Symbol(k) : k

		# is value a Dict ?
		_nval = isa(v, Dict) ? dict_keys_to_sym(v) : v

		# is value an Array of Dicts ?
		if isa(v, Vector) && !isempty(v) 
			_nval = isa(v[begin], Dict) ? dict_keys_to_sym.(v) : v
		end

		# write anyway
		setindex!(_new, _nval, _nkey)
		
	end

	return _new
end

# ╔═╡ 28ee9310-9b7d-4169-bae4-615e4b2c386e
function msg_dispatcher(ws, msg_id, msg_code, payload = Dict(), _status::Bool = true)

	# copy response payload
	_response::Dict{Symbol, Any} = deepcopy(payload)

	# prepare response code
	_sfx_msg_code = msg_code * (_status ? sfx_CODE_OK : sfx_CODE_ERR)
	
	# append original msg id and updated response_code
	setindex!(_response, msg_id, :msg_id)
	setindex!(_response, _sfx_msg_code, :msg_code)

	# add statusCode 200 
	setindex!(_response, 200, :statusCode)

	# send response
	send(ws, JSON3.write(_response))

	# log
	println("LOG - $_sfx_msg_code sent for msg ID $msg_id")

	# save response (TO BE REMOVED)
	setindex!(_response, "sent", :type)
	push!(ws_messages_log, _response)


end

# ╔═╡ 612a1121-b672-4bc7-9eee-f7989ac27346
function update_ws_handler!(game_id::String, ws, is_orig_player::Bool)

# updates WS handler for a specific player within a game
# if the game is not found, it will throw an error
# could be made more independent in the future (handle directly msg)
	
	try
		
		# understand necessary key  
		_dict_key = is_orig_player ? :orig_player_ws : :join_player_ws
		
		games_log_dict[game_id][:ws_connections][_dict_key] = ws

		println("LOG - WS handler updated for $_dict_key")
	
	catch 
		throw(error("ERROR retrieving game data when updating WS handler"))

	end
	
	

end

# ╔═╡ ac87a771-1d91-4ade-ad39-271205c1e16e
function fn_join_game(ws, msg)
# human client asking to join existing code via game code

	# retrieve existing game data (otherwise error is handled by calling function)
	_existing_game_data = getLast_clientPkg(msg[:payload][:game_id]) # caller payload

	# save ws handler for joining player
	update_ws_handler!(msg[:payload][:game_id], ws, false) # true if originator

	_other_pld = Dict() # empty payload for other

	# return payload - requester, other
	return _existing_game_data, _other_pld

end

# ╔═╡ 384e2313-e1c7-4221-8bcf-142b0a49bff2
function _is_playing_next(game_id::String, _player_id::String)::Bool
# returns false if error

	try

		_current_turn = games_log_dict[game_id][:turns][:current]
		_moving_player = games_log_dict[game_id][:turns][:data][_current_turn][:moving_player]

		return _moving_player == _player_id

	catch
		println("ERROR - _is_playing_next fn, data for g_id $game_id can't be located")
		return false
	end

end

# ╔═╡ 5d6e868b-50a9-420b-8533-5db4c5d8f72c
function is_human_playing_next(game_id::String)::Bool
# human is always the originator

	try
		_originator_id = games_log_dict[game_id][:identity][:orig_player_id]
		
		return _is_playing_next(game_id, _originator_id)

	catch

		println("ERROR - is_human_playing_next fn, data for g_id $game_id can't be located")
		return false

	end
end

# ╔═╡ c77607ad-c11b-4fd3-bac9-6c43d71ae932
function get_ws_handler(game_id::String, _is_originator::Bool)

	_key = _is_originator ? :orig_player_ws : :join_player_ws

	return games_log_dict[game_id][:ws_connections][_key]

end

# ╔═╡ b5c7295e-c464-4f57-8556-c36b9a5df6ca
function set_turn_closed!(game_code::String, turn_no::Int)

	try 
		setindex!(games_log_dict[game_code][:turns][:data][turn_no], :closed, :status)

	catch e
		throw(error("ERROR while setting turn $turn_no as closed - $e"))
	end

end

# ╔═╡ 92a20829-9f0a-4ed2-9fd3-2d6560514e03
function advance_turn!(game_code::String, completed_turn_no::Int)::Dict
# this function manages turns across :open -> :closed
# closes indicated turn and creates new one
# returns dict of new turn data


	# current vars
	_game = games_log_dict[game_code]

	_turns = _game[:turns]
	_current_turn_no = _turns[:current]
	_current_status = _turns[:data][_current_turn_no][:status]
	_current_moving_player = _turns[:data][_current_turn_no][:moving_player]
	

	if _current_turn_no != completed_turn_no

		throw(error("ERROR - fn advance_turn - current and completed turn don't match"))

	else

		# close current turn
		set_turn_closed!(game_code, completed_turn_no)

		# create new one
		_next_moving = (_current_moving_player == "W") ? "B" : "W"
		_next_status = :open
		_next_turn_no = _current_turn_no + 1
		
		_new_turn_data = Dict(:turn_no => _next_turn_no,
								:status => _next_status, 
								:moving_player =>_next_moving)

		# save turn data
		push!(games_log_dict[game_code][:turns][:data], _new_turn_data)
		games_log_dict[game_code][:turns][:current] = _next_turn_no
		
		# return new turn data
		return _new_turn_data

	end
		
end

# ╔═╡ 13eb72c7-ac24-4b93-8fd9-260b49940370
function check_both_players_ready(game_id)
# checks if both players are ready

	try
		
		_players = get(games_log_dict[game_id], :players, nothing)

		if !isnothing(_players)

			_both_ready = _players[:orig_player_status] == :ready && 	   _players[:join_player_status] == :ready
	
			return _both_ready
		else
			return false
		end

	catch

		throw(error("ERROR checking players readiness status"))

	end

end

# ╔═╡ 8929062f-0d97-41f9-99dd-99d51f01b664
function is_game_vs_ai(game_id::String)::Bool
# checks if game is vs ai/server, if not (or if error) returns false
	
	try
		return games_log_dict[game_id][:identity][:game_type] == :h_vs_ai
	catch
		println("ERROR in is_game_vs_ai check: game code $game_id not found")
		return false
	end

end

# ╔═╡ ebd8e962-2150-4ada-8ebd-3eba6e29c12e
function whos_player(game_code::String, player_id::String)::Symbol

	try 
		
		# retrieve game setup info
		_orig_player = games_log_dict[game_code][:identity][:orig_player_id]

		# understand who is the player 
		return whos = (_orig_player == player_id) ? :originator : :joiner

	catch

		throw(error("ERROR retrieving game data for whos_player lookup"))
	end

end

# ╔═╡ af5a7cbf-8f9c-42e0-9f8f-6d3561635c40
function strip_reshape_in_recap(recap::Dict)
# takes turn recap from client, strips away not relevant fields, convert Int -> CI
# does type conversion (json3 obj/array => julia) using other functions
	
#= 	# CLIENT - expected input 

	score_actions_preMove : [ { mk_locs: [], ring_score: -1 } ],
	move_action: { start: start_move_index, end: drop_loc_index },
	score_actions: [ { mk_locs: [], ring_score: -1 } ], 
	completed_turn_no: _played_turn_no     

	# SERVER/AI - input 
	- returned by turn_play_server, has cartesianIndexes as coord -> should skip
	- turn_play_AI instead returns client-like and needs pick-translation + this fn


	# general notes
	- v0 AI should remap to CI if it wants to survive
	- V1 shouldn't not pass from this -> passing paramter to updateServerStates! ?

=#
	
	_srv_recap = Dict()

	# keep only dicts (within arrays) that have non-default values in their fields
	for (k, v) in recap
		if isa(v, Array) && !isempty(v) && isa(v[begin], Dict)
			if haskey(v[begin], :ring_score) && v[begin][:ring_score] != -1
				setindex!(_srv_recap, v, k) 
			end
		elseif isa(v, Dict)
			if haskey(v, :start)
				setindex!(_srv_recap, v, k)
			end
		end
	end

	return reshape_in(_srv_recap) # defined only on julia dicts 
	
end

# ╔═╡ 5ae493f4-346d-40ce-830f-909ec40de8d0
function filter_msg_logs_by_gameID(game_id::String)::Array

	return ws_messages_log |> 
			logs -> filter(m -> (haskey(m, :game_id) && m[:game_id] == game_id) 
							|| (haskey(m, :payload) && haskey(m[:payload], :game_id) && m[:payload][:game_id] == game_id)
								,logs)

end

# ╔═╡ 276dd93c-05f9-46b1-909c-1d449c07e2b5
function get_player_score(game_id::String, player_id::String)

	try
		_player_type = whos_player(game_id, player_id)
		key = _player_type == :originator ? :orig_player_score : :join_player_score
		
		return games_log_dict[game_id][:players][key] 
	catch e
		throw(error("ERROR - while retrieving $player_id score for game $game_id $e"))
	end

end

# ╔═╡ 8797a304-aa98-4ce0-ab0b-759df0256fa7
function edit_player_score!(game_id::String, player_id::String, new_score::Int)

	try
		_player_type = whos_player(game_id, player_id)
		key = _player_type == :originator ? :orig_player_score : :join_player_score
		
		games_log_dict[game_id][:players][key] = new_score

		return games_log_dict[game_id][:players][key]
	
	catch e
		throw(error("ERROR - while increasing $player_id score for game $game_id $e"))
	end

end

# ╔═╡ 67322d28-5f9e-43da-90a0-2e517b003b58
swap_player_id(player_id) = ( player_id == _W) ? _B : _W

# ╔═╡ f1c0e395-1b22-4e68-8d2d-49d6fc71e7d9
function get_last_srv_gameState(game_id::String, param::Int = 0)::Matrix

	return games_log_dict[game_id][:server_states][end-param]

end

# ╔═╡ c38bfef9-2e3a-4042-8bd0-05f1e1bcc10b
function get_last_moving_player(game_code)

	_current_turn = games_log_dict[game_code][:turns][:current]

	return games_log_dict[game_code][:turns][:data][_current_turn][:moving_player]

end

# ╔═╡ 7a4cb25a-59cf-4d2c-8b1b-5881b8dad606
function is_game_over_by_score(game_id::String)::Dict
# checks if one of the players scored 3

	ret = Dict(:end_flag => false, :won_by => :undef, :won_why => :score)

	_orig_player_sk = :orig_player_score
	_join_player_sk = :join_player_score

	_orig_score = games_log_dict[game_id][:players][_orig_player_sk] 
	_join_score = games_log_dict[game_id][:players][_join_player_sk] 

	if _orig_score == 3
		ret[:end_flag] = true
		ret[:won_by] = games_log_dict[game_id][:identity][:orig_player_id]

	elseif _join_score == 3
		ret[:end_flag] = true
		ret[:won_by] = games_log_dict[game_id][:identity][:join_player_id]
	end

	return ret

end

# ╔═╡ 42e4b611-abe4-41c4-8f92-ea39bb928122
function is_game_over_by_resign(game_id::String)::Dict
# checks if one of the players abandoned game

	ret = Dict(:end_flag => false, :won_by => :undef, :won_why => :resign)

	_orig_player_sk = :orig_player_status
	_join_player_sk = :join_player_status

	_orig_status = games_log_dict[game_id][:players][_orig_player_sk] 
	_join_status = games_log_dict[game_id][:players][_join_player_sk] 

	if _orig_status == :resigned
		ret[:end_flag] = true
		ret[:won_by] = games_log_dict[game_id][:identity][:join_player_id]

	elseif _join_status == :resigned
		ret[:end_flag] = true
		ret[:won_by] = games_log_dict[game_id][:identity][:orig_player_id]
	end

	return ret

end

# ╔═╡ 20a8fbe0-5840-4a70-be33-b4103df291a1
function update_game_end!(game_id::String)::Dict
# checks if game is over or not, either by scoring or resign by one of the players
# marks reason in game log - who won, reason (score vs resign), and end time 
	
	_def_ret = Dict(:end_flag => false)

	_end_check_by_score = is_game_over_by_score(game_id)
	_end_check_by_resign = is_game_over_by_resign(game_id)

	if _end_check_by_score[:end_flag] 

		games_log_dict[game_id][:identity][:won_by] = _end_check_by_score[:won_by]
		games_log_dict[game_id][:identity][:won_why] = :score
		games_log_dict[game_id][:identity][:end_dateTime] = now()
		games_log_dict[game_id][:identity][:status] = :completed

		println("SRV - Game $game_id completed")
		
		return _end_check_by_score

	elseif _end_check_by_resign[:end_flag]  

		games_log_dict[game_id][:identity][:won_by] = _end_check_by_resign[:won_by]
		games_log_dict[game_id][:identity][:won_why] = :resign
		games_log_dict[game_id][:identity][:end_dateTime] = now()
		games_log_dict[game_id][:identity][:status] = :completed

		println("SRV - Game $game_id completed")

		return _end_check_by_resign

	else

		return _def_ret
	
	end

end

# ╔═╡ 8b830eee-ae0a-4c9f-a16b-34045b4bef6f
function get_last_turn_details(game_code::String)

	_current_turn = games_log_dict[game_code][:turns][:current]

	return games_log_dict[game_code][:turns][:data][_current_turn]::Dict

end

# ╔═╡ c6e915be-2853-48ff-a8da-49755b9b1a44
function setindex_container!(d::Dict, val, key, use_set = false)
# saves value within array or set container within a dictionary at :key index
# if container array/set exists, push to it - otherwise create container first
# if value is an array, splat/append it	

	_splat::Bool = isa(val, Array)

	if haskey(d, key)
		_splat ? append!(d[key], val) : push!(d[key], val)
	else
		if use_set
			_splat ? setindex!(d, Set([val...]), key) : setindex!(d, Set([val]), key)
		else # use array
			_splat ? setindex!(d, [val...], key) : setindex!(d, [val], key)
		end
	end

end

# ╔═╡ a27e0adf-aa09-42ee-97f5-ede084a9edc3
function sim_new_gameState(ex_game_state::Matrix, sc::Dict, fn_mode::Symbol)::Dict
	
#=
This function has three modes of use:
- :replay - reflect a client's moves in the game state (opp scoring, move, scoring)
- :inspect - surface flip/scoring/opp_scoring potential as-is
- :move - surface flip/scoring/opp_scoring potential for a given move (start -> end)


The function assumes all coordinate ids are in server-side format (cartIndexes).
It will return its calling mode, the modified gameState, and relevant deltas.
The presence of a key/dict acts as a true flag in its own right.

All data is returned in srv-side format.
Making sense of move/flip data depends on the mode the function was called in.

=# 
#= > INPUT format for SC (Scenario)

	! id
		! player_id -> B/W
		! player_score -> 0...3
		() opp_score -> 0...3 # it can't increase until after opponent scores
		() game_mode -> classic (3) vs quick (1)
		() game_id / turn_no / scenario_id -> have a single id for N choices and read changes from DB ?

	-- all data in dicts below can be reshaped-in/out as a whole, only coordinates --

	() score_actions_preMove [] -> opponent scored for player at the end of their turn
			mk_locs
			ring_score
	
	() move_action  
	  		start 
			end

	() score_actions []
			mk_locs
			ring_score

=#

	## extract relevant flags from input (given by presence of keys in dict)
	f_scores_act_preMove::Bool = haskey(sc, :score_actions_preMove)
	f_move_act::Bool = haskey(sc, :move_action)
	f_scores_act::Bool = haskey(sc, :score_actions)

	# extract player_id (B/W)
	@inbounds _player_id::String = sc[:id][:player_id]
	_opp_id::String = _player_id == _W ? _B : _W

	# baseline game state that we'll modify and return later
	new_gs::Matrix{String} = deepcopy(ex_game_state)
	new_player_score::Int = sc[:id][:player_score]
	#new_opp_score::Int = sc[:id][:opp_score] # returned as-is, we can't pick opp ring

	# dict to return w/ game state delta - used for replay or add leaves to the tree
	_ret::Dict{Symbol, Union{Dict, Array, Matrix, Int, Symbol}} = Dict()

	#= OUTPUT structure - fields are added only if valued
	
		:scores_preMove_done => [ (:mk_locs => CI[], :ring_score => CI) ]
		:move_done => (:mk_add => (loc, player), :ring_move = (start, end, player))
		:mk_flip => CI[]
		:scores_done => [ (:mk_locs => CI[], :ring_score => CI) ]
		:scores_avail_opp => { :s_rows => Dict[], :s_sets => [ (1,2,4), (3,5)] } # scoring rows and their possible sets
		:scores_avail_player => { :s_rows => Dict[], :s_sets => [ (1,2,4), (3,5)] } # scoring-row: Dict(mk_locs, mk_sel, player)

		:new_game_state => Matrix
		:mode => Symbol (sames as how this fn was called)
		:new_player_score => Int
		:new_opp_score => Int (needed to check if game is over)

	=#
	
	################## EDITING unctions

	function scores_preMove_do!() # pre-move scoring - ie. opp scored for player

		for score in sc[:score_actions_preMove]
			
			# remove markers from game state
			pms_mks_locs::Vector{CartesianIndex} = score[:mk_locs]
			foreach(mk_id -> new_gs[mk_id] = "", pms_mks_locs)
	
			# remove ring
			pms_ring_loc = score[:ring_score]
			new_gs[pms_ring_loc] = ""
	
			# update player score
			new_player_score += 1 # NOTE -> HANDLE END GAME
	
			# update global dict
			pms = Dict(:mk_locs => pms_mks_locs, :ring_score => pms_ring_loc)
			setindex_container!(_ret, pms, :scores_preMove_done)
		end
	end
	

	function move_do!() # ring moved -> mk placement -> flipping

		### move ring & place marker
		
		start_loc::CartesianIndex = sc[:move_action][:start]
		end_loc::CartesianIndex = sc[:move_action][:end]

		# marker placed in start_move (same color as picked ring / player_id)
		@inbounds new_gs[start_loc] = _player_id == _B ? _MB : _MW
		
		# ring placed in end_move 
		@inbounds new_gs[end_loc] = ex_game_state[start_loc]

		### flip markers in the moving direction

		# retrieve search space for the starting point, ie. ring directions
		@inbounds r_dirs::Vector{Vector{CartesianIndex}} = _locs_searchSpace[start_loc]

		# spot direction/array that contains the ring 
		n::Int = findfirst(rd -> (end_loc in rd), r_dirs)
	
		# return flag + ids of markers to flip in direction of movement
		f_flip::Bool, mks_toFlip = search_markers_toFlip(new_gs, r_dirs[n])

		# flip markers in game state
		f_flip && for m_id in mks_toFlip
			@inbounds s::String = new_gs[m_id]
			if (s == _MB || s == _MW)
				@inbounds new_gs[m_id] = (s == _MW) ? _MB : _MW
			end
		end

		### update global dict
		
		mk_add = Dict(:loc => start_loc, :player_id => _player_id)
		ring_move = Dict(:start => start_loc, 
						 :end => end_loc, 						
						 :player_id => _player_id)
		
		_md = Dict(:mk_add => mk_add, :ring_move => ring_move)
		setindex!(_ret, _md, :move_done)	
	
		f_flip && setindex!(_ret, mks_toFlip, :mk_flip)	

	end
	

	function scores_do!() # post-move scoring

		for score in sc[:score_actions]

			# remove markers from game state
			sd_mks_locs::Vector{CartesianIndex} = score[:mk_locs]
			foreach(mk_id -> new_gs[mk_id] = "", sd_mks_locs)
	
			# remove ring
			sd_ring_loc::CartesianIndex = score[:ring_score]
			new_gs[sd_ring_loc] = ""
	
			# update player score
			new_player_score += 1 # NOTE -> HANDLE END GAME
	
			# update global dict
			sd = Dict(:mk_locs => sd_mks_locs, :ring_score => sd_ring_loc)
			setindex_container!(_ret, sd, :scores_done)
		
		end
	end

	
	function score_check!() # post-move scoring

		# search for possible scoring options
		scores::Dict{Symbol, Dict} = search_scores_gs(new_gs)

		# save scores information for each player
		sinfo_player = scores[Symbol(_player_id)]
		sinfo_opp = scores[Symbol(_opp_id)]

		# update global dict -> is there a score available for either player or opp?
		!(isempty(sinfo_player[:s_rows])) && setindex!(_ret, sinfo_player, :scores_avail_player)
		!(isempty(sinfo_opp[:s_rows])) && setindex!(_ret, sinfo_opp, :scores_avail_opp)

	end
	

	################## ACTING on input mode
	if fn_mode == :replay # whole turn
		
		f_scores_act_preMove && scores_preMove_do!() # -> win check
		f_move_act && move_do!()
		f_scores_act && scores_do!()

	elseif fn_mode == :move # single move -> check score

		f_move_act && move_do!()
		score_check!()
	
	elseif fn_mode == :inspect # just check

		score_check!()

	end

	# add updated player score
	setindex!(_ret, new_player_score, :new_player_score)
	# add opp score as-is -> needs to be given as input first to check for win
	#setindex!(_ret, new_opp_score, :new_opp_score)

	# add last game state and calling mode to _return
	setindex!(_ret, new_gs, :new_game_state)
	setindex!(_ret, fn_mode, :mode)
	

	return _ret

end

# ╔═╡ 156c508f-2026-4619-9632-d679ca2cae50
function sim_scenarioTrees(ex_gs::Matrix, nx_player_id::String, nx_player_score::Int)
# takes as input an ex game state (server format) and info of next moving player
# computes results for all possible moves of next moving player

	# to be returned
	scenario_trees::Dict{Symbol, Union{Dict, Array}} = Dict()

		#= return structure
		
			() :scores_preMove_avail => { :s_rows => Dict[], :s_sets => [] }
		
			!/() :treepots => [ ]
					:tree_summary => { :sc_flip => [] , :sc_score => []}
					:gs_id = { s_set, s_rings} # ID absent if only 1 tree
					:tree => { :start => :end => flags/deltas }
					:gs => Matrix{String} # starting gamestate for tree
		=#

	# ring id for this player
	_ring_id::String = nx_player_id == _W ? _RW : _RB

	# identify any pre-move score to be acted on - ie. left by previous player
	pms_sc_id = Dict( :id => Dict( 	:player_id => nx_player_id, 
									:player_score => nx_player_score))
	
	pm_scores_inspect = sim_new_gameState(ex_gs, pms_sc_id, :inspect)
	flag_pms::Bool = haskey(pm_scores_inspect, :scores_avail_player)

	# container for 
	treepots::Vector{Dict{Symbol, Union{Dict, Matrix}}} = [] 
	
	# act on score opportunity if present
	if flag_pms

		# there could be multiple choices for opp_score -> array of new game states
		@inbounds pms_options::Dict = pm_scores_inspect[:scores_avail_player]

		# save choices in tree to be returned 
		@inbounds setindex!(scenario_trees, pms_options, :scores_preMove_avail)

		# retrieve rings locations 
		_rings::Vector{CartesianIndex} = findall(==(_ring_id), ex_gs)

		# here we simulate possible combination sequences of scoring choices
		# retrieved from info[:s_sets] -> [ (1,2,4), (2,3,1), (4,5), ... ]
		@inbounds scoring_sets = pms_options[:s_sets]

		for sset in scoring_sets

			n::Int = length(sset) # number of scoring actions in the set sequence
			rings_comb::Vector{Vector{CartesianIndex}} = collect(combinations(_rings, n)) # [ [r1,r2], [r1,r3], ... ]
		
			for rc in rings_comb # new game state for each rings combination

				# container for pre-move score actions of this set, saved for replay
				preMove_actions_array::Vector{Dict} = []

				# identifier of future game state
				gs_id = Dict(:s_set => sset, :s_rings => Set{CartesianIndex}())

				# map rings to score actions within the set/sequence
				# order doesn't matter, end result is the same
				for (i, s_row_id) in enumerate(sset) 

					# prep preMove action data
					@inbounds pm_mk_locs = pms_options[:s_rows][s_row_id][:mk_locs]
					@inbounds pm_ring_score = rc[i] # num rings == length set
					
					score_action_inSeq = Dict( 	:mk_locs => pm_mk_locs,
												:ring_score => pm_ring_score)
					
					push!(preMove_actions_array, score_action_inSeq)

					# log removed rings, to identify game state later
					setindex_container!(gs_id, pm_ring_score, :s_rings, true)

					# MEMO - we use sets for id/brancing as:
					# order of removal for mks/rings doesn't change the resulting gs
					# so we avoid duplicate branches

				end

				# prep scenario data
				pms_actions = Dict( :id => Dict(:player_id => nx_player_id, 
									:player_score => nx_player_score),
									:score_actions_preMove => preMove_actions_array)

				# replay pre-move scores and get new game state
				post_pms_sim = sim_new_gameState(ex_gs, pms_actions, :replay)
				@inbounds post_pms_gs = post_pms_sim[:new_game_state]
				
				# save new gs with matching ID prepared before
				push!(treepots, Dict(:gs_id => gs_id, :gs => post_pms_gs))
				
					# NOTE -> still need to FLAG GAME AS over by score by Nth choice 
					# increase player score as pre-move score took place
					# nx_player_score += 1
	
			end
				
		end
		
	else # save the only available starting game state (no pre move score) 
		push!(treepots, Dict(:gs => ex_gs))
	end


		# ex_gs -> {scores_preMove_avail} -> [treepots] -> [tree] -> [scenarios]
	
		#= 	treepots = [ Dict( 	:gs_id => score_action_preMove
								:gs => game_state
								:tree => () 						)] =#
	
		# NOTE: if the game ends at the pre-move score, we flag it -> skip tree gen
	

	# we prepared the pots (starting game states), now we generate the scenario trees
	for pot in treepots

		# prep empty tree for each pots + its summary
		tree::Dict{CartesianIndex, Dict} = Dict()
		
		# summary for server/AI, saving scenario_ids for each flip/score case
		tree_sum = Dict(:flip_sc => [], # something flips
						:score_player_sc => [], # scoring ops player
						:score_opp_sc => [] ) # scoring ops opponent

		# extract gs details
		@inbounds gs::Matrix{String} = pot[:gs]

		
		# find legal moves for each of the rings start loc and save them
		rings::Vector{CartesianIndex} = findall(==(_ring_id), gs)
		nx_legal_moves::Dict{CartesianIndex, Vector{CartesianIndex}} = Dict()
			for r in rings
			 	@inbounds setindex!(nx_legal_moves, search_legal_moves(gs, r), r)
			end
		
		# for each start
		for move_start in rings # rings = keys of nx_legal_moves dict
			@inbounds for move_end in nx_legal_moves[move_start]
				if move_start != move_end # -> if ring not dropped in-place
					
					sc_id::Dict{Symbol, CartesianIndex} = Dict(:start => move_start, :end => move_end)

					# simulate new game state for start/end combination
					move = Dict(:id => Dict(:player_id => nx_player_id, 
											:player_score => nx_player_score),
											:move_action => sc_id)

					### NOTE: PLAYER SCORE NEEDS HANDLING

					# simulate move and check for scoring opportunities
					sim_res = sim_new_gameState(gs, move, :move)

					# save scenario sim results in tree (start -> end -> scenario)
					set_nested!(tree, sim_res, move_start, move_end)

					# Tree summary -> scenarios for scoring opportunities
					f_score_player::Bool = haskey(sim_res, :scores_avail_player)
					f_score_opp::Bool = haskey(sim_res, :scores_avail_opp)
	
					# save the id of each scenario accordingly
					f_score_player && push!(tree_sum[:score_player_sc], sc_id)
					f_score_opp && push!(tree_sum[:score_opp_sc], sc_id)

				else
					# save empty dict so same-loc drop is available in the tree -> !! rings with only such move available won't be in tree otherwise
					# impact on available legal moves in the client
					set_nested!(tree, Dict(), move_start, move_end)
				end
			end
		end

		# save tree in its pot
		setindex!(pot, tree, :tree)

		# save summary of tree in the branch
		setindex!(pot, tree_sum, :tree_summary)

	end
	
	# save tree of possible game moves for each starting game state
	setindex!(scenario_trees, treepots, :treepots)

	return scenario_trees

end

# ╔═╡ f1949d12-86eb-4236-b887-b750916d3493
function gen_newGame(vs_server = false)
# initializes new game, saves data server-side and returns object for client

	# generate random game identifier (only uppercase letters)
	game_id = randstring(['A':'Z'; '0':'9'], 6)

	# pick the id of the originating vs joining player -> should be a setting
	ORIG_player_id = rand([_W, _B]) 
	JOIN_player_id = (ORIG_player_id == _W) ? _B : _W

	# set next moving player -> should be a setting (for now always white)
	first_moving = _W 

	# generate random initial game state (server format)
	# true param => GENERATING STATES w/ 4MKS in a row for a randomly picked player
	gs = gen_random_gameState(4, 30)

	# RINGS
		# retrieves location ids in client format 
		whiteRings_ids = findall(==(_RW), gs) |> reshape_out
		blackRings_ids = findall(==(_RB), gs) |> reshape_out

		# prepare rings array to be sent to client
		white_rings = [Dict(:id => id, :player => _W) for id in whiteRings_ids]
		black_rings = [Dict(:id => id, :player => _B) for id in blackRings_ids]
		
		_rings = union(white_rings, black_rings)

	# MARKERS
		# retrieves location ids in client format 
		whiteMarkers_ids = findall(==(_MW), gs) |> reshape_out
		blackMarkers_ids = findall(==(_MB), gs) |> reshape_out
		
		white_mks = [Dict(:id => id, :player => _W) for id in whiteMarkers_ids]
		black_mks = [Dict(:id => id, :player => _B) for id in blackMarkers_ids]

		# prepare markers array to be sent to client
		_markers = union(white_mks, black_mks)
		
	# pre possible moves and scoring/flipping outcomes for each -> in client's format
	_scenario_trees = sim_scenarioTrees(gs, first_moving, 0) |> reshape_out_fields
	
	
	### package data for server storage

		game_status = :not_started

		# game identity
		_identity = Dict(:game_id => game_id,
						:game_type => (vs_server ? :h_vs_ai : :h_vs_h),
						:orig_player_id => ORIG_player_id,
						:join_player_id => JOIN_player_id,
						:init_dateTime => now(),
						:status => game_status,
						:end_dateTime => now(),
						:won_by => :undef,
						:won_why => :undef)
	
		# logs of game messages (one per player)
		_players = Dict(:orig_player_status => :not_available,
						:join_player_status => (vs_server ? :ready : :not_available),
						:orig_player_score => 0, 
						:join_player_score => 0)
		
		# first game state (server format)
		_srv_states = [gs]


		
		### package data for client
		_cli_pkg = Dict(:game_id => game_id,
						:orig_player_id => ORIG_player_id,
						:join_player_id => JOIN_player_id,
						:rings => _rings,
						:markers => _markers, 
						:scenario_trees => _scenario_trees,
						:turn_no => 1) # first game turn

		_first_turn = Dict( :turn_no => 1,
							:status => :open,
							:moving_player => first_moving)

	
		## package new game data for storage
		new_game_data = Dict(:identity => _identity,
							:players => _players, 
							:turns => Dict(:current => 1, :data => [_first_turn]),
							:server_states => _srv_states,
							:client_delta => [],
							:client_pkgs => [_cli_pkg],
							:ws_connections => Dict())

	
		
		# saves game to general log (DB?)
		save_newGame!(games_log_dict, new_game_data)


	println("LOG - New game initialized - Game ID $game_id")
	return game_id
	
end

# ╔═╡ a6c68bb9-f7b4-4bed-ac06-315a80af9d2e
function fn_new_game_vs_human(ws, msg)
# human client (originator) wants new game to play against a nother human

	# NOTE: msg input is now ignored, but in the future it could contain game options

	# generate and store new game data
	_new_game_id = gen_newGame()

	# save ws handler for originating player
	update_ws_handler!(_new_game_id, ws, true)
	
	# retrieve payload in client format 
	new_game_data = getLast_clientPkg(_new_game_id)

	_other_pld = Dict() # empty payload for other

	# return payload - requester, other
	return new_game_data, _other_pld

end

# ╔═╡ 32307f96-6503-4dbc-bf5e-49cf253fbfb2
function fn_new_game_vs_server(ws, msg)
# human client (originator) wants new game to play against server/AI
	

	# generate and store new game data
	_new_game_id = gen_newGame(true) 

	# save ws handler for originating player
	update_ws_handler!(_new_game_id, ws, true)

	# retrieve payload
	new_game_data = getLast_clientPkg(_new_game_id)

	_other_pld = Dict() # empty payload for other

	# return payload - requester, other
	return new_game_data, _other_pld


end

# ╔═╡ e0368e81-fb5a-4dc4-aebb-130c7fd0a123
function gen_new_clientPkg(game_id::String, nx_player_id::String)
# generates follow up responses for the client, whenever the preceding turn is completed by the other player or AI


	# retrieve latest game state (server format)
	gs = get_last_srv_gameState(game_id)

	# RINGS
		# retrieves location ids in client format 
		whiteRings_ids = findall(==(_RW), gs) |> reshape_out
		blackRings_ids = findall(==(_RB), gs) |> reshape_out

		# prepare rings array to be sent to client
		white_rings = [Dict(:id => id, :player => _W) for id in whiteRings_ids]
		black_rings = [Dict(:id => id, :player => _B) for id in blackRings_ids]
		
		_rings = union(white_rings, black_rings)

	# MARKERS
		# retrieves location ids in client format 
		whiteMarkers_ids = findall(==(_MW), gs) |> reshape_out
		blackMarkers_ids = findall(==(_MB), gs) |> reshape_out
		
		white_mks = [Dict(:id => id, :player => _W) for id in whiteMarkers_ids]
		black_mks = [Dict(:id => id, :player => _B) for id in blackMarkers_ids]

		# prepare markers array to be sent to client
		_markers = union(white_mks, black_mks)
	

	# simulates possible moves and outcomes for each -> in client's format
	ex_score = get_player_score(game_id, nx_player_id)
	
	_scenario_trees = sim_scenarioTrees(gs, nx_player_id, ex_score) |> reshape_out_fields
		
	### package data for client
	_cli_pkg = Dict(:game_id => game_id,
					:rings => _rings,
					:markers => _markers,
					:scenario_trees => _scenario_trees)
	
	
	# saves game to general log (DB?)
	save_new_clientPkg!(games_log_dict, game_id, _cli_pkg)


	println("LOG - New client pkg created for game: $game_id")
	
	
end

# ╔═╡ a7b92ca8-8a39-4332-bab9-ed612bf24c17
function fn_nextPlaying_payload(game_code::String)
# generate payload for next playing player
# assumes at least a move took place from previous player

	try 

		_next_player_id = get_last_moving_player(game_code)
	
		# gen new game data for client
		gen_new_clientPkg(game_code, _next_player_id)
	
		# retrieve last client package (just generated)
		_pkg = getLast_clientPkg(game_code)
	
		# retrieve states delta
		_client_delta = getLast_clientDelta(game_code)
	
			# append delta to package for client
			setindex!(_pkg, _client_delta, :delta)

	
		return _pkg::Dict

	catch e

		throw(error("ERROR generating payload for next move, $e"))

	end

end

# ╔═╡ f55bb88f-ecce-4c14-b9ac-4fc975c3592e
function update_serverStates!(_game_code, _player_id, turn_recap, ai_play = false)
# updates server state for game given a scenario by a player 
# replays move server-side and logs score
# generates delta payload info 

	#= SCENARIO PICK data format OLD (turn_recap)

		{ 	start: start_move_index, 
            end: drop_loc_index,
            mk_sel_pick: scoring_mk_sel_picked, // default to -1
            ring_removed: scoring_ring_picked, // defaults to -1
            completed_turn_no: _played_turn_no
                                }; 

		SCENARIO PICK data format NEW (same used internally by sim_game_state)

		score_action_preMove : { mk_sel: -1, mk_locs: [], ring_score: -1 },
		move_action: { start: start_move_index, end: drop_loc_index },
		score_action: { mk_sel: -1, mk_locs: [], ring_score: -1 }, 
		completed_turn_no: _played_turn_no       

	=#
	
	#@info turn_recap

	## clean up and convert keys/coords when input comes from client
	# drops non actionable fields and dicts w/ default values (-1)
	# server/ai_play is instead used as-is
	
	srv_turn_recap = ai_play ? turn_recap : strip_reshape_in_recap(turn_recap)	
	
	#@info srv_turn_recap

	# retrieve old game state and last moving
	ex_gs = get_last_srv_gameState(_game_code)

	# sim new game state with turn recap sent from client (as-is)
	_sc_id = Dict( :player_id => _player_id, 
					:player_score => get_player_score(_game_code, _player_id))

	# add pre-move/move/score info from client
	_sc_info = setindex!(srv_turn_recap, _sc_id, :id)
	
	#@info _sc_info
	new_gs_sim = sim_new_gameState(ex_gs, _sc_info, :replay)
	#@info new_gs_sim
	
	# update player score
	edit_player_score!(_game_code, _player_id, new_gs_sim[:new_player_score])

	# save new game state to log
	push!(games_log_dict[_game_code][:server_states], new_gs_sim[:new_game_state])

	# save delta for client (w/ client loc coordinates)
	push!(games_log_dict[_game_code][:client_delta], reshape_out_fields(new_gs_sim))
	
	println("LOG - Server game state and delta updated")


end

# ╔═╡ 8e1673fe-5286-43cd-8830-fba353f1cd89
function prune_tree_fn(d::Dict{CartesianIndex, Dict}, sc::Dict)::Dict{CartesianIndex, Dict}
# deletes the nested level in a dictionary sc(A -> B)
# deletes also the parent A if B was the only item
# returns a modified copy of the original collection

	_ret = deepcopy(d)

	_a_kp = sc[:start]
	_b_kp = sc[:end]

	for (ak, av) in d
		for (bk, bv) in d[ak]
			
			if ak == _a_kp && bk == _b_kp # delete nested key
				delete!(_ret[ak], bk)
				
				if isempty(_ret[ak]) # delete parent if empty
					delete!(_ret, ak)
				end
			end

		end
	end

	return _ret
end

# ╔═╡ ea7779ea-cd11-4f9e-8022-ff4f370ffddd
function inspect_trees_sums(treepots::Vector)::Dict{Symbol, Bool}
# given the treepots array of sim results, inspects summaries of all the trees in it
# returns flags for the presence of scoring opportunities for either player/opponent
# note: input tree is simulated from the point of view of the 'player'

# data: sim -> :treepots -> :tree_summary -> [score_sc opp/player]

f_opp = findfirst(tp -> !isempty(tp[:tree_summary][:score_opp_sc]), treepots)
f_player = findfirst(tp -> !isempty(tp[:tree_summary][:score_player_sc]), treepots)

	OPP_score_possible = isnothing(f_opp) ? false : true
	PLAYER_score_possible = isnothing(f_player) ? false : true

	return Dict(:opp_score_possible => OPP_score_possible,
				:player_score_possible => PLAYER_score_possible)

end

# ╔═╡ 3d09a15d-685b-4d9b-a47f-95067441928d
function get_new_gs(tree::Dict, move_sc::Dict)::Matrix
# given a reference tree, return the new_game_state given a start/end

	return tree[move_sc[:start]][move_sc[:end]][:new_game_state]

end

# ╔═╡ e785f43f-0902-4b7b-874b-bf1c09438970
function find_treepotIndex(gs_id::Dict, treepots::Vector)::Int
# one or more scoring actions might have taken place at the premove stage
# pick relevant starting game state for 'move' phase of the turn
	
# since arrays are order-sensitive, we use sets for gs identification => order of scoring actions doesn't change final gamestate
# we match on the sequence set of scoring rows ids and 
	
	# locate treepot in array
	treepot_index = findfirst(tp -> tp[:gs_id] == gs_id, treepots)

	# throw error if not found - it shouldn't happen
	if isnothing(treepot_index) 
		throw(error("ERROR - Treepot index for $gs_id can't be found"))
	else
		return treepot_index
	end
	
end

# ╔═╡ fdb40907-1047-41e5-9d39-3f94b06b91c0
function play_turn_server(game_code::String, srv_player_id::String, prev::Int=0)::Dict
# assumes turns and game state are updated
# input srv_player_id should be of the server/AI

try

	_time_start::DateTime = now()

	# returning value
	turn_recap = Dict()

#= output format for _turn_recap:

	note: fields only added if valued/done/non-default
	
	score_actions_preMove : [ { mk_sel: -1, mk_locs: [], ring_score: -1 } ],
	move_action: { start: start_move_index, end: drop_loc_index },
	score_actions: [ { mk_sel: -1, mk_locs: [], ring_score: -1 } ], 

=#

	# last game state in srv format
	ex_gs::Matrix{String} = deepcopy(get_last_srv_gameState(game_code, prev))
	
	# scenarios
	ex_srv_score::Int = get_player_score(game_code, srv_player_id)
	sim::Dict{Symbol, Any} = sim_scenarioTrees(ex_gs, srv_player_id, ex_srv_score)

	# keep track of score across server play
	last_srv_score::Int = deepcopy(ex_srv_score) 

	# ring id for this player
	_ring_id::String = srv_player_id == _W ? _RW : _RB

	
	# heuristic
	#=
	- if you have a score opportunity pre-move, do it
	- at every step, exclude from possible choices any that could result in scoring for the opponent - unless it will be the winning move
	- if you can, score
	- if can't, minmax -> pick first available move action from best to worst

	=#

	# scenarioTree data structure
	#=

		g_tree_sum = 	:score_player_sc = > [], # score
						:score_opp_sc => [] # score for the opponent 

		each array contains move scenarios desc = { :start => CI, :end => end }

		at each tree leaf (start, end) we have a turn recap and new game state

	=#


	### PRE-MOVE
	# take any preMove scores if available
	preMove_score_actions = Dict[]
	move_gs_id = Dict() # to be used later -> pick starting game state and its tree
	
	if haskey(sim, :scores_preMove_avail) # support for double scoring

		# extract data
		@inbounds pm_scores_info = sim[:scores_preMove_avail]

		# pick random sequence set and log it
		@inbounds scoring_set_pick::Set{Int} = rand(pm_scores_info[:s_sets])
		setindex!(move_gs_id, scoring_set_pick, :s_set)

		# rings array to pick from
		ex_rings_locs::Vector{CartesianIndex} = findall(==(_ring_id), ex_gs)

		for s in scoring_set_pick

			# pick ring and remove it from array -> can't pick it again
			ring_score = pop!(ex_rings_locs)

			# prep pre-move scenario
			@inbounds pm_sc = Dict( :mk_locs => pm_scores_info[:s_rows][s][:mk_locs],
									:ring_score => ring_score )
		
			# save local array for id following starting state
			push!(preMove_score_actions, pm_sc)

			# add to the game state id
			setindex_container!(move_gs_id, ring_score, :s_rings, true)
	
			# increase score
			last_srv_score += 1

			# NOTE: check if game is over by score -> break sequence
			
		end


		# save all moves in turn recap
		setindex!(turn_recap, preMove_score_actions, :score_actions_preMove)
		
	end


	__pick_txt::String = "" 

	### MOVE

	# action sc, w/ empty default used as a true/false later
	move_action::Dict{Symbol, CartesianIndex} = Dict() 
	
	# picking game state and tree based on previous choices
	treepot_id::Int = 1 # default/only tree

	if !isempty(move_gs_id) # pick specific tree
		treepot_id = find_treepotIndex(move_gs_id, sim[:treepots]::Vector)
	end	

	# extract tree
	@inbounds treepot = sim[:treepots][treepot_id] 
	@inbounds tree::Dict{CartesianIndex,Dict{CartesianIndex,Dict}} = treepot[:tree]

	# starting game state and rings for move
	@inbounds gs_move::Matrix{String} = treepot[:gs] 
	rings_locs::Vector{CartesianIndex} = findall(==(_ring_id), gs_move) 

	# extract info from summary
	@inbounds score_player_sc::Vector{Dict{Symbol, CartesianIndex}} = treepot[:tree_summary][:score_player_sc]
	@inbounds score_opp_sc::Vector{Dict{Symbol, CartesianIndex}} = treepot[:tree_summary][:score_opp_sc]

	## TRY SCORING
	score_actions = Dict[]

	## prioritize moving actions that result in a score
	# but don't score for the opponent
	valid_scoring_sc::Vector{Dict} = setdiff(score_player_sc, score_opp_sc)

	# criterias for score pick
	if !isempty(score_player_sc) && isempty(valid_scoring_sc) 
		# # no net scoring options -> pick one only if winning move
		if last_srv_score == 2 # to be made configurable, for quick opt & 2x scores
			move_action = rand(score_player_sc)
		end
	elseif !isempty(valid_scoring_sc)
		# valid scoring options
		move_action = rand(valid_scoring_sc)
	end

		# if we have a scoring move -> save info {mk_locs, ring_score} for replay
		if !isempty(move_action)

			
			m_start::CartesianIndex = move_action[:start]
			m_end::CartesianIndex = move_action[:end]

			# extract scoring info
			@inbounds s_rows = tree[m_start][m_end][:scores_avail_player][:s_rows]
			@inbounds s_sets = tree[m_start][m_end][:scores_avail_player][:s_sets]

			# pick a random sequence among the sets
			set_pick::Set{Int} = rand(s_sets)

			# a ring was moved -> swap start w/ end
			new_rings_locs::Vector{CartesianIndex} = replace(rings_locs, m_start => m_end)

			# act on all the scores
			for s_row_id in set_pick

				# pick and remove ring from array
				ring_score::CartesianIndex = pop!(new_rings_locs)

				# save scoring choice - random for scoring ring
				@inbounds score_action_pick = Dict(:ring_score => ring_score,
											:mk_locs => s_rows[s_row_id][:mk_locs])

				# save choice in array
				push!(score_actions, score_action_pick)

				# increase score
				last_srv_score += 1
				# NOTE -> should check for game ending at each score increase
	
				__pick_txt = "score" # logging

			end

			# save all scoring actions in turn recap
			setindex!(turn_recap, score_actions, :score_actions)

		end

	## NO SCORING POSSIBLE -> PLACE/FLIP : minimax depth 2
	len_cm = 0 # num of candidate moves
	max_i = 0 # moves explored
	if isempty(move_action) # no move action taken yet 


		# split move candidates in these groups
		candidate_moves_sc::Vector{Dict} = [];  # candidate moves
			best_sc::Vector{Dict} = []; # closer to score for us
			neutral_sc::Vector{Dict} = []; # no close to score for us or opponent
			risky_sc::Vector{Dict} = []; # closer for both
			bad_sc::Vector{Dict} = []; # closer for opponent only
			worst_sc::Vector{Dict} = []; # we score for the opponent
	

		opp_player_id::String = srv_player_id == _W ? _B : _W
		
		# traverse the whole tree, create candidate move sc to categorize later
		@inbounds for start_k in eachindex(tree), end_k in eachindex(tree[start_k])
			# exlude same-loc-drop moves
			if start_k != end_k
				sc::Dict{Symbol, CartesianIndex} = Dict(:start => start_k,:end => end_k)
				push!(candidate_moves_sc, sc)
			end
		end

		# categorize moves
		len_cm::Int = candidate_moves_sc |> length
		for (i, sc) in enumerate(candidate_moves_sc) 

			max_i::Int = i # keep track of how many scenarios we explore
			
			@inbounds new_gs::Matrix{String} = get_new_gs(tree, sc)
			new_sim::Dict = sim_scenarioTrees(new_gs, opp_player_id, 0) 
			# any opp score is fine for now, as any score is put in worst

			# prevent states that can lead opponent to score next
				# no scores_preMove_avail (root)
				# no score_player_sc in (any tree) 

			if haskey(new_sim, :scores_preMove_avail) # worst if score avail for opp
				push!(worst_sc, sc) 
				@goto skip_sc_inspection
			end

			# inspect possible scoring outcomes 
			sim_check::Dict{Symbol, Bool} = inspect_trees_sums(new_sim[:treepots])

			# in this case, the 'other' is the player
			server_score_px = sim_check[:opp_score_possible]
			user_score_px = sim_check[:player_score_possible]

			# 2x2 possible outcomes: best > neutral > risky > bad 
			f_best::Bool = server_score_px == true && user_score_px == false
			f_neutral::Bool = server_score_px == false && user_score_px == false
			f_risky::Bool = server_score_px == true && user_score_px == true
			f_bad::Bool = server_score_px == false && user_score_px == true

			# categorize sc, break at first best choice
			f_best && push!(best_sc, sc) 
			f_neutral && push!(neutral_sc, sc)
			f_risky && push!(risky_sc, sc)
			f_bad && push!(bad_sc, sc)

			# break at first best choice (could be refined for double score)
			if f_best
				move_action = sc
				__pick_txt = "best"
				break
			end
			
			@label skip_sc_inspection

		end		


		## NO BEST MOVE -> pick from: neutral > risky > bad > worst
		if isempty(move_action)

			if !isempty(neutral_sc) # NEUTRAL
				move_action = rand(neutral_sc)
				__pick_txt = "neutral"

			elseif !isempty(risky_sc) # RISKY
				move_action = rand(risky_sc)
				__pick_txt = "risky"

			elseif !isempty(bad_sc) # BAD
				move_action = rand(bad_sc)
				__pick_txt = "bad"

			elseif !isempty(worst_sc) # WORST
				move_action = rand(worst_sc)
				__pick_txt = "worst"

			end
		end
	
	end


	# save move action in turn recap (one should be always be found)
	setindex!(turn_recap, move_action, :move_action)

		# logging
		_runtime::Int = (now() - _time_start).value
		_expl_rate::Float64 = round(max_i/len_cm*100, digits=2)
	
		println("LOG - AI play, $__pick_txt pick - runtime: $(_runtime)ms, expl.rate: $(_expl_rate)%, # sc: $len_cm")
	
	return turn_recap

catch e
	@error "ERROR during server play, $e"
	stacktrace(catch_backtrace())
end

end

# ╔═╡ 2bcc0cf2-61b5-438f-86ea-331b565902f5
play_turn_server("UMG6S8", "B",0)

# ╔═╡ e6cc0cf6-617a-4231-826d-63f36d6136a5
function mark_player_ready!(game_code::String, who::Symbol)

# marks player as ready

	
	# which status to update? 
	_which_status = (who == :originator) ? :orig_player_status : :join_player_status
		
	# update status
	games_log_dict[game_code][:players][_which_status] = :ready
	
	

end

# ╔═╡ cd06cad4-4b47-48dd-913f-61028ebe8cb3
function mark_player_resigned!(game_code::String, who::Symbol)

# marks player resigned

	
	# which status to update? 
	_which_status = (who == :originator) ? :orig_player_status : :join_player_status
		
	# update status
	games_log_dict[game_code][:players][_which_status] = :resigned
	
	

end

# ╔═╡ 88616e0f-6c85-4bb2-a856-ea7cee1b187d
function game_runner(msg)
# this function takes care of orchestrating messages and running the game
# scenario: a game has been created and one or both players have joined
# players may have made or not a move, and asking to advance the game

	# retrieve game and caller move details
	_msg_code = msg[:msg_code]
	_game_code = msg[:payload][:game_id]
	_player_id = msg[:payload][:player_id]
	_who = whos_player(_game_code, _player_id) # :originator || :joiner
	_game_vs_ai_flag = is_game_vs_ai(_game_code)
	_turn_recap = msg[:payload][:turn_recap] # false || { :move_action {}, :score_actions [{}], :preMove_score_actions [{}] }
	
	# println("SRV Game runner - scenario pick: ", _turn_recap)


	# default variable, is overwritten later
	_end_check = Dict(:end_flag => false)


	## EMPTY RESPONSE PAYLOADS
	
		# template payload for playing player (+ turn info)
		_PLAY_payload::Dict{Symbol, Any} = Dict(key_nextActionCode => CODE_play)
		
		# template payload for waiting player
		_WAIT_payload::Dict{Symbol, Any} = Dict(key_nextActionCode => CODE_wait)
		
		# template payload in case game ends
		_END_payload::Dict{Symbol, Any} = Dict(key_nextActionCode => CODE_end_game)
	
		# empty responses for CALLER / OTHER
		_caller_pld = Dict()
		_other_pld = Dict()


	# update player status 
		if _msg_code == CODE_advance_game # player stays ready
			mark_player_ready!(_game_code, _who)
		
		elseif _msg_code == CODE_resign_game # player resigned
			
			# flag player as resigned
			mark_player_resigned!(_game_code, _who)
		
			# mark that game is over by resignation
			_end_check = update_game_end!(_game_code)
		
			# add ending info to template payload
			merge!(_END_payload, _end_check)
		
			# inform both players with same base payload (END)
			_PLAY_payload = copy(_END_payload)
			_WAIT_payload = copy(_END_payload)
		end

	
	## REFLECT LAST MOVE
		if _turn_recap != false
		
			# update server state & generates delta for move replay
			update_serverStates!(_game_code, _player_id, _turn_recap)
			
			# move turn due to scenario being picked
			advance_turn!(_game_code, _turn_recap[:completed_turn_no])

				# check if game is over after last move (by score)
				_end_check = update_game_end!(_game_code)
				println("SRV - end check $_end_check")
				
				if _end_check[:end_flag]

					# add ending info to template payload
					merge!(_END_payload, _end_check)

					# inform both players with same base payload (END)
					_PLAY_payload = copy(_END_payload)
					_WAIT_payload = copy(_END_payload)

				end
			
			if !_game_vs_ai_flag # human vs human games (just pass on changes)

				# generate payload for next moving player
				merge!(_PLAY_payload, fn_nextPlaying_payload(_game_code))
		
				# add turn information
				setindex!(_PLAY_payload, get_last_turn_details(_game_code)[:turn_no], :turn_no)

			end
		end
	

	## HANDLE PLAY AND RESPONSES 
		if _game_vs_ai_flag # vs AI, make AI play and pass changes to human

			if is_human_playing_next(_game_code) # human plays current turn
				
				println("SRV - HUMAN plays next, just passing on changes")

				# add turn information
				setindex!(_PLAY_payload, get_last_turn_details(_game_code)[:turn_no], :turn_no)

				# inform human it's their turn
				_caller_pld = _PLAY_payload
				
			else # AI plays current turn
				
				println("SRV - AI plays")

				if _end_check[:end_flag] # AI loses by score or human resigned

					# alter caller payload, PLAY was modified at first end_check
					_caller_pld = _PLAY_payload

				else # AI moves

					_ai_player_id = get_last_moving_player(_game_code)

					# move by SERVER/AI > sync server data
					_pick = play_turn_server(_game_code, _ai_player_id)
					update_serverStates!(_game_code, _ai_player_id, _pick, true)
					
					# mark turn completed
					_no_turn_played_by_ai = get_last_turn_details(_game_code)[:turn_no]

					
					# re-check if last AI play ended game
					_end_check = update_game_end!(_game_code)
					println("SRV - end check $_end_check")
				
					if _end_check[:end_flag] # AI beats human w/ last move
	
						# add ending info to template payload
						merge!(_END_payload, _end_check)
	
						# alter base payload
						_PLAY_payload = copy(_END_payload)

					else

						# prep new turn for human
						advance_turn!(_game_code, _no_turn_played_by_ai)
						_new_turn_info = get_last_turn_details(_game_code)[:turn_no]

						# add turn information
						setindex!(_PLAY_payload, _new_turn_info, :turn_no)
						
					end 

					
					# prepare payload for client (delta information)
					merge!(_PLAY_payload, fn_nextPlaying_payload(_game_code))

					# alter called payload
					_caller_pld = _PLAY_payload
				end
			end

		else # vs HUMAN, just handle payload swap - payload generated before

			# if both players ready 
			if check_both_players_ready(_game_code) 
	
				# check if the caller is who plays next
				_caller_plays = _is_playing_next(_game_code, _player_id)
		
				# assigns payloads accordingly
				_caller_pld = _caller_plays ? _PLAY_payload : _WAIT_payload
				_other_pld = _caller_plays ? _WAIT_payload : _PLAY_payload 
			
			elseif _msg_code == CODE_resign_game # if one resigned

				# inform both players with same END payload (modified above)
				_caller_pld = _END_payload
				_other_pld = _END_payload
				
			else # both players not ready, tell the caller to wait
				_caller_pld = _WAIT_payload
				
			end

		end		


	# return CALLER and OTHER payload
	return _caller_pld, _other_pld

end

# ╔═╡ ca346015-b2c9-45da-8c1e-17493274aca2
function fn_advance_game(ws, msg)
# human client asking to advance the game status (either ready or just made a move)
	
	try 
		
		# is this orig or joiner ?
		_who = whos_player(msg[:payload][:game_id], msg[:payload][:player_id])
		_is_originator = (_who == :originator) ? true : false
	
		# save ws handler for originating vs joining player
		update_ws_handler!(msg[:payload][:game_id], ws, _is_originator)

		# generate responses for caller & other
		_resp_caller, _resp_other = game_runner(msg)
	
		return _resp_caller, _resp_other
	

	catch e

		println("ERROR in fn_advance_game - $e")
	end
end

# ╔═╡ 7316a125-3bfe-4bac-babf-4e3db953078b
begin

	# matching each code to a function call
	codes_toFun_match::Dict{String, Function} = Dict(
									CODE_new_game_human => fn_new_game_vs_human,
									CODE_new_game_server => fn_new_game_vs_server,
									CODE_join_game => fn_join_game,
									CODE_advance_game => fn_advance_game,
									CODE_resign_game => fn_advance_game
									)

	# note: advance and resign both converge on game_runner, case handled there

	# array of codes
	allowed_CODES = collect(keys(codes_toFun_match))

end

# ╔═╡ 064496dc-4e23-4242-9e25-a41ddbaf59d1
function msg_handler(ws, msg, msg_log)

# handles messages depending on their code
# every incoming message should have an id and code - if they're missing, throw error
	
	# save incoming message
	setindex!(msg, "received", :type)
	push!(msg_log, msg)

	# try retrieving specific values (msg header)
	_msg_id = get(msg, :msg_id, nothing)
	_msg_code = get(msg, :msg_code, nothing)
	_msg_payload = get(msg, :payload, nothing)

	# if messages are valid, run matching function 
	if !isnothing(_msg_id) && (_msg_code in allowed_CODES)

		try

			# all functions return two dictionaries
			_pld_caller, _pld_other = codes_toFun_match[_msg_code](ws, msg)

				# reply to caller, including code-specific response
				msg_dispatcher(ws, _msg_id, _msg_code, _pld_caller)
				
			# if payload is not empty, assumes game already exists
			# game vs other human player, informed with other payload
			if !isempty(_pld_other) && !is_game_vs_ai(_msg_payload[:game_id])

				# game and player id are in the original msg as game exists
				_game_id = _msg_payload[:game_id]
				_player_id = _msg_payload[:player_id]

				# identify caller
				_who = whos_player(_game_id, _player_id)
				_is_caller_originator = (_who == :originator) ? true : false

				# retrieve ws handler for other
				_other_identity_flag = !_is_caller_originator
				_ws_other = get_ws_handler(_game_id, _other_identity_flag)

				msg_dispatcher(_ws_other, _msg_id, _msg_code, _pld_other)
			
			end

		catch e

			# reply to client with error
			msg_dispatcher(ws, _msg_id, _msg_code, Dict(:server_msg => "Error when handling request, $e"), false)

			println("ERROR in msg_handler - $e")

		end


	else

		# if fields are missing, also give error
		msg_dispatcher(ws, _msg_id, _msg_code, Dict(:server_msg => "Error, missing msg_id and/or invalid msg_code"), false)

		
	end


end

# ╔═╡ 1ada0c42-9f11-4a9a-b0dc-e3e7011230a2
function start_ws_server(ws_array, _log, _log_OG)

	try 

		# start new server 
		ws_server = WebSockets.listen!(ws_ip, ws_port; idle_timeout_enabled = false) do ws

			# iterate over incoming messages
			for msg in ws

				# save received messages as-is
				push!(_log_OG, msg) 
				
				# parse incoming msg as JL Dict -> then keys from String to Symbol
				# we could halve time (~4 -> 2 micro_s) if skip key conversion
				# but would need to use Strings when reading client's msgs
				_msg_jl = dict_keys_to_sym(JSON3.read(msg, Dict))
				
				
				# dispatch parsed message to message handler
				# handler takes care of generating response payload and replying,
				# as well as handling potential errors
				msg_handler(ws, _msg_jl, _log)

			end
		end

		# saves server handler in array
		push!(ws_array, ws_server)

		println("WebSocket server $(objectid(ws_server.task)) START at $(now())")

	catch e
		println("ERROR starting server - $e")
		throw(e)
	end

end

# ╔═╡ 91c35ba0-729e-4ea9-8848-3887936a8a21
# this function is mostly needed because due to the reactive nature of Pluto,
# anytime we change something in the child functions (parameters) the ws server is initiated again
# so we're killing the previous one to avoid errors (listening on same ip/port)
	
function reactive_start_server(ws_array, _msg_log, _msg_log_OG)

	# start websocket server if there's none
	if isempty(ws_array)

		start_ws_server(ws_array, _msg_log, _msg_log_OG)

	# otherwise, close all open ones existing and start a new one
	else

		# check task status 
		_open_ws = filter(ws -> !istaskdone(ws.task), ws_array)
		
		for ws in _open_ws
			HTTP.forceclose(ws)
			println("WebSocket server $(objectid(ws.task)) STOP at $(now())")
		end
		
		
		sleep(0.025)
		start_ws_server(ws_array, _msg_log, _msg_log_OG)
		
	end

end

# ╔═╡ 8b6264b0-f7ea-4177-9700-30072d4c5826
reactive_start_server(ws_servers_array, ws_messages_log, ws_messages_log_OG)

# ╔═╡ 2a63de92-47c9-44d1-ab30-6ac1e4ac3a59
function test_ws_client()

	msg_sent_counter = 0
	msg_rec_counter = 0

	try
		# open ws
		WebSockets.open("ws://$ws_test_ip:$ws_test_port") do ws
			
			println("connection opened")

			for i in 1:10 # max of 10 messages sent
				# send  message to server
				msg = "input by client__"
				send(ws, msg)
				msg_sent_counter += 1
		
				println("--- New message sent, total: $msg_sent_counter")

	
				# handle incoming responses from server
				for msg in ws
	
					msg_rec_counter +=1
					println("--- New message received, total: $msg_rec_counter")
	
					if contains(msg, "close")
						#closing websockets
						println("message received from server:")
						println(msg)
						println("closing socket")
						close(ws)
					else
						# receive msg and do something
						println("message received from server:")
						println(msg)
					end
		

					# wait before sending other messages
					sleep(2)
				
				end

				# iteration

			end
	
			println("end of ws iteration")
	             
		end

	catch

		throw(error("ERROR occurred"))
		
	end

end

# ╔═╡ db1ce9bc-0593-4dd7-b905-a14295d47533
md"### TODO"

# ╔═╡ 5ce26cae-4604-4ad8-8d15-15f0bfc9a81a
md"#### Open issues "

# ╔═╡ 9b8a5995-d8f0-4528-ad62-a2113d5790fd
#=

- better end detection (51 mks) and 'draw' option
- game history in client (snapshots <> navigation while no animations in play)
- uniform handling/naming of originator vs joiner
- clients disconnecting / non-responsive are not handled / websocket disconneting
- should I use a DB?
- perf optimizations
- revise github readme + add note for suggestions -> or alt text/hover on page?

=#

# ╔═╡ c9d90fd5-4b65-435f-82e7-324340f31cd8
# ╠═╡ disabled = true
#=╠═╡
using Profile, PProf
  ╠═╡ =#

# ╔═╡ 24185d12-d29c-4e72-a1de-a28319b4d369
# make it wait forever
println("Service running")
wait(Condition())

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
Combinatorics = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
JET = "c3a54625-cd67-489e-a8e7-0a5a0ff4e31b"
JSON3 = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"

[compat]
BenchmarkTools = "~1.4.0"
Combinatorics = "~1.0.2"
HTTP = "~1.10.1"
JET = "~0.8.24"
JSON3 = "~1.14.0"
StatsBase = "~0.33.21"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.0"
manifest_format = "2.0"
project_hash = "69f18d64fc8c683b2f249253fff556ae4cc3b75a"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "f1f03a9fa24271160ed7e73051fba3c1a759b53f"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.4.0"

[[deps.BitFlags]]
git-tree-sha1 = "2dc09997850d68179b69dafb58ae806167a32b1b"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.8"

[[deps.CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "c0216e792f518b39b22212127d4a84dc31e4e386"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.3.5"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "cd67fc487743b2f0fd4380d4cbd3a24660d0eec8"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.3"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "886826d76ea9e72b35fcd000e535588f7b60f21d"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.10.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+1"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "8cfa272e8bdedfa88b6aefbbca7c19f1befac519"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.3.0"

[[deps.DataAPI]]
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "ac67408d9ddf207de5cfa9a97e114352430f01ed"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.16"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "dcb08a0d93ec0b1cdc4af184b26b591e9695423a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.10"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "abbbb9ec3afd783a7cbd82ef01dcd088ea051398"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.1"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.JET]]
deps = ["InteractiveUtils", "JuliaInterpreter", "LoweredCodeUtils", "MacroTools", "Pkg", "PrecompileTools", "Preferences", "Revise", "Test"]
git-tree-sha1 = "9587e44f478b5fddc70fc3baae60a587deaa3a31"
uuid = "c3a54625-cd67-489e-a8e7-0a5a0ff4e31b"
version = "0.8.24"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "PrecompileTools", "StructTypes", "UUIDs"]
git-tree-sha1 = "eb3edce0ed4fa32f75a0a11217433c31d56bd48b"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.14.0"

    [deps.JSON3.extensions]
    JSON3ArrowExt = ["ArrowTypes"]

    [deps.JSON3.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "04663b9e1eb0d0eabf76a6d0752e0dac83d53b36"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.9.28"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "7d6dd4e9212aebaeed356de34ccf262a3cd415aa"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.26"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "c1dd6d7978c12545b4179fb6153b9250c96b0075"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.3"

[[deps.LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "0b8cf121228f7dae022700c1c11ac1f04122f384"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "2.3.2"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "b211c553c199c111d998ecdaf7623d1b89b69f93"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.12"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+2"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "51901a49222b09e3743c65b8847687ae5fc78eb2"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.1"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "cc6e1927ac521b659af340e0ca45828a3ffc748f"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.12+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00805cd429dcb4870060ff49ef443486c262e38e"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Revise]]
deps = ["CodeTracking", "Distributed", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "Pkg", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "3fe4e5b9cdbb9bbc851c57b149e516acc07f8f72"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.5.13"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "ca4bccb03acf9faaf4137a9abc1881ed1841aa70"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.10.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
git-tree-sha1 = "1fbeaaca45801b4ba17c251dd8603ef24801dd84"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.10.2"
weakdeps = ["Random", "Test"]

    [deps.TranscodingStreams.extensions]
    TestExt = ["Test", "Random"]

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╠═69c4770e-1091-4744-950c-ed23deb55661
# ╠═6f0ad323-1776-4efd-bf1e-667e8a834f41
# ╠═e68b41fc-cbf5-477f-b211-2462d835def0
# ╠═c2797a4c-81d3-4409-9038-117fe50540a8
# ╠═13cb8a74-8f5e-48eb-89c6-f7429d616fb9
# ╠═70ecd4ed-cbb1-4ebd-85a8-42f7b072bee3
# ╠═bd7e7cdd-878e-475e-b2bb-b00c636ff26a
# ╠═f6dc2723-ab4a-42fc-855e-d74915b4dcbf
# ╠═43f89626-8583-11ed-2b3d-b118ff996f37
# ╠═1df30830-1a44-49f5-bb9a-309a8e9f2274
# ╠═9505b0f0-91a2-46a8-90a5-d615c2acdbc1
# ╠═cd36abda-0f4e-431a-a4d1-bd5366c83b9b
# ╟─2d69b45e-d8e4-4505-87ed-382e45bebae7
# ╟─48bbc7c2-ba53-41cd-9b3c-ab3faedfc6b0
# ╠═c96e1ee9-6d78-42d2-bfd6-2e8f88913b37
# ╠═b6292e1f-a3a8-46d7-be15-05a74a5736de
# ╟─55987f3e-aaf7-4d85-a6cf-11eda59cd066
# ╟─d996152e-e9e6-412f-b4db-3eacf5b7a5a6
# ╠═ff94655f-3603-4553-9ca3-e1dec83361b8
# ╠═dffecc3d-4737-4bf3-b109-882687b2e361
# ╠═bfb15937-a3b0-434d-ac5e-0d6d6b42e92e
# ╠═856b71d6-130e-4312-9a51-62f04d97a02c
# ╠═5fcd1944-57c8-4923-8f04-fc9ed24cd25c
# ╠═b2387e60-5107-4f66-924f-ff56e6127037
# ╠═6ba97a86-9602-4291-9a78-1875ee80ddc4
# ╠═e7afbb50-f343-47df-88c9-88a7ff336ea1
# ╠═37ff4698-4418-4abc-b726-c5f719b8f792
# ╠═abb1848e-2ade-49e7-9b15-a4c94b2f9cb7
# ╟─403d52da-464e-42df-8739-269eb5f98df1
# ╟─387eeec5-f483-48af-a27c-468683fe497b
# ╟─c1ae2819-974f-4209-8cf8-3fa98bc9cf93
# ╠═f6811e34-8576-4e1f-9638-79652b30aef3
# ╠═49ff65f9-8ead-448f-8a44-1a741c20bbc5
# ╟─6e7ab4f4-7c52-45bc-a503-6bf9cb0d7932
# ╠═e767b0a7-282f-46c4-b2e7-1f737807a3cb
# ╠═edfa0b25-9132-4de9-bf11-3ea2f0952e4f
# ╠═ccbf567a-8923-4343-a2ff-53d81f2b6361
# ╟─a3ae2bfe-41ea-4fe1-870b-2ac35153da5d
# ╠═1d811aa5-940b-4ddd-908d-e94fe3635a6a
# ╠═2cee3e2b-5061-40f4-a205-94d80cfdc20b
# ╠═9be19399-c7e6-4089-b746-1d4d749f7774
# ╠═29a93299-f577-4114-b77f-dbc079392090
# ╟─003f670b-d3b1-4905-b105-67504f16ba19
# ╟─a96a9a78-0aeb-4b00-8f3c-db61839deb5c
# ╟─f0e9e077-f435-4f4b-bd69-f495dfccec27
# ╟─989f8ecc-724d-4f80-a359-fb55d2e356d6
# ╟─9700ea30-a99c-4832-a181-7ef23c86030a
# ╟─bbabb049-9418-4a6b-9c1a-c5822d971aba
# ╟─148d1418-76a3-462d-9049-d30e85a45f06
# ╟─fc68fa36-e2ea-40fa-9d0e-722167a2506e
# ╟─7fe89538-b2fe-47db-a961-fdbdd4278963
# ╟─c1fbbcf3-aeec-483e-880a-05d3c7a8a895
# ╟─b56084e8-7286-404b-9088-094070331afe
# ╟─2c1c4182-5654-46ad-b4fb-2c79727aba3d
# ╠═8e400909-8cfd-4c46-b782-c73ffac03712
# ╟─c334b67e-594f-49fc-8c11-be4ea11c33b5
# ╟─f1949d12-86eb-4236-b887-b750916d3493
# ╟─e0368e81-fb5a-4dc4-aebb-130c7fd0a123
# ╠═bc19e42a-fc82-4191-bca5-09622198d102
# ╟─57153574-e5ca-4167-814e-2d176baa0de9
# ╟─1fe8a98e-6dc6-466e-9bc9-406c416d8076
# ╟─156c508f-2026-4619-9632-d679ca2cae50
# ╟─823ce280-15c4-410f-8216-efad03897282
# ╟─c0c45548-9792-4969-9147-93f09411a71f
# ╟─dd941045-3b5f-4393-a6ae-b3d1f029a585
# ╠═8348950a-11cb-4eaa-a639-fcd2b758fb3b
# ╠═c0881f04-40e5-4108-85e2-f3aca3420513
# ╠═74951f2f-1bc4-4d0f-a2ee-fd6862c6feec
# ╠═5ea1985d-8788-445e-9c8c-f8ebab01ecf6
# ╠═9b2123a3-12fb-4ebf-ad9b-1aa65ff9ee43
# ╠═00e20281-2046-487b-89a2-1a9f848c67fa
# ╠═60cb964f-1cd4-4dc4-bb6e-12e4be395fcd
# ╠═bff81fc8-bce9-4f45-8a2e-21f7d2c18648
# ╠═c3ab8073-165e-4013-99bc-6d32cf9f4514
# ╠═fd1b186d-b042-4e42-97ea-7e2338eaf75c
# ╠═39d81ecc-ecf5-491f-bb6e-1e545f10bfd0
# ╠═69b9885f-96bd-4f8d-9bde-9ac09521f435
# ╟─9f1d770b-7c67-4b25-bf2b-0fbf6a29fb6a
# ╟─fae1cebf-9355-4c4c-b0aa-0eab1f517785
# ╟─18f8a5d6-c775-44a3-9490-cd11352c4a63
# ╟─67b8c557-1cf2-465d-a888-6b77f3940f39
# ╠═a27e0adf-aa09-42ee-97f5-ede084a9edc3
# ╟─cf587261-6193-4e7a-a3e8-e24ba27929c7
# ╟─439903cb-c2d1-49d8-a5ef-59dbff96e792
# ╟─f86b195e-06a9-493d-8536-16bdcaadd60e
# ╟─466eaa12-3a55-4ee9-9f2d-ac2320b0f6b1
# ╟─b170050e-cb51-47ec-9870-909ec141dc3d
# ╠═c9233e3f-1d2c-4f6f-b86d-b6767c3f83a2
# ╟─91c35ba0-729e-4ea9-8848-3887936a8a21
# ╟─1ada0c42-9f11-4a9a-b0dc-e3e7011230a2
# ╠═0bb77295-be29-4b50-bff8-f712ebe08197
# ╠═8b6264b0-f7ea-4177-9700-30072d4c5826
# ╠═f9949a92-f4f8-4bbb-81d0-650ff218dd1c
# ╠═5e5366a9-3086-4210-a037-c56e1374a686
# ╠═7316a125-3bfe-4bac-babf-4e3db953078b
# ╟─ca522939-422f-482a-8658-452790c463f6
# ╟─064496dc-4e23-4242-9e25-a41ddbaf59d1
# ╟─28ee9310-9b7d-4169-bae4-615e4b2c386e
# ╟─612a1121-b672-4bc7-9eee-f7989ac27346
# ╟─a6c68bb9-f7b4-4bed-ac06-315a80af9d2e
# ╟─32307f96-6503-4dbc-bf5e-49cf253fbfb2
# ╟─ac87a771-1d91-4ade-ad39-271205c1e16e
# ╟─ca346015-b2c9-45da-8c1e-17493274aca2
# ╠═88616e0f-6c85-4bb2-a856-ea7cee1b187d
# ╠═2bcc0cf2-61b5-438f-86ea-331b565902f5
# ╟─a7b92ca8-8a39-4332-bab9-ed612bf24c17
# ╟─384e2313-e1c7-4221-8bcf-142b0a49bff2
# ╟─5d6e868b-50a9-420b-8533-5db4c5d8f72c
# ╟─c77607ad-c11b-4fd3-bac9-6c43d71ae932
# ╟─b5c7295e-c464-4f57-8556-c36b9a5df6ca
# ╟─92a20829-9f0a-4ed2-9fd3-2d6560514e03
# ╟─13eb72c7-ac24-4b93-8fd9-260b49940370
# ╟─8929062f-0d97-41f9-99dd-99d51f01b664
# ╟─ebd8e962-2150-4ada-8ebd-3eba6e29c12e
# ╟─af5a7cbf-8f9c-42e0-9f8f-6d3561635c40
# ╟─5ae493f4-346d-40ce-830f-909ec40de8d0
# ╟─276dd93c-05f9-46b1-909c-1d449c07e2b5
# ╟─8797a304-aa98-4ce0-ab0b-759df0256fa7
# ╟─f55bb88f-ecce-4c14-b9ac-4fc975c3592e
# ╟─67322d28-5f9e-43da-90a0-2e517b003b58
# ╟─f1c0e395-1b22-4e68-8d2d-49d6fc71e7d9
# ╟─c38bfef9-2e3a-4042-8bd0-05f1e1bcc10b
# ╟─20a8fbe0-5840-4a70-be33-b4103df291a1
# ╟─7a4cb25a-59cf-4d2c-8b1b-5881b8dad606
# ╟─42e4b611-abe4-41c4-8f92-ea39bb928122
# ╟─8b830eee-ae0a-4c9f-a16b-34045b4bef6f
# ╠═fdb40907-1047-41e5-9d39-3f94b06b91c0
# ╟─c6e915be-2853-48ff-a8da-49755b9b1a44
# ╟─8e1673fe-5286-43cd-8830-fba353f1cd89
# ╟─ea7779ea-cd11-4f9e-8022-ff4f370ffddd
# ╟─3d09a15d-685b-4d9b-a47f-95067441928d
# ╟─e785f43f-0902-4b7b-874b-bf1c09438970
# ╟─e6cc0cf6-617a-4231-826d-63f36d6136a5
# ╟─cd06cad4-4b47-48dd-913f-61028ebe8cb3
# ╟─2a63de92-47c9-44d1-ab30-6ac1e4ac3a59
# ╟─db1ce9bc-0593-4dd7-b905-a14295d47533
# ╟─5ce26cae-4604-4ad8-8d15-15f0bfc9a81a
# ╠═9b8a5995-d8f0-4528-ad62-a2113d5790fd
# ╠═20bc797e-c99b-417d-8921-9b95c8e21679
# ╠═c9d90fd5-4b65-435f-82e7-324340f31cd8
# ╠═24185d12-d29c-4e72-a1de-a28319b4d369
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
