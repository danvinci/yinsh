### A Pluto.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ 9aa41b22-c5fe-11ef-0462-afad4496a201
using Random

# ╔═╡ 0e8cd2f5-8bee-4a9f-8710-b9d202e2a387
using Dates

# ╔═╡ 091f21e6-a71c-420c-92ea-4582a8073970
using HTTP, JSON3

# ╔═╡ 60d0b02b-c8af-4494-afc6-2c46deedfae2
using HTTP.WebSockets

# ╔═╡ 42734e5f-9c7d-46d3-9482-54911bf4e12d
using .Threads

# ╔═╡ 527622e1-fcf4-4ffc-8de5-c4006ede05ce
using PlutoUI

# ╔═╡ 45b9cdc8-28c2-4a49-855e-733314a9f7a6
using StatsBase

# ╔═╡ 4b5bb371-0575-452b-8fe3-4204245c6b85
TableOfContents()

# ╔═╡ a92a4b60-9c66-4a23-a249-37437677ca2e
md"## Server connection"

# ╔═╡ 44db8669-985a-46f8-8d52-1f1a4053f25a
begin
	
	# ip and port to use for the server
	const ws_ip = "0.0.0.0" # listen on every ip / host ip
	const ws_port = 6091 # local dev game server
end

# ╔═╡ ae3a9096-f868-4649-ae63-efde9cbef423
# ╠═╡ disabled = true
#=╠═╡
function push_to_ws_log!(_msg)

	try 
		lock(ws_msg_log_lock)
			push!(ws_msg_log, _msg)
		unlock(ws_msg_log_lock)
	catch e
		println("LOG - Error writing to ws logs: $e")
	end
	
end
  ╠═╡ =#

# ╔═╡ 8e1ac4e0-dbba-4a6e-b38a-bfb3f349d285
gen_rand_id() = randstring(['a':'z'; '0':'9'])

# ╔═╡ 6799bbd5-2ab3-47af-ad17-e781b2b9c4d5
# interrupt identification fn
interrupt_ex_HTTP(e) = (isa(e, HTTP.Exceptions.HTTPError) && isa(e.error, InterruptException))

# ╔═╡ 4c7739b2-cf0a-4350-a049-f87875aa793e
md"## Server communication"

# ╔═╡ 379f96f4-3f11-40b2-98ed-0c11a489c3fd
begin
	
	# game codes - used for different requests by player
	# server responds with same + _OK or _ERROR
	const CODE_new_game_human = "new_game_vs_human"
	const CODE_new_game_server = "new_game_vs_server"
	const CODE_join_game = "join_game"
 	const CODE_advance_game = "advance_game" # player asking to progress the game
	const CODE_resign_game = "resign_game" # player asking to resign
	
	# server codes to instruct player (only the server can use these)
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

# ╔═╡ 3e2b416c-1e41-4d4b-911c-ccb9413b4823
md"## Test controls"

# ╔═╡ 39daeffb-2da6-484e-8ac2-90f701832898
## https://discourse.julialang.org/t/how-to-kill-thread/34236/8

# ╔═╡ 6888cbee-f76e-4d00-ab0b-190962f6ca55
const test_dump = Dict(:any => [], :outcomes => [], :errors => [])

# ╔═╡ 4b68abff-91b3-4810-b5e3-bb615417cbac
const _test_lock = ReentrantLock()

# ╔═╡ 99d14a39-08b5-43bb-b42c-bc729990d229
struct StopToken end

# ╔═╡ 3f8aa63d-5a6b-4d82-bd72-889472be3f92
begin
	const num_p = 50
	const max_concurrent_p = 10
end

# ╔═╡ d38a0908-a55c-4183-927d-894efe6e9ffb
begin
	const pending_p = Channel{Int}(num_p)
	const running_p = Channel{Int}(max_concurrent_p)
	const terminated_p = Channel{Int}(num_p)
end

# ╔═╡ ef27a573-669d-499b-80f4-f076222373b3
function init_pending_ch()
	
	empty!(pending_p) # for re-runs
	
	for k in 1:num_p
		put!(pending_p, k)
	end
	
	@info "LOG - pending_p channel loaded with $num_p players"
end

# ╔═╡ a1514598-6c4e-42fa-b9b8-2f7ef388f356
md"#### Start concurrent test: $(@bind start_test CheckBox(default=false))"

# ╔═╡ 04da4765-05d5-44e3-a724-3d98d808a483
if start_test

	@spawn init_pending_ch()

	@spawn begin

		try

			## act on yet to run players
			while isready(pending_p)
	
				k = take!(pending_p)

				put!(running_p, k) # will wait until channel has space

				# initialize new player on demand
				create_player(k)
				spawn_p_dispatch_task(k)
					
				# actually start game -> msg dispatcher & handler will take over
				@spawn SRV_req_new_game_vs_server(p_dict[k])
				
				# limiting outer loop
				sleep(2)
	
			end
		catch e
			@error "ERROR - player #$(p.id) - new games initializer", e
			rethrow(e)
		end
			
	end
end

# ╔═╡ 6e38243a-9127-4983-ad52-8d69f4ae12e2
if start_test

	@spawn begin

		sleep(30) # give time for games to start

		try
			while isready(running_p) || isready(pending_p)
				
				k = fetch(running_p)
				p = p_dict[k]

				can_terminate = false
				while !can_terminate
					_never_started = isready(p.send_channel) && isnothing(p.game) 
					_completed = !isnothing(p.game) && p.game.status=="completed"
					_stuck = !isnothing(p.game) && p.game.updated+Second(30)<now()
					
					if _never_started || _completed || _stuck
						can_terminate = true
						take!(running_p)
					end
					sleep(3) # wait before re-checking same player
				end
	
				@spawn begin # <- termination task for each game
	
					try 
						@warn "LOG - terminating player #$(p.id)"
						
						# stop ws task / connection
						if !isnothing(p.ws_task) && !istaskdone(p.ws_task)
							schedule(p.ws_task, InterruptException(), error=true)
						end 
						
						# stop dispatcher 
						if !isnothing(p.dispatch_task) && !istaskdone(p.dispatch_task)
							put!(p.receive_channel, StopToken()) 
						end 

						# set aside the index
						put!(terminated_p, k)
						GC.safepoint()
						
					catch e
						@error "ERROR - p #$(p.id) - termination task", e
						rethrow(e)
					end
	
				end
				sleep(2) # wait before re-checking running players
			end

		catch e
			@error "ERROR - p #$(p.id) - termination handler", e
			rethrow(e)
		end
	end
end

# ╔═╡ db003af9-654c-4a3a-8797-8f6ff8e7d8b5
test_dump

# ╔═╡ 1df492d5-f456-4242-9d40-35a50492b6bd
md"## Play the game"

# ╔═╡ 4de23652-f375-4362-9c68-a3460d6940e1
mutable struct Game

	id::String
	status::String
	rings::Vector{Dict}
	markers::Vector{Dict}
	player_id::String
	rings_mode::String
	ring_setup_spots::Vector
	turn_no::Int
	scenario_trees::Dict
	updated::DateTime

end

# ╔═╡ f38f4e3e-f9dc-4d8c-9afc-0309a3ccc362
begin

	mutable struct Player

		id::Int
		send_channel::Channel{Any}
		receive_channel::Channel{Any}
		dispatch_task::Union{Task, Nothing}
		ws_task::Union{Task, Nothing}
		game::Union{Game, Nothing}
		
	end

	Player(id) = Player(id, Channel{Any}(Inf), Channel{Any}(Inf), nothing, nothing, nothing)
	
end

# ╔═╡ d7cc05ac-e4c6-4bb8-9977-0b5d290b4253
begin
	const p_dict = Dict{Int, Player}() # dict( player.id => player )
	const p_dict_lock = ReentrantLock()
end

# ╔═╡ 6916407b-62f5-4093-98a7-ebaa18c71014
function spawn_p_dispatch_task(k)

	p = p_dict[k]

	_prev_task = p.dispatch_task
	
	if isa(_prev_task, Task) && !istaskdone(_prev_task) # stop existing task
		
		put!(p.receive_channel, StopToken()) # terminates prev task
		sleep(0.1)
		@info "LOG - player #$k - dispatch task: sending stop token"
	
	end
	
	p.dispatch_task = @spawn incoming_msg_dispatcher(p)
	@info "LOG - player #$k - dispatch task: active"

end

# ╔═╡ 8f29f032-1c5b-4578-ae7f-22f5111b19b7
function filter_msg_by_gid(gid::String)

	p_num = filter(kv -> (last(kv).game.id == gid), p_dict) |> first |> first

	@info "Game $gid was played by player #$p_num"
	
	filter(d -> (haskey(d, :game_id) && d[:game_id]==gid), test_dump[:any])
	
end

# ╔═╡ f856ad31-1393-4fb8-a0f8-32f2975cf793
function save_player_details!(p::Player)

	try 
		lock(p_dict_lock)
			try
				setindex!(p_dict, p, p.id)
				@info "LOG - player #$(p.id) saved"
			finally
				unlock(p_dict_lock)
			end
	catch e
		@error "Error - player $(p.id) can't be saved in p_dict"
	end

end

# ╔═╡ 76a92456-f985-4b1e-9821-20b54fe1d073
function create_player(id::Int)

# new player
p = Player(id)

ws_task = @spawn begin

	listener_task = nothing
	sender_task = nothing

	try

		WebSockets.open("ws://$ws_ip:$ws_port"; idle_timeout_enabled = false) do ws 

			# listener task definition
			function init_listener(ws, receive_ch)
				return () -> begin
					try
						while !WebSockets.isclosed(ws)
							for msg in ws # <- blocking call to ws
								put!(receive_ch, msg)
							end
						end
					catch e
						if isa(e, InterruptException) || isa(e, EOFError)
							@warn "LOG - player #$(p.id) - listener task interrupted", e
							return # clean exit
						end
						@error "ERROR - player #$(p.id) - listener task failure", e
						rethrow(e) # task failure
					end
				end
			end

			   
			# sender task definition
			function init_sender(ws, sender_ch)
				return () -> begin
					try
						while !WebSockets.isclosed(ws) 
	
							msg = take!(sender_ch)
							setindex!(msg, gen_rand_id(), :msg_id) # add id
		
							!(ws.writeclosed) && send(ws, JSON3.write(msg))
						end
					catch e
						if isa(e, InterruptException) || isa(e, EOFError)
							@warn "LOG - player #$(p.id) - sender task interrupted", e
							return # clean exit
						end
						@error "ERROR - player #$(p.id) - sender task failure", e
						rethrow(e) # task failure
					end
				end
			end

			try 
				# create and schedule tasks
				listener_task = @spawn init_listener(ws, p.receive_channel)()
				sender_task = @spawn init_sender(ws, p.send_channel)()

				wait(listener_task)
				wait(sender_task)

				# websocket connection should closes as we send interrupt
				
			catch e 
				# InterruptException is caught by innermost try/catch first
				# close ws and unblock receive (for msg in ws)
				!WebSockets.isclosed(ws) && close(ws) 
				sleep(0.5)
				rethrow(e)
			end
		end

	catch e

		# InterruptException is caught by innermost try/catch first
	   	# try to clean up child tasks regardless of error type
		if isa(e, InterruptException) || interrupt_ex_HTTP(e) || isa(e, EOFError)
			for t in [listener_task, sender_task]
		       if !isnothing(t) && !istaskdone(t) # done is true also if failed
		           try
		               schedule(t, InterruptException(), error=true)
		           catch e
		               @warn "LOG - player #$(p.id) - task interruption failed", e
		           end
		       end
		   	end
			@warn "LOG - player #$(p.id) - ws task interrupted", e 
	   else # <- handling non-clean exits
	       @error "ERROR - player #$(p.id) - ws unhandled error", e
	   end
	end
end

p.ws_task = ws_task
save_player_details!(p)

end

# ╔═╡ 999d80ad-8800-4906-bed7-d8eeec15d53e
function SRV_req_new_game_vs_server(p::Player)
# assumes the player already has an open connection

	req_msg = Dict( :msg_code => CODE_new_game_server, 
					:payload => Dict(:random_rings => true))

	put!(p.send_channel, req_msg)

end

# ╔═╡ c191aace-4ee0-4ee9-a45d-cdb226413a76
function SRV_advance_game(p::Player, turn_recap::Union{Bool, Dict})

	# => we'll need a turn recap function
	
	resp = Dict(:msg_code => CODE_advance_game, 
				:payload => Dict( 	:game_id => p.game.id,
									:player_id => p.game.player_id,
									:turn_recap => turn_recap))
	

	@info "LOG - player #$(p.id) - game $(p.game.id) - requesting advance"
	put!(p.send_channel, resp)
	
end

# ╔═╡ 2a910de1-8664-4b6e-b992-c27cb613fc24
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
	
end

# ╔═╡ ed6d8a10-c80d-4f3b-8ff3-0c6cb2880811
begin

	# actionable codes
	const RESP_setup_vs_server_OK = CODE_new_game_server*sfx_CODE_OK
	const RESP_advance_game_OK = CODE_advance_game*sfx_CODE_OK
	const RESP_resign_game_OK = CODE_resign_game*sfx_CODE_OK

end

# ╔═╡ 661123d7-b76e-4fdf-ade7-5779808b968d
function internalize_game_state!(p::Player, msg::Dict)

	try

		_has_game_id = haskey(msg, :game_id)
		_has_og_player_id = haskey(msg, :orig_player_id)
		_has_rings = haskey(msg, :rings)
		_has_markers = haskey(msg, :markers)
		_has_status = haskey(msg, :game_status)
		_has_rings_mode = haskey(msg, :rings_mode)
		_has_ring_setup_spots = haskey(msg, :ring_setup_spots)
		_has_turn_no = haskey(msg, :turn_no)
		_has_scenario_trees = haskey(msg, :scenario_trees)
	
	
		### create new game
		if isnothing(p.game) 
			if _has_game_id && _has_og_player_id
				
				p.game = Game( msg[:game_id], 
								"not_started", 
								Dict[], 
								Dict[], 
								msg[:orig_player_id],
								"",
								[], 
								0,
								Dict(),
								now())
			end
		end
	
		### update existing game
		# game id & player
		_has_game_id && (p.game.id = msg[:game_id])
		_has_og_player_id && (p.game.player_id = msg[:orig_player_id])
		
		# rings mode
		_has_rings_mode && (p.game.rings_mode = msg[:rings_mode])
		_has_ring_setup_spots && (p.game.ring_setup_spots = msg[:ring_setup_spots])
		
		# new board state
		_has_rings && (p.game.rings = msg[:rings])
		_has_markers && (p.game.markers = msg[:markers])
			
		# game status
		_has_status && (p.game.status = msg[:game_status])

		# turn number
		_has_turn_no && (p.game.turn_no = msg[:turn_no])

		# game scenarios
		_has_scenario_trees && (p.game.scenario_trees = msg[:scenario_trees])

		# log last updated time anytime this fn is called 
		p.game.updated = now()
		
	
		@info "LOG - player #$(p.id) - game $(p.game.id) updated"
	catch e
		@error "ERROR - player #$(p.id) - game $(p.game.id) - internalizing game state", e
	end
	
end

# ╔═╡ 37158d4d-de39-4cbc-961c-aefb17c102d6
function p_play_turn(p::Player)

	try 

		turn_recap = Dict{Symbol, Any}(:completed_turn_no => p.game.turn_no)
	
		#=	scenario trees
	
			no pre-move scoring -> scenario_trees > treepots[1] > tree -> start -> end
			no pre-move scoring -> scenario_trees > treepots[?] > tree -> start -> end
		=#
	
		### capabilities
		# NO | handle manual rings setup -> later, now asking only random gamesss
		# NO | handle pre-moves scoring -> let's wait for error to get example data
		# OK | handle move
		# NO | handle scoring
		# NO | random resignations
	
		# ----------------------------------------------------------
	
		# ring setup
		# not implemented
	
		# score actions pre-move
		# not implemented
			
	
		# prev code should select correct tree -> not implemented
		_tree = Dict()
		try
			_tree = p.game.scenario_trees[:treepots][1][:tree]
		catch e
			@error "ERROR - player #$(p.id) - game $(p.game.id) - play turn: can't locate scenario tree", e
		end
	
		
		# random move
		ring_start = _tree |> keys |> rand
		ring_end = _tree[ring_start] |> keys |> rand
		setindex!(turn_recap, Dict(:start => ring_start, :end => ring_end), :move_action)
		
		
		# score actions
		# not implemented
		
		@info "LOG - player #$(p.id) - game $(p.game.id) played turn $(p.game.turn_no)"
		return turn_recap

	catch e
		@error "ERROR - player #$(p.id) - game $(p.game.id) - play turn", e
	end
	

end

# ╔═╡ 3609fefa-1e57-4645-9430-e80ff6ff64ca
function server_msg_handler(p::Player, msg::Dict)

	try 

		msg_code = haskey(msg, :msg_code) ? msg[:msg_code] : ""
		next_action_code = haskey(msg, :next_action_code) ? msg[:next_action_code] : ""
		@info "LOG - player #$(p.id) - new msg: $msg_code | $next_action_code"
	
		# CASES
		setup_game=(msg_code==RESP_setup_vs_server_OK)
		play_turn=(msg_code==RESP_advance_game_OK && next_action_code==CODE_play) 
		end_game=(msg_code==RESP_advance_game_OK && next_action_code==CODE_end_game)
		srv_error = contains(next_action_code, sfx_CODE_ERR)
	
		# new game confirmation
		if setup_game
			
			internalize_game_state!(p, msg)
			SRV_advance_game(p, false)
	
		end
	
	
		# play turn
		if play_turn
			
			internalize_game_state!(p, msg)
			turn_recap = p_play_turn(p)
			SRV_advance_game(p, turn_recap)
	
		end
	
	
		# game terminated
		if end_game
			internalize_game_state!(p, msg)
			@info "LOG - player #$(p.id) - game $(p.game.id) completed"
		end
		
		
		lock(_test_lock) 
			push!(test_dump[:any], msg)
			end_game && push!(test_dump[:outcomes], 
									Dict( 	:last_msg => msg, 								
											:player_id => p.game.player_id, 				
											:no_turns => p.game.turn_no))
			srv_error && push!(test_dump[:errors], msg)
		unlock(_test_lock)

	catch e
		lock(_test_lock) 
			push!(test_dump[:errors], e)
		unlock(_test_lock)
		@error "ERROR - server msg handler", e
	end

end

# ╔═╡ 212774ca-5ac1-4054-baab-18c9e759b431
md"## Utilities"

# ╔═╡ eeafa3f7-f5f0-475e-9542-33fa1b1da407
function other_player(id::String)

	(id in ["B", "W"]) ? (return (id == "B") ? "W" : "B") : error("invalid player id")
	
end

# ╔═╡ ad791a85-f38f-4784-921b-2ac066b1ac60
function analyse_logs()

	# players
	num_p = p_dict |> length
	p_w_game = filter(id_p -> !isnothing(last(id_p).game), p_dict)
	p_w_game_completed = filter(id_p -> last(id_p).game.status == "completed", p_w_game)

	# games played
	g_ids = filter(d -> haskey(d, :game_id), test_dump[:any]) |> v -> map(d -> d[:game_id], v) |> unique
	
	tot_games = g_ids |> length

	# totals by outcome
	won = 0
	draw = 0
	lost = 0
	
	turns = Int[]
	not_completed = String[]

	#= possible game sub-outcomes:
		mk_limit_draw -> draw
		mk_limit_score -> won/lost
		score -> won/lost
		resign -> won/lost
	=#

	g_ids_end = String[]
	for id in g_ids

		# extract info
		g_id_outcomes = findfirst( 	d -> (haskey(d[:last_msg], :game_id)
									&& d[:last_msg][:game_id] == id 
									&& haskey(d[:last_msg], :game_status)
									&& d[:last_msg][:game_status] == "completed"), test_dump[:outcomes])

		if !isnothing(g_id_outcomes)
			push!(g_ids_end, id)
			
			outcome = test_dump[:outcomes][g_id_outcomes][:last_msg][:outcome]
			won_by = test_dump[:outcomes][g_id_outcomes][:last_msg][:won_by]
			play_as = test_dump[:outcomes][g_id_outcomes][:player_id]
			no_turns = test_dump[:outcomes][g_id_outcomes][:no_turns]

			push!(turns, no_turns)
	
			# count won/lost/draws
			(won_by == play_as) && (won += 1)
			(won_by == other_player(play_as)) && (lost += 1)
			(contains(outcome, "draw")) && (draw += 1)
			
		else
			push!(not_completed, id)
		end
	end

	# report
	end_games = g_ids_end |> length
	@info "$(p_w_game |> length)/$num_p players with an initialized game"
	@info "$(p_w_game_completed |> length)/$(p_w_game |> length) players, completed vs initialized game"
	@info "$end_games games played: $won won, $draw draw, $lost lost"
	@info "turns: min $(minimum(turns, init=Inf)), mean $(round(mean(turns))), max $(maximum(turns, init=-1)) "

	# errors & games with errors
	for id in not_completed
		@warn "Game $id - did not complete"
	end

	
	no_err = test_dump[:errors] |> length
	@error "$no_err errors"

end

# ╔═╡ b10d5922-ecf0-4c4f-a8fc-7da9c57eef69
analyse_logs()

# ╔═╡ bff27851-df78-4aff-b350-ebd5ff08737d
function dict_keys_to_sym(input::Dict)
# swaps dict keys from String to Symbol, RECURSIVELY
# JSON3.read can take a type specification but it won't turn keys into symbols beyond the first layer of depth, unless a more complex type specification is provided
	
	_new = Dict{Union{Symbol, Int}, Any}()

	for (k,v) in input

		# is key a string or can be parsed as Int?
		_nkey = tryparse(Int, String(k))
		if isnothing(_nkey)
			_nkey = isa(k, String) ? Symbol(k) : k
		end

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


# ╔═╡ 86e15cd0-0f49-412d-b09f-27f51cff6c6c
function incoming_msg_dispatcher(p)
# expected to be spawn as a task by calling fn
# takes in raw messages, parses them, and dispatches them to relevant fn

	while true
		try 
			_msg = take!(p.receive_channel)
				
			isa(_msg, StopToken) && break 
		
			JSON3.read(_msg, Dict) |> dict_keys_to_sym |> m -> server_msg_handler(p, m)
		catch e 
			@error "ERROR - player #$(p.id) - incoming msg dispatcher", e
		end
	end
	
	@info "LOG - player #$(p.id) - dispatch task: stopped"
	
end

# ╔═╡ ca85f64a-1a2b-40cb-9216-a22b7bc8fcba
new_empty_board() = fill("", 19, 11)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
JSON3 = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"

[compat]
HTTP = "~1.10.15"
JSON3 = "~1.14.1"
PlutoUI = "~0.7.60"
StatsBase = "~0.34.4"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.1"
manifest_format = "2.0"
project_hash = "cee8edfac3d3de4e032f6591f87167cc70764eab"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

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

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

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

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "d36f682e590a83d63d1c7dbd287573764682d12a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.11"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "PrecompileTools", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "c67b33b085f6e2faf8bf79a61962e7339a81129c"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.15"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

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

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "PrecompileTools", "StructTypes", "UUIDs"]
git-tree-sha1 = "1d322381ef7b087548321d3f878cb4c9bd8f8f9b"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.14.1"

    [deps.JSON3.extensions]
    JSON3ArrowExt = ["ArrowTypes"]

    [deps.JSON3.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

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

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

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

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eba4810d5e6a01f612b948c9fa94f905b49087b0"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.60"

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

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

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

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Tricks]]
git-tree-sha1 = "7822b97e99a1672bfb1b49b668a6d46d58d8cbcb"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.9"

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

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╠═9aa41b22-c5fe-11ef-0462-afad4496a201
# ╠═0e8cd2f5-8bee-4a9f-8710-b9d202e2a387
# ╠═091f21e6-a71c-420c-92ea-4582a8073970
# ╠═60d0b02b-c8af-4494-afc6-2c46deedfae2
# ╠═42734e5f-9c7d-46d3-9482-54911bf4e12d
# ╠═527622e1-fcf4-4ffc-8de5-c4006ede05ce
# ╠═45b9cdc8-28c2-4a49-855e-733314a9f7a6
# ╠═4b5bb371-0575-452b-8fe3-4204245c6b85
# ╟─a92a4b60-9c66-4a23-a249-37437677ca2e
# ╠═44db8669-985a-46f8-8d52-1f1a4053f25a
# ╟─ae3a9096-f868-4649-ae63-efde9cbef423
# ╠═d7cc05ac-e4c6-4bb8-9977-0b5d290b4253
# ╟─f856ad31-1393-4fb8-a0f8-32f2975cf793
# ╠═f38f4e3e-f9dc-4d8c-9afc-0309a3ccc362
# ╟─8e1ac4e0-dbba-4a6e-b38a-bfb3f349d285
# ╟─6799bbd5-2ab3-47af-ad17-e781b2b9c4d5
# ╟─76a92456-f985-4b1e-9821-20b54fe1d073
# ╟─4c7739b2-cf0a-4350-a049-f87875aa793e
# ╠═379f96f4-3f11-40b2-98ed-0c11a489c3fd
# ╟─999d80ad-8800-4906-bed7-d8eeec15d53e
# ╟─c191aace-4ee0-4ee9-a45d-cdb226413a76
# ╟─3e2b416c-1e41-4d4b-911c-ccb9413b4823
# ╠═39daeffb-2da6-484e-8ac2-90f701832898
# ╠═6888cbee-f76e-4d00-ab0b-190962f6ca55
# ╠═4b68abff-91b3-4810-b5e3-bb615417cbac
# ╠═99d14a39-08b5-43bb-b42c-bc729990d229
# ╟─6916407b-62f5-4093-98a7-ebaa18c71014
# ╟─86e15cd0-0f49-412d-b09f-27f51cff6c6c
# ╠═3f8aa63d-5a6b-4d82-bd72-889472be3f92
# ╠═d38a0908-a55c-4183-927d-894efe6e9ffb
# ╟─ef27a573-669d-499b-80f4-f076222373b3
# ╟─a1514598-6c4e-42fa-b9b8-2f7ef388f356
# ╟─04da4765-05d5-44e3-a724-3d98d808a483
# ╟─6e38243a-9127-4983-ad52-8d69f4ae12e2
# ╠═b10d5922-ecf0-4c4f-a8fc-7da9c57eef69
# ╠═db003af9-654c-4a3a-8797-8f6ff8e7d8b5
# ╟─8f29f032-1c5b-4578-ae7f-22f5111b19b7
# ╟─1df492d5-f456-4242-9d40-35a50492b6bd
# ╠═4de23652-f375-4362-9c68-a3460d6940e1
# ╠═2a910de1-8664-4b6e-b992-c27cb613fc24
# ╠═ed6d8a10-c80d-4f3b-8ff3-0c6cb2880811
# ╠═661123d7-b76e-4fdf-ade7-5779808b968d
# ╠═3609fefa-1e57-4645-9430-e80ff6ff64ca
# ╠═37158d4d-de39-4cbc-961c-aefb17c102d6
# ╟─212774ca-5ac1-4054-baab-18c9e759b431
# ╟─ad791a85-f38f-4784-921b-2ac066b1ac60
# ╟─eeafa3f7-f5f0-475e-9542-33fa1b1da407
# ╟─bff27851-df78-4aff-b350-ebd5ff08737d
# ╟─ca85f64a-1a2b-40cb-9216-a22b7bc8fcba
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
