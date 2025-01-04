### A Pluto.jl notebook ###
# v0.20.4

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

# ╔═╡ d489db2d-3e73-44bd-aeb6-bfe17775d20c
using .Threads

# ╔═╡ 69c4770e-1091-4744-950c-ed23deb55661
# prod packages

# ╔═╡ f6dc2723-ab4a-42fc-855e-d74915b4dcbf
# dev packages

# ╔═╡ 43f89626-8583-11ed-2b3d-b118ff996f37
# ╠═╡ disabled = true
#=╠═╡
using PlutoUI
  ╠═╡ =#

# ╔═╡ 20bc797e-c99b-417d-8921-9b95c8e21679
# ╠═╡ disabled = true
#=╠═╡
using BenchmarkTools
  ╠═╡ =#

# ╔═╡ 1df30830-1a44-49f5-bb9a-309a8e9f2274
# ╠═╡ disabled = true
#=╠═╡
using JET
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
mm_yinsh_01 = map(x -> if x == 1 0 elseif x == 2 1 elseif x==0 0 end, mm_yinsh);

# ╔═╡ 856b71d6-130e-4312-9a51-62f04d97a02c
mm_states = fill("",19,11);

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
	mk_flip_locs::Vector{CartesianIndex} = CartesianIndex[]

	for loc in s_locs
		@inbounds z::String = gs[loc] # read game state
		(z == _RW || z == _RB)::Bool && break # at the first ring (the one we moved)
		(z == _MW || z == _MB)::Bool && push!(mk_flip_locs, loc) # save markers locs
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
function gen_random_gameState(near_score_rows = 0, num_mks = 0, random_rings = true)
# generate a new random game state (server format)

	# empty state (server format)
	server_game_state = fill("",19,11)

	# early return of empty state for manual rings setup option (ie. non-random)
	!random_rings && @goto _return

	# else, generate a random initial game state
	spots = [l for l in _board_locs] # sample doesn't work on sets, only arrays

	## pick 10 random starting locations from board(without replacement)
	ring_locs = sample(spots, 10, replace = false)
	
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
	
	@label _return
	return server_game_state
end

# ╔═╡ bc19e42a-fc82-4191-bca5-09622198d102
const games_log_dict = Dict{String, Dict}()

# ╔═╡ 823ce280-15c4-410f-8216-efad03897282
function new_gs_only_rows(rows::Vector{Vector{CartesianIndex}}, h_rows::Union{Set{Int}, Vector{Int}} = Int[])

	gs = fill("", (19,11))

	if !isempty(rows)
		for r in rows
			for loc in r
				gs[loc] = "MB" # black by default, so highlight can be seen better 
			end
		end
	end

	if !isempty(h_rows) # highlight these rows as white
		for r_id in h_rows
			for loc in rows[r_id]
				gs[loc] = "MW"
			end
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

# ╔═╡ 39d81ecc-ecf5-491f-bb6e-1e545f10bfd0
function discover_scoring_sets(rows::Vector{Vector{CartesianIndex}}, max_ssize::Int=0)::Set{Set{Int}}
#= 
Fn akes in input rows of locations (CI) and returns the possible sets representing groups of scoring actions: with multiple scoring and rows overlap, some scores preclude others having A/B/C, depending on their configuration, A/B/C, A/B, B/C, C/A might be available as different valid scoring sets

Notes:
- we're using the 1-based index of row (in input array) as its ID
- we make heavy use of sets for uniqueness and fast ops
- the additional parameter is passed to limit the size of the sets: propagated from sim_scenarioTrees > sim_new_gameState > search_scores_gs > here, represents the distance in rings a player has from winning
- in case of multiple scoring, sets of max_ssize will be the winning ones
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
		- remove subsets, take out a set, and try extending it by-1
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
		# always delete the 'starting branch', as function never converges otherwise
		# also, we loop & prune after every set evaluation
		# instead of adding to and iterating the same collection with less pruning
		
		s = pop!(base_sets)

		# not extend set if it's at max_size, just save it and skip to the next
		if max_ssize > 2 && length(s) == max_ssize
			
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
function search_scores_gs(gs::Matrix{String}, max_sset_d=Dict{Symbol,Int}())
# look at the game state as it is to check if there are scoring opportunities

	# to be returned -> returns empty vector if nothing found for player
	# :B/:W -> {:s_rows => [], :s_sets => []}
	scores_info::Dict{Symbol, Dict} = Dict()

	# helper vecs/dict to store found locations for scoring rows
	found_rows = Dict(_B_key => Vector{CartesianIndex}[], _W_key => Vector{CartesianIndex}[])

	# all markers locations
	all_mks::Vector{CartesianIndex} = findall(s -> contains(s, _M), gs)

	# find scoring rows
	for mk_index in all_mks

		# for each marker retrieve search space for scoring ops
		mk_search_locs::Vector{Vector{CartesianIndex}} = @inbounds _locs_searchSpace_scoring[mk_index]

		for locs_vec in mk_search_locs

			# reading states for all locs in search array
			states_vec = String[]
			for loc in locs_vec
				s::String = @inbounds gs[loc]
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
					push!(found_rows[player_key], locs_vec)
				end					
			end	

			@label skip_vec
		end
	end

	
	# add extra info on scoring sets and mk_sel for each row
	for player_k in keys(found_rows)

		# extract rows
		rows::Vector{Vector{CartesianIndex}} = @inbounds found_rows[player_k]

		# check if we have data on how far player is from winning score
		max_set_size::Int = 0
		if !isempty(max_sset_d)
			max_set_size = @inbounds max_sset_d[player_k]
		end

		# identify scoring sets among rows and save them in container
		scoring_sets::Set{Set{Int}} = discover_scoring_sets(rows, max_set_size)

		# # keep track of mk_sel already taken for the same color/player
		mk_sel_taken = Vector{CartesianIndex}(undef,0) 

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
			mk_sel::CartesianIndex = @inbounds mk_sel_avail[id]
			
			push!(mk_sel_taken, mk_sel)

			# package score information
			score_row_info = Dict{Symbol,Union{CartesianIndex, Vector{CartesianIndex}}}(:mk_sel => mk_sel, :mk_locs => r)

			# save prepared scoring row
			push!(s_rows, score_row_info)

		end

		# save player's data
		setindex!(scores_info, s_player, player_k)
	end


	return scores_info

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

	keys_to_skip = Symbol[:gs, :tree_summary, :new_game_state, :mode]

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

# ╔═╡ 0d5558ca-7e01-4ed2-8b37-61649690346a
function mks_limit_hit(gs::Matrix{String})::Bool
# checks if we hit the maximum number of markers on the board 

	return findall(s -> ( s ==_MW || s == _MB), gs) |> length == 51

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
				mm_to_print *= "|" * string(print_val) * ""
			
			elseif j == col_m 
				mm_to_print *= string(print_val) * "| \n"
				
			else
				mm_to_print *= string(print_val) * ""
			end
		end
	end

@info mm_to_print

end

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
	const ws_watchdog = Task[]; # ws server watchdog task
	const ws_array = []; # array of server handles & tasks
	const ws_msg_log = Dict[]; # log for all sent & received (parsed) messages
	const ws_msg_log_raw = []; # log for all received messages (raw)
end

# ╔═╡ 691404a6-53bc-4340-a750-636fe219f633
msg_lock = ReentrantLock()

# ╔═╡ 1160c8c0-8a90-4c89-898f-328749611a76
games_lock = ReentrantLock()

# ╔═╡ 57153574-e5ca-4167-814e-2d176baa0de9
function save_newGame!(new_game_details)
# handles writing to dict (redis in the future?)

	# saves starting state of new game
	try
		lock(games_lock)
			setindex!(games_log_dict, new_game_details, new_game_details[:identity][:game_id])
	catch e 
		e |> throw
	finally
		unlock(games_lock)
	end

end

# ╔═╡ 1fe8a98e-6dc6-466e-9bc9-406c416d8076
function save_new_clientPkg!(game_id, _client_pkg)
# handles writing to dict (redis in the future?)
# returns index to last saved package

	# saves starting state of new game
	try 
		lock(games_lock)
		push!(games_log_dict[game_id][:client_pkgs], _client_pkg)
	catch e 
		e |> throw
	finally 
		unlock(games_lock)
	end

end

# ╔═╡ 0bb77295-be29-4b50-bff8-f712ebe08197
begin
	
	# ip and port to use for the server
	const ws_ip = "0.0.0.0" # listen on every ip / host ip
	const ws_port = 6091

end

# ╔═╡ 4fad24a9-f75b-48c1-8990-041c75afc09c
ws_msg_log_raw

# ╔═╡ 7c026677-5c44-4a12-99a4-2d1228e31795
function terminate_active_ws!()

	for ws in filter(ws -> !istaskdone(ws.task) || !isempty(ws.connections), ws_array)
		HTTP.forceclose(ws)
		_num_conn = ws.connections |> length
		@warn "WARNING - Terminating ws server: $(ws.task) - $_num_conn connections"
	end
end

# ╔═╡ 5ff005dd-2347-4dc3-a24f-42cb576822fc
function terminate_active_watchdog!()

	for task in ws_watchdog
		if !istaskdone(task)
   			schedule(task, InterruptException(), error=true)
			@warn "WARNING - Terminating ws watchdog: $task"
		end
	end
end

# ╔═╡ 5e5366a9-3086-4210-a037-c56e1374a686
begin
	
	# client codes codes - used for different requests
	# server responds with these + _OK or _ERROR
	const CODE_new_game_human = "new_game_vs_human"
	const CODE_new_game_server = "new_game_vs_server"
	const CODE_join_game = "join_game"
 	const CODE_advance_game = "advance_game" # clients asking to progress the game
	const CODE_resign_game = "resign_game" # clients asking to resign
	
	# server codes (only the server can use these)
	# client responds with these + _OK or _ERROR
	const CODE_play = "play" # the other player has joined -> move
	const CODE_wait = "wait" # the other player has yet to join -> wait 
	const CODE_end_game = "end_game" # someone won

	# game states
	const GS_not_started = :not_started
	const GS_progress_rings = :progress_rings
	const GS_progress_game = :progress_game
	const GS_completed = :completed
	const ref_game_status = Set([GS_not_started, GS_progress_rings, GS_progress_game, GS_completed])
	
	# suffixes for code response type
	const sfx_CODE_OK = "_OK"
	const sfx_CODE_ERR = "_ERROR"

	# keys to access specific values
	const key_nextActionCode = :next_action_code
	
end

# ╔═╡ ca522939-422f-482a-8658-452790c463f6
function dict_keys_to_sym(input::Dict)::Dict{Symbol, Any}
# swaps dict keys from String to Symbol, RECURSIVELY
# JSON3.read can take a type specification but it won't turn keys into symbols beyond the first layer of depth, unless a more complex type specification is provided
	
	_new = Dict{Symbol, Any}()

	for (k,v) in input

		# is key a string ?
		_nkey = isa(k, String) ? Symbol(k) : k

		# is value a Dict ?
		_nval = isa(v, Dict) ? dict_keys_to_sym(v) : v

		# is value an Array of Dicts ?
		if isa(v, Vector) && !isempty(v) 
			_nval = isa(v[begin], Dict) ? dict_keys_to_sym.(v) : v
		end

		# write everything anyway
		setindex!(_new, _nval, _nkey)
		
	end

	return _new
end

# ╔═╡ 612a1121-b672-4bc7-9eee-f7989ac27346
function update_ws_handler!(game_id::String, ws, is_orig_player::Bool)

# updates WS handler for a specific player within a game
# if the game is not found, it will throw an error
# could be made more independent in the future (handle directly msg)
	
	try
		
		# understand necessary key  
		_dict_key = is_orig_player ? :orig_player_ws : :join_player_ws
		
		lock(games_lock)
			games_log_dict[game_id][:ws_connections][_dict_key] = ws

			println("LOG - WS handler updated for $_dict_key")
	
	catch 
		throw(error("ERROR retrieving game data when updating WS handler"))
	
	finally
		unlock(games_lock)
	end
	
	

end

# ╔═╡ 28ee9310-9b7d-4169-bae4-615e4b2c386e
function msg_dispatcher(ws, msg_id, msg_code, payload = Dict{Symbol, Any}(), ok_status::Bool = true)

	# copy response payload
	# need to do a comprehension so we have a separate copy + general type
	_response = Dict{Symbol, Any}(k => v for (k,v) in payload)

	# prepare response code
	_sfx_msg_code = msg_code * (ok_status ? sfx_CODE_OK : sfx_CODE_ERR)
	
	# append original msg id and updated response_code
	setindex!(_response, msg_id, :msg_id)
	setindex!(_response, _sfx_msg_code, :msg_code)

	# add statusCode 200 
	setindex!(_response, 200, :statusCode)

	# save response (just for logging/debug)
	setindex!(_response, "sent", :type)
	
	lock(msg_lock)
		push!(ws_msg_log, _response)
	unlock(msg_lock)

	# send response
	send(ws, JSON3.write(_response))
	
	# log
	println("LOG - $_sfx_msg_code sent for msg ID $msg_id")

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

# ╔═╡ 69152551-c381-42f0-9ef6-a1c4ea969b34
function _sys_mem_check(limit::Float64) 
# as of percentage of total memory
	
	tot = Base.Sys.total_memory()
	free = Base.Sys.free_memory()
	
	_free_mem_ratio = free/tot
	_free_below_limit = (_free_mem_ratio <= limit) ? true : false
	_free_mb = free / 1024^2

	return round(Int, _free_mb), round(_free_mem_ratio*100, digits=2), _free_below_limit

end

# ╔═╡ 61d75e9e-b2d3-4551-947b-e8acc11e2eeb
begin

const __last_cleanup = [now()]
const __cleanup_interval = Hour(2)
const __mem_thresh::Float64 = 0.04 # % of free memory over total


function _mem_cleanup!(force = false) # called by game_runner

	free_mb, free_mem_p, mem_limit_hit = _sys_mem_check(__mem_thresh)
	time_diff = now() - __last_cleanup[1]

	
    if force || (time_diff > __cleanup_interval || mem_limit_hit)

		_mem_log = "> MEM CLEANUP | free: $free_mb MB [$(free_mem_p) %] | last run: $(time_diff |> canonicalize) ago"
		println(_mem_log)
		@info _mem_log # comment out for deployment

		# games log 
		try 
			lock(games_lock)
			
			# -> delete completed games older than 1hr
			g_ids_done = [ 	k for (k,v) in games_log_dict if 
							v[:identity][:status] == GS_completed && 
							v[:identity][:end_dateTime] <= (now() - Hour(1)) ]
	
			# -> delete games older than a week, regardless of status
			g_ids_zombie = [k for (k,v) in games_log_dict if 
							v[:identity][:init_dateTime] <= (now() - Day(7)) ]
	
			foreach(k -> delete!(games_log_dict, k), union(g_ids_done, g_ids_zombie))

		catch e 
			e |> throw
		finally
			unlock(games_lock)
		end

		# wipe messages logs
		lock(msg_lock)
			ws_msg_log |> empty!
			ws_msg_log_raw |> empty!
		unlock(msg_lock)

		# run garbage collector	
		GC.gc(true)

		# log last cleanup run time
		global __last_cleanup[1] = now() # log 
		
    end
end

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

	try
		return games_log_dict[game_id][:ws_connections][_key]
	catch e
		@error e
	end

end

# ╔═╡ b5c7295e-c464-4f57-8556-c36b9a5df6ca
function set_turn_closed!(game_code::String, turn_no::Int)

	try 
		lock(games_lock)
		setindex!(games_log_dict[game_code][:turns][:data][turn_no], :closed, :status)
	catch e
		throw(error("ERROR while setting turn $turn_no as closed - $e"))
	finally
		unlock(games_lock)
	end

end

# ╔═╡ 92a20829-9f0a-4ed2-9fd3-2d6560514e03
function advance_turn!(game_code::String, completed_turn_no::Int)::Dict
# this function manages turns across :open -> :closed
# closes indicated turn and creates new one
# returns dict of new turn data


	# current vars
	_turns = games_log_dict[game_code][:turns]
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
		try 
			lock(games_lock)
				push!(games_log_dict[game_code][:turns][:data], _new_turn_data)
				games_log_dict[game_code][:turns][:current] = _next_turn_no
		catch e
			e |> throw
		finally 
			unlock(games_lock)
		end

		# return new turn data
		return _new_turn_data

	end
		
end

# ╔═╡ 13eb72c7-ac24-4b93-8fd9-260b49940370
function check_both_players_ready(game_id)
# checks if both players are ready

	try
		
		players = get(games_log_dict[game_id], :players, nothing)

		if !isnothing(players)
			return players[:orig_player_status] == :ready && players[:join_player_status] == :ready
		end

	catch e

		throw("ERROR checking players readiness status, $e")

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

# ╔═╡ f7fe7ff7-0fff-4740-9aec-56354fdca9a3
function is_rings_setup_random(game_id::String)::Bool
# checks if ring setup mode is random, if not (or if error) returns false
	
	try
		return games_log_dict[game_id][:identity][:random_rings] # true/false
	catch
		error("ERROR in is_game_vs_ai check: game code $game_id not found") |> throw
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

	ring_setup_action: -1
	score_actions_preMove : [ { mk_locs: [], ring_score: -1 } ],
	move_action: { start: -1, end: -1 },
	score_actions: [ { mk_locs: [], ring_score: -1 } ], 
	completed_turn_no: _played_turn_no     

	-1 is the default value sent by the client when the given action is not done,
	this function strips the input dict of dict / dict[] that contain it before reshaping in client coordinates to cart_indexes

	NOTE: this fn could be made cleaner
=#

	keys_to_keep = Set([:ring_setup_action, :score_actions_preMove, :move_action, :score_actions])
	
	srv_recap = Dict()

	# keep only relevant keys, skip default values (-1)
	for (k, v) in recap

		if k in keys_to_keep
			
			if k == :move_action && v[:start] == -1
				@goto skip_default_value # no move took place

			elseif k in [:score_actions_preMove, :score_actions]&& v[begin][:ring_score] == -1 
				@goto skip_default_value # no scoring during pre-move/move
			
			elseif k == :ring_setup_action && v == -1
				@goto skip_default_value # no manual ring setup
			end

			setindex!(srv_recap, v, k) # save only if not skipped
		end

		@label skip_default_value

	end


	return reshape_in(srv_recap) # defined only on julia dicts 
	
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
		
		lock(games_lock)
		
			games_log_dict[game_id][:players][key] = new_score
			return games_log_dict[game_id][:players][key]
	
	catch e
		error("ERROR - while increasing $player_id score for game $game_id $e")
	finally
		unlock(games_lock)
	end

end

# ╔═╡ 0193d14a-9e55-42c2-97d6-2a0bef50da1e
function get_scores_byID(game_id::String)::Dict{String, Int}
# returns {"B" => n, "W" => n}
	
	try
		
		orig_player_score = games_log_dict[game_id][:players][:orig_player_score] 
		join_player_score = games_log_dict[game_id][:players][:join_player_score] 

		orig_player_id = games_log_dict[game_id][:identity][:orig_player_id]

		B_score_val = orig_player_id == _B ? orig_player_score : join_player_score
		W_score_val = orig_player_id == _W ? orig_player_score : join_player_score
		
		
		return Dict(_W => W_score_val, _B => B_score_val)
	catch e
		throw(error("ERROR - while retrieving player scores for game $game_id $e"))
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

# ╔═╡ 59efcc6c-7ec7-4ac7-8510-ae9257d0ff23
function set_gameStatus!(game_id::String, status::Symbol)

	if status in ref_game_status
		try
			lock(games_lock)
				games_log_dict[game_id][:identity][:status] = status
				println("Game $game_id -> $(status)")
		catch e 
			e |> throw
		finally 
			unlock(games_lock)
		end
	else
		"Attempt to set invalid game status" |> error |> throw
	end

end

# ╔═╡ d4e9c5b2-4eb5-44a5-a221-399d77b50db3
function get_gameStatus(game_id::String, return_dict = false)

	game_status = games_log_dict[game_id][:identity][:status]

	if !return_dict
		return game_status
	else # return dict, used by game_runner to add game status information to payload
		return Dict(:game_status => game_status)
	end
		
end

# ╔═╡ b2b31d4e-75c7-4232-b486-a4515d01408b
function infer_set_game_transitions!(game_id)

#= OVERVIEW
- the possible game states are defined in ref_game_status
- not_started -> (:progress_rings) -> :progress_game -> :completed
- not started is given at game creation
- :progress_rings & :progress_game are inferred and set by this function
- this function is called by play_turn_server ( place rings vs make a move ) and update_serverStates post-move
- :completed is instead set by another function, check_update_game_end!, and it handles evaluating scores/outcomes as well as handling player resignation
- might be better to condense both functions into a better architected events handling layer
=#

	_game_status = get_gameStatus(game_id)
	
	if _game_status != GS_completed # unless game is already completed
		if _game_status in [GS_not_started, GS_progress_rings] 
			
			gs = get_last_srv_gameState(game_id)
			_num_rings = findall(contains(_R), gs) |> length
			_num_markers = findall(contains(_M), gs) |> length

			if _num_rings < 10 && _num_markers == 0 # set progress_rings
				_game_status = GS_progress_rings
			else
				_game_status = GS_progress_game
			end

		end

		set_gameStatus!(game_id, _game_status)
	end

	# when status is :completed or :progress_game, it's propagated as-is
	return _game_status

end

# ╔═╡ cb8ffb39-073d-4f2b-9df4-53febcf3ca99
function get_resignedStatus_byID(game_id::String)::Dict{String, Bool}
# returns {"B" => false/true, "W" => false/true}
	
	try
		
		orig_player_status = games_log_dict[game_id][:players][:orig_player_status] 
		join_player_status = games_log_dict[game_id][:players][:join_player_status]

		orig_p_resigned = orig_player_status == :resigned ? true : false
		join_p_resigned = join_player_status == :resigned ? true : false

		orig_player_id = games_log_dict[game_id][:identity][:orig_player_id]

		B_resigned = orig_player_id == _B ? orig_p_resigned : join_p_resigned
		W_resigned = orig_player_id == _W ? orig_p_resigned : join_p_resigned
		
		return Dict(_W => W_resigned, _B => B_resigned)
		
	catch e
		throw(error("ERROR - while retrieving player status for game $game_id $e"))
	end

end

# ╔═╡ 20a8fbe0-5840-4a70-be33-b4103df291a1
function check_update_game_end!(game_id::String)::Dict
# checks if game is over or not, either by scoring, resignation by one of the players, or if the maximum number of markers has been hit (51)
# if max markers have been hit, checks if someone wins or if it's a draw
# marks reason in game log - who won/lost (or if it's a draw), reason score vs resign vs markers, and the game end time 
# outcome can be valued to one of [ score, mk_limit_score, mk_limit_draw, resign ]
# won_by is B/W unless mk_limit_draw, in which case is left empty

#=
UPDATE

this function was extended to also handle the rings placement phase
while the game previously had either a 'not-started' or 'completed' status
now it can go from ns -> (progress_rings) -> progress_play -> completed
() is optional and depends on randomRings flag set at game creation

=#

	winning_score = 3 # hardcoded, can be tied to game_id (-> game mode)
	ret = Dict(:end_flag => false, :outcome => "", :won_by => "")

	# retrieves scores and resign status
	scores = get_scores_byID(game_id)
	resign_status = get_resignedStatus_byID(game_id)

	# check if we are at the limit of markers (51) in last game state
	gs = get_last_srv_gameState(game_id)
	f_mks_limit = mks_limit_hit(gs)
	
	## HANDLE CASES

	# winning score
	if (scores[_W] == winning_score || scores[_B] == winning_score)

		ret[:end_flag] = true
		ret[:outcome] = "score"
		winning_player = scores[_W] == winning_score ? _W : _B
		ret[:won_by] = winning_player
	end
	
	# resignation
	if (resign_status[_W] || resign_status[_B])
		ret[:end_flag] = true
		ret[:outcome] = "resign"
		winning_player = resign_status[_W] ? _B : _W
		ret[:won_by] = winning_player
	end
		
	# markers limit hit -> assess winner or draw
	if f_mks_limit

		ret[:end_flag] = true
		
		if scores[_W] == scores[_B] 
			ret[:outcome] = "mk_limit_draw"
			# won_by stays as "" in case of draw
		else 
			ret[:outcome] = "mk_limit_score"
			ret[:won_by] = (scores[_W] > scores[_B]) ? _W : _B 
		end
	end
	
	
	# save results in log if game is over
	if ret[:end_flag]

		try 
			lock(games_lock)

			games_log_dict[game_id][:identity][:won_by] = ret[:won_by]
			games_log_dict[game_id][:identity][:outcome] = ret[:outcome]
			games_log_dict[game_id][:identity][:end_dateTime] = now()

			# update game status
			# using dedicated function just to handle status
			# might need to evolve it into whole-identity setter later
			set_gameStatus!(game_id, :completed)
		
		catch e 
			e |> throw
		finally
			unlock(games_lock)
		end
		
	end
	

	return ret
	

end

# ╔═╡ 8b830eee-ae0a-4c9f-a16b-34045b4bef6f
function get_last_turn_details(game_code::String)

	_current_turn = games_log_dict[game_code][:turns][:current]

	return games_log_dict[game_code][:turns][:data][_current_turn]::Dict

end

# ╔═╡ de5356b7-1c9d-4065-9ef2-4db1575249c4
function valid_empty_locs(gs::Matrix{String})

	return Dict(loc .=> gs[loc] for loc in _board_locs) |> d -> filter(kv -> last(kv) == "", d) |> keys |> collect

end

# ╔═╡ eb3b3182-2e32-40f8-adf7-062691bf53c6
function get_first_maxL(set::Set)
# return first element in set of maximum length 

	if !isempty(set)
		vec = collect(set)
		fm_id = findfirst( v -> length(v) == maximum(vec .|> length), vec)
		return @inbounds vec[fm_id]
	else
		throw(error("ERROR - get_first_maxL expects a non-empty input"))		
	end

end

# ╔═╡ 09c1e858-09ae-44b2-9de7-e73f1b4f188d
function get_first_maxL(vec::Vector)
# return first element in array of maximum length

	if !isempty(vec)
		fm_id = findfirst( v -> length(v) == maximum(vec .|> length), vec)
		return @inbounds vec[fm_id]
	else
		throw(error("ERROR - get_first_maxL expects a non-empty input"))		
	end

end

# ╔═╡ fa924233-8ada-4289-9249-b6731edab371
function get_hScoring_sc(tree, ref_sc)::Dict{Symbol, CartesianIndex}
# explores a tree for the scenarios given in input [ {start, end} ] and finds the first one with the largest scoring possibility, returning its index
# assumes all scenarios given lead to a score for the PLAYER in the tree
	
	try

		h_sset_sizes = fill(0, length(ref_sc))
		
		for (i, sc) in enumerate(ref_sc)
		
			ssets = tree[sc[:start]][sc[:end]][:scores_avail_player][:s_sets]

			max_ss_size::Int = ssets |> get_first_maxL |> length
			#@info "max_ss_size for sc $i: $max_ss_size"
			
			@inbounds h_sset_sizes[i] = max_ss_size
		
		end

		h_sc_index = argmax(h_sset_sizes) # index of sc in ref array 

		return ref_sc[h_sc_index]

	catch
		throw(error("ERROR in get_hScoring_sc, no scenario found"))
	end


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
function sim_new_gameState(ex_game_state::Matrix{String}, sc::Dict, fn_mode::Symbol)::Dict
	
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
	() means optional field

	! id
		! player_id -> B/W
		! players_scores -> { W => 0...3, B => 0...3 }
		() game_mode -> classic (3) vs quick (1) -> used to calc max_sset size
		() game_id / turn_no / scenario_id -> have a single id for N choices and read changes from DB ?

	-- all data in dicts below can be reshaped-in/out as a whole, only coordinates --

	turn recap data:

	() ring_setup_action (ci)
			ring_loc

	() score_actions_preMove [] 
			mk_locs
			ring_score
	
	() move_action  (ci, ci)
	  		start 
			end

	() score_actions []
			mk_locs
			ring_score

=#


	# following value is hardcoded for now
	winning_score::Int = 3; # game_mode == quick ? 1 : 3

	## extract relevant flags from input (given by presence of keys in dict)
	f_ring_setup_act::Bool = haskey(sc, :ring_setup_action)
	f_scores_act_preMove::Bool = haskey(sc, :score_actions_preMove)
	f_move_act::Bool = haskey(sc, :move_action)
	f_scores_act::Bool = haskey(sc, :score_actions)

	# extract player_id (B/W)
	_player_id::String = sc[:id][:player_id]::String
	_opp_id::String = _player_id == _W ? _B : _W

	# baseline game state that we'll modify and return later
	new_gs::Matrix{String} = deepcopy(ex_game_state)::Matrix{String}
	new_player_score::Int = deepcopy(sc[:id][:players_scores][_player_id])::Int  
	new_opp_score::Int = deepcopy(sc[:id][:players_scores][_opp_id])::Int

	# dict to return w/ game state delta - used for replay or add leaves to the tree
	_ret::Dict{Symbol, Union{Dict, Array, Matrix, Int, Symbol}} = Dict{Symbol, Union{Dict, Array, Matrix, Int, Symbol}}()

	#= OUTPUT structure - fields are added only if valued

	# delta
		:ring_setup_done => (loc, player)
		:scores_preMove_done => [ (:mk_locs => CI[], :ring_score => CI) ]
		:move_done => (:mk_add => (loc, player), :ring_move = (start, end, player))
		:mk_flip => CI[] (to be flipped) | used only by CLI, SRV re-checks on the fly
		:scores_done => [ (:mk_locs => CI[], :ring_score => CI) ]

	# new state post-delta 
		:new_game_state => Matrix
		:new_player_score => Int
		:new_opp_score => Int 
		
	# inspect results
		:scores_avail_opp => { :s_rows => Dict[], :s_sets => { (1,2,4), (3,5) } 
		:scores_avail_player => { :s_rows => Dict[], :s_sets => { (1,2,4), (3,5) }

	# log/debug value
		:mode => Symbol (how this fn was called)

	=#
	
	################## EDITING functions for board state

	function ring_setup_do!() # place ring (manual rings setup mode)

		# ring placed in ring_loc (same color as player_id)
		ring_loc::CartesianIndex = @inbounds sc[:ring_setup_action]
		@inbounds new_gs[ring_loc] = (_player_id == _B ? _RB : _RW)::String

		# update global dict
		ring_setup = Dict{Symbol, Union{CartesianIndex, String}}(:loc => ring_loc, :player_id => _player_id)
		setindex!(_ret, ring_setup, :ring_setup_done)

	end
	

	function scores_preMove_do!() # pre-move scoring - ie. opp scored for player

		for score in sc[:score_actions_preMove]
			
			# remove markers from game state
			pms_mks_locs::Vector{CartesianIndex} = @inbounds score[:mk_locs]::Vector{CartesianIndex}
			
			foreach(mk_id -> new_gs[mk_id] = "", pms_mks_locs)
	
			# remove ring
			pms_ring_loc = @inbounds score[:ring_score]::CartesianIndex
			new_gs[pms_ring_loc] = ""
	
			# update player score
			new_player_score += 1 
	
			# update global dict
			pms = Dict(:mk_locs => pms_mks_locs, :ring_score => pms_ring_loc)
			setindex_container!(_ret, pms, :scores_preMove_done)
		end
	end
	

	function move_do!() # ring moved -> mk placement -> flipping
		
		start_loc::CartesianIndex = @inbounds sc[:move_action][:start]::CartesianIndex
		end_loc::CartesianIndex = @inbounds sc[:move_action][:end]::CartesianIndex
		
		# marker placed in start_move (same color as picked ring / player_id)
		@inbounds new_gs[start_loc] = (_player_id == _B ? _MB : _MW)::String
		
		# ring placed in end_move 
		@inbounds new_gs[end_loc] = ex_game_state[start_loc]

		### flip markers in the moving direction

		# retrieve search space for the starting point, ie. ring directions
		r_dirs::Vector{Vector{CartesianIndex}} = @inbounds _locs_searchSpace[start_loc]

		# spot direction/array that contains the ring 
		n = findfirst(rd -> (end_loc in rd), r_dirs)
	
		# return flag + ids of markers to flip in direction of movement
		f_flip::Bool = false; mks_toFlip = CartesianIndex[];
		if !isnothing(n)
			f_flip, mks_toFlip = search_markers_toFlip(new_gs, r_dirs[n])
		end

		# flip markers in game state
		if f_flip
			for m_id in mks_toFlip
				@inbounds s::String = new_gs[m_id]
				if (s == _MB || s == _MW)
					@inbounds new_gs[m_id] = (s == _MW) ? _MB : _MW
				end
			end
		end

		### update global dict
		
		mk_add::Dict{Symbol, Union{CartesianIndex, String}} = Dict{Symbol, Union{CartesianIndex, String}}(:loc => start_loc, :player_id => _player_id)
		ring_move::Dict{Symbol, Union{CartesianIndex, String}} = Dict{Symbol, Union{CartesianIndex, String}}(:start => start_loc, 
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
			new_player_score += 1 
	
			# update global dict
			sd::Dict{Symbol, Union{CartesianIndex, Vector{CartesianIndex}}} = Dict(:mk_locs => sd_mks_locs, :ring_score => sd_ring_loc)
			setindex_container!(_ret, sd, :scores_done)
		
		end
	end

	
	function score_check!() # post-move scoring

		# distance from winning -> max_sset for player/opp
		# only using black/white keys here
		W_score_val::Int = _player_id == "W" ? new_player_score : new_opp_score
		B_score_val::Int = _opp_id == "B" ? new_opp_score : new_player_score
		
		W_max_sset::Int = winning_score - W_score_val
		B_max_sset::Int = winning_score - B_score_val
		max_sset_d = Dict{Symbol, Int}(_W_key => W_max_sset, _B_key => B_max_sset)
		
		# search for possible scoring options
		scores::Dict{Symbol, Dict} = search_scores_gs(new_gs, max_sset_d)::Dict{Symbol, Dict}

		# save scores information for each player
		sinfo_player = @inbounds scores[Symbol(_player_id)]
		sinfo_opp = @inbounds scores[Symbol(_opp_id)]

		# update global dict -> is there a score available for either player or opp?
		!(isempty(sinfo_player[:s_rows])) && setindex!(_ret, sinfo_player, :scores_avail_player)
		!(isempty(sinfo_opp[:s_rows])) && setindex!(_ret, sinfo_opp, :scores_avail_opp)

	end
	

	################## ACTING on input mode
	if fn_mode == :replay # whole turn

		f_ring_setup_act && ring_setup_do!()
		f_scores_act_preMove && scores_preMove_do!() # -> win check
		f_move_act && move_do!() # -> mks check you can move only if limit not hit
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
function sim_scenarioTrees(ex_gs::Matrix, nx_player_id::String, players_scores::Dict)
# takes as input an ex game state (server format) and info of next moving player
# computes results for all possible moves of next moving player

	# to be returned
	scenario_trees::Dict{Symbol, Union{Dict, Vector}} = Dict{Symbol, Union{Dict, Vector}}()

		#= return structure
		
			() :scores_preMove_avail => { :s_rows => Dict[], :s_sets => [] }
		
			!/() :treepots => [ ]
					:tree_summary => { :sc_flip => [] , :sc_score => []}
					:gs_id = { s_set, s_rings} # ID absent if only 1 tree
					:tree => { :start => :end => flags/deltas/new-scores }
					:gs => Matrix{String} # starting gamestate for tree
		=#

	# ring id for this player
	_ring_id::String = nx_player_id == _W ? _RW : _RB

	# retrieve player/opp scores
	opp_id::String = nx_player_id == _W ? _B : _W
	
	nx_player_score::Int = deepcopy(players_scores[nx_player_id])::Int
	opp_score::Int = deepcopy(players_scores[opp_id])::Int

	# lower functions take in scores as white/black, not player/opp
	# the dict will be referenced later on, values directly written in it
	last_W_score::Int = nx_player_id == _W ? nx_player_score : opp_score
	last_B_score::Int = opp_id == _B ? opp_score : nx_player_score 
	last_scores::Dict{String, Int} = Dict(_W => last_W_score, _B => last_B_score)

	# identify any pre-move score to be acted on - ie. left by previous player
	pms_sc_id = Dict( :id => Dict( 	:player_id => nx_player_id, 
									:players_scores => last_scores,
									:opp_score => opp_score))
	
	pm_scores_inspect = sim_new_gameState(ex_gs, pms_sc_id, :inspect)
	flag_pms::Bool = haskey(pm_scores_inspect, :scores_avail_player)

	# container for 
	treepots::Vector{Dict{Symbol, Union{Dict, Matrix}}} = [] 
	
	# act on score opportunity if present
	if flag_pms

		# there could be multiple choices for opp_score -> array of new game states
		@inbounds pms_options::Dict = pm_scores_inspect[:scores_avail_player]

		# save choices in tree to be returned 
		setindex!(scenario_trees, pms_options, :scores_preMove_avail)

		# retrieve rings locations 
		_rings::Vector{CartesianIndex} = findall(==(_ring_id), ex_gs)

		# here we simulate possible combination sequences of scoring choices
		# retrieved from info[:s_sets] -> [ (1,2,4), (2,3,1), (4,5), ... ]
		@inbounds scoring_sets::Set{Set{Int}} = pms_options[:s_sets]

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
												:players_scores => last_scores),
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
			
			 for move_end in @inbounds nx_legal_moves[move_start]
				
				if move_start != move_end # -> if ring not dropped in-place
					
					sc_id::Dict{Symbol, CartesianIndex} = Dict{Symbol, CartesianIndex}(:start => move_start, :end => move_end)

					# simulate new game state for start/end combination
					move = Dict(:id => Dict(:player_id => nx_player_id, 
												:players_scores => last_scores),
												:move_action => sc_id)

					### we can flag end leaves if handling player's scores

					# simulate move and check for scoring opportunities
					sim_res = sim_new_gameState(gs, move, :move)

					# Tree summary -> scenarios for scoring opportunities
					f_score_player::Bool = haskey(sim_res, :scores_avail_player)
					f_score_opp::Bool = haskey(sim_res, :scores_avail_opp)
					

					# save scenario sim results (start -> end -> scenario)
					set_nested!(tree, sim_res, move_start, move_end)

					# save the id of each scenario accordingly
					f_score_player && push!(tree_sum[:score_player_sc], sc_id)
					f_score_opp && push!(tree_sum[:score_opp_sc], sc_id)

				else
					# save empty dict so same-loc drop is available in the tree -> !! rings with only such move available won't be in tree otherwise, impacts available legal moves in client
					
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
function gen_newGame(vs_server = false, random_rings = true)
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
	gs = gen_random_gameState(0, 0, random_rings)

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
		
	players_scores = Dict(_W => 0, _B => 0) # starting scores for both
	
	# precompute possible moves and scoring/flipping outcomes for each -> in client's format - compute trees only if necessary
	# same for ring drop spots (1st mover will use them)
	
	_scenario_trees = random_rings ? (sim_scenarioTrees(gs, first_moving, players_scores) |> reshape_out_fields) : Dict() 

	_ring_setup_spots = random_rings ? [] : (valid_empty_locs(gs) |> reshape_out)
	
	
	
	### package data for server storage

		# game identity
		_identity = Dict(:game_id => game_id,
						:game_type => (vs_server ? :h_vs_ai : :h_vs_h),
						:random_rings => (random_rings ? true : false),
						:orig_player_id => ORIG_player_id,
						:join_player_id => JOIN_player_id,
						:init_dateTime => now(),
						:status => GS_not_started,
						:end_dateTime => now(),
						:won_by => "",
						:outcome => "")
	
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
						:rings_mode => (random_rings ? :random : :manual),
						:rings => _rings,
						:markers => _markers, 
						:scenario_trees => _scenario_trees,
						:ring_setup_spots => _ring_setup_spots,
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
		save_newGame!(new_game_data)


	println("LOG - New game initialized - Game ID $game_id")
	return game_id
	
end

# ╔═╡ a6c68bb9-f7b4-4bed-ac06-315a80af9d2e
function fn_new_game_vs_human(ws, msg)
# human client (originator) wants new game to play against a nother human
## NOTE -> this and other new_game request fn could be unified

	# handle game settings/preferences in msg payload
	_random_rings = msg[:payload][:random_rings] # true (random) | false (manual)

	# generate and store new game data
	_new_game_id = gen_newGame(false, _random_rings)

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
	
	# handle game settings/preferences in msg payload
	_random_rings = msg[:payload][:random_rings] # true (random) | false (manual)
	
	# generate and store new game data
	_new_game_id = gen_newGame(true, _random_rings) 

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

	
	# assess & add last game status to payloads
	# info used by client, as server will infer & set status each time
	infer_set_game_transitions!(game_id)
	_game_status = get_gameStatus(game_id)

	# simulates possible moves and outcomes for each -> in client's format
	# as well as finding valid locs for manual ring placement
	# do each depending on game status
	_scenario_trees = Dict()
	_ring_setup_spots = []
	
	if _game_status == :progress_game
		#ex_score = get_player_score(game_id, nx_player_id)
		players_scores = get_scores_byID(game_id)
		_scenario_trees = sim_scenarioTrees(gs, nx_player_id, players_scores) |> reshape_out_fields
	elseif _game_status == :progress_rings
		_ring_setup_spots = valid_empty_locs(gs) |> reshape_out
	end
		
	### package data for client
	_cli_pkg = Dict(:game_id => game_id,
					:game_status => _game_status,
					:rings => _rings,
					:markers => _markers,
					:scenario_trees => _scenario_trees,
					:ring_setup_spots => _ring_setup_spots)
	
	
	# saves game to general log (DB?)
	save_new_clientPkg!(game_id, _cli_pkg)


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

	#= 
		TURN RECAP data format (same used internally by sim_game_state)

		ring_setup_action : -1
		score_actions_preMove : [ { mk_sel: -1, mk_locs: [], ring_score: -1 } ],
		move_action: { start: start_move_index, end: drop_loc_index },
		score_actions: [ { mk_sel: -1, mk_locs: [], ring_score: -1 } ], 
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
	_sc_id = Dict( 	:player_id => _player_id, 
				  	:players_scores => get_scores_byID(_game_code))

	# add ring_setup/pre-move/move/score info from client
	_sc_info = setindex!(srv_turn_recap, _sc_id, :id)
	
	#@info _sc_info
	new_gs_sim = sim_new_gameState(ex_gs, _sc_info, :replay)
	#@info new_gs_sim
	
	# update player score
	edit_player_score!(_game_code, _player_id, new_gs_sim[:new_player_score])

	# save new board state to log
	lock(games_lock)
		push!(games_log_dict[_game_code][:server_states], new_gs_sim[:new_game_state])
	unlock(games_lock)

	# infer & set new game state
	infer_set_game_transitions!(_game_code)

	# save delta for client (w/ client loc coordinates)
	lock(games_lock)
		push!(games_log_dict[_game_code][:client_delta], reshape_out_fields(new_gs_sim))
	unlock(games_lock)
	
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

	# logging
	_time_start::DateTime = now()
	num_px_moves::Int = 0 # num of possible moves (already excluding same start/end)
	num_pruned_moves::Int = 0 # num non-explored moves/trees
	max_i::Int = 0 # moves explored (if server moves)
	__pick_txt::String = "no_move" 


	# returning value
	turn_recap = Dict()

	#= output format for _turn_recap:
	
		note: fields only added if valued/done/non-default

		ring_setup_action : ring_loc
		score_actions_preMove : [ { mk_sel: -1, mk_locs: [], ring_score: -1 } ],
		move_action: { start: start_move_index, end: drop_loc_index },
		score_actions: [ { mk_sel: -1, mk_locs: [], ring_score: -1 } ], 
	
	=#

	# game parameters
	winning_score = 3 # should be configurable 

	# last game state in srv format
	ex_gs::Matrix{String} = deepcopy(get_last_srv_gameState(game_code, prev))

	### INFER GAME STATE
	## :progress_rings -> PLACE RING
	_game_progress_state = infer_set_game_transitions!(game_code)
	if _game_progress_state == GS_progress_rings

		# pick random spot for ring
		ring_setup_loc = valid_empty_locs(ex_gs) |> rand

		# prep response turn recap 
		setindex!(turn_recap, ring_setup_loc, :ring_setup_action)

		# early return
		__pick_txt = "ring_setup_action"
		@goto complete_turn
	end

	
	## :progress_game -> PLAY GAME 
	
	# scenarios
	players_scores = get_scores_byID(game_code)::Dict{String, Int}
	sim::Dict{Symbol, Any} = sim_scenarioTrees(ex_gs, srv_player_id, players_scores)

	# keep track of score across server play
	last_srv_score::Int = deepcopy(players_scores[srv_player_id]) 

	# ring id for this player
	_ring_id::String = srv_player_id == _W ? _RW : _RB

	
	# PLAY heuristic
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
	# set discovery function has found only scores set = max distance from score
	preMove_score_actions = Dict[]
	move_gs_id = Dict() # to be used later -> pick starting game state and its tree
	
	if haskey(sim, :scores_preMove_avail) # support for double scoring

		# extract data
		@inbounds pm_scores_info = sim[:scores_preMove_avail]

		# pick first longeste sequence set and save it
		@inbounds scoring_set_pick::Set{Int} = get_first_maxL(pm_scores_info[:s_sets])
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
			
		end

		# save all moves in turn recap
		setindex!(turn_recap, preMove_score_actions, :score_actions_preMove)
		
	end



	#= NOTE: check if game is over by score or max num of markers

		but, we might have just removed markers when the other player put the 51st marker - so the check on markers, and allowing for opponent to pick a score only if available, should be made before the server plays, and this 'last move' info passed as a parameter

		here we check just for the winning score -> we should have clean ends, without score + move when server wins
	=#
	
	if last_srv_score == winning_score
		__pick_txt = "pre-move score"
		@goto complete_turn
	end

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
	# prioritize moving actions that result in only a net score for us
	# among those, pick the scenarios with the longest scoring sequences 
	# avoid scoring also for the opponent while taking a score or us
	
	score_actions = Dict[]
	
	net_scoring_sc::Vector{Dict} = setdiff(score_player_sc, score_opp_sc)

		if !isempty(net_scoring_sc) # clean
			move_action = get_hScoring_sc(tree, net_scoring_sc)
			
		elseif !isempty(score_player_sc)  # risky
			move_action = get_hScoring_sc(tree, score_player_sc)
		end
	

		# if we have a scoring move -> save info {mk_locs, ring_score} for replay
		if !isempty(move_action)
			
			m_start::CartesianIndex = move_action[:start]
			m_end::CartesianIndex = move_action[:end]

			# extract scoring info
			@inbounds s_rows = tree[m_start][m_end][:scores_avail_player][:s_rows]
			@inbounds s_sets = tree[m_start][m_end][:scores_avail_player][:s_sets]

			# pick longest sequence among the sets
			set_pick::Set{Int} = get_first_maxL(s_sets)

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
	if isempty(move_action) # no move action taken yet 


		# split all possible moves in groups
		pruned_sc = Dict{Symbol, CartesianIndex}[]; # we score for other at step 1
		px_moves_sc = Dict{Symbol, CartesianIndex}[];  # candidate moves
			best_sc = Dict{Symbol, CartesianIndex}[]; # closer to score for us
			neutral_sc = Dict{Symbol, CartesianIndex}[]; # no closer to score for both
			risky_sc = Dict{Symbol, CartesianIndex}[]; # closer for both
			bad_sc = Dict{Symbol, CartesianIndex}[]; # closer for opponent only
	

		opp_player_id::String = srv_player_id == _W ? _B : _W
		
		# traverse the whole tree, all possible moves sc to be categorized later
		@inbounds for start_k in eachindex(tree), end_k in eachindex(tree[start_k])
			
			# exlude same-start/end moves
			if start_k != end_k

				# prep dict
				sc::Dict{Symbol, CartesianIndex} = Dict(:start => start_k,:end => end_k)

				# prune moves that score for the opponent at step 1
				if haskey(tree[start_k][end_k], :scores_avail_opp) 
					push!(pruned_sc, sc) 
					num_pruned_moves += 1
				else
					push!(px_moves_sc, sc) # keep for tree exploration
				end

			end
		end

		# play possible opponent's moves and categorize px-moves based on outcomes 
		num_px_moves = px_moves_sc |> length
		_last_scores = Dict(_W => 0, _B => 0) # TODO should reflect real vs potential 

		w_lock = ReentrantLock() # lock for writing to the sc arrays above
		best_found_yet = false # check if best option was already found 

		@sync for (i, sc) in enumerate(px_moves_sc) 

			if !best_found_yet 
				Threads.@spawn begin	
				
				new_gs::Matrix{String} = get_new_gs(tree, sc)::Matrix{String}
				new_sim::Dict = sim_scenarioTrees(new_gs, opp_player_id, _last_scores) 
	
				# inspect possible scoring outcomes 
				sim_check::Dict{Symbol, Bool} = inspect_trees_sums(new_sim[:treepots])
	
				# swapped player/opp - 'other' is the server player at depth 2
				server_score_px::Bool = sim_check[:opp_score_possible]
				user_score_px::Bool = sim_check[:player_score_possible]
	
				# replace below with a simpler scoring system for each outcome
				# 2x2 possible outcomes: best > neutral > risky > bad 
				f_best::Bool = server_score_px == true && user_score_px == false
				f_neutral::Bool = server_score_px == false && user_score_px == false
				f_risky::Bool = server_score_px == true && user_score_px == true
				f_bad::Bool = server_score_px == false && user_score_px == true
	
				# categorize sc, log when first best choice found
				lock(w_lock)

					max_i += 1 # keep track of how many generated & inspected trees
				
					f_best && push!(best_sc, sc) 
					f_neutral && push!(neutral_sc, sc)
					f_risky && push!(risky_sc, sc)
					f_bad && push!(bad_sc, sc)
	
					if f_best
						move_action = sc
						ft_best_found = true # flag best found
						__pick_txt = "best"
					end

				unlock(w_lock)

				GC.safepoint()

				end
			end
		end		


		## NO BEST MOVE -> pick from: neutral > risky > bad (> pruned)
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

			elseif !isempty(pruned_sc) # PRUNED (shouldn't happen, here for safety)
				move_action = rand(pruned_sc)
				__pick_txt = "pruned"

			end
		end
	
	end


	# save move action in turn recap
	# skipped only when a pre-move score wins the game, as of label below
	setindex!(turn_recap, move_action, :move_action)


	##### LOGGING & RETURN

	@label complete_turn 

	# logging
	_runtime::Int = (now() - _time_start).value
	_expl_rate::Int = (num_px_moves == max_i == 0) ? 0 : round(max_i/num_px_moves*100)

	println("LOG - Server turn, $__pick_txt pick - runtime: $(_runtime)ms - expl.rate: $(_expl_rate)% [ $num_px_moves ] - pruned: $num_pruned_moves")
	
	return turn_recap

catch e
	@error "ERROR during server play, $e"
	#stacktrace(catch_backtrace())
end

end

# ╔═╡ e6cc0cf6-617a-4231-826d-63f36d6136a5
function mark_player_ready!(game_code::String, who::Symbol)

# marks player as ready

	
	# which status to update? 
	_which_status = (who == :originator) ? :orig_player_status : :join_player_status
		
	# update status
	try
		lock(games_lock)
		games_log_dict[game_code][:players][_which_status] = :ready
	catch e
		e |> throw
	finally
		unlock(games_lock)
	end

end

# ╔═╡ cd06cad4-4b47-48dd-913f-61028ebe8cb3
function mark_player_resigned!(game_code::String, who::Symbol)

# marks player resigned

	
	# which status to update? 
	_which_status = (who == :originator) ? :orig_player_status : :join_player_status
		
	# update status
	try
		lock(games_lock)
		games_log_dict[game_code][:players][_which_status] = :resigned
	catch e
		e |> throw
	finally
		unlock(games_lock)
	end

end

# ╔═╡ 88616e0f-6c85-4bb2-a856-ea7cee1b187d
function game_runner(msg)
# this function takes care of orchestrating messages and running the game
# scenario: a game has been created and one or both players have joined
# players may have made or not a move, and asking to advance the game

	# check if necessary to reduce mem pressure
	# runs once every 2hrs or when available memory < 4% of total
	_mem_cleanup!()
	
	# retrieve game and caller move details
	_msg_code = msg[:msg_code]
	_game_code = msg[:payload][:game_id]
	_player_id = msg[:payload][:player_id]
	_who = whos_player(_game_code, _player_id) # :originator || :joiner
	_game_vs_ai_flag = is_game_vs_ai(_game_code)
	_turn_recap = msg[:payload][:turn_recap] 

	# turn recap structure
	# false || { :ring_setup_action , :move_action {}, :score_actions [{}], :preMove_score_actions [{}] }
	

	## RESPONSE TEMPLATES
	
		# for playing player (+ turn info)
		PLAY_payload::Dict{Symbol, Any} = Dict(key_nextActionCode => CODE_play)
		
		# for waiting player
		WAIT_payload::Dict{Symbol, Any} = Dict(key_nextActionCode => CODE_wait)
		
		# if game ends
		END_payload::Dict{Symbol, Any} = Dict(key_nextActionCode => CODE_end_game)
	
		# containers for CALLER / OTHER responses
		# swapped before returning depending on who plays next
		_caller_pld = Dict()
		_other_pld = Dict()


	# need this var in outer-scope, is overwritten/reused later
	end_check = Dict(:end_flag => false) 


	# UPDATE player status & handle resignations
		if _msg_code == CODE_advance_game # player ready
			mark_player_ready!(_game_code, _who)
		
		elseif _msg_code == CODE_resign_game # a player resigned
			
			# flag player as resigned
			mark_player_resigned!(_game_code, _who)
		
			# retrieve data on game end
			end_check = check_update_game_end!(_game_code)
		
			# add ending info to template payload
			merge!(END_payload, end_check)
		
			# inform both players with same base payload (END)
			PLAY_payload = deepcopy(END_payload)
			WAIT_payload = deepcopy(END_payload)
		end

	
	## REFLECT TURN DATA 
		if _turn_recap != false
		
			# update server state & generates delta for move replay
			update_serverStates!(_game_code, _player_id, _turn_recap)
			
			# move turn due to scenario being picked
			advance_turn!(_game_code, _turn_recap[:completed_turn_no])

			# check if game is over after last move (by score)
			end_check = check_update_game_end!(_game_code)
			
			if end_check[:end_flag] # true/false

				# add ending info to template payload
				merge!(END_payload, end_check)

				# inform both players with same base payload (END)
				PLAY_payload = deepcopy(END_payload)
				WAIT_payload = deepcopy(END_payload)

				println("LOG - Game $_game_code completed")

			end
			
			if !_game_vs_ai_flag # human vs human games (just pass on changes)

				# generate payload for next moving player
				merge!(PLAY_payload, fn_nextPlaying_payload(_game_code))
		
				# add turn information
				setindex!(PLAY_payload, get_last_turn_details(_game_code)[:turn_no], :turn_no)

			end
		end
	

	## HANDLE PLAY AND RESPONSES 
		if _game_vs_ai_flag # vs AI, make AI play and pass changes to human

			if is_human_playing_next(_game_code) # human plays current turn
				
				println("SRV - HUMAN plays next, passing on delta")

				# add turn information
				setindex!(PLAY_payload, get_last_turn_details(_game_code)[:turn_no], :turn_no)

				# inform human it's their turn
				_caller_pld = PLAY_payload
				
			else # AI plays current turn
				
				println("LOG - Server plays")

				if end_check[:end_flag] # AI loses by score or human resigned

					# alter caller payload, PLAY was modified at first end_check
					_caller_pld = PLAY_payload

				else # AI moves

					_ai_player_id = get_last_moving_player(_game_code)

					# move by SERVER/AI > sync server data
					_pick = play_turn_server(_game_code, _ai_player_id)
					update_serverStates!(_game_code, _ai_player_id, _pick, true)
					
					# mark turn completed
					_no_turn_played_by_ai = get_last_turn_details(_game_code)[:turn_no]

					
					# re-check if last AI play ended game
					end_check = check_update_game_end!(_game_code)
					if end_check[:end_flag]
						println("LOG - Game $_game_code completed")
					end
				
					if end_check[:end_flag] # AI beats human w/ last move
	
						# add ending info to template payload
						merge!(END_payload, end_check)
	
						# alter base payload
						PLAY_payload = deepcopy(END_payload)

					else

						# prep new turn for human
						advance_turn!(_game_code, _no_turn_played_by_ai)
						_new_turn_info = get_last_turn_details(_game_code)[:turn_no]

						# add turn information
						setindex!(PLAY_payload, _new_turn_info, :turn_no)
						
					end 

					# prepare payload for client (delta information)
					merge!(PLAY_payload, fn_nextPlaying_payload(_game_code))
					

					# alter called payload
					_caller_pld = PLAY_payload
					
				end
			end

		else # vs HUMAN, just handle payload swap - setup payload generated before

			# if both players ready 
			if check_both_players_ready(_game_code) 
	
				# check if the caller is who plays next
				_caller_plays = _is_playing_next(_game_code, _player_id)
		
				# assign/swap payloads accordingly
				# if game is over, both payloads are equal to END payload
				_caller_pld = _caller_plays ? PLAY_payload : WAIT_payload
				_other_pld = _caller_plays ? WAIT_payload : PLAY_payload 

			# if one resigned they're not both available
			elseif _msg_code == CODE_resign_game 
			
				# inform both players with same END payload (prepared above)
				_caller_pld = END_payload
				_other_pld = END_payload
				
			else # both players not ready, tell the caller to wait
				_caller_pld = WAIT_payload
				
			end

		end		


	# formally start the game and update game_status
	# this should be triggered only on first turn after setup
	# ideally need to cleanup pkg gen / runner pipeline
	_not_started_yet = get_gameStatus(_game_code) == GS_not_started

	# regardless, add game status to payloads if missing 
	gs_in_caller = haskey(_caller_pld, :game_status)
	gs_in_other = haskey(_other_pld, :game_status)

	if _not_started_yet || !gs_in_caller || !gs_in_other
		gs = infer_set_game_transitions!(_game_code)
		setindex!(_caller_pld, gs, :game_status)
		setindex!(_other_pld, gs, :game_status)
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
		stacktrace(catch_backtrace())
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
function msg_handler(ws, msg)

# handles messages depending on their code
# every incoming message should have an id and code - if they're missing, throw error

	# try retrieving specific values (msg header)
	_msg_id = get(msg, :msg_id, nothing)
	_msg_code = get(msg, :msg_code, nothing)
	_msg_payload = get(msg, :payload, nothing)

	# if messages are valid, run matching function 
	if !isnothing(_msg_id) && (_msg_code in allowed_CODES)

		try

			# all functions called here return two dictionaries
			# matchign functions allow to generate/join a new game, or advance one
			_pld_caller, _pld_other = codes_toFun_match[_msg_code](ws, msg)

				# reply to caller, including code-specific response
				msg_dispatcher(ws, _msg_id, _msg_code, _pld_caller)
				
			# if payload is not empty, assumes game already exists
			# game vs other human player, informed with 'other' payload
			if !isempty(_pld_other) && !is_game_vs_ai(_msg_payload[:game_id])

				# game and player id are in the original msg as game exists
				_game_id = _msg_payload[:game_id]
				_player_id = _msg_payload[:player_id]

				# identify caller
				_who = whos_player(_game_id, _player_id)
				_is_caller_originator = (_who == :originator) ? true : false

				# retrieve ws handler for other
				_other_identity_flag = !_is_caller_originator

				# BUT other might not have joined yet
				# this can also be a new game request
				# also, the msg_id in this case is the one of the orig request, but not a problem as clients handle both responses & push msg
				if check_both_players_ready(_game_id)
					_ws_other = get_ws_handler(_game_id, _other_identity_flag)
					msg_dispatcher(_ws_other, _msg_id, _msg_code, _pld_other)
				end
			
			end

		catch e

			# reply to client with error
			msg_dispatcher(ws, _msg_id, _msg_code, Dict(:server_msg => "Error when handling request, $e"), false)

			println("ERROR in msg_handler - $e")

		end


	else

		# if fields are missing, also give error
		msg_dispatcher(ws, _msg_id, _msg_code, Dict(:server_msg => "Error, missing msg_id and/or invalid msg_code"), false)
		
		_err = "ERROR in msg_handler - missing msg_id and/or invalid msg_code"
		println(_err)
		@error _errr
	end


end

# ╔═╡ d5239071-d71a-4e56-a938-5051e23a07de
function start_ws_server()


	# start new server 
    ws_server = WebSockets.listen!(ws_ip, ws_port; verbose = true) do ws

		for msg in ws

			# message handler & downstream functions have their own task/thread
			@spawn try

				# save received messages as-is
				lock(msg_lock)
					push!(ws_msg_log_raw, msg)
				unlock(msg_lock)

				# parse incoming msg as JL Dict -> then keys from String to Symbol
				# we could halve time (~4 -> 2 micro_s) if skip key conversion
				# but would need to use Strings when reading client's msgs
				parsed_msg = JSON3.read(msg, Dict) |> dict_keys_to_sym
				
				# save parsed message
				setindex!(parsed_msg, "received", :type)
				lock(msg_lock)
					push!(ws_msg_log, parsed_msg)
				unlock(msg_lock)

				# pass msg on
				msg_handler(ws, parsed_msg)
			
			catch e
				@error "ERROR - Message handler error, $e"
			end
		end
		
    end

	
	_info = "LOG - New Websocket server started: $(ws_server.task)"
	@info _info
	println(_info)

	# saves server handler & task for reference
    push!(ws_array, ws_server)
	
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

# ╔═╡ b1e9aafc-6473-4114-a5d5-b0c3114eab7d
function start_ws_watchdog()
# this function is mostly needed due to the reactive nature of Pluto,
# anytime we change something in any related function, all linked cells are re-executed, and the ws server is initiated again
# need to close previous one to avoid errors, as new tries to listen on same ip/port

	## on first run
	
	# terminate any running watchdog(s) - by InterruptException
	terminate_active_watchdog!()

	# terminate any active websockets
	terminate_active_ws!()
	
	sleep(1)

	# start new watchdog
	watchdog_task = @spawn try 

			#ws_array |> empty!

			while true
				try
				
					# start websocket server if there's none or they're all done
					if isempty(ws_array) || all(ws -> istaskdone(ws.task), ws_array)
						start_ws_server()				
					end

				catch e
					
					if isa(e, Base.IOError) && occursin("EADDRINUSE", e.msg)
						# port already in use, re-start was too early
						@warn "WARNING - ws start, port already in use $e"
						sleep(1)	
						terminate_active_ws!()
					else
						rethrow(e)
					end
				end
				
				sleep(5) # re-checks every 5 sec
			end
				
		catch e
			if isa(e, InterruptException)
	            @warn "LOG - Websocket watchdog terminated"
	        else
				@error "ERROR - ws watchdog, $e"
				rethrow(e)
	        end
		end

	@info "LOG - New watchdog started: $watchdog_task"
    
    # save watchdog task reference
    push!(ws_watchdog, watchdog_task)

end

# ╔═╡ 721547b0-7be1-41d6-bffe-cb82a5c294cd
start_ws_watchdog()

# ╔═╡ 24185d12-d29c-4e72-a1de-a28319b4d369
# make it wait forever when running as a script
# (as this cell is not wrapped in begin/end, it's never executed in pluto, and so it doesn't hang the main thread)
println("> Service running")
wait(Condition())

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Combinatorics = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
JSON3 = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"

[compat]
Combinatorics = "~1.0.2"
HTTP = "~1.10.15"
JSON3 = "~1.14.1"
StatsBase = "~0.34.4"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.1"
manifest_format = "2.0"
project_hash = "a83dd56650c9f3967f1c72a6471bffdc425a53fd"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BitFlags]]
git-tree-sha1 = "0691e34b3bb8be9307330f88d1a3c3f25466c24d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.9"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "bce6804e5e6044c6daab27bb533d1295e4a2e759"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.6"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "f36e5e8fdffcb5646ea5da81495a5a7566005127"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.4.3"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "d36f682e590a83d63d1c7dbd287573764682d12a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.11"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "PrecompileTools", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "c67b33b085f6e2faf8bf79a61962e7339a81129c"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.15"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "a007feb38b422fbdab534406aeca1b86823cb4d6"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.0"

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "PrecompileTools", "StructTypes", "UUIDs"]
git-tree-sha1 = "1d322381ef7b087548321d3f878cb4c9bd8f8f9b"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.14.1"

    [deps.JSON3.extensions]
    JSON3ArrowExt = ["ArrowTypes"]

    [deps.JSON3.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

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
version = "1.11.0"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "f02b56007b064fbfddb4c9cd60161b6dd0f40df3"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.1.0"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "38cb508d080d21dc1128f7fb04f20387ed4c0af4"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.3"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f58782a883ecbf9fb48dcd363f9ccd65f36c23a8"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.0.15+2"

[[deps.OrderedCollections]]
git-tree-sha1 = "12f1439c4f986bb868acda6ea33ebc78e19b95ad"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.7.0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.PtrArrays]]
git-tree-sha1 = "77a42d78b6a92df47ab37e177b2deac405e1c88f"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.2.1"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "f305871d2f381d21527c770d4788c06c097c9bc1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.2.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.11.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["AliasTables", "DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "29321314c920c26684834965ec2ce0dacc9cf8e5"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.4"

[[deps.StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "159331b30e94d7b11379037feeb9b690950cace8"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.11.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.7.0+0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"
"""

# ╔═╡ Cell order:
# ╠═69c4770e-1091-4744-950c-ed23deb55661
# ╠═6f0ad323-1776-4efd-bf1e-667e8a834f41
# ╠═e68b41fc-cbf5-477f-b211-2462d835def0
# ╠═c2797a4c-81d3-4409-9038-117fe50540a8
# ╠═13cb8a74-8f5e-48eb-89c6-f7429d616fb9
# ╠═70ecd4ed-cbb1-4ebd-85a8-42f7b072bee3
# ╠═bd7e7cdd-878e-475e-b2bb-b00c636ff26a
# ╠═d489db2d-3e73-44bd-aeb6-bfe17775d20c
# ╠═f6dc2723-ab4a-42fc-855e-d74915b4dcbf
# ╠═43f89626-8583-11ed-2b3d-b118ff996f37
# ╠═20bc797e-c99b-417d-8921-9b95c8e21679
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
# ╟─bc19e42a-fc82-4191-bca5-09622198d102
# ╟─e0368e81-fb5a-4dc4-aebb-130c7fd0a123
# ╟─57153574-e5ca-4167-814e-2d176baa0de9
# ╟─1fe8a98e-6dc6-466e-9bc9-406c416d8076
# ╟─156c508f-2026-4619-9632-d679ca2cae50
# ╟─823ce280-15c4-410f-8216-efad03897282
# ╟─c0c45548-9792-4969-9147-93f09411a71f
# ╟─dd941045-3b5f-4393-a6ae-b3d1f029a585
# ╟─39d81ecc-ecf5-491f-bb6e-1e545f10bfd0
# ╟─69b9885f-96bd-4f8d-9bde-9ac09521f435
# ╟─18f8a5d6-c775-44a3-9490-cd11352c4a63
# ╟─67b8c557-1cf2-465d-a888-6b77f3940f39
# ╟─0d5558ca-7e01-4ed2-8b37-61649690346a
# ╟─a27e0adf-aa09-42ee-97f5-ede084a9edc3
# ╟─cf587261-6193-4e7a-a3e8-e24ba27929c7
# ╟─439903cb-c2d1-49d8-a5ef-59dbff96e792
# ╟─f86b195e-06a9-493d-8536-16bdcaadd60e
# ╟─466eaa12-3a55-4ee9-9f2d-ac2320b0f6b1
# ╟─b170050e-cb51-47ec-9870-909ec141dc3d
# ╠═c9233e3f-1d2c-4f6f-b86d-b6767c3f83a2
# ╠═691404a6-53bc-4340-a750-636fe219f633
# ╠═1160c8c0-8a90-4c89-898f-328749611a76
# ╟─91c35ba0-729e-4ea9-8848-3887936a8a21
# ╠═0bb77295-be29-4b50-bff8-f712ebe08197
# ╠═721547b0-7be1-41d6-bffe-cb82a5c294cd
# ╠═4fad24a9-f75b-48c1-8990-041c75afc09c
# ╟─7c026677-5c44-4a12-99a4-2d1228e31795
# ╟─5ff005dd-2347-4dc3-a24f-42cb576822fc
# ╟─b1e9aafc-6473-4114-a5d5-b0c3114eab7d
# ╟─d5239071-d71a-4e56-a938-5051e23a07de
# ╟─5e5366a9-3086-4210-a037-c56e1374a686
# ╟─7316a125-3bfe-4bac-babf-4e3db953078b
# ╟─ca522939-422f-482a-8658-452790c463f6
# ╟─612a1121-b672-4bc7-9eee-f7989ac27346
# ╟─064496dc-4e23-4242-9e25-a41ddbaf59d1
# ╟─28ee9310-9b7d-4169-bae4-615e4b2c386e
# ╟─a6c68bb9-f7b4-4bed-ac06-315a80af9d2e
# ╟─32307f96-6503-4dbc-bf5e-49cf253fbfb2
# ╟─ac87a771-1d91-4ade-ad39-271205c1e16e
# ╟─ca346015-b2c9-45da-8c1e-17493274aca2
# ╟─88616e0f-6c85-4bb2-a856-ea7cee1b187d
# ╟─69152551-c381-42f0-9ef6-a1c4ea969b34
# ╟─61d75e9e-b2d3-4551-947b-e8acc11e2eeb
# ╟─a7b92ca8-8a39-4332-bab9-ed612bf24c17
# ╟─384e2313-e1c7-4221-8bcf-142b0a49bff2
# ╟─5d6e868b-50a9-420b-8533-5db4c5d8f72c
# ╟─c77607ad-c11b-4fd3-bac9-6c43d71ae932
# ╟─b5c7295e-c464-4f57-8556-c36b9a5df6ca
# ╟─92a20829-9f0a-4ed2-9fd3-2d6560514e03
# ╟─13eb72c7-ac24-4b93-8fd9-260b49940370
# ╟─8929062f-0d97-41f9-99dd-99d51f01b664
# ╟─f7fe7ff7-0fff-4740-9aec-56354fdca9a3
# ╟─ebd8e962-2150-4ada-8ebd-3eba6e29c12e
# ╟─af5a7cbf-8f9c-42e0-9f8f-6d3561635c40
# ╟─5ae493f4-346d-40ce-830f-909ec40de8d0
# ╟─276dd93c-05f9-46b1-909c-1d449c07e2b5
# ╟─8797a304-aa98-4ce0-ab0b-759df0256fa7
# ╟─0193d14a-9e55-42c2-97d6-2a0bef50da1e
# ╟─f55bb88f-ecce-4c14-b9ac-4fc975c3592e
# ╟─b2b31d4e-75c7-4232-b486-a4515d01408b
# ╟─fdb40907-1047-41e5-9d39-3f94b06b91c0
# ╟─67322d28-5f9e-43da-90a0-2e517b003b58
# ╟─f1c0e395-1b22-4e68-8d2d-49d6fc71e7d9
# ╟─c38bfef9-2e3a-4042-8bd0-05f1e1bcc10b
# ╠═20a8fbe0-5840-4a70-be33-b4103df291a1
# ╟─59efcc6c-7ec7-4ac7-8510-ae9257d0ff23
# ╟─d4e9c5b2-4eb5-44a5-a221-399d77b50db3
# ╟─cb8ffb39-073d-4f2b-9df4-53febcf3ca99
# ╟─8b830eee-ae0a-4c9f-a16b-34045b4bef6f
# ╟─de5356b7-1c9d-4065-9ef2-4db1575249c4
# ╟─fa924233-8ada-4289-9249-b6731edab371
# ╟─eb3b3182-2e32-40f8-adf7-062691bf53c6
# ╟─09c1e858-09ae-44b2-9de7-e73f1b4f188d
# ╟─c6e915be-2853-48ff-a8da-49755b9b1a44
# ╟─8e1673fe-5286-43cd-8830-fba353f1cd89
# ╟─ea7779ea-cd11-4f9e-8022-ff4f370ffddd
# ╟─3d09a15d-685b-4d9b-a47f-95067441928d
# ╟─e785f43f-0902-4b7b-874b-bf1c09438970
# ╟─e6cc0cf6-617a-4231-826d-63f36d6136a5
# ╟─cd06cad4-4b47-48dd-913f-61028ebe8cb3
# ╠═24185d12-d29c-4e72-a1de-a28319b4d369
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
