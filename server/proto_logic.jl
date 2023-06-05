### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 43f89626-8583-11ed-2b3d-b118ff996f37
using PlutoUI

# ╔═╡ 9505b0f0-91a2-46a8-90a5-d615c2acdbc1
using Plots, PlotThemes;  plotly() ; theme(:default)

# ╔═╡ c2797a4c-81d3-4409-9038-117fe50540a8
using StatsBase

# ╔═╡ 6f0ad323-1776-4efd-bf1e-667e8a834f41
using Random

# ╔═╡ 13cb8a74-8f5e-48eb-89c6-f7429d616fb9
using Dates

# ╔═╡ 70ecd4ed-cbb1-4ebd-85a8-42f7b072bee3
using HTTP, JSON3

# ╔═╡ bd7e7cdd-878e-475e-b2bb-b00c636ff26a
using HTTP.WebSockets

# ╔═╡ 1f9da483-6b05-4867-a509-2c24b41cd5d6
mm_yinsh = zeros(Int64, 19, 11)

# ╔═╡ d41d8f2c-16f2-4e41-bf81-fccc761b62cc
row_m, col_m = size(mm_yinsh)

# ╔═╡ fddf20d4-15e4-4ac8-99b1-98860f991297
#mm_yinsh

# 0 -> not part of the board
# 1 -> mid-point
# 2 -> active point

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

# ╔═╡ 1b8f5256-7433-405b-8419-cd00fceb4ccf
begin
	for i in 1:row_m
	for j in 1:col_m
		if partOfBoard(i,j) == true 
			mm_yinsh[i,j] = 1
		end
	end
	end

end

# ╔═╡ 58e4dbd8-61c6-473f-95e1-826822884895
begin
# checks if point is active (can be used for placing rings/markers)
# for each column, valid points are found each 2nd one

	for j in 1:col_m

		# extract column array
		temp_array = view(mm_yinsh,:,j)

		# get index of first and last non-zero element
		start_index = findfirst(x -> x != 0, temp_array)
		end_index = findlast(x -> x != 0, temp_array)

		#every second element is the active one
		for k in start_index:2:end_index
			mm_yinsh[k,j] = 2
		end
		
	
	end


end

# ╔═╡ c96e1ee9-6d78-42d2-bfd6-2e8f88913b37
mm_yinsh

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

# ╔═╡ b6292e1f-a3a8-46d7-be15-05a74a5736de
draw_board()

# ╔═╡ 00468008-0cbc-4f68-832b-2a5b46431fb7
begin
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
@bind locz_index Slider(1:length(locz), show_value=true)

# ╔═╡ e7afbb50-f343-47df-88c9-88a7ff336ea1
row_start = locz[locz_index][1]

# ╔═╡ 37ff4698-4418-4abc-b726-c5f719b8f792
col_start = locz[locz_index][2]

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
mm_setup = random_states_setup();

# ╔═╡ 6e7ab4f4-7c52-45bc-a503-6bf9cb0d7932
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

# ╔═╡ 49ff65f9-8ead-448f-8a44-1a741c20bbc5
setup_graph = rings_marks_graph();

# ╔═╡ e767b0a7-282f-46c4-b2e7-1f737807a3cb
@bind locz_index_n Slider(1:length(locz), show_value=true, default=rand(1:length(locz)))

# ╔═╡ edfa0b25-9132-4de9-bf11-3ea2f0952e4f
row_start_n = locz[locz_index_n][1]; col_start_n = locz[locz_index_n][2];

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
function _search_legal_srv(ref_state, start_index::CartesianIndex)
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

	return_array = CartesianIndex[]

	for i in input_array

		push!(return_array, return_IN_lookup[i])

	end

	return return_array


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

# ╔═╡ abb1848e-2ade-49e7-9b15-a4c94b2f9cb7
search_loc_graph(draw_board(), row_start, col_start, search_loc(mm_states, reshape_out(CartesianIndex(row_start,col_start))))

# ╔═╡ ccbf567a-8923-4343-a2ff-53d81f2b6361
search_loc_graph(rings_marks_graph(), row_start_n, col_start_n, search_loc(mm_setup, reshape_out(CartesianIndex(row_start_n,col_start_n))))

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

# ╔═╡ 6075f560-e190-409b-8435-a7cf08ec1bc6
games_log_dict

# ╔═╡ aaa8c614-16aa-4ca8-9ec5-f4f4c6574240
function gen_New_gameState(ex_game_state, start_move, end_move)
# generates new game state, starting from an existing one + start/end moves
# assumes start/end are valid moves AND in cartesian indexes
# works with game state in server-side format (matrix)

	new_gs = deepcopy(ex_game_state)
	
	if start_move == end_move # ring dropped where picked

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

	end


	_return = Dict(:new_game_state_srv => new_gs, 
					:flip_flag => flip_flag,
					:markers_toFlip_srv => markers_toFlip,
					:markers_toFlip_cli => reshape_out(markers_toFlip),
					:added_marker_cli => added_marker,
					:moved_ring_cli => moved_ring)

	return _return

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

# ╔═╡ 1f021cc5-edb0-4515-b8c9-6a2395bc9547
function gen_scenarioTree(ex_game_state, next_movingPlayer)
# takes as input game state (server format) and info of next moving player
# computes results for all possible moves of next moving player
# output is reshaped for client's consumption

# scenario tree to be returned
scenario_tree = Dict()

# add summary to tree
summary = Dict(:global_score_flag => false, 
				:global_flip_flag => false,
				:scoring_moves => [],
				:flipping_moves => [])
setindex!(scenario_tree, summary, :summary)

# find all rings for next moving player on the board
rings_locs = findall(i -> contains(i, next_movingPlayer), ex_game_state)

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

	# constants for players and game objects
	white_id = "W"
	black_id = "B"
	ring_id = "R"
	marker_id = "M"

	white_ring = ring_id * white_id
	black_ring = ring_id * black_id

	# generate random game identifier
	game_id = randstring(6)

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
						:status => game_status)
	
		# logs of game messages (one per player)
		_players = Dict(:orig_player_status => :not_available,
						:join_player_status => (vs_ai ? :ready : :not_available),
						:orig_player_comms => [], 
						:join_player_comms => [])
		
		# first game state (server format)
		_srv_states = [_game_state]

		
		### package data for client
		_cli_pkg = Dict(:game_id => game_id,
							:orig_player_id => ORIG_player_id,
							:join_player_id => JOIN_player_id,
							:rings => rings,
							# no markers yet
							:scenarioTree => scenario_tree)

		_first_turn = Dict(:status => :not_started,
							:moving_player => next_movingPlayer)

	
		## package new game data for storage
		new_game_data = Dict(:identity => _identity,
							:players => _players, 
							:turns => Dict(:pointer => 1, :data => [_first_turn]),
							:server_states => _srv_states,
							:client_delta => [],
							:client_pkgs => [_cli_pkg])

	
		
		# saves game to general log (DB?)
		save_newGame!(games_log_dict, new_game_data)


	println("LOG - New game initialized - Game ID $game_id")
	return game_id
	
end

# ╔═╡ 8eab6d11-6d28-411d-bd82-7bec59b3f496
# ╠═╡ disabled = true
#=╠═╡
gen_newGame()
  ╠═╡ =#

# ╔═╡ 761fb8d7-0c7d-4428-ad48-707d219582c0
## NEED FUNCTION TO HANDLE MESSAGES FROM CLIENT (NEXT MOVES), UPDATE STATE, SEND CHANGERS BACK TO OTHER PLAYER -> AND IDENTIFY OTHER PLAYER (HOW?)
# FROM THE ID OF THE PLAYER/SOCKET, WE SHOULD ALSO BE ABLE TO HANDLE RECONNECTS (UPDATING IDS)

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

# ╔═╡ 9a08682a-6406-45d2-b655-9fe24a9158e5
games_log_dict["Ij6AV"]

# ╔═╡ d9077e87-df02-43c8-ae5c-0df75eeee846
getLast_clientDelta("Ij6AV")

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

# ╔═╡ 1450c9e4-4080-476c-90d2-87b19c00cfdf
ws_messages_log = []; # test log for all received messages

# ╔═╡ c9c4129f-b507-4c92-899b-bc31087b63f4
ws_servers_ref = []; # array of server handles

# ╔═╡ 0bb77295-be29-4b50-bff8-f712ebe08197
begin
	
# ip and port to use for the server
ws_test_ip = "127.0.0.1"
ws_test_port = 8090

# codes used with client
CODE_ask_new_game = "ask_new_game"
CODE_ask_join_game = "ask_join_game"
CODE_ask_new_game_AI = "ask_new_game_AI"
CODE_what_now = "what_now"

# positive response
CODE_OK = "_OK"
CODE_ERR = "_ERR"


end

# ╔═╡ b85d9d1c-213c-4330-9f1d-95823c3a9491
function fwd_outbound(ws, msg_id, msg_code, resp_payload = Dict(), ok_response = true)

	# copy response payload
	response_msg = deepcopy(resp_payload)

	# prepare response code
	resp_msg_code = msg_code * (ok_response ? CODE_OK : CODE_ERR)
	
	# append original request id and response_code
	setindex!(response_msg, msg_id, :msg_id)
	setindex!(response_msg, resp_msg_code, :msg_code)

	# send response
	send(ws, JSON3.write(response_msg))

	# log
	println("LOG - $resp_msg_code - msg ID: $msg_id")

end

# ╔═╡ ebd8e962-2150-4ada-8ebd-3eba6e29c12e
function whos_player(game_code, player_id)
	
	# retrieve game setup info
	_orig_player = games_log_dict[game_code][:identity][:orig_player_id]

	# understand who is the player 
	return whos = (_orig_player == player_id) ? :originator : :joiner

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
	
	# set next moving player -> should be a setting (for now always white)
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
					:scenarioTree => scenario_tree,
					:next_action_code => "move") # client is next moving
					# later we should address cases of double scoring
	
	
	# saves game to general log (DB?)
	save_new_clientPkg!(games_log_dict, game_id, _cli_pkg)


	println("LOG - New client pkg created for game: $game_id")
	
	
end

# ╔═╡ f55bb88f-ecce-4c14-b9ac-4fc975c3592e
function update_serverStates(_game_code, _player_id, _scenario_pick)

	# convert moves to server indexes
	_start_index = reshape_in(_scenario_pick[:start])
	_end_index =  reshape_in(_scenario_pick[:end])

	# retrieve old game state and last moving
	ex_game_state = get_last_srv_gameState(_game_code)

	# get new game state
	_new_gs_delta = gen_New_gameState(ex_game_state, _start_index, _end_index)

	push!(games_log_dict[_game_code][:server_states], _new_gs_delta[:new_game_state_srv])

	

	# extract delta to be logged and passed onto client
	_delta_client = Dict(:flip_flag => _new_gs_delta[:flip_flag],
						:markers_toFlip => _new_gs_delta[:markers_toFlip_cli],
						:added_marker => _new_gs_delta[:added_marker_cli],
						:moved_ring => _new_gs_delta[:moved_ring_cli])


	push!(games_log_dict[_game_code][:client_delta], _delta_client)
	
	
	#=
	added marker index and color
	moved ring
	flipped markers
	removed markers (later, scoring)
	removed rings (later, scoring)

	=#

	println("LOG - Server game state and delta updated")


end

# ╔═╡ c38bfef9-2e3a-4042-8bd0-05f1e1bcc10b
function get_last_moving_player(game_code)

	return games_log_dict[game_code][:turns][:data][end][:moving_player]

end

# ╔═╡ 2bf729f5-d918-4965-b514-2a247fc9c760
games_log_dict["yNHKU"]

# ╔═╡ 7c0ea928-2cfc-472b-8320-e9420a498da8
print_gameState(games_log_dict["SopiI"][:server_states][end-1])

# ╔═╡ 388190e2-b017-40e6-9ec7-a984824a6f9a
reshape_out(findall(i -> i == "MB", get_last_srv_gameState("8Hil3")))

# ╔═╡ b483f566-e454-4f56-9625-607e9d158237
print_gameState(get_last_srv_gameState("SopiI"))

# ╔═╡ 14aa5b7c-9065-4ca3-b0e9-19c104b1854d
function scenario_choice(_tree::Dict)
	# value function for picking moves
	# works with depth-1 game scenario trees

	# retrieve summary function
	global_score_flag = _tree[:summary][:global_score_flag]
	global_flip_flag = _tree[:summary][:global_flip_flag]

	# pick random scoring option if available
	if global_score_flag && !isempty(_tree[:summary][:scoring_moves])
		
		_pick = rand(_tree[:summary][:scoring_moves])

	# if none, pick random that leads to flipped markers
	elseif global_flip_flag && !isempty(_tree[:summary][:flipping_moves])

		_pick = rand(_tree[:summary][:flipping_moves])

	# otherwise, pick a random move
	else
		_first_k = rand(filter(k -> k != :summary, collect(keys(_tree))))
		_second_k = rand(collect(keys(_tree[_first_k])))

		_pick = Dict(:start => _first_k, :end => _second_k)

	end

	return _pick::Dict{Symbol, Int}

end

# ╔═╡ 8dfd18a5-4127-40d2-819c-f17da2d6453d
_pick = scenario_choice(games_log_dict["SopiI"][])

# ╔═╡ 6a174abd-c9bc-4c3c-93f0-05a7d70db4af
function play_turn_AI(game_code::String, _moving_player_id::String)

	# get last game state and id of moving player
	# assumes turns are updated and moving player is AI
	_ex_game_state = get_last_srv_gameState(game_code)

	# generate scenarios
	_scenarios = gen_scenarioTree(_ex_game_state, _moving_player_id)

	# make choice
	_pick = scenario_choice(_scenarios)

	return _pick

end

# ╔═╡ a6f38ca6-99a9-4353-b820-0896b09b32f0
#=

	- get client response
	- update server game state
	- trigger AI
		- generate new scenarios
		- pick action
		- complete move/turn
	- reply to client
	- have client show results
	- repeat turn client-wise


=#

# ╔═╡ 1d64e575-2efe-4c50-a07b-1cd722e7a755
# update players status
# activate game
# trigger first turn

# ╔═╡ 3539b21d-4082-4b84-84dd-b736ea24978e
function update_player_status!(game_code, player_id)

	# reads last comunication from player and updates its status
	# player status can be: not_available OR ready

	# which log to look at?
	which_log = (whos_player(game_code, player_id) == :originator) ? :orig_player_comms : :join_player_comms

	# which status to update? (in case)
	which_status = (whos_player(game_code, player_id) == :originator) ? :orig_player_status : :join_player_status
	_player_status = games_log_dict[game_code][:players][which_status]

	# retrieve last communication
	last_player_comm = games_log_dict[game_code][:players][which_log][end]
	last_msg_code = last_player_comm[:msg_code]

	# if player is asking what to do and wasn't logged as ready -> mark as ready
	if last_msg_code == CODE_what_now && _player_status == :not_available

		_new_player_status = :ready
		games_log_dict[game_code][:players][which_status] = _new_player_status

	end


	# we should use this function to handle clients going offline and later handle re-connections

end

# ╔═╡ 5b4f9b35-0246-4813-9eb4-be8d28726f3f
function activate_next_turn!(game_code)

	# get more comfy handlers
	_game = games_log_dict[game_code]
	_turns = games_log_dict[game_code][:turns]
	_pointer = games_log_dict[game_code][:turns][:pointer]
	_status = games_log_dict[game_code][:turns][:data][_pointer][:status]
	_player = games_log_dict[game_code][:turns][:data][_pointer][:moving_player]


	#=
	# check if there was a previous turn
	_ex_pointer = (_pointer > 1) ? _pointer-1 : 0
	_ex_status = (_ex_pointer >= 1) ? _turns[:data][_ex_pointer][:status] : missing
	=#
	
	# case: turn not started -> goes to in_progress
	if _status == :not_started 

		_new_status = :in_progress
		_turns[:data][_pointer][:status] = _new_status

		return _pointer, _turns[:data][_pointer][:moving_player], _new_status

	# case: turn still in progress -> throw error 
	elseif _status == :in_progress 
		
		throw(error("ERROR: turn $_pointer in progress"))

	# case: turn completed -> create new one as not_started
	elseif _status == :completed 

		_next_moving = (_player == "W") ? "B" : "W"
		_new_status = :not_started
		_new_pointer = _pointer + 1
		
		_new_turn = Dict(:status => _new_status, :moving_player =>_next_moving)

		# write turns data
		push!(games_log_dict[game_code][:turns][:data], _new_turn)
		games_log_dict[game_code][:turns][:pointer] = _new_pointer

		return _new_pointer, _next_moving, _new_status
		
	end
		
end

# ╔═╡ 903e103c-ec53-423f-9fe1-99abea55c28d
function complete_turn!(game_code)

	# get more comfy handlers
	_game = games_log_dict[game_code]
	_turns = games_log_dict[game_code][:turns]
	_pointer = games_log_dict[game_code][:turns][:pointer]
	_status = games_log_dict[game_code][:turns][:data][_pointer][:status]
	_player = games_log_dict[game_code][:turns][:data][_pointer][:moving_player]


	# case: turn in progress -> mark as completed
	if _status == :in_progress 

		_new_status = :completed
		_turns[:data][_pointer][:status] = _new_status

		return _pointer, _turns[:data][_pointer][:moving_player], _new_status

	# case: turn not_started or completed -> throw error
	else
		throw(error("ERROR: turn $_pointer in status $_status"))
	end


end

# ╔═╡ f479f1f8-d6fd-4e48-a0f3-447997bc0416
function wannabe_orchestrator(msg_id, msg_code, msg_parsed)

	# get info from payload
	_game_code = msg_parsed[:game_id]
	_player_id = msg_parsed[:player_id]
	_scenario_pick = msg_parsed[:scenario_pick]

	# get game type info
	_game_type = games_log_dict[_game_code][:identity][:game_type]

	# is this the originator or joiner? -> log accordingly
	who_msg = whos_player(_game_code, _player_id)
	where_log = (who_msg == :originator) ? :orig_player_comms : :join_player_comms

	# save communication -> assumes is about player ready or turn completed
	push!(games_log_dict[_game_code][:players][where_log], msg_parsed)
	# log save action
	println("LOG - Client msg logged - msg ID: $msg_id")

	###### -> this should run as a separate service with websockets pings
		# update player status
		update_player_status!(_game_code, _player_id)
	
		# update player turn data -> should set turn to completed
		# TODO
	
		# everyone ready? -> check turns
		_status_orig = games_log_dict[_game_code][:players][:orig_player_status]
		_status_join = games_log_dict[_game_code][:players][:join_player_status]

	######


	## understand what's going on in the game
	_pointer = games_log_dict[_game_code][:turns][:pointer]
	_status = games_log_dict[_game_code][:turns][:data][_pointer][:status]


	#### handling first turn / game start
	if _pointer == 1 && _status == :not_started 
		
		if _status_orig == _status_join == :ready 
	
			# activate turn
			turn_no, next_player, turn_status = activate_next_turn!(_game_code)
	
			# who moves next?
			who_moves = whos_player(_game_code, next_player)
	
			if who_msg == who_moves

				_cli_response = Dict(:next_action_code => "move",
									:turn_no => turn_no)
				
				# -> make move
				return _cli_response
	
			elseif who_msg != who_moves
	
				# -> wait for opponent's move
				return Dict(:next_action_code => "wait")
	
			end
	
		else
			throw(error("ERROR - players not ready"))
		end
	end


	## handling following turns
	if _pointer >= 1 && _status == :in_progress

		# check information from player
		if !(_scenario_pick == false)
		
			# update server game state
			update_serverStates(_game_code, _player_id, _scenario_pick)

			# complete turn
			complete_turn!(_game_code)
			
			# compute next move if AI game 
			if _game_type == :h_vs_ai

				# create AI turn
				activate_next_turn!(_game_code)

				# activate turn
				turn_no, next_player, turn_status = activate_next_turn!(_game_code)

				# pick move
				_pick = play_turn_AI(_game_code, next_player)

				# update server game state and extract delta
				update_serverStates(_game_code, next_player, _pick)

				# complete turn
				complete_turn!(_game_code)
						
				# create & activate turn
				activate_next_turn!(_game_code)
				turn_no, next_player, turn_status = activate_next_turn!(_game_code)

				# gen new game data for client
				gen_new_clientPkg(_game_code, next_player)

				# retrieve client package
				_client_pkg = getLast_clientPkg(_game_code)

				# retrieve states delta
				_client_delta = getLast_clientDelta(_game_code)

					# append delta to package for client
					setindex!(_client_pkg, _client_delta, :delta)
	
					# add info on turn_no
					setindex!(_client_pkg, turn_no, :turn_no)
				
				
				return _client_pkg
			end
		
		end

	end


end

# ╔═╡ a2d0d733-345d-46a7-959b-69c3fac3eabe
function ws_msg_handler(ws, msg_parsed)

	# retrieve id and message code
	msg_id = msg_parsed[:msg_id]
	msg_code = msg_parsed[:msg_code]

	# save incoming message
	push!(ws_messages_log, msg_parsed)

####################################
	
	# handle request for a new game
	if msg_code == CODE_ask_new_game

		# generate new game
		new_game_id = gen_newGame() # <- will generate and save game data
		new_game_data = getLast_clientPkg(new_game_id)

		# reply to client
		fwd_outbound(ws, msg_id, msg_code, new_game_data)
	
	end

####################################
	
	# handle request to join existing game
	if msg_code == CODE_ask_join_game

		# try retrieving and sending game data
		try 

			# retrieve existing game data
			ex_game_id = msg_parsed[:game_id]
			ex_game_data = getLast_clientPkg(ex_game_id)

			# reply to client
			fwd_outbound(ws, msg_id, msg_code, ex_game_data)

		# handle errors
		catch 
			
			# reply to client
			fwd_outbound(ws, msg_id, msg_code, ok_response = false)
			
		end
	end

####################################

	# handle request to play with AI
	if msg_code == CODE_ask_new_game_AI

		# generate new game
		new_game_id = gen_newGame(true) # <- generate and save game data vs AI
		new_game_data = getLast_clientPkg(new_game_id)

		# reply to client
		fwd_outbound(ws, msg_id, msg_code, new_game_data)
	
	end

####################################

	# handle players asking for what to do next (turns)
	if msg_code == CODE_what_now

		# orchestrator
		_resp = wannabe_orchestrator(msg_id, msg_code, msg_parsed)

		# reply to client
		fwd_outbound(ws, msg_id, msg_code, _resp)

	end


end

# ╔═╡ 1ada0c42-9f11-4a9a-b0dc-e3e7011230a2
function init_ws_server()

	# starts new websockets server 
	ws_server = WebSockets.listen!(ws_test_ip, ws_test_port) do ws

		# iterate over incoming messages
		for msg in ws

			# parse incoming msg as json
			msg_parsed = Dict(JSON3.read(msg))
			
			# dispatch parsed message to message handler
			ws_msg_handler(ws, msg_parsed)

		end
    end

	# saves websocket server handler
	push!(ws_servers_ref, ws_server)

end

# ╔═╡ a89ad247-bde8-4912-a5c3-65a361e6942c
function respawn_ws_server()

	# forces closure of last server (if existing) and starts a new one
	if length(ws_servers_ref) > 0
		
		HTTP.forceclose(ws_servers_ref[end])
		init_ws_server()

	else
		init_ws_server()
	end
	

end

# ╔═╡ 31bea118-f628-4f98-bd25-4f0077f06538
respawn_ws_server()

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

# ╔═╡ 664de69a-aaa6-4139-806b-b3d241bd7e40
ws_servers_ref[end]

# ╔═╡ bd16c53e-bd3e-4328-988d-857bab42f0e6
last_conn = collect(ws_servers_ref[end].connections)

# ╔═╡ 972d60e0-ed99-465e-a6fa-aefca286c2cb
md"#### Handling turns logic "

# ╔═╡ e7de85fc-e51e-47a3-98e8-ddc0fab782ba
#=

event chain

new game handling

A = originating player
S = server
B = joiner


--
A -> requests new game
S -> sends data
A -> sets up game -> notifies server of ready state (10s to reply)
S -> logs game as ready for originator
--
A -> (shares code with B)
B -> requests server for game data 
S -> sends data
B -> sets up game -> notifies server of ready state
S -> logs game as ready for joiner
--
S -> both players ready -> game can start
S -> checks who is the first moving player -> notifies player
--
B -> receives message -> acknowledge msg to server (10s to reply)
B -> interaction enabled -> player completes turn -> notifies server
S -> server replies acknowledge
B -> waits for other players' turn (timed ?)
S -> server handles turn -> presimulates next moves -> notifies other player
S -> .... (cycle repeats)


=#

# ╔═╡ 26ce8f2c-efc2-4ff0-84c6-54c75dc887f1


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
JSON3 = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
PlotThemes = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"

[compat]
HTTP = "~1.9.5"
JSON3 = "~1.12.0"
PlotThemes = "~3.1.0"
Plots = "~1.38.7"
PlutoUI = "~0.7.50"
StatsBase = "~0.33.21"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.0"
manifest_format = "2.0"
project_hash = "3e07a06d64e538a955daef45d305f17ecaae42b8"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitFlags]]
git-tree-sha1 = "43b1a4a8f797c1cddadf60499a8a077d4af2cd2d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.7"

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
git-tree-sha1 = "9c209fb7536406834aa938fb149964b985de6c83"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.1"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "be6ab11021cd29f0344d5c4357b163af05a48cba"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.21.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "600cc5508d66b78aae350f7accdb58763ac18589"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.10"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "7a60c856b9fa189eb34f5f8a6f6b5529b7942957"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.6.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.2+0"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "96d823b94ba8d187a6d8f0826e731195a74b90e9"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.2.0"

[[deps.Contour]]
git-tree-sha1 = "d05d9e7b7aedff4e5b51a029dced05cfb6125781"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.2"

[[deps.DataAPI]]
git-tree-sha1 = "e8119c1a33d267e16108be441a287a6981ba1630"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.14.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bad72f730e9e91c08d9427d5e8db95478a3c323d"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.8+0"

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

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

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
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "d972031d28c8c8d9d7b41a536ad7bb0c2579caca"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.8+0"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Preferences", "Printf", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "UUIDs", "p7zip_jll"]
git-tree-sha1 = "efaac003187ccc71ace6c755b197284cd4811bfe"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.72.4"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4486ff47de4c18cb511a0da420efebb314556316"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.72.4+0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "d3b3624125c1474292d0d8ed0f65554ac37ddb23"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.74.0+2"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "ba9eca9f8bdb787c6f3cf52cb4a404c0e349a0d1"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.9.5"

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
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.JLFzf]]
deps = ["Pipe", "REPL", "Random", "fzf_jll"]
git-tree-sha1 = "f377670cda23b6b7c1c0b3893e37451c5c1a2185"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.5"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "SnoopPrecompile", "StructTypes", "UUIDs"]
git-tree-sha1 = "84b10656a41ef564c39d2d477d7236966d2b5683"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.12.0"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6f2675ef130a300a112286de91973805fcc5ffbc"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.91+0"

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

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Printf", "Requires"]
git-tree-sha1 = "099e356f267354f46ba65087981a77da23a279b7"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.0"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

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
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c7cb1f5d892775ba13767a87c7ada0b980ea0a71"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+2"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

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
git-tree-sha1 = "0a1b7c2863e44523180fdb3146534e265a91870b"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.23"

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
git-tree-sha1 = "cedb76b37bc5a6c702ade66be44f831fa23c681e"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.0"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

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
version = "2.28.2+0"

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
version = "2022.10.11"

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
version = "0.3.21+4"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "51901a49222b09e3743c65b8847687ae5fc78eb2"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.4.1"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9ff31d101d987eb9d66bd8b176ac7c277beccd09"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.20+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "d321bf2de576bf25ec4d3e4360faca399afca282"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.0"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+0"

[[deps.Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "478ac6c952fddd4399e71d4779797c538d0ff2bf"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.8"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.0"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "1f03a2d339f42dca4a4da149c7e15e9b896ad899"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.1.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "f92e1315dadf8c46561fb9396e525f7200cdc227"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.5"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "PrecompileTools", "Preferences", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "6c7f47fd112001fc95ea1569c2757dffd9e81328"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.38.11"

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
git-tree-sha1 = "b478a748be27bd2f2c73a7690da219d0844db305"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.51"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "259e206946c293698122f63e2b513a7c99a244e8"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.1.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "7eb1686b4f04b82f96ed7a4ea5890a4f0c7a09f1"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "0c03844e2231e12fda4d0086fd7cbe4098ee8dc5"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+2"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
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
git-tree-sha1 = "90bc7a7c96410424509e4263e277e43250c05691"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.0"

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
git-tree-sha1 = "30449ee12237627992a99d5e30ae63e4d78cd24a"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.0"

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

[[deps.SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "ef28127915f4229c971eb43f3fc075dd3fe91880"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.2.0"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "45a7769a04a3cf80da1c1c7c60caf932e6f4c9f7"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.6.0"

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
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

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
git-tree-sha1 = "aadb748be58b492045b4f56166b5188aa63ce549"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.7"

[[deps.URIs]]
git-tree-sha1 = "074f993b0ca030848b897beff716d93aca60f06a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.2"

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

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "ed8d92d9774b077c53e1da50fd81a36af3744c1c"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+0"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4528479aa01ee1b3b4cd0e6faef0e04cf16466da"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.25.0+0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "93c41695bc1c08c46c5899f4fe06d6ead504bb73"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.10.3+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

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
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

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
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "49ce682769cd5de6c72dcf1b94ed7790cd08974c"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.5+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "868e669ccb12ba16eaf50cb2957ee2ff61261c56"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.29.0+0"

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
version = "5.7.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

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
git-tree-sha1 = "9ebfc140cc56e8c2156a15ceac2f0302e327ac0a"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+0"
"""

# ╔═╡ Cell order:
# ╠═43f89626-8583-11ed-2b3d-b118ff996f37
# ╠═9505b0f0-91a2-46a8-90a5-d615c2acdbc1
# ╠═1f9da483-6b05-4867-a509-2c24b41cd5d6
# ╠═d41d8f2c-16f2-4e41-bf81-fccc761b62cc
# ╠═fddf20d4-15e4-4ac8-99b1-98860f991297
# ╠═1b8f5256-7433-405b-8419-cd00fceb4ccf
# ╠═2d69b45e-d8e4-4505-87ed-382e45bebae7
# ╠═58e4dbd8-61c6-473f-95e1-826822884895
# ╠═c96e1ee9-6d78-42d2-bfd6-2e8f88913b37
# ╠═b6292e1f-a3a8-46d7-be15-05a74a5736de
# ╟─55987f3e-aaf7-4d85-a6cf-11eda59cd066
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
# ╠═403d52da-464e-42df-8739-269eb5f98df1
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
# ╠═f0e9e077-f435-4f4b-bd69-f495dfccec27
# ╠═bf2dce8c-f026-40e3-89db-d72edb0b041c
# ╠═33707130-7703-4aa0-84e6-23ab387c0c4d
# ╠═9d153cf1-3e3b-49c0-abe7-ebd0f524557c
# ╟─52bf45df-d3cd-45bb-bc94-ec9f4cf850ad
# ╠═8f2e4816-b60d-40eb-a9d8-acf4240c646a
# ╠═c67154cb-c8cc-406c-90a8-0ea8241d8571
# ╠═c2797a4c-81d3-4409-9038-117fe50540a8
# ╟─53dec9b0-dac1-47a6-b242-9696ff45b91b
# ╟─148d1418-76a3-462d-9049-d30e85a45f06
# ╟─fc68fa36-e2ea-40fa-9d0e-722167a2506e
# ╟─7fe89538-b2fe-47db-a961-fdbdd4278963
# ╟─c1fbbcf3-aeec-483e-880a-05d3c7a8a895
# ╠═8e400909-8cfd-4c46-b782-c73ffac03712
# ╟─2c1c4182-5654-46ad-b4fb-2c79727aba3d
# ╠═6f0ad323-1776-4efd-bf1e-667e8a834f41
# ╠═13cb8a74-8f5e-48eb-89c6-f7429d616fb9
# ╠═c334b67e-594f-49fc-8c11-be4ea11c33b5
# ╠═f1949d12-86eb-4236-b887-b750916d3493
# ╠═e0368e81-fb5a-4dc4-aebb-130c7fd0a123
# ╟─61a0e2bf-2fed-4141-afc0-c8b5507679d1
# ╠═bc19e42a-fc82-4191-bca5-09622198d102
# ╠═57153574-e5ca-4167-814e-2d176baa0de9
# ╠═1fe8a98e-6dc6-466e-9bc9-406c416d8076
# ╠═6075f560-e190-409b-8435-a7cf08ec1bc6
# ╠═1f021cc5-edb0-4515-b8c9-6a2395bc9547
# ╠═aaa8c614-16aa-4ca8-9ec5-f4f4c6574240
# ╟─5da79176-7005-4afe-91b7-accaac0bd7b5
# ╠═8eab6d11-6d28-411d-bd82-7bec59b3f496
# ╠═761fb8d7-0c7d-4428-ad48-707d219582c0
# ╟─cf587261-6193-4e7a-a3e8-e24ba27929c7
# ╟─439903cb-c2d1-49d8-a5ef-59dbff96e792
# ╠═9a08682a-6406-45d2-b655-9fe24a9158e5
# ╠═d9077e87-df02-43c8-ae5c-0df75eeee846
# ╟─f86b195e-06a9-493d-8536-16bdcaadd60e
# ╟─466eaa12-3a55-4ee9-9f2d-ac2320b0f6b1
# ╟─b170050e-cb51-47ec-9870-909ec141dc3d
# ╠═70ecd4ed-cbb1-4ebd-85a8-42f7b072bee3
# ╠═bd7e7cdd-878e-475e-b2bb-b00c636ff26a
# ╠═1450c9e4-4080-476c-90d2-87b19c00cfdf
# ╠═c9c4129f-b507-4c92-899b-bc31087b63f4
# ╠═31bea118-f628-4f98-bd25-4f0077f06538
# ╠═0bb77295-be29-4b50-bff8-f712ebe08197
# ╟─1ada0c42-9f11-4a9a-b0dc-e3e7011230a2
# ╟─a89ad247-bde8-4912-a5c3-65a361e6942c
# ╟─a2d0d733-345d-46a7-959b-69c3fac3eabe
# ╟─b85d9d1c-213c-4330-9f1d-95823c3a9491
# ╠═f479f1f8-d6fd-4e48-a0f3-447997bc0416
# ╟─ebd8e962-2150-4ada-8ebd-3eba6e29c12e
# ╠═f55bb88f-ecce-4c14-b9ac-4fc975c3592e
# ╟─67322d28-5f9e-43da-90a0-2e517b003b58
# ╟─f1c0e395-1b22-4e68-8d2d-49d6fc71e7d9
# ╟─c38bfef9-2e3a-4042-8bd0-05f1e1bcc10b
# ╠═2bf729f5-d918-4965-b514-2a247fc9c760
# ╠═7c0ea928-2cfc-472b-8320-e9420a498da8
# ╠═388190e2-b017-40e6-9ec7-a984824a6f9a
# ╠═b483f566-e454-4f56-9625-607e9d158237
# ╠═8dfd18a5-4127-40d2-819c-f17da2d6453d
# ╠═6a174abd-c9bc-4c3c-93f0-05a7d70db4af
# ╠═14aa5b7c-9065-4ca3-b0e9-19c104b1854d
# ╠═a6f38ca6-99a9-4353-b820-0896b09b32f0
# ╠═1d64e575-2efe-4c50-a07b-1cd722e7a755
# ╠═3539b21d-4082-4b84-84dd-b736ea24978e
# ╠═5b4f9b35-0246-4813-9eb4-be8d28726f3f
# ╠═903e103c-ec53-423f-9fe1-99abea55c28d
# ╟─2a63de92-47c9-44d1-ab30-6ac1e4ac3a59
# ╠═664de69a-aaa6-4139-806b-b3d241bd7e40
# ╠═bd16c53e-bd3e-4328-988d-857bab42f0e6
# ╟─972d60e0-ed99-465e-a6fa-aefca286c2cb
# ╠═e7de85fc-e51e-47a3-98e8-ddc0fab782ba
# ╠═26ce8f2c-efc2-4ff0-84c6-54c75dc887f1
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
