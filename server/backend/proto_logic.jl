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
	locs_searchSpace = Dict()
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
	locs_searchSpace_scoring = Dict()
	populate_searchSpace_scoring!(locs_searchSpace_scoring)
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
function gen_random_gameState(white_ring, black_ring)
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

		# is the key a CI?
		_nk = isa(k, CartesianIndex) ? reshape_out(k) : k
		
		# is this either a CI or an array?
		_flag_CI = isa(v, CartesianIndex)
		_flag_array = isa(v, Array)

			# if an array, is the array made of CI?
			_flag_array_CI = _flag_array && isa(v[begin], CartesianIndex)

		# is this a dict?
		_flag_dict = isa(v, Dict)

			# is this an array of dicts?
			_flag_array_dict = _flag_array && isa(v[begin], Dict)

		if _flag_CI || _flag_array_CI
			_new_v = reshape_out(v) # reshape works w/ both
			setindex!(_ret, _new_v, _nk)

		elseif _flag_dict # recursion
			_new_v = reshape_out_fields(v)
			setindex!(_ret, _new_v, _nk)

		elseif _flag_array_dict # recursion x broadcasting
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
	_game_state = gen_random_gameState(white_ring, black_ring)
	
	# retrieves location ids in client format 
	whiteRings_ids = reshape_out(findall(i -> i == white_ring, _game_state))
	blackRings_ids = reshape_out(findall(i -> i == black_ring, _game_state))

	white_rings = [Dict(:id => id, :player => white_id) for id in whiteRings_ids]
	black_rings = [Dict(:id => id, :player => black_id) for id in blackRings_ids]

	# prepare rings array to be sent to client
	rings = union(white_rings, black_rings)


	# simulates possible moves and scoring/flipping outcomes for each
	scenario_tree = gen_scenarioTree(_game_state, next_movingPlayer)
	
	
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
						:markers => [], # no markers yet
						:scenarioTree => scenario_tree,
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

	#= OUTPUT structure
	
		:score_preMove_done => (:mk_locs => CI[], :ring_score => CI) 
		:move_done => (:mk_add => (loc, player), :ring_move = (start, end, player))
		:mk_flip => CI[]
		:score_done => (:mk_locs => CI[], :ring_score => CI) 
		:score_avail_opp => Dict[] # (mk_locs, mk_sel, player)
		:score_avail_player => Dict[] # (mk_locs, mk_sel, player)

		+ :new_game_state, :mode added before return
		+ :new_player_score, :new_opp_score

		note: mk_locs => mks_remove could be removed

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
		flip_flag, mks_toFlip = markers_toFlip_search(new_gs, r_dirs[dir_no])

		if flip_flag # flip markers in game state
			for m_id in mks_toFlip
				if contains(new_gs[m_id], "M")
					new_gs[m_id] = (new_gs[m_id] == "MW") ? "MB" : "MW" 
				end
			end
		end

		# update global dict
			mk_add = Dict(:index => _start_move_id, :player_id => _ring_color)
			ring_move = Dict(:start => _start_move_id, :end => _end_move_id, :player_id => _ring_color)
			
			_md = Dict(:mk_add => mk_add, :ring_move => ring_move)
		
			setindex!(_return, _md, :move_done)	
			flip_flag && setindex!(_return, mks_toFlip, :mk_flip)	

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
	if fn_mode == :replay 
		
		_f_score_action_preMove && score_preMove_do!() 
		_f_move_action && move_do!()
		_f_score_action && score_do!()

	elseif fn_mode == :move

		_f_move_action && move_do!()
		score_check!()
	
	elseif fn_mode == :inspect

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

# () output is reshaped for client's consumption --> TO BE RECHECKED
	
	# scenario tree to be returned
	scenario_tree = Dict()

	#= SCENARIO TREE structure

		!  :summary => global flags (used by AI)
	
		() :score_preMove_avail => [ options ] 
	
		() :game_trees => [(:gs_id, :gs, :tree)] (id is mk_sel & ring_score of premove or absent if only 1 branch)
	
			:tree => ( :start => :end => flags/deltas)

	=#
	
	
	# add summary to tree, will be edited along the function and only added in the end
	summary = Dict( :f_score_preMove_avail => false, 
					:f_flip => false,
					:f_score => false)
	

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

		# mark ops score opportunity
		summary[:f_score_preMove_avail] = true
		
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

		# prep empty tree for each game state
		g_tree = Dict()

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

					# simulate new game state for start/end combination
					_move = Dict(:id => Dict( 	:player_id => nx_player_id, 
												:player_score => nx_player_score),
								 :move_action => Dict( 	:start => move_start,
								 						:end => move_end))
					
					sim_res = sim_new_gameState(gs, _move, :move)


					# save what can happen
					
					#= old function was returning these
					flip_flag = new_gs_delta[:flip_flag]
					markers_toFlip = new_gs_delta[:markers_toFlip_srv]

					
					:flip_done -> mks to flip
					:score_avail_player -> scoring ops
					:move_done[:mk_add]
					=#

					# log global flags (used by AI)
					#scenario_tree[:summary][:global_score_flag] = true

					# prune unnecessary data (maybe done downstream before push to client?)
					
					## save scenario in tree (start -> end -> scenario)
					set_nested!(g_tree, sim_res, move_start, move_end)
					
				end
			end
		end

		# save tree in 
		setindex!(g_branch, g_tree, :tree)

	end
	

	# save tree of possible game moves for each starting game state
	setindex!(scenario_tree, _g_trees_array, :move_trees)

	# save summary (NOT BEING FULLY UPDATED YET)
	setindex!(scenario_tree, summary, :turn_summary)
	

	return scenario_tree

end

# ╔═╡ e91849bb-32f5-405f-98bd-cae73e3ed1d7
_res_tw = sim_scenarioTree(ex_gm_n, "B", 3)

# ╔═╡ 77f4387b-63e9-4f2f-bd23-3a820378541e
reshape_out_fields(_res_tw)

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
end

# ╔═╡ 0bb77295-be29-4b50-bff8-f712ebe08197
begin
	
	# ip and port to use for the server
	ws_ip = "0.0.0.0" # listen on every ip / host ip
	ws_port = 6091

end

# ╔═╡ 2ccc880f-805e-47e3-af9e-eae4f5fa261d
games_log_dict

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

# ╔═╡ 4cb9af27-b7c2-4b76-8c67-dd5221240de6
ws_messages_log

# ╔═╡ f6cb0643-d60c-4a64-baf1-8afbff17f582
games_log_dict

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
	_existing_game_data = getLast_clientPkg(msg[:game_id]) # caller payload

	# save ws handler for joining player
	update_ws_handler!(msg[:game_id], ws, false) # true if originator

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
	

		
	### package data for client
	_cli_pkg = Dict(:game_id => game_id,
					:rings => rings,
					:markers => markers,
					:scenarioTree => scenario_tree)
					# later we should address cases of double scoring
	
	
	# saves game to general log (DB?)
	save_new_clientPkg!(games_log_dict, game_id, _cli_pkg)


	println("LOG - New client pkg created for game: $game_id")
	
	
end

# ╔═╡ f55bb88f-ecce-4c14-b9ac-4fc975c3592e
function update_serverStates!(_game_code, _player_id, _scenario_pick)
# updates server state for game given a scenario by a player 
# replays move server-side and logs score
# generates delta payload info
	

	## extract info payload, convert moves to server indexes
	_start_index = reshape_in(_scenario_pick[:start])
	_end_index =  reshape_in(_scenario_pick[:end])

	_no_scoring_default = -1

		_mk_sel_pick_cli = get(_scenario_pick, :mk_sel_pick, _no_scoring_default)
		_ring_removed_cli = get(_scenario_pick, :ring_removed, _no_scoring_default) 

	# false if either the keys are missing (AI -> -1) or returned as -1 by the client
	_scoring_handled = (_mk_sel_pick_cli != _no_scoring_default && 
						_ring_removed_cli != _no_scoring_default) ? true : false

	# neutral value
	_no_scoring_def_server = CartesianIndex(0,0)

	_mk_sel_index = _no_scoring_def_server
	_score_ring_index = _no_scoring_def_server
	
		# overwrite data on scoring choices
		if _scoring_handled 
	
			_mk_sel_index = reshape_in(_scenario_pick[:mk_sel_pick])
			_score_ring_index = reshape_in(_scenario_pick[:ring_removed])

			# updates score for player_id
			_player_type = whos_player(_game_code, _player_id)
			_player_score_k = _player_type == :originator ? :orig_player_score : :join_player_score
			
			games_log_dict[_game_code][:players][_player_score_k] += 1
					
		end

	# retrieve old game state and last moving
	ex_game_state = get_last_srv_gameState(_game_code)

	# get new game state
	_new_gs_delta = gen_New_gameState(ex_game_state, _start_index, _end_index, _mk_sel_index, _score_ring_index)

	# save new game state to log
	push!(games_log_dict[_game_code][:server_states], _new_gs_delta[:new_game_state_srv])


	# extract delta to be logged and passed onto client
	_array_delta_client = Dict[] # array, for multiple deltas/replays
	_delta_client = Dict()

	# differentiate response based on scoring being handled (it sucks, to be cleaned)
	if _scoring_handled
		_delta_client = Dict(:flip_flag => _new_gs_delta[:flip_flag],
							:markers_toFlip => _new_gs_delta[:markers_toFlip_cli],
							:added_marker => _new_gs_delta[:added_marker_cli],
							:moved_ring => _new_gs_delta[:moved_ring_cli],
							:score_handled => _new_gs_delta[:score_handled],
							:markers_toRemove => _new_gs_delta[:markers_toRemove_cli],
							:scoring_ring => _new_gs_delta[:scoring_ring_cli]
							)

	else
		_delta_client = Dict(:flip_flag => _new_gs_delta[:flip_flag],
							:markers_toFlip => _new_gs_delta[:markers_toFlip_cli],
							:added_marker => _new_gs_delta[:added_marker_cli],
							:moved_ring => _new_gs_delta[:moved_ring_cli],
							:score_handled => _new_gs_delta[:score_handled]
							)
		
	end

	push!(_array_delta_client, _delta_client)

	# save delta array for client
	push!(games_log_dict[_game_code][:client_delta], _array_delta_client)
	

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
		_client_delta_array = getLast_clientDelta(game_code)
	
			# append delta to package for client
			setindex!(_pkg, _client_delta_array, :delta_array)

	
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

# ╔═╡ 7b090d5d-cce2-415b-8621-fbdc11b54f77
function pick_adv_scoring(g_state::Matrix, _scoring_details::Array, _player_id::String)::Dict
## act on score opportunity created by human player
# function called when there's at least one scoring ops for player_id
# for now everything is in client-side coordinates (indexes)

	# pick random scoring opportunity within array, among the ones for player
	_adv_scoring_ops = rand(filter(s -> s[:player] == _player_id, _scoring_details))

	# all player rings locations (cart index) -> pick ring to remove
	gs_rings_locs = findall(i -> contains(i, "R"*_player_id), g_state)
	_scoring_ring_pick = reshape_out(rand(gs_rings_locs))


	return Dict(:mk_sel_pick => _adv_scoring_ops[:mk_sel], 
				:mk_locs_remove => _adv_scoring_ops[:mk_locs],
				:ring_removed => _scoring_ring_pick)


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

	#_adv_flag = false # keep track if we scored due to an adv point

	# get last game state and id of moving player
	# assumes turns are updated and moving player is AI
	_ex_game_state = get_last_srv_gameState(game_code)

		#= check if human player made a point for us
		_num_scoring_rows, _scoring_details = static_score_lookup(_ex_game_state)
			
		if _num_scoring_rows[Symbol(ai_moving_player_id)] > 0 # [:B || :W] 
			# if so, score point for ai player
			_adv_score = pick_adv_scoring(_ex_game_state, _scoring_details, ai_moving_player_id)

			# update game state
			# if point is final, return here
			# otherwise continue
		# update game state and gen delta -> inform via pick
		end
		=#

	# generate scenarios
	_scenarios = gen_scenarioTree(_ex_game_state, ai_moving_player_id)

	# make choice
	_pick = scenario_choice(_ex_game_state, _scenarios, ai_moving_player_id)

	return _pick

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
	_game_code = msg[:game_id]
	_player_id = msg[:player_id]
	_who = whos_player(_game_code, _player_id) # :originator || :joiner
	_game_vs_ai_flag = is_game_vs_ai(_game_code)
	_scenario_pick = msg[:scenario_pick] # false || start/end/mk_sel/ring_pick
	_msg_code = msg[:msg_code]
	
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
		_who = whos_player(msg[:game_id], msg[:player_id])
		_is_originator = (_who == :originator) ? true : false
	
		# save ws handler for originating vs joining player
		update_ws_handler!(msg[:game_id], ws, _is_originator)

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

	# try retrieving specific values
	_msg_id = get(msg, :msg_id, nothing)
	_msg_code = get(msg, :msg_code, nothing)


	# if messages are valid, run matching function 
	if !isnothing(_msg_id) && (_msg_code in allowed_CODES)

		try

			# all functions return two dictionaries
			_pld_caller, _pld_other = codes_toFun_match[_msg_code](ws, msg)

				# reply to caller, including code-specific response
				msg_dispatcher(ws, _msg_id, _msg_code, _pld_caller)
				
			# if payload is not empty, assumes game already exists
			# game vs other human player, informed with other payload
			if !isempty(_pld_other) && !is_game_vs_ai(msg[:game_id])

				# game and player id are in the original msg as game exists
				_game_id = msg[:game_id]
				_player_id = msg[:player_id]

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
function start_ws_server(ws_array, _log)

	try 

		# start new server 
		ws_server = WebSockets.listen!(ws_ip, ws_port; idle_timeout_enabled = false) do ws

			# iterate over incoming messages
			for msg in ws

				# parse incoming msg as json
				msg_parsed = Dict(JSON3.read(msg))
				
				# dispatch parsed message to message handler
				# handler takes care of generating response payload and replying,
				# as well as handling potential errors
				msg_handler(ws, msg_parsed, _log)

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
	
function reactive_start_server(ws_array, _msg_log)

	# start websocket server if there's none
	if isempty(ws_array)

		start_ws_server(ws_array, _msg_log)

	# otherwise, close all open ones existing and start a new one
	else

		# check task status 
		_open_ws = filter(ws -> !istaskdone(ws.task), ws_array)
		
		for ws in _open_ws
			HTTP.forceclose(ws)
			println("WebSocket server $(objectid(ws.task)) STOP at $(now())")
		end
		
		
		sleep(0.025)
		start_ws_server(ws_array, _msg_log)
		
	end

end

# ╔═╡ 8b6264b0-f7ea-4177-9700-30072d4c5826
reactive_start_server(ws_servers_array, ws_messages_log)

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
- clients disconnecting / non-responsive are not handled
- websocket disconneting
- should I use a DB?
- perf optimizations
- revise github readme + add note for suggestions -> or alt text/hover on page?

=#

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
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
JSON3 = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"

[compat]
HTTP = "~1.9.15"
JSON3 = "~1.13.2"
StatsBase = "~0.34.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.0"
manifest_format = "2.0"
project_hash = "72975cf3b7f1104ee482fae1a25cd20fdbd10245"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitFlags]]
git-tree-sha1 = "43b1a4a8f797c1cddadf60499a8a077d4af2cd2d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.7"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "02aa26a4cf76381be7f66e020a3eddeb27b0a092"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.2"

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

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "e90caa41f5a86296e014e148ee061bd6c3edec96"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.9"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "19e974eced1768fb46fd6020171f2cec06b1edb5"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.9.15"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "PrecompileTools", "StructTypes", "UUIDs"]
git-tree-sha1 = "95220473901735a0f4df9d1ca5b171b568b2daa3"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.13.2"

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
git-tree-sha1 = "0d097476b6c381ab7906460ef1ef1638fbce1d91"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.2"

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
git-tree-sha1 = "bbb5c2115d63c2f1451cb70e5ef75e8fe4707019"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.22+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "2e73fe17cac3c62ad1aebe70d44c963c3cfdc3e3"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.2"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "716e24b21538abc91f6205fd1d8363f39b442851"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.7.2"

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

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

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

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "9a6ae7ed916312b41236fcef7e0af564ef934769"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.13"

[[deps.URIs]]
git-tree-sha1 = "b7a5e99f24892b6824a954199a45e9ffcc1c70f0"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.0"

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
# ╟─9d153cf1-3e3b-49c0-abe7-ebd0f524557c
# ╟─52bf45df-d3cd-45bb-bc94-ec9f4cf850ad
# ╟─8f2e4816-b60d-40eb-a9d8-acf4240c646a
# ╟─c67154cb-c8cc-406c-90a8-0ea8241d8571
# ╟─53dec9b0-dac1-47a6-b242-9696ff45b91b
# ╟─148d1418-76a3-462d-9049-d30e85a45f06
# ╟─fc68fa36-e2ea-40fa-9d0e-722167a2506e
# ╟─7fe89538-b2fe-47db-a961-fdbdd4278963
# ╟─c1fbbcf3-aeec-483e-880a-05d3c7a8a895
# ╠═8e400909-8cfd-4c46-b782-c73ffac03712
# ╟─2c1c4182-5654-46ad-b4fb-2c79727aba3d
# ╟─c334b67e-594f-49fc-8c11-be4ea11c33b5
# ╠═29a93299-f577-4114-b77f-dbc079392090
# ╠═f1949d12-86eb-4236-b887-b750916d3493
# ╟─e0368e81-fb5a-4dc4-aebb-130c7fd0a123
# ╟─61a0e2bf-2fed-4141-afc0-c8b5507679d1
# ╠═bc19e42a-fc82-4191-bca5-09622198d102
# ╠═57153574-e5ca-4167-814e-2d176baa0de9
# ╠═1fe8a98e-6dc6-466e-9bc9-406c416d8076
# ╠═1f021cc5-edb0-4515-b8c9-6a2395bc9547
# ╟─aaa8c614-16aa-4ca8-9ec5-f4f4c6574240
# ╠═156c508f-2026-4619-9632-d679ca2cae50
# ╟─18f8a5d6-c775-44a3-9490-cd11352c4a63
# ╠═e91849bb-32f5-405f-98bd-cae73e3ed1d7
# ╠═77f4387b-63e9-4f2f-bd23-3a820378541e
# ╠═67b8c557-1cf2-465d-a888-6b77f3940f39
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
# ╠═2ccc880f-805e-47e3-af9e-eae4f5fa261d
# ╠═f9949a92-f4f8-4bbb-81d0-650ff218dd1c
# ╠═5e5366a9-3086-4210-a037-c56e1374a686
# ╠═7316a125-3bfe-4bac-babf-4e3db953078b
# ╠═064496dc-4e23-4242-9e25-a41ddbaf59d1
# ╠═28ee9310-9b7d-4169-bae4-615e4b2c386e
# ╠═4cb9af27-b7c2-4b76-8c67-dd5221240de6
# ╠═f6cb0643-d60c-4a64-baf1-8afbff17f582
# ╟─612a1121-b672-4bc7-9eee-f7989ac27346
# ╟─a6c68bb9-f7b4-4bed-ac06-315a80af9d2e
# ╟─32307f96-6503-4dbc-bf5e-49cf253fbfb2
# ╟─ac87a771-1d91-4ade-ad39-271205c1e16e
# ╠═ca346015-b2c9-45da-8c1e-17493274aca2
# ╠═88616e0f-6c85-4bb2-a856-ea7cee1b187d
# ╠═a7b92ca8-8a39-4332-bab9-ed612bf24c17
# ╟─384e2313-e1c7-4221-8bcf-142b0a49bff2
# ╟─5d6e868b-50a9-420b-8533-5db4c5d8f72c
# ╟─c77607ad-c11b-4fd3-bac9-6c43d71ae932
# ╟─b5c7295e-c464-4f57-8556-c36b9a5df6ca
# ╟─92a20829-9f0a-4ed2-9fd3-2d6560514e03
# ╟─13eb72c7-ac24-4b93-8fd9-260b49940370
# ╟─8929062f-0d97-41f9-99dd-99d51f01b664
# ╟─ebd8e962-2150-4ada-8ebd-3eba6e29c12e
# ╠═f55bb88f-ecce-4c14-b9ac-4fc975c3592e
# ╟─67322d28-5f9e-43da-90a0-2e517b003b58
# ╟─f1c0e395-1b22-4e68-8d2d-49d6fc71e7d9
# ╟─c38bfef9-2e3a-4042-8bd0-05f1e1bcc10b
# ╟─20a8fbe0-5840-4a70-be33-b4103df291a1
# ╟─7a4cb25a-59cf-4d2c-8b1b-5881b8dad606
# ╟─42e4b611-abe4-41c4-8f92-ea39bb928122
# ╟─8b830eee-ae0a-4c9f-a16b-34045b4bef6f
# ╠═6a174abd-c9bc-4c3c-93f0-05a7d70db4af
# ╟─14aa5b7c-9065-4ca3-b0e9-19c104b1854d
# ╠═7b090d5d-cce2-415b-8621-fbdc11b54f77
# ╟─4976c9c5-d60d-4b19-aa72-0e135ad37361
# ╟─1c970cc9-de1f-48cf-aa81-684d209689e0
# ╟─e6cc0cf6-617a-4231-826d-63f36d6136a5
# ╟─cd06cad4-4b47-48dd-913f-61028ebe8cb3
# ╟─2a63de92-47c9-44d1-ab30-6ac1e4ac3a59
# ╟─db1ce9bc-0593-4dd7-b905-a14295d47533
# ╠═63cf005b-e631-4de4-8927-085c3f982803
# ╟─5ce26cae-4604-4ad8-8d15-15f0bfc9a81a
# ╠═9b8a5995-d8f0-4528-ad62-a2113d5790fd
# ╠═c9d90fd5-4b65-435f-82e7-324340f31cd8
# ╠═5d1ba3df-3e0d-49b8-a995-c27fab85ab54
# ╠═c6f5745b-4299-48d5-ac80-268260ac7e0f
# ╠═c367153b-703d-44f5-97ad-635b61bb9043
# ╠═24185d12-d29c-4e72-a1de-a28319b4d369
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
