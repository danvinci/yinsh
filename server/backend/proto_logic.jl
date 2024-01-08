### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# ╔═╡ 6f0ad323-1776-4efd-bf1e-667e8a834f41
using Random

# ╔═╡ c2797a4c-81d3-4409-9038-117fe50540a8
using StatsBase

# ╔═╡ 13cb8a74-8f5e-48eb-89c6-f7429d616fb9
using Dates

# ╔═╡ 70ecd4ed-cbb1-4ebd-85a8-42f7b072bee3
using HTTP, JSON3

# ╔═╡ bd7e7cdd-878e-475e-b2bb-b00c636ff26a
using HTTP.WebSockets

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
row_m = 19; col_m = 11;

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


# ╔═╡ 00468008-0cbc-4f68-832b-2a5b46431fb7
# call printing function
#printable_base_m()

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
function bounds_check(row::Int, col::Int)
	
	if mm_yinsh_01[row, col] == 1
		return true
	else
		return false
	end
	
end

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

# ╔═╡ 003f670b-d3b1-4905-b105-67504f16ba19
# populate dictionary of locations search space 
function populate_searchSpace!(store_dict::Dict)

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
		cartIndex_ranges = []

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
		setindex!(store_dict, cartIndex_ranges, key)

	end

end

# ╔═╡ 1d811aa5-940b-4ddd-908d-e94fe3635a6a
# pre-populate dictionary with search space for each starting location

begin
	locs_searchSpace = Dict{CartesianIndex, Any}()
	populate_searchSpace!(locs_searchSpace)
end

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
function populate_searchSpace_scoring!(store_dict::Dict)

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
		cartIndex_ranges = []

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
		setindex!(store_dict, cartIndex_ranges, key)

	end

end

# ╔═╡ 2cee3e2b-5061-40f4-a205-94d80cfdc20b
# pre-populate dictionary with search space (scoring)

begin
	locs_searchSpace_scoring = Dict{CartesianIndex, Any}()
	populate_searchSpace_scoring!(locs_searchSpace_scoring)
end

# ╔═╡ 9700ea30-a99c-4832-a181-7ef23c86030a
function _pick_rand_locsRow()
# used for generating starting points for replicating close-to-scoring scenarios
	
	return rand(rand(locs_searchSpace_scoring).second)

end

# ╔═╡ 52bf45df-d3cd-45bb-bc94-ec9f4cf850ad
function keepValid(state, input_array)

	# create a copy to avoid modifying location arrays
	loc_array = input_array

	# recovering states for all indexes in temp array
	states_array = [state[z] for z in loc_array]

	# cutting at the first ring encountered
	firstRing_index = findfirst(x -> contains(x,"R"), states_array)

	if firstRing_index !== nothing
		# slice locations array to be returned
		loc_array = loc_array[1:firstRing_index-1]
		
		# keeping states array updated
		states_array = [state[z] for z in loc_array]
	end


	# searching for the first empty spot after a marker
	# if range is 1:0 or 1:-1 collection is empty and cycle is skipped
	for i in 1:length(states_array)-1
		if contains(states_array[i],"M") == true && states_array[i+1] == ""
			# slice locations array to be returned
			loc_array = loc_array[1:i+1]

			# keeping states array fresh
			states_array = [state[z] for z in loc_array]
			break
		end
	end


	# remove existing markers from set of valid locations	
	loc_array = filter(z -> !contains(state[z], "M"), loc_array)
			
	
	return loc_array

end

# ╔═╡ 9d153cf1-3e3b-49c0-abe7-ebd0f524557c
function _search_legal_srv(ref_state::Matrix, start_index::CartesianIndex)
# returns sub-array of valid moves
# this function is used by the server to compute allowable moves in advance 
# using server types (matrix, cartesian indexes) both in input and output
	
	# checks that row/col are valid
	if !(start_index in keys(locs_searchSpace))
		return [] 
	end

	# retrieve search space for the starting point
	search_space = locs_searchSpace[start_index]

	# array to be returned
	search_return = CartesianIndex[]

	for range in search_space

		# check valid moves in each range and append them to returning array
		append!(search_return, keepValid(ref_state, range)) 

	end

	# append starting index (can drop the ring from where picked)
	append!(search_return, [start_index]) 

return search_return

end

# ╔═╡ c67154cb-c8cc-406c-90a8-0ea8241d8571
function markers_toFlip_search(state, input_array)
	
	# create a copy to avoid modifying location arrays
	loc_array = input_array

	# recovering states for all indexes in temp array
	states_array = [state[z] for z in loc_array]

	# cutting at the first ring encountered
	# the first ring is the one that was moved!
	firstRing_index = findfirst(x -> contains(x,"R"), states_array)

	if firstRing_index !== nothing
		# slice locations array 
		loc_array = loc_array[1:firstRing_index-1]
	end

	# pick markers from set of remaining locations	
	loc_array = filter(z -> contains(state[z], "M"), loc_array)

	
	## return bits to inform client of which case is unfolding
	# FLIP_FLAG
	# true -> nothing to flip
	# false -> something to flip

	flip_flag = (length(loc_array) > 0) ? true : false

	# returns true/false if markers flip and their locations 
	return flip_flag, loc_array

end

# ╔═╡ 53dec9b0-dac1-47a6-b242-9696ff45b91b
function score_lookup(state, mks_toFlip_ids)
	# look at the game state to check if a score was made
	# passing markers about to flip as their state hasn't changed yet

	# all markers locations
	gs_markers_locs = findall(i -> contains(i, "M"), state)
	
	# as the markers haven't been flipped (yet) we must anticipate it
	## build object to reference when it comes to about-to-be mk states
	anticipated_states = Dict()

		# for each marker to be flipped, swapped its current state
		# assumed that state will only return MW or MB - i.e. a marker is there
		for mk_index in mks_toFlip_ids
	
			ant_mk_state = (state[mk_index] == "MW") ? "MB" : "MW"
	
			setindex!(anticipated_states, ant_mk_state, mk_index)
			
		end

	# values to be returned
	num_scoring_rows = Dict(:tot => 0, :B => 0, :W => 0)
	scoring_details = []

	# helper array to store found locations for scoring markers
	found_ss_locs = []

	for mk_index in gs_markers_locs

		# for each marker retrieve search space for scoring
		ss_locs_arrays = locs_searchSpace_scoring[mk_index]

		for ss_locs in ss_locs_arrays
				
			# reading states for all indexes in loc search array
			# if the index is of a flipped array, read from anticipated states
			# otherwise read from the existing state

			states_array = []
			for index in ss_locs
				
				if index in mks_toFlip_ids
					push!(states_array, anticipated_states[index])
				else
					push!(states_array, state[index])
				end
					
			end
	
			# search if a score was made in loc
			MB_count = count(s -> isequal(s, "MB"), states_array)
				black_scoring = MB_count == 5 ? true : false
			
			MW_count = count(s -> isequal(s, "MW"), states_array)
				white_scoring = MW_count == 5 ? true : false

			# if a score was made
			if black_scoring || white_scoring
				# log who's the player
				scoring_player = black_scoring ? "B" : "W"

				# save the row but check that scoring row wasn't saved already
				# scoring locs are the same for each marker in it due to sorting
				# if not found already, save it
				if !(ss_locs in found_ss_locs)

					# save score_row details
					score_row = Dict(:mk_locs => ss_locs, :player => scoring_player)
			
					push!(scoring_details, score_row)
					
					# keep count of scoring rows (total and per player)
					num_scoring_rows[:tot] += 1	
					
						if black_scoring
							num_scoring_rows[:B] += 1
						elseif white_scoring
							num_scoring_rows[:W] += 1
						end

					# save array of locations to simplify future checks
					push!(found_ss_locs, ss_locs)
				
				end		
				
			end	
		end
	end

	## handling case of multiple scoring rows in the same move + row selection
	if num_scoring_rows[:tot] >= 1

		# scoring rows: find markers outside intersection and use them for selection
		# guaranteed to find at least 1 for each series (found_locs helps)

		all_scoring_mk_ids = []
		for row in scoring_details
			append!(all_scoring_mk_ids, row[:mk_locs])
		end

		# frequency count of each marker location ID
		mk_ids_fCount = countmap(all_scoring_mk_ids)

		# keep track of sel markers already taken (by CartIndex)
		mk_sel_taken = []
		
		for (row_id, row) in enumerate(scoring_details)

			# temp copy of locations, to avoid modifying the original array
			temp_locs = copy(row[:mk_locs])

			# build search array of locations in row by exluding taken locations
			if !isempty(mk_sel_taken)

				indexes_toRemove = findall(m -> m in mk_sel_taken, temp_locs)
				if !isempty(indexes_toRemove)

					deleteat!(temp_locs, indexes_toRemove)
				end
			end
				

			# find marker with min frequency that hasn't been already taken
			min_fr, min_fr_index = findmin(i -> mk_ids_fCount[i], temp_locs)
			mk_sel = temp_locs[min_fr_index]
				
			# save mk_sel in row collection to be returned
			setindex!(scoring_details[row_id], mk_sel, :mk_sel)

			# store mk_sel in array (useful for solving conflicts later)
			push!(mk_sel_taken, mk_sel)
		end
	end

	return num_scoring_rows, scoring_details

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
return_IN_lookup, return_OUT_lookup = reshape_lookupDicts_create();

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

# ╔═╡ 33707130-7703-4aa0-84e6-23ab387c0c4d
# returns sub-array of valid moves
# this function is used by the server to compute allowable moves in advance 
# using server types (matrix, cartesian indexes) vs client types (array, int)
# functions could be unified but likely the other will be killed
function search_loc_srv(game_state_srv, start_index_srv::CartesianIndex)

	# the client state must be reshaped
	ref_state = game_state_srv

	# copying startstart index needs no conversion
	start_index = start_index_srv
	
	# checks that row/col are valid
	if !(start_index in keys(locs_searchSpace))
		return [] 
	end

	# retrieve search space for the starting point
	search_space = locs_searchSpace[start_index]

	# array to be returned
	search_return = CartesianIndex[]

	for range in search_space

		# check valid moves in each range and append them to returning array
		append!(search_return, keepValid(ref_state, range)) 

	end

	# append starting index (can drop the ring from where picked)
	append!(search_return, [start_index]) 

return reshape_out(search_return) # convert to linear indexes

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

# ╔═╡ bf2dce8c-f026-40e3-89db-d72edb0b041c
# returns sub-array of valid moves
function search_loc(client_state, client_start_index::Int64)

	# the client state must be reshaped
	ref_state = reshape([s for s in client_state], 19, 11)

	# the client start index needs to be converted to CI (row, col)
	start_index = reshape_in(client_start_index)
	
	# checks that row/col are valid
	if !(start_index in keys(locs_searchSpace))
		return [] 
	end

	# retrieve search space for the starting point
	search_space = locs_searchSpace[start_index]

	# array to be returned
	search_return = CartesianIndex[]

	for range in search_space

		# check valid moves in each range and append them to returning array
		append!(search_return, keepValid(ref_state, range)) 

	end

	# append starting index (can drop the ring from where picked)
	append!(search_return, [start_index]) 

return reshape_out(search_return) # convert to linear indexes

end

# ╔═╡ 8f2e4816-b60d-40eb-a9d8-acf4240c646a
function markers_actions(client_state, client_start_index, client_end_index)

	# it's useful that state is queried only once and then passed as an argument downstream (if/when the state will be stored somewhere all could be passed could be a game ID that points to an object that's updated by a separate function)
	# to measure changes in latency under load

	## HANDLE INPUT FROM CLIENT
	# the client state must be reshaped
	ref_state = reshape([s for s in client_state], 19, 11)

	# the client start index needs to be converted to CI (row, col)
	start_index = reshape_in(client_start_index)
	end_index = reshape_in(client_end_index)
	
	## DOES STUFF
	# checks that end both start and end are valid -> otherwise return no markers
	valid_locs = keys(locs_searchSpace)
	if (!(start_index in valid_locs) || !(end_index in valid_locs))
		return [] 
	end

	# case of ring picked up and dropped in same location
	if start_index == end_index 
		return [] 
	end

	# retrieve search space for the starting point
	search_space = locs_searchSpace[start_index]


	direction = 0

	# spot direction/array that contains the ring 
	for (i, range) in enumerate(search_space)

		# check if search_temp contains end_index
		if (end_index in range)
			 direction = i
			break
		end
	end

	# return flag + markers to flip in direction of movement
	flip_flag, markers_toFlip = markers_toFlip_search(ref_state, search_space[direction])

	# pass markers about to flip for checking score
	num_sc_rows, sc_details = score_lookup(ref_state, markers_toFlip)

	# reshape indexes for scoring rows and mk_sel (if any) before returning
	if num_sc_rows[:tot] > 0
		for (row_id, row) in enumerate(sc_details)
			sc_details[row_id][:mk_locs] = reshape_out(row[:mk_locs])
			sc_details[row_id][:mk_sel] = reshape_out(row[:mk_sel])
		end
	end

	# reshaping index of results -> doing this after array has been used as input
	markers_toFlip = reshape_out(markers_toFlip)

	
	return Dict("flip_flag" => flip_flag, 
				"markers_toFlip" => markers_toFlip,
				"num_scoring_rows" => num_sc_rows,
				"scoring_details" => sc_details)


end

# ╔═╡ c334b67e-594f-49fc-8c11-be4ea11c33b5
function gen_random_gameState(white_ring, black_ring, _near_score_mks = false)
# generate a new random game state (server format)

	## pick 10 random starting valid locations (without replacement)
	
	keys_loc = findall(x -> x==1, mm_yinsh_01)
	sampled_locs = sample(keys_loc, 10, replace = false)

	# empty state (server format)
	server_game_state = fill("",19,11)

	# write down state in those locations
	for (i, loc) in enumerate(sampled_locs)

		# write each odd/even
		server_game_state[loc] = (i%2 == 0) ? white_ring : black_ring

	end

	# add a 4-markers row for a player
	if _near_score_mks

		_rand_locs_row = _pick_rand_locsRow()

		# !!! subtract locations already taken for rings
		_pot_mks_locs = setdiff(_rand_locs_row, sampled_locs)
		_sampled_mk_locsRow = []
		_sam = 4

		@label retry_sampling
		try 
			# @info _sam
			_sampled_mk_locsRow = sample(_pot_mks_locs, _sam, replace = false)
	
		catch #not enough samples
			_sam -= 1
			@goto retry_sampling
		end
			
			
		_lucky_player = rand(["W", "B"])

		for loc in _sampled_mk_locsRow
			server_game_state[loc] = "M"*_lucky_player
		end

	end
	

	return server_game_state
end

# ╔═╡ 29a93299-f577-4114-b77f-dbc079392090
begin
# global parameters for identifying rings and markers

	white_id = "W"
	black_id = "B"
	ring_id = "R"
	marker_id = "M"

end

# ╔═╡ 61a0e2bf-2fed-4141-afc0-c8b5507679d1
md"#### Server-side storage of game data"


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

	_ret = Dict{Any, Any}() # keys can be symbols or int

	for (k,v) in srv_dict

		## updating the key of it's a CI
		_nk = isa(k, CartesianIndex) ? reshape_out(k) : k
		
		## checking which case we'll have to handle
			# CI 
			f_CI = isa(v, CartesianIndex)
	
			# DICT
			f_DICT = isa(v, Dict)
	
			# non-empty array
			f_ne_ARR = isa(v, Array) && !isempty(v)
	
				# CI-array
				f_ne_ARR_CI = f_ne_ARR && isa(v[begin], CartesianIndex)
	
				# DICT-array
				f_ne_ARR_DICT = f_ne_ARR && isa(v[begin], Dict)

		
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
			
		else # leave value as-is
			setindex!(_ret, v, _nk)
			
		end
	end

	return _ret
	
end

# ╔═╡ 5da79176-7005-4afe-91b7-accaac0bd7b5
function static_score_lookup(state)
	# look at the game state to check if there are scoring opportunities
	# ASSUMES MOVE IS DONE AND AFFECTED MARKERS HAVE BEEN FLIPPED

	# all markers locations
	gs_markers_locs = findall(i -> contains(i, "M"), state)

	# values to be returned
	num_scoring_rows = Dict(:tot => 0, :B => 0, :W => 0)
	scoring_details = []

	# helper array to store found locations for scoring markers
	found_ss_locs = []

	for mk_index in gs_markers_locs

		# for each marker retrieve search space for scoring
		ss_locs_arrays = locs_searchSpace_scoring[mk_index]

		for ss_locs in ss_locs_arrays
				
			# reading states for all indexes in loc search array

			states_array = []
			for index in ss_locs
				push!(states_array, state[index])
			end
					
	
			# search if a score was made in loc
			MB_count = count(s -> isequal(s, "MB"), states_array)
				black_scoring = MB_count == 5 ? true : false
			
			MW_count = count(s -> isequal(s, "MW"), states_array)
				white_scoring = MW_count == 5 ? true : false

			# if a score was made
			if black_scoring || white_scoring
				# log who's the player
				scoring_player = black_scoring ? "B" : "W"

				# save the row but check that scoring row wasn't saved already
				# scoring locs are the same for each marker in it due to sorting
				# if not found already, save it
				if !(ss_locs in found_ss_locs)

					# save score_row details
					score_row = Dict(:mk_locs => ss_locs, :player => scoring_player)
			
					push!(scoring_details, score_row)
					
					# keep count of scoring rows (total and per player)
					num_scoring_rows[:tot] += 1	
					
						if black_scoring
							num_scoring_rows[:B] += 1
						elseif white_scoring
							num_scoring_rows[:W] += 1
						end

					# save array of locations to simplify future checks
					push!(found_ss_locs, ss_locs)
				
				end		
				
			end	
		end
	end

	## handling case of multiple scoring rows in the same move + row selection
	if num_scoring_rows[:tot] >= 1

		# scoring rows: find markers outside intersection and use them for selection
		# guaranteed to find at least 1 for each series (found_locs helps)

		all_scoring_mk_ids = []
		for row in scoring_details
			append!(all_scoring_mk_ids, row[:mk_locs])
		end

		# frequency count of each marker location ID
		mk_ids_fCount = countmap(all_scoring_mk_ids)

		# keep track of sel markers already taken (by CartIndex)
		mk_sel_taken = []
		
		for (row_id, row) in enumerate(scoring_details)

			# temp copy of locations, to avoid modifying the original array
			temp_locs = copy(row[:mk_locs])

			# build search array of locations in row by exluding taken locations
			if !isempty(mk_sel_taken)

				indexes_toRemove = findall(m -> m in mk_sel_taken, temp_locs)
				if !isempty(indexes_toRemove)

					deleteat!(temp_locs, indexes_toRemove)
				end
			end
				

			# find marker with min frequency that hasn't been already taken
			min_fr, min_fr_index = findmin(i -> mk_ids_fCount[i], temp_locs)
			mk_sel = temp_locs[min_fr_index]
				
			# save mk_sel in row collection to be returned
			setindex!(scoring_details[row_id], mk_sel, :mk_sel)

			# store mk_sel in array (useful for solving conflicts later)
			push!(mk_sel_taken, mk_sel)
		end
	end

	return num_scoring_rows, scoring_details

end

# ╔═╡ aaa8c614-16aa-4ca8-9ec5-f4f4c6574240
function gen_New_gameState(ex_game_state, start_move, end_move, mk_sel = CartesianIndex(0,0), score_ring_index = CartesianIndex(0,0))
# generates new game state, starting from an existing one + start/end moves
# assumes start/end are valid moves AND in cartesian indexes
# works with game state in server-side format (matrix)

	# return game state delta (used later to replay moves)
	_return = Dict()

	# baseline game state that we'll modify and return later
	new_gs = deepcopy(ex_game_state)

	# check which case of game update we're dealing with
		# score handled
		_no_scoring_def_server = CartesianIndex(0,0)

		_scoring_handled = (mk_sel != _no_scoring_def_server && 
						score_ring_index != _no_scoring_def_server) ? true : false
	
	if start_move == end_move # ring dropped where picked, nothing happens
		
			return ex_game_state

	else # ring moved elsewhere -> game state changed

		# get ring details
		picked_ring = ex_game_state[start_move]
		picked_ring_color = picked_ring[end] # RW, RB -> should work with identifiers

		added_marker = Dict(:cli_index => reshape_out(start_move), 
							:player_id => picked_ring_color)

		moved_ring = Dict(:cli_index_start => reshape_out(start_move),
							:cli_index_end => reshape_out(end_move),
							:player_id => picked_ring_color)

		# marker placed in start_move (same color as picked ring)
		new_gs[start_move] = "M"*picked_ring_color # should work with identifiers
		
		# ring placed in end_move # -> assumes valid move
		new_gs[end_move] = picked_ring

		# markers flipped (if any)

			# retrieve search space for the starting point
			search_space = locs_searchSpace[start_move]
		
			direction = 0
		
			# spot direction/array that contains the ring 
			for (i, range) in enumerate(search_space)
		
				# check if search_temp contains end_index
				if (end_move in range)
					 direction = i
					break
				end
			end
		
			# return flag + ids of markers to flip in direction of movement
			flip_flag, markers_toFlip = markers_toFlip_search(new_gs, search_space[direction])

			if flip_flag
				# actually flip markers in game state
				for m_id in markers_toFlip
					if contains(new_gs[m_id], 'M')
	
						new_gs[m_id] = (new_gs[m_id] == "MW") ? "MB" : "MW" 
					end
				end
			end

			# checks scoring opportunities
			scoring_rows, scores_toHandle = static_score_lookup(new_gs)
			score_flag = (scoring_rows[:tot] >= 1) ? true : false	

			_mk_to_remove = []
			# if score -> replay mk selection, mk row removal, scoring ring removal
			if score_flag && _scoring_handled

				# markers to remove
				_mk_to_remove = first(filter(s -> s[:mk_sel] == mk_sel, scores_toHandle))[:mk_locs]

				# clean game state for markers ids
				foreach(mk -> new_gs[mk] = "", _mk_to_remove)

				# remove ring
				new_gs[score_ring_index] = ""
			
			end
	end



		if _scoring_handled
			_return = Dict( :new_game_state_srv => new_gs, 
							:flip_flag => flip_flag,
							:markers_toFlip_srv => markers_toFlip,
							:markers_toFlip_cli => reshape_out(markers_toFlip),
							:added_marker_cli => added_marker,
							:moved_ring_cli => moved_ring,
							:score_handled => true,
							:markers_toRemove_srv => _mk_to_remove,
							:markers_toRemove_cli => reshape_out(_mk_to_remove),
							:scoring_ring_srv => score_ring_index,
							:scoring_ring_cli => reshape_out(score_ring_index)
							)

		else 
			_return = Dict( :new_game_state_srv => new_gs, 
							:flip_flag => flip_flag,
							:markers_toFlip_srv => markers_toFlip,
							:markers_toFlip_cli => reshape_out(markers_toFlip),
							:added_marker_cli => added_marker,
							:moved_ring_cli => moved_ring,
							:score_handled => false
							)
	
		end

	
	return _return

end

# ╔═╡ 1f021cc5-edb0-4515-b8c9-6a2395bc9547
function gen_scenarioTree(ex_game_state, next_movingPlayer)
# takes as input game state (server format) and info of next moving player
# computes results for all possible moves of next moving player
# output is reshaped for client's consumption

# scenario tree to be returned
scenario_tree = Dict()

# add summary to tree (only relevant for moving player)
summary = Dict(:global_score_flag => false, 
				:global_flip_flag => false,
				:scoring_moves => [],
				:flipping_moves => [])
setindex!(scenario_tree, summary, :summary)

# find all rings for next moving player on the board (should use IDs)
rings_locs = findall(i -> isequal(i, "R"*next_movingPlayer), ex_game_state)

# find legal moves for next moving player
next_legalMoves = Dict()
for loc in rings_locs
	legal_moves = _search_legal_srv(ex_game_state, loc) # search for moves
	setindex!(next_legalMoves, legal_moves, loc)
end

# for each move start
for move_start in collect(keys(next_legalMoves))

	# for each move end
	for move_end in next_legalMoves[move_start]

		if move_end == move_start # nothing happens
			continue
		else # something happens

			# generate new game state for start/end combination
			# new state will have ring in new location and markers flipped
			# saves if markers need to flip and which IDs
			new_gs_delta = gen_New_gameState(ex_game_state, move_start, move_end)

				new_game_state = new_gs_delta[:new_game_state_srv]
				flip_flag = new_gs_delta[:flip_flag]
				markers_toFlip = new_gs_delta[:markers_toFlip_srv]

			# checks scoring opportunities
			scoring_rows, scores_toHandle = static_score_lookup(new_game_state)
			score_flag = (scoring_rows[:tot] >= 1) ? true : false	
			
			# save all in a single scenario -> for client consumption
			s_first_key = reshape_out(move_start) # linear indexes
			s_second_key = reshape_out(move_end)
			s_value = Dict()

			## make scenario data lighter -> only write extra data if flags true
			# scoring details
			setindex!(s_value, score_flag, :score_flag)
			if score_flag

				# log in summary
				scenario_tree[:summary][:global_score_flag] = true
				push!(scenario_tree[:summary][:scoring_moves], Dict(:start => s_first_key, :end => s_second_key))

				# reshape for client consumption
				for (row_id, row) in enumerate(scores_toHandle)
					scores_toHandle[row_id][:mk_locs] = reshape_out(row[:mk_locs])
					scores_toHandle[row_id][:mk_sel] = reshape_out(row[:mk_sel])
				end
					
					setindex!(s_value, scores_toHandle, :scores_toHandle)
			end
			
			# markers details
			setindex!(s_value, flip_flag, :flip_flag)
			if flip_flag

				# log in summary
				scenario_tree[:summary][:global_flip_flag] = true
				push!(scenario_tree[:summary][:flipping_moves], Dict(:start => s_first_key, :end => s_second_key))
				
				# saving reshaped indexes
				setindex!(s_value, reshape_out(markers_toFlip), :markers_toFlip)
			end
			
			## save scenario in tree (first_key -> second_key -> scenario)
			# test if root branch already created
			if haskey(scenario_tree, s_first_key)

				setindex!(scenario_tree[s_first_key], s_value, s_second_key)
			
			else #create root branch first
				setindex!(scenario_tree, Dict(s_second_key => s_value), s_first_key)
			end
			
		end
	end
end

return scenario_tree

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

	# scoring options can be multiple, we read mks_removed data
	() score_action_preMove -> opponent scored for player at the end of their turn
			mk_sel
			mk_locs
			ring_score
	
	() move_action  
	  		start 
			end

	() score_action
			mk_sel
			mk_locs
			ring_score

=#

	## extract relevant flags from input (given by presence of keys in dict)
	_f_score_action_preMove = haskey(sc, :score_action_preMove)
	_f_move_action = haskey(sc, :move_action)
	_f_score_action = haskey(sc, :score_action)

	# extract player_id (B/W)
	_player_id = sc[:id][:player_id]
	_opp_id = _player_id == "W" ? "B" : "W"

	# baseline game state that we'll modify and return later
	new_gs = copy(ex_game_state)
	new_player_score = sc[:id][:player_score]
	# new_opp_score = sc[:id][:opp_score] # it won't be touched

	# dict to return w/ game state delta - used for replay or add leaves to the tree
	_return = Dict()

	#= OUTPUT structure - fields are added only if valued
	
		:score_preMove_done => (:mk_locs => CI[], :ring_score => CI) 
		:move_done => (:mk_add => (loc, player), :ring_move = (start, end, player))
		:mk_flip => CI[]
		:score_done => (:mk_locs => CI[], :ring_score => CI) 
		:score_avail_opp => Dict[] # (mk_locs, mk_sel, player)
		:score_avail_player => Dict[] # (mk_locs, mk_sel, player)

		+ :new_game_state + :mode + :new_player_score (added before return)
		(not added for now -> :new_opp_score)

	=#
	
	################## EDITING unctions

	function score_preMove_do!() # pre-move scoring - ie. opp scored for player
	
		# remove markers from game state
		pms_mks_locs = sc[:score_action_preMove][:mk_locs]
		foreach(mk_id -> new_gs[mk_id] = "", pms_mks_locs)

		# remove ring
		pms_ring_loc = sc[:score_action_preMove][:ring_score]
		new_gs[pms_ring_loc] = ""

		# update player score
		new_player_score += 1

		# update global dict
			_pms = Dict(:mk_locs => pms_mks_locs, :ring_score => pms_ring_loc)
			setindex!(_return, _pms, :score_preMove_done)
		
	end

	function move_do!() # ring moved -> mk placement -> flipping

		_start_move_id = sc[:move_action][:start]
		_end_move_id = sc[:move_action][:end]

		# get ring details
		moved_ring = ex_game_state[_start_move_id]
		_ring_color = moved_ring[end] # B || W

		# marker placed in start_move (same color as picked ring / player_id)
		new_gs[_start_move_id] = "M"*_ring_color 
		
		# ring placed in end_move 
		new_gs[_end_move_id] = moved_ring

		# flip markers in the moving direction

		# retrieve search space for the starting point, ie. ring directions
		r_dirs = locs_searchSpace[_start_move_id]

		# spot direction/array that contains the ring 
		dir_no = findfirst(rd -> (_end_move_id in rd), r_dirs)
	
		# return flag + ids of markers to flip in direction of movement
		_flip_flag, mks_toFlip = markers_toFlip_search(new_gs, r_dirs[dir_no])

		if _flip_flag # flip markers in game state
			for m_id in mks_toFlip
				if contains(new_gs[m_id], "M")
					new_gs[m_id] = (new_gs[m_id] == "MW") ? "MB" : "MW" 
				end
			end
		end

		# update global dict
			mk_add = Dict(:loc => _start_move_id, :player_id => _ring_color)
			ring_move = Dict(:start => _start_move_id, 
							 :end => _end_move_id, 						
							 :player_id => _ring_color)
			
			_md = Dict(:mk_add => mk_add, :ring_move => ring_move)
			setindex!(_return, _md, :move_done)	
		
			_flip_flag && setindex!(_return, mks_toFlip, :mk_flip)	

	end

	function score_do!() # post-move scoring

		# remove markers from game state
		sd_mks_locs = sc[:score_action][:mk_locs]
		foreach(mk_id -> new_gs[mk_id] = "", sd_mks_locs)

		# remove ring
		sd_ring_loc = sc[:score_action][:ring_score]
		new_gs[sd_ring_loc] = ""

		# update player score
		new_player_score += 1

		# update global dict
			_sd = Dict(:mk_locs => sd_mks_locs, :ring_score => sd_ring_loc)
			setindex!(_return, _sd, :score_done)

	end

	function score_check!() # post-move scoring

		# check scoring options
		score_rows, score_det = static_score_lookup(new_gs)

		# check scoring ops
		_f_score_player = (score_rows[Symbol(_player_id)] >= 1) ? true : false
		_f_score_opp = (score_rows[Symbol(_opp_id)] >= 1) ? true : false

		player_scores = Dict[] #[(mk_locs, mk_sel, player)]
		opp_scores = Dict[]

		append!(player_scores, filter(s -> s[:player] == _player_id, score_det))
		append!(opp_scores, filter(s -> s[:player] == _opp_id, score_det))

		# update global dict -> is there a score available for either player or opp?
			_f_score_player && setindex!(_return, player_scores, :score_avail_player)
			_f_score_opp && setindex!(_return, opp_scores, :score_avail_opp)

	end
	

	################## ACTING on input mode
	if fn_mode == :replay # whole turn
		
		_f_score_action_preMove && score_preMove_do!() 
		_f_move_action && move_do!()
		_f_score_action && score_do!()

	elseif fn_mode == :move # single move -> check score

		_f_move_action && move_do!()
		score_check!()
	
	elseif fn_mode == :inspect # just check

		score_check!()

	end

	# add updated player score
	setindex!(_return, new_player_score, :new_player_score)
	# add opp score as-is
	# setindex!(_return, new_opp_score, :new_opp_score)

	# add last game state and calling mode to _return
	setindex!(_return, new_gs, :new_game_state)
	setindex!(_return, fn_mode, :mode)
	

	return _return

end

# ╔═╡ 156c508f-2026-4619-9632-d679ca2cae50
function sim_scenarioTree(ex_gs::Matrix, nx_player_id::String, nx_player_score::Int)
# takes as input an ex game state (server format) and info of next moving player
# computes results for all possible moves of next moving player

	scenario_tree = Dict() # to be returned

	#= SCENARIO TREE structure
	
		() :score_preMove_avail => [ options ] 
	
		!/() :game_trees => [(:gs_id, :gs, :tree)] (id is mk_sel & ring_score of premove or absent if only 1 branch)
	
			:tree => ( :start => :end => flags/deltas)

	=#
	

	# identify any pre-move score to be acted on - ie. left by previous player
	_pms_id = Dict(:id => Dict( :player_id => nx_player_id, 
								:player_score => nx_player_score))
	
	_inspect_res = sim_new_gameState(ex_gs, _pms_id, :inspect)
	flag_pms = haskey(_inspect_res, :score_avail_player)

	# act on score opportunity if present
	_g_trees_array = []
	if flag_pms

		# there could be multiple choices for opp_score -> array of new game states
		_pms_choices = _inspect_res[:score_avail_player]

		# save choices in tree to be returned
		setindex!(scenario_tree, _pms_choices, :score_preMove_avail)
		
		for s_choice in _pms_choices
			
			# gen new game state for the opp scoring opportunity
			# branch further on the picked ring

			_player_rings = findall(i -> isequal(i, "R"*nx_player_id), ex_gs)

			for r in _player_rings

				# describe pre-move score action
				_pms_action = Dict( :mk_sel => s_choice[:mk_sel],
									:mk_locs => s_choice[:mk_locs], 
									:ring_score => r) 

				_sc = Dict( :id => Dict(:player_id => nx_player_id, 
										:player_score => nx_player_score),
							:score_action_preMove => _pms_action)
			
				# replay move and get new game state
				_pms_replay_gs = sim_new_gameState(ex_gs, _sc, :replay)[:new_game_state]
				
				# save each of the possible game states
				# identifying each by means of the action taken
				# client knows which tree to pick depending on pre-move score action
				_gs_id = Dict( :mk_sel => s_choice[:mk_sel], :ring_score => r) 
				_pms_gs_start = Dict(:gs_id => _gs_id, :gs => _pms_replay_gs)

				push!(_g_trees_array, _pms_gs_start)
			
			end
		end

		# increase player score as pre-move score took place
		nx_player_score += 1

	else # save only available starting game state (no pre move) 

		push!(_g_trees_array, Dict{Symbol, Any}(:gs => ex_gs))
		
	end


	# ex_gs -> [score_preMove_avail] -> [_g_trees_array] -> [moves] -> [scenarios]

	#= 	_g_trees_array = [Dict( 	:gs_id => score_action_preMove
									:gs => game_state
									:tree => () 						)] =#

	# NOTE: if the game ends at the pre-move score, we should indicate it, so we skip tree generation
	
	# iterate over all the possible starting game states
	for g_branch in _g_trees_array

		# prep empty tree for each game state, along with its summary
		g_tree = Dict()
		# turn summary to avoid traversing each tree, saving scenario_ids per case
		g_tree_sum = Dict(:flip_sc=> [], :score_player_sc=> [], :score_opp_sc=> []) 

		# extract gs details
		gs = g_branch[:gs]
		
		# find all rings for next moving player in this game state
		rings = findall(i -> isequal(i, "R"*nx_player_id), gs)

		# find legal moves for each of the rings start loc and save them
		nx_legal_moves = Dict()
		foreach(r -> setindex!(nx_legal_moves, _search_legal_srv(gs, r), r), rings)

		# for each start
		for move_start in rings # keys of the nx_legal_moves dict anyway

			# for each move end
			for move_end in nx_legal_moves[move_start]
				if move_start != move_end # -> ring not dropped in-place

					_sc_id = Dict(:start => move_start, :end => move_end)

					# simulate new game state for start/end combination
					_move = Dict(:id => Dict( 	:player_id => nx_player_id, 
												:player_score => nx_player_score),
								 :move_action => _sc_id)
					
					sim_res = sim_new_gameState(gs, _move, :move)


					# save flags for flip and score opportunities
					# avoid traversing the whole tree later for AI play
					# we care to only save true cases for each
					
					f_mk_flip = haskey(sim_res, :mk_flip)
					f_score_player = haskey(sim_res, :score_avail_player)
					f_score_opp = haskey(sim_res, :score_avail_opp)

						# save the id of each scenario accordingly
						f_mk_flip && push!(g_tree_sum[:flip_sc], _sc_id)
						f_score_player && push!(g_tree_sum[:score_player_sc], _sc_id)
						f_score_opp && push!(g_tree_sum[:score_opp_sc], _sc_id)

						# save summary of tree
						setindex!(g_tree, g_tree_sum, :summary)
	
					# save scenario in tree (start -> end -> scenario)
					set_nested!(g_tree, sim_res, move_start, move_end)
					
				end
			end
		end

		# save tree in 
		setindex!(g_branch, g_tree, :tree)

	end
	

	# save tree of possible game moves for each starting game state
	setindex!(scenario_tree, _g_trees_array, :move_trees)
	

	return scenario_tree

end

# ╔═╡ f1949d12-86eb-4236-b887-b750916d3493
function gen_newGame(vs_ai=false)
# initializes new game, saves data server-side and returns object for client

	white_ring = ring_id * white_id
	black_ring = ring_id * black_id

	# generate random game identifier (only uppercase letters)
	game_id = randstring(['A':'Z'; '0':'9'], 6)

	# pick the id of the originating vs joining player -> should be a setting
	ORIG_player_id = rand([white_id, black_id]) 
	JOIN_player_id = (ORIG_player_id == white_id) ? black_id : white_id

	# set next moving player -> should be a setting (for now always white)
	next_movingPlayer = white_id 

	# generate random initial game state (server format)
	# TEMP GENERATING STATES w/ 4MKS in a row for random player
	_game_state = gen_random_gameState(white_ring, black_ring, true)

	# RINGS
		# retrieves location ids in client format 
		whiteRings_ids = reshape_out(findall(i -> i == white_ring, _game_state))
		blackRings_ids = reshape_out(findall(i -> i == black_ring, _game_state))
	
		white_rings = [Dict(:id => id, :player => white_id) for id in whiteRings_ids]
		black_rings = [Dict(:id => id, :player => black_id) for id in blackRings_ids]
	
		# prepare rings array to be sent to client
		rings = union(white_rings, black_rings)

	# MARKERS
		# retrieves location ids in client format 
		whiteMKS_ids = reshape_out(findall(i -> i == "MW", _game_state))
		blackMKS_ids = reshape_out(findall(i -> i == "MB", _game_state))
		
		white_mks = [Dict(:id => id, :player => white_id) for id in whiteMKS_ids]
		black_mks = [Dict(:id => id, :player => black_id) for id in blackMKS_ids]

		# prepare markers array to be sent to client
		__mks = union(white_mks, black_mks)
		
	# simulates possible moves and scoring/flipping outcomes for each
	scenario_tree = gen_scenarioTree(_game_state, next_movingPlayer)

		# sneaking new format it, alongside old one
		_new_scenario = sim_scenarioTree(_game_state, next_movingPlayer, 0) |> s -> reshape_out_fields(s)
	
	
	### package data for server storage

		game_status = :not_started

		# game identity
		_identity = Dict(:game_id => game_id,
						:game_type => (vs_ai ? :h_vs_ai : :h_vs_h),
						:orig_player_id => ORIG_player_id,
						:join_player_id => JOIN_player_id,
						:init_dateTime => now(),
						:status => game_status,
						:end_dateTime => now(),
						:won_by => :undef,
						:won_why => :undef)
	
		# logs of game messages (one per player)
		_players = Dict(:orig_player_status => :not_available,
						:join_player_status => (vs_ai ? :ready : :not_available),
						:orig_player_score => 0, 
						:join_player_score => 0)
		
		# first game state (server format)
		_srv_states = [_game_state]

	

		
		### package data for client
		_cli_pkg = Dict(:game_id => game_id,
						:orig_player_id => ORIG_player_id,
						:join_player_id => JOIN_player_id,
						:rings => rings,
						:markers => __mks, # no markers yet
						:scenarioTree => scenario_tree,
						:new_scenario => _new_scenario,
						:turn_no => 1) # first game turn

		_first_turn = Dict(:turn_no => 1,
							:status => :open,
							:moving_player => next_movingPlayer)

	
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
function print_gameState(server_game_state)
	# print matrix easy copying in js code
	mm_to_print = ""
	
	for i in 1:row_m
		for j in 1:col_m

			if server_game_state[i,j] == ""
				print_val = "  "
			else
				print_val = server_game_state[i,j]
			end
			
			if j == 1 
				mm_to_print *= "[" * string(print_val) * ", "
			
			elseif j == col_m 
				mm_to_print *= string(print_val) * "] \n"
				
			else
				mm_to_print *= string(print_val) * ", "
			end
		end
	end

print(mm_to_print)

end

# ╔═╡ dffafbec-3c1e-4f93-852b-e890a94b7e5c
print_gameState(gen_random_gameState("RW", "RB", true))

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
	ws_servers_array = []; # array of server handles
	ws_messages_log = []; # log for all received messages
	ws_messages_log_OG = []; # log for all received messages (only parsing)
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
function dict_keys_to_sym(input::Dict{String, Any})::Dict{Symbol, Any}
# swaps dict keys from String to Symbol
	
	_new = Dict{Symbol, Any}()

	for (k,v) in input

		# is key a string ?
		_nkey = isa(k, String) ? Symbol(k) : k

		# is value a Dict ?
		_nval = isa(v, Dict) ? dict_keys_to_sym(v) : v

		# write 
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
	
#= expected input from client

	score_action_preMove : { mk_sel: -1, mk_locs: [], ring_score: -1 },
	move_action: { start: start_move_index, end: drop_loc_index },
	score_action: { mk_sel: -1, mk_locs: [], ring_score: -1 }, 
	completed_turn_no: _played_turn_no     

=#
	_srv_recap = Dict()

	# keep only dicts that have non-default values in their fields
	for (k, v) in recap
		if isa(v, Dict)
			if haskey(v, :mk_sel) && v[:mk_sel] != -1 && v[:ring_score] != -1
				
				setindex!(_srv_recap, v, k) 
			elseif haskey(v, :start)
				setindex!(_srv_recap, v, k)
			end
		end
	end

	reshape_in(_srv_recap) # defined only on julia dicts 
	
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

# ╔═╡ 4f3e9400-6eb7-4ffb-bf5b-887d523e00a4
function temp_sim_delta_translation(sim::Dict)::Dict
# temporary function to allow for gradual phasing out of old data format
# extracts and translates info from new_gs_sim to client delta payload format
# returns translated payload 


#= Ref data structure of INPUT sim
		
		:score_preMove_done => (:mk_locs => CI[], :ring_score => CI) 
		:move_done => ( :mk_add => (loc, player_id), 
						:ring_move = (start, end, player_id))
		:mk_flip => CI[]
		:score_done => (:mk_locs => CI[], :ring_score => CI) 
		:score_avail_opp => Dict[] # (mk_locs, mk_sel, player)
		:score_avail_player => Dict[] # (mk_locs, mk_sel, player)

=#

	_ret = copy(sim) # copy existing data, substitute use over time downstream 

	if haskey(sim, :move_done)

		# added marker
		_mk_add = Dict(:cli_index => sim[:move_done][:mk_add][:loc], 
						:player_id => sim[:move_done][:mk_add][:player_id])
		
			setindex!(_ret, _mk_add, :added_marker)

		# moved ring
		_moved_ring = Dict(:cli_index_start => sim[:move_done][:ring_move][:start],
							:cli_index_end => sim[:move_done][:ring_move][:end],
							:player_id => sim[:move_done][:ring_move][:player_id])

			setindex!(_ret, _moved_ring, :moved_ring)

		# flipped markers
		if haskey(sim, :mk_flip)
			
			setindex!(_ret, true, :flip_flag)
			setindex!(_ret, sim[:mk_flip], :markers_toFlip)

		else
			setindex!(_ret, false, :flip_flag)
		end

		# score handled
		if haskey(sim, :score_done)

			setindex!(_ret, true, :score_handled)
			setindex!(_ret, sim[:score_done][:mk_locs], :markers_toRemove)
			setindex!(_ret, sim[:score_done][:ring_score], :scoring_ring)

		else
			setindex!(_ret, false, :score_handled)
		end
		
		
	end

	

	# translate everything in client's format before returning

	return reshape_out_fields(_ret)
		
end

# ╔═╡ 67322d28-5f9e-43da-90a0-2e517b003b58
swap_player_id(player_id) = ( player_id == "W") ? "B" : "W"

# ╔═╡ f1c0e395-1b22-4e68-8d2d-49d6fc71e7d9
get_last_srv_gameState(game_id) = games_log_dict[game_id][:server_states][end]

# ╔═╡ e0368e81-fb5a-4dc4-aebb-130c7fd0a123
function gen_new_clientPkg(game_id, moving_client_id)
# generates follow up responses for the client, whenever the preceding turn is completed by the other player or AI


	# constants for players and game objects
	white_id = "W"
	black_id = "B"
	ring_id = "R"
	marker_id = "M"

	white_ring = ring_id * white_id
	black_ring = ring_id * black_id
	
	white_mk = marker_id * white_id
	black_mk = marker_id * black_id
	
	# set next moving player (invoking function knows who's turn is it)
	next_movingPlayer = moving_client_id 

	# retrieve latest game state (server format)
	_game_state = get_last_srv_gameState(game_id)

	## RINGS
		# retrieves location ids in client format 
		whiteRings_ids = reshape_out(findall(i -> i == white_ring, _game_state))
		blackRings_ids = reshape_out(findall(i -> i == black_ring, _game_state))
	
		white_rings = [Dict(:id => id, :player => white_id) for id in whiteRings_ids]
		black_rings = [Dict(:id => id, :player => black_id) for id in blackRings_ids]
	
		# prepare rings array to be sent to client
		rings = union(white_rings, black_rings)

	## MARKERS
		# retrieves location ids in client format 
		whiteMarkers_ids = reshape_out(findall(i -> i == white_mk, _game_state))
		blackMarkers_ids = reshape_out(findall(i -> i == black_mk, _game_state))
	
		whiteMks = [Dict(:id => id, :player => white_id) for id in whiteMarkers_ids]
		blackMks = [Dict(:id => id, :player => black_id) for id in blackMarkers_ids]
	
		# prepare markers array to be sent to client
		markers = union(whiteMks, blackMks)
	

	# simulates possible moves and outcomes for each
	scenario_tree = gen_scenarioTree(_game_state, next_movingPlayer)

	# sneaking new format it, alongside old one
	_ex_score = get_player_score(game_id, next_movingPlayer)
	_new_scenario = sim_scenarioTree(_game_state, next_movingPlayer, _ex_score) |> s -> reshape_out_fields(s)
		
	### package data for client
	_cli_pkg = Dict(:game_id => game_id,
					:rings => rings,
					:markers => markers,
					:scenarioTree => scenario_tree,
					:new_scenario => _new_scenario)
	
	
	# saves game to general log (DB?)
	save_new_clientPkg!(games_log_dict, game_id, _cli_pkg)


	println("LOG - New client pkg created for game: $game_id")
	
	
end

# ╔═╡ f55bb88f-ecce-4c14-b9ac-4fc975c3592e
function update_serverStates!(_game_code, _player_id, turn_recap)
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

	## extract info from turn recap data, convert moves to server indexes
	# drops non actionable fields and dicts w/ default values
	# it should be good as-is to be fed into sim_new_gameState
	srv_turn_recap = strip_reshape_in_recap(turn_recap)	
	
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


	# extract delta to be logged and passed onto client
	_delta_client = temp_sim_delta_translation(new_gs_sim)
	#@info _delta_client # let's see what's inside

	# save delta for client
	push!(games_log_dict[_game_code][:client_delta], _delta_client)
	
	println("LOG - Server game state and delta updated")


end

# ╔═╡ c38bfef9-2e3a-4042-8bd0-05f1e1bcc10b
function get_last_moving_player(game_code)

	_current_turn = games_log_dict[game_code][:turns][:current]

	return games_log_dict[game_code][:turns][:data][_current_turn][:moving_player]

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

# ╔═╡ 9fdbf307-1067-4f55-ac56-8335ecc84962
function temp_ai_pick_translation(pick::Dict)::Dict

	#= need to translate IN the AI pick in this format:
	
		score_action_preMove : { mk_sel: -1, mk_locs: [], ring_score: -1 },
		move_action: { start: start_move_index, end: drop_loc_index },
		score_action: { mk_sel: -1, mk_locs: [], ring_score: -1 }, 
		completed_turn_no: _played_turn_no  


	from this format:

	flip || random move :start => _start_k, 
						:end => _end_k

	scoring pick 	:start => _picked_start,
					:end => _picked_end,
					:mk_locs => _mk_locs,
					:mk_sel_pick => _mk_sel, 
					:ring_removed => _scoring_ring

	=#

	_ret = Dict{Symbol, Any}()

	# we assume it always has a move
	_move = Dict(:start => pick[:start], :end => pick[:end])
		setindex!(_ret, _move, :move_action)

	# need to check if we scored
	if haskey(pick, :mk_sel_pick)

		# prep score object
		_score = Dict( 	:mk_sel => pick[:mk_sel_pick],
						:mk_locs => pick[:mk_locs],
						:ring_score => pick[:ring_removed])

			setindex!(_ret, _score, :score_action)
		
	end

	return _ret

end

# ╔═╡ 4976c9c5-d60d-4b19-aa72-0e135ad37361
function pick_flipping_move(_ex_game_state, _tree::Dict, _player_id::String)
## filter flipping options for specific player
## pick first flipping opportunity that results in something flipping to the player's color

	_pick_found = false
	_picked_start = 0
	_picked_end = 0
	
	# possible flipping moves
	_f_moves = _tree[:summary][:flipping_moves]

	for move in _f_moves

		start_m = move[:start] 
		end_m = move[:end] 	
		
		# which leads to a marker flipping to black?
		_possible_flips = _tree[start_m][end_m][:markers_toFlip]
		for _mk_flip_id in _possible_flips

			_mk_state::String = _ex_game_state[reshape_in(_mk_flip_id)] # need to reshape
			if !contains(_mk_state, _player_id) # -> ! as it's yet to flip

				# we need at least one marker flipping to the player's color
				_pick_found = true

				_picked_start = start_m
				_picked_end = end_m

				break
				
			end
		end
	end

	return Dict(:pick_found => _pick_found, 
				:start => _picked_start,
				:end => _picked_end)


end

# ╔═╡ 1c970cc9-de1f-48cf-aa81-684d209689e0
function pick_scoring_move(_tree::Dict, _player_id::String)
## filter scoring options for specific player
## pick first scoring opportunity

	_pick_found = false
	_picked_start = 0
	_picked_end = 0
	_mk_sel = []
	_mk_locs = []
	_scoring_ring = 0

	# the tree only has keys for the player's rings 
	_rings = filter(k -> typeof(k) == Int, collect(keys(_tree)))
	
	# possible scoring moves
	_s_moves = _tree[:summary][:scoring_moves]

	for move in _s_moves

		start_m = move[:start] 
		end_m = move[:end] 	
		
		# which leads to a score for the player?

		_possible_scores = _tree[start_m][end_m][:scores_toHandle]
		for _score in  _possible_scores
			if _score[:player] == _player_id
				
				_pick_found = true

				_picked_start = start_m
				_picked_end = end_m
				_mk_sel = _score[:mk_sel]
				_mk_locs = _score[:mk_locs]

				# pick scoring ring at random
				# BUT rings have changed due to the move -> swap p_start w/ p_end
				_post_rings = replace(_rings, _picked_start => _picked_end)
				_scoring_ring = rand(_post_rings)

				break
				
			end
		end
	end

	return Dict(:pick_found => _pick_found, 
				:start => _picked_start,
				:end => _picked_end,
				:mk_sel_pick => _mk_sel, 
				:mk_locs => _mk_locs,
				:ring_removed => _scoring_ring)


end

# ╔═╡ 14aa5b7c-9065-4ca3-b0e9-19c104b1854d
function scenario_choice(_ex_game_state, _tree::Dict, ai_moving_player_id::String)
	# value function for picking moves
	# works with depth-1 game scenario trees
	# important to pass id of player so that it picks with context
	# returned values/ids are in client-format
	# it should return a move as long as at least one is listed in the tree

	# track if choice made
	_choice_made = false
	_return_pick = Dict() # to be returned

	# retrieve summary function
	global_score_flag = _tree[:summary][:global_score_flag]
	global_flip_flag = _tree[:summary][:global_flip_flag]

	# pick scoring option for current player if available
	if global_score_flag

		# check which ones result in a score for current player
		_score_pick = pick_scoring_move(_tree, ai_moving_player_id)

		if get(_score_pick, :pick_found, false)
			_choice_made = true
			_return_pick = _score_pick
			println("LOG - Scoring move picked")

			return _score_pick
		end
	end


	# if none, pick something that leads to markers being flipped to black
	if global_flip_flag && !_choice_made

		# check which ones result in a score for current player
		_flip_pick = pick_flipping_move(_ex_game_state, _tree, ai_moving_player_id)
		
		if get(_flip_pick, :pick_found, false)
			_choice_made = true
			_return_pick = _flip_pick
			println("LOG - Flip move picked")

			return _flip_pick
		end
	end
			
	
	# otherwise, make a random move
	if !_choice_made
		
		_start_k = filter(k -> typeof(k) == Int, collect(keys(_tree))) |> rand
		_end_k = collect(keys(_tree[_start_k])) |> rand

		_random_pick = Dict(:start => _start_k, 
							:end => _end_k)

		println("LOG - Random move picked")

		return _random_pick

	end

end

# ╔═╡ 6a174abd-c9bc-4c3c-93f0-05a7d70db4af
function play_turn_AI(game_code::String, ai_moving_player_id::String)

	# get last game state and id of moving player
	# assumes turns are updated and moving player is AI
	_ex_game_state = get_last_srv_gameState(game_code)

	# generate scenarios
	_scenarios = gen_scenarioTree(_ex_game_state, ai_moving_player_id)

	# make choice
	_pick = scenario_choice(_ex_game_state, _scenarios, ai_moving_player_id)

	# TEMP TRANSLATION LAYER
	_tr_pick = temp_ai_pick_translation(_pick)
	
	return _tr_pick

end

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
	_scenario_pick = msg[:payload][:scenario_pick] # false || start/end/mk_sel/ring_pick
	
	# println("SRV Game runner - scenario pick: ", _scenario_pick)


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
		if _scenario_pick != false
		
			# update server state & generates delta for move replay
			update_serverStates!(_game_code, _player_id, _scenario_pick)
			
			# move turn due to scenario being picked
			advance_turn!(_game_code, _scenario_pick[:completed_turn_no])

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

					# make a move - last moving player should be AI
					_pick = play_turn_AI(_game_code, _ai_player_id)
					
					# sync server data
					update_serverStates!(_game_code, _ai_player_id, _pick)
	
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
		msg_dispatcher(ws, _msg_id, _msg_code, Dict(:server_msg => "Error, missing msg_id and/or incorrect msg_code"), false)

		
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
md"### Adv scoring refactoring"

# ╔═╡ 63cf005b-e631-4de4-8927-085c3f982803
#=

for AI server:
- replay client changes
- if won -> flag game, inform client
- if not
-- check if adv scoring -> pick score
-- check if won -> inform in case
- prep payload


for client:
- replay changes
- if won/not (server tells)
- in case of adv scoring allow for choice (server tell)
-- server will also tell if this was final move
-- resume game (diff scenario trees depending X scored row(s) - rings stay unmoved )
--- but only if not final move ahead


for h vs h:
- replay changes
- check for adv scoring options
- expose/surface options in payload
- gen different scenario trees for every option (diff markers being removed)

TODO
-- revise data handling & structures
- function to check if adv scoring took place
- if adv scoring, deal w/ multiple scenario trees depending on picked scoring ring
- detect and highlight adv scoring and allow for handling in client
- detect early win/lose and emit/handle events accordingly

-- check srv function dependencies to refactor
-- eval search, if mask search is a perf option
-- think scenarios + ways of reproducing them quickly for testing

=#

# ╔═╡ 5ce26cae-4604-4ad8-8d15-15f0bfc9a81a
md"#### Open issues "

# ╔═╡ 9b8a5995-d8f0-4528-ad62-a2113d5790fd
#=

- game history
- opponent scoring for other
- uniform handling/naming of originator vs joiner
- way too many hardcoded values everywhere
- AI is too annoying  -> could add rule about placing something first, or experiment with RL and self-play ??
- clients disconnecting / non-responsive are not handled / websocket disconneting
- should I use a DB?
- perf optimizations
- revise github readme + add note for suggestions -> or alt text/hover on page?

=#

# ╔═╡ 20bc797e-c99b-417d-8921-9b95c8e21679
# ╠═╡ disabled = true
#=╠═╡
using BenchmarkTools
  ╠═╡ =#

# ╔═╡ c9d90fd5-4b65-435f-82e7-324340f31cd8
# ╠═╡ disabled = true
#=╠═╡
using Profile, PProf
  ╠═╡ =#

# ╔═╡ 5d1ba3df-3e0d-49b8-a995-c27fab85ab54
# ╠═╡ disabled = true
#=╠═╡
begin

	Profile.clear()
	@profile gen_newGame(true)
	
	pprof()
	
end
  ╠═╡ =#

# ╔═╡ c6f5745b-4299-48d5-ac80-268260ac7e0f
# ╠═╡ disabled = true
#=╠═╡
begin
	Profile.clear()
	@profile gen_scenarioTree(games_log_dict["OZMPUX"][:server_states][end], "W")

	pprof()

end
  ╠═╡ =#

# ╔═╡ c367153b-703d-44f5-97ad-635b61bb9043
# ╠═╡ disabled = true
#=╠═╡
games_log_dict
  ╠═╡ =#

# ╔═╡ 24185d12-d29c-4e72-a1de-a28319b4d369
# make it wait forever
println("Service running")
wait(Condition())

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
JSON3 = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
PProf = "e4faabce-9ead-11e9-39d9-4379958e3056"
PlotThemes = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Profile = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"

[compat]
BenchmarkTools = "~1.4.0"
HTTP = "~1.9.15"
JSON3 = "~1.13.2"
PProf = "~3.1.0"
PlotThemes = "~3.1.0"
Plots = "~1.39.0"
PlutoUI = "~0.7.54"
StatsBase = "~0.34.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.0"
manifest_format = "2.0"
project_hash = "70954f52299df4808221378796e8f01ed814c755"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "793501dcd3fa7ce8d375a2c878dca2296232686e"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.2.2"

[[deps.AbstractTrees]]
git-tree-sha1 = "faa260e4cb5aba097a73fab382dd4b5819d8ec8c"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.4"

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
git-tree-sha1 = "43b1a4a8f797c1cddadf60499a8a077d4af2cd2d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.7"

[[deps.BufferedStreams]]
git-tree-sha1 = "4ae47f9a4b1dc19897d3743ff13685925c5202ec"
uuid = "e1450e63-4bb3-523b-b2a4-4ffa8c0fd77d"
version = "1.2.1"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "02aa26a4cf76381be7f66e020a3eddeb27b0a092"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.2"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "67c1f244b991cad9b0aa4b7540fb758c2488b129"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.24.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

    [deps.ColorVectorSpace.weakdeps]
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "e460f044ca8b99be31d35fe54fc33a5c33dd8ed7"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.9.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+1"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "5372dbbf8f0bdb8c700db5367132925c0771ef7e"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.2.1"

[[deps.Contour]]
git-tree-sha1 = "d05d9e7b7aedff4e5b51a029dced05cfb6125781"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.2"

[[deps.DataAPI]]
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3dbd312d370723b6bb43ba9d02fc36abade4518d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.15"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

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

[[deps.EnumX]]
git-tree-sha1 = "bdb1942cd4c45e3c678fd11569d5cccd80976237"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.4"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8e9441ee83492030ace98f9789a654a6d0b1f643"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "e90caa41f5a86296e014e148ee061bd6c3edec96"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.9"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "4558ab818dcceaab612d1bb8c19cee87eda2b83c"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.5.0+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "74faea50c1d007c85837327f6775bea60b5492dd"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+2"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "299dc33549f68299137e51e6d49a13b5b1da9673"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.1"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.FlameGraphs]]
deps = ["AbstractTrees", "Colors", "FileIO", "FixedPointNumbers", "IndirectArrays", "LeftChildRightSiblingTrees", "Profile"]
git-tree-sha1 = "bd1aaf448be998ea427b1c7213b8acf2e278498b"
uuid = "08572546-2f56-4bcf-ba4e-bab62c3a3f89"
version = "1.0.0"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "d8db6a5a2fe1381c1ea4ef2cab7c69c2de7f9ea0"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.1+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "ff38ba61beff76b8f4acad8ab0c97ef73bb670cb"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.9+0"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Preferences", "Printf", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "UUIDs", "p7zip_jll"]
git-tree-sha1 = "27442171f28c952804dede8ff72828a96f2bfc1f"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.72.10"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "FreeType2_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt6Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "025d171a2847f616becc0f84c8dc62fe18f0f6dd"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.72.10+0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "e94c92c7bf4819685eb80186d51c43e71d4afa17"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.76.5+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Graphviz_jll]]
deps = ["Artifacts", "Cairo_jll", "Expat_jll", "JLLWrappers", "Libdl", "Pango_jll", "Pkg"]
git-tree-sha1 = "a5d45833dda71048117e8a9828bef75c03b18b1c"
uuid = "3c863552-8265-54e4-a6dc-903eb78fde85"
version = "2.50.0+1"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "19e974eced1768fb46fd6020171f2cec06b1edb5"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.9.15"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "d75853a0bdbfb1ac815478bacd89cd27b550ace6"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.3"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.JLFzf]]
deps = ["Pipe", "REPL", "Random", "fzf_jll"]
git-tree-sha1 = "a53ebe394b71470c7f97c2e7e170d51df21b17af"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.7"

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
git-tree-sha1 = "95220473901735a0f4df9d1ca5b171b568b2daa3"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.13.2"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "60b1194df0a3298f460063de985eae7b01bc011a"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.0.1+0"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d986ce2d884d49126836ea94ed5bfb0f12679713"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "15.0.7+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "50901ebc375ed41dbf8058da26f9de442febbbec"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.1"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Printf", "Requires"]
git-tree-sha1 = "f428ae552340899a935973270b8d98e5a31c49fe"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.1"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LeftChildRightSiblingTrees]]
deps = ["AbstractTrees"]
git-tree-sha1 = "fb6803dafae4a5d62ea5cab204b1e657d9737e7f"
uuid = "1d6d02ad-be62-4b6b-8a6d-2f90e265016e"
version = "0.2.0"

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

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f9557a255370125b405568f9767d6d195822a175"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "2da088d113af58221c52828a80378e16be7d037a"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.5.1+1"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

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
git-tree-sha1 = "0d097476b6c381ab7906460ef1ef1638fbce1d91"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.2"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "b211c553c199c111d998ecdaf7623d1b89b69f93"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.12"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "03a9b9718f5682ecb107ac9f7308991db4ce395b"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.7"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

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

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+2"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+2"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "51901a49222b09e3743c65b8847687ae5fc78eb2"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.1"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "bbb5c2115d63c2f1451cb70e5ef75e8fe4707019"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.22+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "2e73fe17cac3c62ad1aebe70d44c963c3cfdc3e3"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.2"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.PProf]]
deps = ["AbstractTrees", "CodecZlib", "EnumX", "FlameGraphs", "Libdl", "OrderedCollections", "Profile", "ProgressMeter", "ProtoBuf", "pprof_jll"]
git-tree-sha1 = "c909f647881a80ec4c5974eec9624b0c96afad9d"
uuid = "e4faabce-9ead-11e9-39d9-4379958e3056"
version = "3.1.0"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "4745216e94f71cb768d58330b059c9b76f32cb66"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.50.14+0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "716e24b21538abc91f6205fd1d8363f39b442851"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.7.2"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "64779bc4c9784fee475689a1752ef4d5747c5e87"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.42.2+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "1f03a2d339f42dca4a4da149c7e15e9b896ad899"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.1.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "862942baf5663da528f66d24996eb6da85218e76"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.0"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "PrecompileTools", "Preferences", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "UnitfulLatexify", "Unzip"]
git-tree-sha1 = "ccee59c6e48e6f2edf8a5b64dc817b6729f99eb5"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.39.0"

    [deps.Plots.extensions]
    FileIOExt = "FileIO"
    GeometryBasicsExt = "GeometryBasics"
    IJuliaExt = "IJulia"
    ImageInTerminalExt = "ImageInTerminal"
    UnitfulExt = "Unitful"

    [deps.Plots.weakdeps]
    FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
    GeometryBasics = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    ImageInTerminal = "d8c32880-2388-543b-8c61-d9f865259254"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "bd7c69c7f7173097e7b5e1be07cee2b8b7447f51"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.54"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "7eb1686b4f04b82f96ed7a4ea5890a4f0c7a09f1"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "00099623ffee15972c16111bcf84c58a0051257c"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.9.0"

[[deps.ProtoBuf]]
deps = ["BufferedStreams", "Dates", "EnumX", "TOML", "TranscodingStreams"]
git-tree-sha1 = "dc85dc33abde04b3c2f687834a5551994b27c328"
uuid = "3349acd9-ac6a-5e09-bcdb-63829b23a429"
version = "1.0.14"

[[deps.Qt6Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Vulkan_Loader_jll", "Xorg_libSM_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_cursor_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "libinput_jll", "xkbcommon_jll"]
git-tree-sha1 = "7c29f0e8c575428bd84dc3c72ece5178caa67336"
uuid = "c0090381-4147-56d7-9ebc-da0b1113ec56"
version = "6.5.2+2"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "PrecompileTools", "RecipesBase"]
git-tree-sha1 = "45cf9fd0ca5839d06ef333c8201714e888486342"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.12"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "c60ec5c62180f27efea3ba2908480f8055e17cee"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.1"

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
git-tree-sha1 = "75ebe04c5bed70b91614d684259b661c9e6274a4"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.0"

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

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "9a6ae7ed916312b41236fcef7e0af564ef934769"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.13"

[[deps.Tricks]]
git-tree-sha1 = "eae1bb484cd63b36999ee58be2de6c178105112f"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.8"

[[deps.URIs]]
git-tree-sha1 = "b7a5e99f24892b6824a954199a45e9ffcc1c70f0"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "3c793be6df9dd77a0cf49d80984ef9ff996948fa"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.19.0"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.UnitfulLatexify]]
deps = ["LaTeXStrings", "Latexify", "Unitful"]
git-tree-sha1 = "e2d817cc500e960fdbafcf988ac8436ba3208bfd"
uuid = "45397f5d-5981-4c77-b2b3-fc36d6e9b728"
version = "1.6.3"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.Vulkan_Loader_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Wayland_jll", "Xorg_libX11_jll", "Xorg_libXrandr_jll", "xkbcommon_jll"]
git-tree-sha1 = "2f0486047a07670caad3a81a075d2e518acc5c59"
uuid = "a44049a8-05dd-5a78-86c9-5fde0876e88c"
version = "1.3.243+0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "7558e29847e99bc3f04d6569e82d0f5c54460703"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+1"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4528479aa01ee1b3b4cd0e6faef0e04cf16466da"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.25.0+0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "801cbe47eae69adc50f36c3caec4758d2650741b"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.12.2+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "522b8414d40c4cbbab8dee346ac3a09f9768f25d"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.4.5+0"

[[deps.Xorg_libICE_jll]]
deps = ["Libdl", "Pkg"]
git-tree-sha1 = "e5becd4411063bdcac16be8b66fc2f9f6f1e8fe5"
uuid = "f67eecfb-183a-506d-b269-f58e52b52d7c"
version = "1.0.10+1"

[[deps.Xorg_libSM_jll]]
deps = ["Libdl", "Pkg", "Xorg_libICE_jll"]
git-tree-sha1 = "4a9d9e4c180e1e8119b5ffc224a7b59d3a7f7e18"
uuid = "c834827a-8449-5923-a945-d239c165b7dd"
version = "1.2.3+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "afead5aba5aa507ad5a3bf01f58f82c8d1403495"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.6+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6035850dcc70518ca32f012e46015b9beeda49d8"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.11+0"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "34d526d318358a859d7de23da945578e8e8727b7"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.4+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8fdda4c692503d44d04a0603d9ac0982054635f9"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.1+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "b4bfde5d5b652e22b9c790ad00af08b6d042b97d"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.15.0+0"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "730eeca102434283c50ccf7d1ecdadf521a765a4"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.2+0"

[[deps.Xorg_xcb_util_cursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_jll", "Xorg_xcb_util_renderutil_jll"]
git-tree-sha1 = "04341cb870f29dcd5e39055f895c39d016e18ccd"
uuid = "e920d4aa-a673-5f3a-b3d7-f755a4d47c43"
version = "0.1.4+0"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "330f955bc41bb8f5270a369c473fc4a5a4e4d3cb"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.6+0"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "691634e5453ad362044e2ad653e79f3ee3bb98c3"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.39.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e92a1a012a10506618f10b7047e478403a046c77"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.5.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "49ce682769cd5de6c72dcf1b94ed7790cd08974c"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.5+0"

[[deps.eudev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "gperf_jll"]
git-tree-sha1 = "431b678a28ebb559d224c0b6b6d01afce87c51ba"
uuid = "35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"
version = "3.2.9+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a68c9655fbe6dfcab3d972808f1aafec151ce3f8"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.43.0+0"

[[deps.gperf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3516a5630f741c9eecb3720b1ec9d8edc3ecc033"
uuid = "1a1c6b14-54f6-533d-8383-74cd7377aa70"
version = "3.1.1+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"

[[deps.libevdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "141fe65dc3efabb0b1d5ba74e91f6ad26f84cc22"
uuid = "2db6ffa8-e38f-5e21-84af-90c45d0032cc"
version = "1.11.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libinput_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "eudev_jll", "libevdev_jll", "mtdev_jll"]
git-tree-sha1 = "ad50e5b90f222cfe78aa3d5183a20a12de1322ce"
uuid = "36db933b-70db-51c0-b978-0f229ee0e533"
version = "1.18.0+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "93284c28274d9e75218a416c65ec49d0e0fcdf3d"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.40+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.mtdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "814e154bdb7be91d78b6802843f76b6ece642f11"
uuid = "009596ad-96f7-51b1-9f1b-5ce2d5e8a71e"
version = "1.1.6+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.pprof_jll]]
deps = ["Artifacts", "Graphviz_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b004c9fd6294afe24efccc7e2f055436b63cb809"
uuid = "cf2c5f97-e748-59fa-a03f-dda3c62118cb"
version = "1.0.1+0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9c304562909ab2bab0262639bd4f444d7bc2be37"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+1"
"""

# ╔═╡ Cell order:
# ╠═69c4770e-1091-4744-950c-ed23deb55661
# ╠═6f0ad323-1776-4efd-bf1e-667e8a834f41
# ╠═c2797a4c-81d3-4409-9038-117fe50540a8
# ╠═13cb8a74-8f5e-48eb-89c6-f7429d616fb9
# ╠═70ecd4ed-cbb1-4ebd-85a8-42f7b072bee3
# ╠═bd7e7cdd-878e-475e-b2bb-b00c636ff26a
# ╠═f6dc2723-ab4a-42fc-855e-d74915b4dcbf
# ╠═43f89626-8583-11ed-2b3d-b118ff996f37
# ╠═9505b0f0-91a2-46a8-90a5-d615c2acdbc1
# ╠═cd36abda-0f4e-431a-a4d1-bd5366c83b9b
# ╟─2d69b45e-d8e4-4505-87ed-382e45bebae7
# ╟─48bbc7c2-ba53-41cd-9b3c-ab3faedfc6b0
# ╠═c96e1ee9-6d78-42d2-bfd6-2e8f88913b37
# ╠═b6292e1f-a3a8-46d7-be15-05a74a5736de
# ╟─55987f3e-aaf7-4d85-a6cf-11eda59cd066
# ╟─d996152e-e9e6-412f-b4db-3eacf5b7a5a6
# ╠═00468008-0cbc-4f68-832b-2a5b46431fb7
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
# ╟─003f670b-d3b1-4905-b105-67504f16ba19
# ╠═2cee3e2b-5061-40f4-a205-94d80cfdc20b
# ╟─a96a9a78-0aeb-4b00-8f3c-db61839deb5c
# ╟─f0e9e077-f435-4f4b-bd69-f495dfccec27
# ╟─bf2dce8c-f026-40e3-89db-d72edb0b041c
# ╟─33707130-7703-4aa0-84e6-23ab387c0c4d
# ╟─9700ea30-a99c-4832-a181-7ef23c86030a
# ╟─9d153cf1-3e3b-49c0-abe7-ebd0f524557c
# ╟─52bf45df-d3cd-45bb-bc94-ec9f4cf850ad
# ╟─8f2e4816-b60d-40eb-a9d8-acf4240c646a
# ╟─c67154cb-c8cc-406c-90a8-0ea8241d8571
# ╟─53dec9b0-dac1-47a6-b242-9696ff45b91b
# ╟─148d1418-76a3-462d-9049-d30e85a45f06
# ╟─fc68fa36-e2ea-40fa-9d0e-722167a2506e
# ╟─7fe89538-b2fe-47db-a961-fdbdd4278963
# ╟─c1fbbcf3-aeec-483e-880a-05d3c7a8a895
# ╟─b56084e8-7286-404b-9088-094070331afe
# ╠═8e400909-8cfd-4c46-b782-c73ffac03712
# ╟─2c1c4182-5654-46ad-b4fb-2c79727aba3d
# ╠═c334b67e-594f-49fc-8c11-be4ea11c33b5
# ╠═dffafbec-3c1e-4f93-852b-e890a94b7e5c
# ╠═29a93299-f577-4114-b77f-dbc079392090
# ╠═f1949d12-86eb-4236-b887-b750916d3493
# ╠═e0368e81-fb5a-4dc4-aebb-130c7fd0a123
# ╟─61a0e2bf-2fed-4141-afc0-c8b5507679d1
# ╠═bc19e42a-fc82-4191-bca5-09622198d102
# ╠═57153574-e5ca-4167-814e-2d176baa0de9
# ╠═1fe8a98e-6dc6-466e-9bc9-406c416d8076
# ╟─1f021cc5-edb0-4515-b8c9-6a2395bc9547
# ╟─aaa8c614-16aa-4ca8-9ec5-f4f4c6574240
# ╟─156c508f-2026-4619-9632-d679ca2cae50
# ╟─18f8a5d6-c775-44a3-9490-cd11352c4a63
# ╟─67b8c557-1cf2-465d-a888-6b77f3940f39
# ╠═a27e0adf-aa09-42ee-97f5-ede084a9edc3
# ╟─5da79176-7005-4afe-91b7-accaac0bd7b5
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
# ╟─ca522939-422f-482a-8658-452790c463f6
# ╠═7316a125-3bfe-4bac-babf-4e3db953078b
# ╠═064496dc-4e23-4242-9e25-a41ddbaf59d1
# ╠═28ee9310-9b7d-4169-bae4-615e4b2c386e
# ╟─612a1121-b672-4bc7-9eee-f7989ac27346
# ╟─a6c68bb9-f7b4-4bed-ac06-315a80af9d2e
# ╟─32307f96-6503-4dbc-bf5e-49cf253fbfb2
# ╟─ac87a771-1d91-4ade-ad39-271205c1e16e
# ╠═ca346015-b2c9-45da-8c1e-17493274aca2
# ╠═88616e0f-6c85-4bb2-a856-ea7cee1b187d
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
# ╠═4f3e9400-6eb7-4ffb-bf5b-887d523e00a4
# ╠═f55bb88f-ecce-4c14-b9ac-4fc975c3592e
# ╟─67322d28-5f9e-43da-90a0-2e517b003b58
# ╟─f1c0e395-1b22-4e68-8d2d-49d6fc71e7d9
# ╟─c38bfef9-2e3a-4042-8bd0-05f1e1bcc10b
# ╟─20a8fbe0-5840-4a70-be33-b4103df291a1
# ╟─7a4cb25a-59cf-4d2c-8b1b-5881b8dad606
# ╟─42e4b611-abe4-41c4-8f92-ea39bb928122
# ╟─8b830eee-ae0a-4c9f-a16b-34045b4bef6f
# ╟─6a174abd-c9bc-4c3c-93f0-05a7d70db4af
# ╟─9fdbf307-1067-4f55-ac56-8335ecc84962
# ╟─14aa5b7c-9065-4ca3-b0e9-19c104b1854d
# ╟─4976c9c5-d60d-4b19-aa72-0e135ad37361
# ╟─1c970cc9-de1f-48cf-aa81-684d209689e0
# ╟─e6cc0cf6-617a-4231-826d-63f36d6136a5
# ╟─cd06cad4-4b47-48dd-913f-61028ebe8cb3
# ╟─2a63de92-47c9-44d1-ab30-6ac1e4ac3a59
# ╟─db1ce9bc-0593-4dd7-b905-a14295d47533
# ╠═63cf005b-e631-4de4-8927-085c3f982803
# ╟─5ce26cae-4604-4ad8-8d15-15f0bfc9a81a
# ╠═9b8a5995-d8f0-4528-ad62-a2113d5790fd
# ╠═20bc797e-c99b-417d-8921-9b95c8e21679
# ╠═c9d90fd5-4b65-435f-82e7-324340f31cd8
# ╠═5d1ba3df-3e0d-49b8-a995-c27fab85ab54
# ╠═c6f5745b-4299-48d5-ac80-268260ac7e0f
# ╠═c367153b-703d-44f5-97ad-635b61bb9043
# ╠═24185d12-d29c-4e72-a1de-a28319b4d369
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
