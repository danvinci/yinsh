//////////////////////////////
//////////// CORE LOGIC


//////////// IMPORTS
import { init_ws, server_ws_send } from './server.js'
import { CODE_new_game_human, CODE_new_game_server, CODE_join_game, CODE_advance_game, CODE_resign_game } from './server.js'

import { init_global_obj_params, init_empty_game_objects, init_game_objs, get_game_id, get_player_id } from './data.js'
import { bind_adapt_canvas, reorder_rings, update_current_move, add_marker, update_legal_cues, getIndex_last_ring, updateLoc_last_ring, flip_markers, remove_markers } from './data.js'
import { swap_data_next_turn, update_objects_next_turn, turn_start, turn_end, get_current_turn_no, update_ring_highlights, get_coord_free_slot} from './data.js' 
import { activate_task, get_scoring_options, update_mk_halos, complete_task, reset_scoring_tasks, remove_ring_scoring, increase_player_score, increase_opponent_score, init_scoring_slots} from './data.js' 
import { get_preMove_scoring_pick, set_preMove_scoring_pick } from './data.js'

import { refresh_canvas_state } from './drawing.js'
import { init_interaction, enableInteraction, disableInteraction } from './interaction.js'
import { ringDrop_playS, markersRemoved_player_playS, markersRemoved_oppon_playS, endGame_win_playS, endGame_lose_playS } from './sound.js'

//////////// GLOBAL DEFINITIONS

    // redefining console log function for production
    // console.log = function() {};

    // inits global event target for core logic
    globalThis.core_et = new EventTarget(); // <- this semicolon is very important

    // moves
    core_et.addEventListener('ring_picked', ringPicked_handler, false);
    core_et.addEventListener('ring_moved', ringMoved_handler, false);
    core_et.addEventListener('ring_drop', ringDrop_handler, false);
    core_et.addEventListener('marker_moved', markerMoved_handler, false);
   
    // server comms
    core_et.addEventListener('srv_next_action', server_actions_handler, false);
    
    // mk scoring
    core_et.addEventListener('mk_score_handling_on', mk_scoring_options_handler, false);
    core_et.addEventListener('mk_sel_picked', mk_scoring_options_handler, false);
    core_et.addEventListener('mk_sel_hover_ON', mk_sel_hover_handler, false);
    core_et.addEventListener('mk_sel_hover_OFF', mk_sel_hover_handler, false);
    
    // ring scoring
    core_et.addEventListener('ring_picked_scoring', ring_scoring_handler, false);
    core_et.addEventListener('ring_sel_hover_ON', ring_sel_hover_handler, false);
    core_et.addEventListener('ring_sel_hover_OFF', ring_sel_hover_handler, false);

    // action codes
    const CODE_action_play = 'play'
    const CODE_action_wait = 'wait'
    const CODE_action_end_game = 'end_game'

    // window resizing -> canvas and object adjustments
    window.addEventListener("resize", window_resize_handler);

    // game termination by user (via UI)
    core_et.addEventListener('game_exited', game_exit_handler, false);

    // handler for tests triggered from the UI
    core_et.addEventListener('test_triggered', text_exec_from_ui_handler, false);


//////////// FUNCTIONS FOR INITIALIZING GAMES (NEW or JOIN)

// paint empty game board on canvas (called before any game is started)
export function draw_empty_game_board() {

    // inits global object (globalThis.yinsh) + constants used throughout the game
    init_global_obj_params();

    // initialize empty game objects
    init_empty_game_objects();

    // bind and make canvas size match its parent -> redraw everything
    window_resize_handler();


    disableInteraction();  // just in case
}

// window resizing -> impacts canvas, board, and objects (via drawing constants)
function window_resize_handler() {

    // NOTE: resize triggers regen/redraw, which changes the order of rings in the array, and a mess can happen if a move is in progress

    // bind and make canvas size match its parent
    bind_adapt_canvas();

    // regenerate objects using new S/H constants
    // note -> temp issue with marker halos (need to be re-generated correctly or wiped / will regenerate on 1st hover interaction) + grave issue when handling rings when resizing (as order is changed while moving ring is expected to be on top)
    init_game_objs();

    // draw what you have
    refresh_canvas_state();

};



// retrieve data from server (as originator or joiner) and init new game
export async function init_game_fromServer(originator = false, joiner = false, game_code = '', ai_game = false){

    // input could be changed to a more general purpose object, also to save/send game setup settings
    //_setup = {originator: false, joiner: false, game_code: undefined, ai_game: false}

    console.log(' -- Requesting new game --');
    
    // wipe clean dialog box anytime a new game is requested
    ui_et.dispatchEvent(new CustomEvent('reset_dialog'));

    const request_start_time = Date.now()

    try{

        // inits global object (globalThis.yinsh) + constants used throughout the game
        init_global_obj_params();

        // initialize empty game objects
        init_empty_game_objects();

        // initializes websocket and connects to game server
        await init_ws();
    
        if (joiner) {
            await server_ws_send(CODE_join_game, {game_id: game_code}); // asks to join existing game by ID
            
        } else if (originator) {
            await server_ws_send(CODE_new_game_human); // requests new game vs a friend

        } else if (ai_game) {
            await server_ws_send(CODE_new_game_server); // requests new game vs server/AI
        };
        
        // Bind canvas
        bind_adapt_canvas();
        
            // maps data from server to game objects
            // sets up drop zones and rings
            init_game_objs();
        
            // draw everything
            refresh_canvas_state();

            // initialize event listeners for canvas interaction
            init_interaction();

        // log local game ready
        console.log(`LOG - Game setup time: ${Date.now() - request_start_time}ms`);

        // log game code (later should be in the UI)
        console.log(`USER - Your GAME CODE is: ${yinsh.server_data.game_id}`);

        // inform the user which color they are
        const _player_id_string = get_player_id() == 'B' ? 'BLACK' : 'WHITE and move first';
        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `You'll play as ${_player_id_string}` }));

        // display code in the text prompt depending on player
        if (originator) {
            ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `Share this code to play: ${yinsh.server_data.game_id}` }));
        };

        // ask server what to do -> it will emit event on response
        await server_ws_send(CODE_advance_game, { game_id: get_game_id(), player_id: get_player_id(), scenario_pick: false });

    } catch (err){

        // log error
        console.log(`LOG - Game setup ERROR. ${Date.now() - request_start_time}ms`);

        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `Whoopsie, error while setting up the game` }));


        console.log(err);
        throw err;

    };
};




//////////// EVENT HANDLERS FOR TURNS
async function server_actions_handler (event) {

    const _next_action = event.detail.next_action_code;

    if (_next_action == CODE_action_play) {

        console.log(`LOG - ${CODE_action_play} msg from server`);

        // replay move by opponent (if we have delta data)
        await replay_opponent_move();

        // prepare data, objects, and canvas for next turn
        prep_next_turn(event.detail.turn_no);

        // -> start player's turn
        turn_start(); 

        // handle scoring by opponent if necessary - multiple rows too, FUUUCK :( 
        // TODO

        // from here on, it should go to the client turn manager
        enableInteraction();
        console.log(`USER - It's your turn - # ${get_current_turn_no()}`); // -> this should go to the UI

        // display code in the text prompt
        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `It's your turn` }));

        // hide game setup controls in the first turns in which the player moves (can be either 1 or 3)
        if (get_current_turn_no() <= 3) {
            ui_et.dispatchEvent(new CustomEvent('game_status_update', { detail: `game_in_progress` }));
            //console.log("LOG - Hiding game controls on first playable turns");
        };


    } else if (_next_action == CODE_action_wait) {

        console.log(`LOG - ${CODE_action_wait} msg from server`);

        disableInteraction(); // a bit redundant, is disabled by default
        console.log(`USER - Wait for your opponent.`); 

        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `Wait for your opponent` }));


    } else if (_next_action == CODE_action_end_game) { // handling case of winning/losing game

        disableInteraction(); 

        // replay move by opponent (if we have delta data)
        await replay_opponent_move();
        refresh_canvas_state(); 

        const winning_player = event.detail.won_by;
        const win_reason = event.detail.won_why;
        const _player_id = get_player_id();

            // local player wins 
            if (winning_player == _player_id){

                // play win sound
                endGame_win_playS();

                if (win_reason == 'resign') { // winning as the other player resigns
                    ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `Your opponent resigned. You win! :)` }));
                } else { // winning by score
                    ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `You win! :)` }));
                };

                // trigger winning animation 
                await win_animation();

            // opponent wins
            } else {

                // lose sound
                endGame_lose_playS();

                ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `You lose! :(` }));
            };

        // reset UI
        ui_et.dispatchEvent(new CustomEvent('game_status_update', { detail: `game_exited` }));
        
        console.log("LOG - GAME COMPLETED");

    };
};


//////////// UTILS

// this entity is used to create instances of tasks/interactions the user is expected to complete, 
// like picking a row of markers or scoring ring - on resolution, they return information that can be given by who triggers promise resolution from the outside
// this is used for passing along ID information, that is then shared w/ the server
class Task {
    constructor(name, data = {}) {
        this.name = name;
        this.data = data;
        this.promise = new Promise((resolve, reject) => {
            this.task_success = (success_msg) => resolve(success_msg) // this msg is passed externally and returned as value by the promise
            this.task_failure = () => reject(new Error(`${name} - Task failure`))
        })
    }
};

async function replay_opponent_move(){

    // do something only if we have delta data
    if (typeof yinsh.delta_array !== 'undefined') {

        console.log(`USER - Replaying opponent's moves`);
        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `Your opponent is moving` }));

        const replay_start_time = Date.now();

        console.log(`LOG - Delta: `, yinsh.delta_array);

        // iterate over all deltas in the array, removing them as processed
        for(const delta of yinsh.delta_array) {

            // add opponent's marker
                const _marker_add_wait = 800;
                await sleep(_marker_add_wait);
                const _added_mk_index = delta.added_marker.cli_index;
                add_marker(_added_mk_index, true); // -> as opponent
                refresh_canvas_state();

            // move and drop ring
                const _ring_move_wait = 800;
                await sleep(_ring_move_wait);
                await synthetic_ring_move_drop(delta.moved_ring);
                ringDrop_playS(); 
            
            // flipped markers 
                let _flip_wait = 0;
                if (delta.flip_flag == true) {

                    _flip_wait = 150;
                    await sleep(_flip_wait);
                    flip_markers(delta.markers_toFlip);
                    refresh_canvas_state();
                };
                
            // opponent's scoring
                let _score_mk_wait = 0;
                let _score_ring_wait = 0;
                if (delta.score_handled){
                    
                    // markers
                    _score_mk_wait = 600;
                    await sleep(_score_mk_wait);
                    
                    update_mk_halos(delta.markers_toRemove, true); // highlight markers
                    refresh_canvas_state();
                    
                    await sleep(_score_mk_wait); // wait to let user see visual changes

                    remove_markers(delta.markers_toRemove); // remove markers
                    update_mk_halos(); // turn off markers highlight
                    refresh_canvas_state(); // materialize changes on canvas

                    markersRemoved_oppon_playS(); // play sound

                    //// RING SCORING

                    _score_ring_wait = 650;
                    await sleep(_score_ring_wait);

                    // move scoring ring on top (need for animation)
                    const _ring_index_in_array = yinsh.objs.rings.findIndex(r => r.loc.index == delta.scoring_ring);
                    reorder_rings(_ring_index_in_array);

                    // grab start (x,y) coordinates   
                    const _start = yinsh.objs.drop_zones.find(d => d.loc.index == delta.scoring_ring);
                    const _start_xy = {x:_start.loc.x, y:_start.loc.y};

                    // grab end coordinates -> these will be of the scoring slots for the opponent (hence input is false)
                    const _slot_coord = get_coord_free_slot(false);
                    const _end_xy = {x:_slot_coord.x, y:_slot_coord.y};    

                    // animate ring move via synthetic mouse event
                    await syn_object_move(_start_xy, _end_xy, 45, 15);
                    
                    // increases player's score by one and mark scoring slot as filled
                    const new_opponent_score = increase_opponent_score();
                    console.log(`LOG - New opponent score: ${new_opponent_score}`);

                    // remove ring from rings array 
                    remove_ring_scoring(delta.scoring_ring); // remove ring (scoring ring id)

                    // refresh canvas (ring is drawn in scoring slot now)
                    refresh_canvas_state();

                    ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `Your opponent scored a point!` }));

                };
                
            // total sleep time
                const _tot_sleep_time = array_sum([_marker_add_wait, _ring_move_wait, _flip_wait, _score_mk_wait, _score_mk_wait, _score_ring_wait])
                const _tot_time = Date.now() - replay_start_time;
                const _net_time = _tot_time - _tot_sleep_time

            // log replay done
                console.log(`LOG - Move replay time - Total: ${_tot_time}ms - Net: ${_net_time}ms`);

        };

        // notice if array is empty
        if (yinsh.delta_array.length == 0) {
            console.log(`LOG - No delta to replay`);
        };

        // wipe clean delta data once used
        // avoids issues when replaying_opponent_move in winning scenarios: serverJS only saves new data if it has delta, so on winning move it will mess up trying to replay past delta
        delete yinsh.delta_array;
        
    };


};

// update current/next data -> reinit/redraw everything (on-canvas nothing should change)
function prep_next_turn(_turn_no){

    // do something only for turns no 1+ (no delta data at turn 1)
    if (_turn_no > 1) {

        swap_data_next_turn(); // -> takes data from next
        update_objects_next_turn(); // -> update objcts
        refresh_canvas_state(); 

    };
};

 

// useful for pauses during move replay
const sleep = ms => new Promise(r => setTimeout(r, ms));

// used for summing ms paused
function array_sum(input_array) {

    let _running_sum = 0

    for (const v of input_array) {

        _running_sum = _running_sum + v
    };

    return _running_sum

};

// move ring between start and end state
async function synthetic_ring_move_drop(moved_ring_details) {

    // start/end indexes for moved ring
    const _mr_start_index = moved_ring_details.cli_index_start;
    const _mr_end_index = moved_ring_details.cli_index_end;
    const _mr_player = moved_ring_details.player_id;

    console.log(`LOG - Ring ${_mr_player} picked from index ${_mr_start_index}`);

    // move ring to end of array (top for drawing)
    const _mr_index_in_array = yinsh.objs.rings.findIndex(r => r.loc.index == _mr_start_index);
    reorder_rings(_mr_index_in_array);

    // grab start/end (x,y) coordinates
    const _drop_start = yinsh.objs.drop_zones.find(d => d.loc.index == _mr_start_index);
    const _drop_end = yinsh.objs.drop_zones.find(d => d.loc.index == _mr_end_index);

        const start = {x:_drop_start.loc.x, y:_drop_start.loc.y};
        const end = {x:_drop_end.loc.x, y:_drop_end.loc.y};

    // animate move via synthetic mouse event
    await syn_object_move(start, end, 30, 15);

    // update dropping ring loc information 
    updateLoc_last_ring(_drop_end.loc);

    // retrieve ring and its index details
    const dropping_ring = yinsh.objs.rings.at(-1); // last ring
    const dropping_ring_loc_index = dropping_ring.loc.index;

    console.log(`LOG - Ring ${dropping_ring.player} moved to index ${dropping_ring_loc_index}`);

};



//////////// EVENT HANDLERS FOR LOCAL GAME MECHANICS

// listens to ring picks and updates game state
function ringPicked_handler (event) {

    // detail contains index in rings array of picked ring
    const index_picked_ring_in_array = event.detail;
    
    // retrieve ring and its loc details
    const picked_ring = yinsh.objs.rings[index_picked_ring_in_array];
    const picked_ring_loc = structuredClone(picked_ring.loc)
    const picked_ring_loc_index = picked_ring_loc.index;

        // logging
        console.log(`LOG - Ring ${picked_ring.player} picked from index ${picked_ring_loc_index}`);

    // remove the element and put it back at the end of the array, so it's always drawn last => appears on top of all other rings, useful when moving it
    // we could also move ring to dedicated structure that is drawn last and then put back in, but roughly same copying work
    reorder_rings(index_picked_ring_in_array);

    // write start of the currently active move to a global variable
    update_current_move(true, picked_ring_loc_index);

    // place marker in same location (it's assumed this player)
    add_marker(picked_ring_loc_index);

    // initializes array of legal drop ids + visual cues for starting index
    // will read from current move to see which moves to consider
    update_legal_cues();

    // draw changes
    refresh_canvas_state();

};


// listens to a ring being moved -> updates ring location & triggers re-draw
function ringMoved_handler (event) {

    // event.detail.coord -> mousePos as {x, y}

    // if index of ring in rings array is given, use it (multi-ring animation)
    if ('id_in_array' in event.detail) {
        
        // updates x and y ring location
        yinsh.objs.rings[event.detail.id_in_array].loc.x = event.detail.coord.x;
        yinsh.objs.rings[event.detail.id_in_array].loc.y = event.detail.coord.y;
    
    } else { // pick last ring 

        // the last ring in the array is the one being moved (drawn last / on top)
        const id_picked_ring = getIndex_last_ring();

        // updates x and y ring location
        yinsh.objs.rings[id_picked_ring].loc.x = event.detail.coord.x;
        yinsh.objs.rings[id_picked_ring].loc.y = event.detail.coord.y;

    };
    
    // redraw everything
    refresh_canvas_state();

};

function markerMoved_handler (event) {

    // event.detail.coord -> mousePos as {x, y}

    // if index of marker in array is given, use it (multi-markers animation)
    if ('id_in_array' in event.detail) {
        
        // updates x and y ring location
        yinsh.objs.markers[event.detail.id_in_array].loc.x = event.detail.coord.x;
        yinsh.objs.markers[event.detail.id_in_array].loc.y = event.detail.coord.y;
    
    } else { // pick last marker 

        // the last marker in the array is the one being moved (drawn last / on top)
        const id_last_marker = yinsh.objs.markers.length-1;

        // updates x and y ring location
        yinsh.objs.markers[id_last_marker].loc.x = event.detail.coord.x;
        yinsh.objs.markers[id_last_marker].loc.y = event.detail.coord.y;

    };
    
    // redraw everything
    refresh_canvas_state();

};



// listens to ring snaps/drops -> flips markers -> triggers score handling -> refresh states
async function ringDrop_handler (event) {

    // retrieves loc object of snapping drop zone
    const snap_drop_loc = event.detail;

    // retrieves ids of legal drops for the ring that was picked up
    const _current_legal_drops = yinsh.objs.current_move.legal_drops;
    const player_id = get_player_id();

    // save move starting index
    const start_move_index = yinsh.objs.current_move.start_index;

    // retrieve ring and its index details (last)
    const dropping_ring = yinsh.objs.rings.at(-1);
    
    // retrieve index of drop location
    const drop_loc_index = snap_drop_loc.index

    // check if drop coordinates belong to possible moves or dropped in-place
    if (_current_legal_drops.includes(drop_loc_index) || drop_loc_index == start_move_index){

        // drops ring -> update ring loc information 
        updateLoc_last_ring(snap_drop_loc);

        // resets data for current move (move is complete/off)
        update_current_move(); // -> important to close the move to prevent side effects
        
        // updates legal cues (all will be turned off as move is no longer in progress)
        update_legal_cues();

        // re-draw everything and play sound
        refresh_canvas_state(); 
        ringDrop_playS(); 

        // logging
        console.log(`LOG - Ring ${dropping_ring.player} moved to index ${drop_loc_index}`);

        // CASE: same location drop, nothing to flip, remove added marker
        if (drop_loc_index == start_move_index){

            // remove marker (only touches marker if in location, doesn't touch ring data)
            remove_markers([drop_loc_index]);
            refresh_canvas_state(); 

            // log
            console.log(`LOG - Ring dropped in-place. Turn is still on.`)

        } else {

            // CASE: ring moved to a legal destination -> look at scenarioTree to see what happens
            // retrieve scenario as scenarioTree.index_start_move.index_end_move
            const move_scenario = yinsh.server_data.scenarioTree[start_move_index][drop_loc_index];
            console.log(move_scenario);

            // CASE: some markers must be flipped
            if (move_scenario.flip_flag == true){
                // flip and re-draw
                await sleep(150);
                flip_markers(move_scenario.markers_toFlip);
                refresh_canvas_state(); 
            };

            // CASE: scoring was made -> score handling is triggered
                // values to send back to server
                let scoring_mk_sel_picked = -1;
                let scoring_ring_picked = -1;
                let scoring_mk_locs_removed = [];

            if (move_scenario.score_flag == true){

                // check if the scoring is for the current player or not
                const _all_scores = structuredClone(move_scenario.scores_toHandle);
                const _player_scores = _all_scores.filter(s => s.player == player_id);

                // handle scoring for current player
                if (_player_scores.length > 0) { // fix as server will return only player's score avails 

                    console.log("USER - Score!");

                    // create task for markers scoring (options only for current player)
                    const mk_scoring = new Task('mk_scoring_task', _player_scores);
                    activate_task(mk_scoring); // save scoring options and activate task

                    // create task for ring scoring
                    const ring_scoring = new Task('ring_scoring_task');
                    activate_task(ring_scoring); 

                    // turn will be ended by score handling function 
                    core_et.dispatchEvent(new CustomEvent('mk_score_handling_on'));
                    [scoring_mk_sel_picked, scoring_mk_locs_removed]= await mk_scoring.promise // wait for mk to be picked -> return value of loc_id

                    // highlight rings - need to pass player own rings ids to the function
                    await sleep(350);
                    const _player_rings_ids = yinsh.objs.rings.filter((ring) => (ring.player == player_id)).map(ring => ring.loc.index);;
                    core_et.dispatchEvent(new CustomEvent('ring_sel_hover_OFF', {detail: {player_rings: _player_rings_ids}}));
                    
                    // wait for ring to be picked 
                    scoring_ring_picked = await ring_scoring.promise // wait for ring to be picked -> return value of loc_id
                    
                    // wipe tasks data from global refs
                    reset_scoring_tasks();

                } else {

                    // note: re-use this later, display during opp scoring replay
                    console.log("USER - Oh no, you scored for your opponent!");

                    ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `Oh no, you scored for your opponent!` }));


                };  
            };

            const _played_turn_no = get_current_turn_no();
            console.log(`LOG - Completed player turn no: ${_played_turn_no}`);

            // turn completed -> wrap up info to send back on actions taken by player
            const turn_recap = {    score_action_preMove : get_preMove_scoring_pick(), // this happened at the beginning of the turn, in case, without ring_drop involved
                                    move_action: { start: start_move_index, end: drop_loc_index },
                                    score_action: { mk_sel: scoring_mk_sel_picked, mk_locs: scoring_mk_locs_removed, ring_score: scoring_ring_picked }, // defaults to -1
                                    completed_turn_no: _played_turn_no
                                }; 

            // turn completed -> notify server with info on scenario
            await end_turn_wait_opponent(turn_recap);
        
        };

    // CASE: invalid location for drop attempt
    } else { 

        console.log("USER - Invalid drop location");
        // NOTE: we could play specific sound 'err'

        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `You can't drop the ring in that location` }));


    };
};


// can be called from different points to terminate turn
async function end_turn_wait_opponent(turn_recap) {

    turn_end(); // local turn ends

    disableInteraction();

    let msg_payload = {}

        // add fields to the msg payload
        msg_payload.scenario_pick = turn_recap;
        msg_payload.game_id = get_game_id();
        msg_payload.player_id = get_player_id();

    // -> notify server about completed move (next turn)
    await server_ws_send(CODE_advance_game, msg_payload); 

};

       

// listens to scoring events -> begins/ends score handling 
function mk_scoring_options_handler(event){

    // CASE: score handling started
    if (event.type === 'mk_score_handling_on') {

        console.log("USER - Pick a marker to indicate the row!");

        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `You scored! Pick a row of markers` }));

        // retrieve scoring options
        const scoring_options = get_scoring_options();

        // retrieve ids of selectable markers
        const mk_sel = scoring_options.map(option => option.mk_sel);

        // paint selectable markers in cold color
        update_mk_halos(mk_sel, false);
        refresh_canvas_state();

    // CASE: marker was picked -> score handling is completed
    } else if (event.type === "mk_sel_picked") {

        console.log("LOG - Scoring option selected");

        // retrieve index of marker being clicked on
        const mk_sel_picked_id = event.detail;

        // get markers for selected row
        const scoring_options = get_scoring_options();
        const _mk_row_to_remove = (scoring_options.find(option => option.mk_sel == mk_sel_picked_id)).mk_locs;

        // remove markers for selected row
        remove_markers(_mk_row_to_remove);

        // turn halos off and refresh canvas
        update_mk_halos();
        refresh_canvas_state();

        // play sound
        markersRemoved_player_playS();

        // complete score handling task (success)
        const success_msg = [mk_sel_picked_id, _mk_row_to_remove]; // value to be returned by completed task (mk_sel marker + mk_locs removed)
        complete_task('mk_scoring_task', success_msg);

        console.log("USER - Pick a ring to be removed from the board!");

        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `Pick a ring to remove` }));


    };
};

// listens to hovering event over sel_markers in scoring rows -> handle highlighting
function mk_sel_hover_handler (event) {

    // CASE: mk sel hovered on -> need to highlight markers of a specific row
    if (event.type === 'mk_sel_hover_ON') {

        // retrieve index of marker
        const hovered_marker_id = event.detail;

        // retrieve markers to highlight for row
        const scoring_options = get_scoring_options();
        const _mk_row_to_highlight = (scoring_options.find(option => option.mk_sel == hovered_marker_id)).mk_locs;

        // prepare halo objects and refresh canvas
        update_mk_halos(_mk_row_to_highlight, true);
        refresh_canvas_state();


    // CASE: mk sel hovered off -> need to restore baseline highlighting
    } else if (event.type === 'mk_sel_hover_OFF') {

        // retrieve scoring options
        const scoring_options = get_scoring_options();

        // retrieve ids of selectable markers
        const mk_sel = scoring_options.map(option => option.mk_sel);

        // paint the selectable markers in cold color
        update_mk_halos(mk_sel, false);
        refresh_canvas_state();

    };

};

// listens for scoring ring to be picked, animates its move to the 1st scoring slot and then removes it from the obj array
async function ring_scoring_handler (event) {

    disableInteraction();

    // retrieve index of ring (meant as location)
    const picked_ring_id = event.detail;

    // move picked ring on top (need for animation)
    const _ring_index_in_array = yinsh.objs.rings.findIndex(r => r.loc.index == picked_ring_id);
    reorder_rings(_ring_index_in_array);

    // empty array of rings highlights
    update_ring_highlights(); 

    // grab start (x,y) coordinates     
    const _start = yinsh.objs.drop_zones.find(d => d.loc.index == picked_ring_id);
    const _start_xy = {x:_start.loc.x, y:_start.loc.y};

    // grab end coordinates -> these will be of the scoring slots
    const _slot_coord = get_coord_free_slot(true);
    const _end_xy = {x:_slot_coord.x, y:_slot_coord.y};    

    // animate ring move via synthetic mouse event
    await syn_object_move(_start_xy, _end_xy, 30, 15);
    
    // increases player's score by one and fill scoring slot
    const new_player_score = increase_player_score();
    console.log(`LOG - New player score: ${new_player_score}`);

    // refresh canvas (ring is drawn in scoring slot now)
    // scoring slots call draw_rings function with a ring_spec to draw a ring in their x,y coordinates
    refresh_canvas_state();

    // remove ring from rings array 
    remove_ring_scoring(picked_ring_id);
    refresh_canvas_state();

    // completes ring scoring task
    const success_msg = picked_ring_id; // value to be returned by completed task
    complete_task('ring_scoring_task', success_msg);

};

// listens to hovering event over rings when having to pick a ring for scoring -> handle highlighting
function ring_sel_hover_handler (event) {

    // CASE: ring sel hovered on -> get darker
    if (event.type === 'ring_sel_hover_ON') {

        // retrieve players' rings and index of hovered ring
        const player_rings_ids = event.detail.player_rings;
        const hovered_ring_id = event.detail.hovered_ring;

        // prepare ring cores objects and refresh canvas
        update_ring_highlights(player_rings_ids, hovered_ring_id);
        refresh_canvas_state();

    // CASE: ring sel hovered off -> need to establish/restore baseline highlighting of all rings
    } else if (event.type === 'ring_sel_hover_OFF') {

        // retrieve indexes of rings for current player
        const player_rings_ids = event.detail.player_rings;

        // prepare ring cores objects and refresh canvas
        update_ring_highlights(player_rings_ids);
        refresh_canvas_state();

    };
};

async function text_exec_from_ui_handler(){

    /* 
    //// TEST 1 - ring scoring (hover effect + animation)

        console.log('LOG - Test triggered - Ring scoring');
        
        enableInteraction();

        // mark ring selection as true
        yinsh.objs.current_mk_scoring.in_progress = false;
        yinsh.objs.current_ring_scoring.in_progress = true;

        // interaction JS should work its magic from now on
    */ 

    
    //// TEST 2 - testing win game animation
    
        /*

        console.log('LOG - Test triggered - Win game animation');

        const win_anim_start_time = Date.now();

        // init new game (just to have elements on the board)
        // await init_game_fromServer(true);
        
        disableInteraction();

        endGame_win_playS();

        await sleep(150);

        // loop over every object (rings + markers)
        // pick a different one every 50ms or so
        // accelerate it downwards beyond 900 of height


        // RINGS
        // as we'll pick rings from last in array to the end (easier), we keep track of the virtual array length
        let _rings_vir_len = yinsh.objs.rings.length;
        let _syn_RINGS_moves_prom_array = [];

        while (_rings_vir_len > 0) {

            // pick last ring in array, no need to re-order it
            const r_index_no = _rings_vir_len - 1 ; 
            const r_loc = structuredClone(yinsh.objs.rings[r_index_no].loc); 

            const _start = {x: r_loc.x, y:r_loc.y};
            const _end = {x: r_loc.x, y:r_loc.y + canvas.height};

            const syn_move_prom = syn_object_move(_start, _end, 30, 15, 'ring', r_index_no); // we trigger it but don't await for it to finish, we move onto other objects
            _syn_RINGS_moves_prom_array.push(syn_move_prom);
            await sleep(45);

            _rings_vir_len -= 1; // decrement virtual len 

        };

        // MARKERS
        let _markers_vir_len = yinsh.objs.markers.length;
        let _syn_MARKERS_moves_prom_array = [];

        while (_markers_vir_len > 0) {

            // pick last marker in array
            const mk_index_no = _markers_vir_len - 1 ; 
            const mk_loc = structuredClone(yinsh.objs.markers[mk_index_no].loc); 

            const _start = {x: mk_loc.x, y:mk_loc.y};
            const _end = {x: mk_loc.x, y:mk_loc.y + canvas.height};

            const syn_move_prom = syn_object_move(_start, _end, 30, 15, 'marker', mk_index_no); // we trigger it but don't await for it to finish, we move onto other objects
            _syn_MARKERS_moves_prom_array.push(syn_move_prom);
            await sleep(45);

            _markers_vir_len -= 1; // decrement virtual len 

        };

        // to prevent weird things happening due to a resize, wipe objects data when all moves are done
            // RINGS
            await Promise.all(_syn_RINGS_moves_prom_array);
            yinsh.objs.rings = [];
            yinsh.local_server_data_ref.rings = [];
        
            // MARKERS
            await Promise.all(_syn_MARKERS_moves_prom_array);
            yinsh.objs.markers = [];
            yinsh.local_server_data_ref.markers = [];

        // handle scoring slots - draw them more transparent over time and then delete them
            
            const _f_alpha_array = Array(25).fill().map((_, i) => (i)/25).reverse(); // 0.96 -> 0 values
            for (let i = 0; i < _f_alpha_array.length; i++) {
                await sleep(5);
                refresh_canvas_state(_f_alpha_array[i]);
            };
            yinsh.objs.scoring_slots = [];
            yinsh.objs.player_score = 0;
            yinsh.objs.opponent_score = 0;
            

        // BOARD -  fade out & zoom
        await sleep(200);
        let _scale = 1;
        let _line = 1;
        let _offset = {x:0, y:0};

        for (let i = 0; i < _f_alpha_array.length; i++) {
            
            await sleep(30);

            const _alpha = _f_alpha_array[i];
            // increase scale over time
            _line += 0.7;
            _scale += 0.1;
            
            // move start drawing point up left as we zoom in - note: these values are okayish only for desktop
            _offset.x += -canvas.width/33; 
            _offset.y += -canvas.height/25;

            refresh_canvas_state(_alpha, _scale, _line, _offset, true);

        };
        

        // BOARD - fade-in
        init_scoring_slots(); // regenerate empty scoring slots (scores set to zero)
        
        await sleep(400);
        
        _line = 1;
        _scale = 1;
        _offset.x = 0;
        _offset.y = 0;

        const _n_alpha_array = Array(25).fill().map((_, i) => (i)/25); // 0 -> 0.96 values
        for (let i = 0; i < _n_alpha_array.length; i++) {
            
            await sleep(25);
            const _alpha = _n_alpha_array[i];
            
            refresh_canvas_state(_alpha, _scale, _line, _offset, true);

        };
        refresh_canvas_state(); // calling refresh for last alpha step 0.96 -> 1

        // win animation complete
        console.log(`LOG - Test win animation time: ${Date.now() - win_anim_start_time}ms`);

        */
    
};

async function win_animation() {

    console.log('LOG - Win game animation started');

        const win_anim_start_time = Date.now();

        // init new game (just to have elements on the board)
        // await init_game_fromServer(true);
        
        disableInteraction();

        endGame_win_playS();

        await sleep(150);

        // loop over every object (rings + markers)
        // pick a different one every 50ms or so
        // accelerate it downwards beyond 900 of height


        // RINGS
        // as we'll pick rings from last in array to the end (easier), we keep track of the virtual array length
        let _rings_vir_len = yinsh.objs.rings.length;
        let _syn_RINGS_moves_prom_array = [];

        while (_rings_vir_len > 0) {

            // pick last ring in array, no need to re-order it
            const r_index_no = _rings_vir_len - 1 ; 
            const r_loc = structuredClone(yinsh.objs.rings[r_index_no].loc); 

            const _start = {x: r_loc.x, y:r_loc.y};
            const _end = {x: r_loc.x, y:r_loc.y + canvas.height};

            const syn_move_prom = syn_object_move(_start, _end, 30, 15, 'ring', r_index_no); // we trigger it but don't await for it to finish, we move onto other objects
            _syn_RINGS_moves_prom_array.push(syn_move_prom);
            await sleep(45);

            _rings_vir_len -= 1; // decrement virtual len 

        };

        // MARKERS
        let _markers_vir_len = yinsh.objs.markers.length;
        let _syn_MARKERS_moves_prom_array = [];

        while (_markers_vir_len > 0) {

            // pick last marker in array
            const mk_index_no = _markers_vir_len - 1 ; 
            const mk_loc = structuredClone(yinsh.objs.markers[mk_index_no].loc); 

            const _start = {x: mk_loc.x, y:mk_loc.y};
            const _end = {x: mk_loc.x, y:mk_loc.y + canvas.height};

            const syn_move_prom = syn_object_move(_start, _end, 30, 15, 'marker', mk_index_no); // we trigger it but don't await for it to finish, we move onto other objects
            _syn_MARKERS_moves_prom_array.push(syn_move_prom);
            await sleep(45);

            _markers_vir_len -= 1; // decrement virtual len 

        };

        // to prevent weird things happening due to a resize, wipe objects data when all moves are done
            // RINGS
            await Promise.all(_syn_RINGS_moves_prom_array);
            yinsh.objs.rings = [];
            yinsh.local_server_data_ref.rings = [];
        
            // MARKERS
            await Promise.all(_syn_MARKERS_moves_prom_array);
            yinsh.objs.markers = [];
            yinsh.local_server_data_ref.markers = [];

        // handle scoring slots - draw them more transparent over time and then delete them
            
            const _f_alpha_array = Array(25).fill().map((_, i) => (i)/25).reverse(); // 0.96 -> 0 values
            for (let i = 0; i < _f_alpha_array.length; i++) {
                await sleep(5);
                refresh_canvas_state(_f_alpha_array[i]);
            };
            yinsh.objs.scoring_slots = [];
            yinsh.objs.player_score = 0;
            yinsh.objs.opponent_score = 0;
            

        // BOARD -  fade out & zoom
        await sleep(150);
        let _scale = 1;
        let _line = 1;
        let _offset = {x:0, y:0};

        for (let i = 0; i < _f_alpha_array.length; i++) {
            
            await sleep(30);

            const _alpha = _f_alpha_array[i];
            _line += 0.7;
            _scale += 0.1; // increase scale over time
            
            // move start drawing point up left as we zoom in - note: these values are okayish only for desktop
            _offset.x += -canvas.width/33; 
            _offset.y += -canvas.height/25;

            refresh_canvas_state(_alpha, _scale, _line, _offset, true);

        };
        

        // BOARD - fade-in
        init_scoring_slots(); // regenerate empty scoring slots (scores set to zero)
        
        await sleep(400);
        
        _line = 1;
        _scale = 1;
        _offset.x = 0;
        _offset.y = 0;

        const _n_alpha_array = Array(25).fill().map((_, i) => (i)/25); // 0 -> 0.96 values
        for (let i = 0; i < _n_alpha_array.length; i++) {
            
            await sleep(25);
            const _alpha = _n_alpha_array[i];
            
            refresh_canvas_state(_alpha, _scale, _line, _offset, true);

        };
        refresh_canvas_state(); // calling refresh for last alpha step 0.96 -> 1

        // win animation complete
        console.log(`LOG - Win animation done in: ${Date.now() - win_anim_start_time}ms`);

};


/////////// EXITING GAME - prompted by user via resign action, mediated by server
export async function game_exit_handler(event){

    // disable any canvas interaction
    disableInteraction();

    // notify server (game is lost automatically) --> other user is informed by server
    // note: we're keeping scenario_pick here to avoid handling exceptions inside the server game_runner -> to be fixed
    const _resign_msg_payload = { game_id: get_game_id(), player_id: get_player_id(), scenario_pick: false }; 
    await server_ws_send(CODE_resign_game, _resign_msg_payload); // server will acknowledge

    // we receive formal 'you lost' response from server, handled by next_action_handler
    // we should handle if/when communication w/ server fails, (eg. websocket timeout) so we trigger the game ending anyway and UI can be reset

};


// HELPER FUNCTION
// animate last ring (ie. on top of canvas) to move between start and end points -> as the ring is moved, it triggers redraw of the canvas
// can also be used for moving markers - either last or a specific ID (multi-object animation, without array re-ordering)
async function syn_object_move(start, end, no_steps, sleep_ms, obj = 'ring', id_in_array = -1){

    let _progress = 0;

    for(let i=1; i <= no_steps; i++){ 

        // compute cumulative integral for sin
        // results in non-linear progress for having ease-in/out effect
        if (i == no_steps) { // force 100% as integral is very approximated
            _progress = 1;
        } else {
            _progress += (Math.sin(Math.PI*((i)/no_steps)) * Math.PI/no_steps )/2;
        };
    
        const _new_x = start.x + _progress*(end.x - start.x);
        const _new_y = start.y + _progress*(end.y - start.y);

        await sleep(sleep_ms);

        const synthetic_mouse_coord = {x:_new_x, y:_new_y};

        // we use OBJ parameter to detemine which event we want to dispatch (ring vs marker)

        if (obj == 'ring') {

            // for animating multiple rings, we need to avoid re-shuffling them in the array
            // with the last parameter, we pass directly the ring index in the array, so the handler doesn't reshuffle it
            if (id_in_array == -1) {
                core_et.dispatchEvent(new CustomEvent('ring_moved', { detail: {coord: synthetic_mouse_coord }}));
            } else {
                core_et.dispatchEvent(new CustomEvent('ring_moved', { detail: {coord: synthetic_mouse_coord, id_in_array: id_in_array }}));
            };

        } else if (obj == 'marker') {
            
            if (id_in_array == -1) {
                core_et.dispatchEvent(new CustomEvent('marker_moved', { detail: {coord: synthetic_mouse_coord }}));
            } else {
                core_et.dispatchEvent(new CustomEvent('marker_moved', { detail: {coord: synthetic_mouse_coord, id_in_array: id_in_array }}));
            };

        };

    };
};