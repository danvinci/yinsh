//////////////////////////////
//////////// CORE LOGIC


//////////// IMPORTS
import { init_ws, server_ws_genNewGame, server_ws_joinWithCode, server_ws_genNewGame_AI, server_ws_whatNow} from './server.js'
import { init_global_obj_params, init_empty_game_objects, init_new_game_data, save_next_server_response } from './data.js'
import { reorder_rings, update_game_state, update_current_move, add_marker, update_legal_cues, getIndex_last_ring, updateLoc_last_ring, flip_markers, remove_markers } from './data.js'
import { swap_data_next_turn, update_objects_next_turn, turn_start, turn_end} from './data.js' 
import { update_scoring_data, get_scoring_options, update_mk_halos, complete_score_handling_task} from './data.js' 
import { refresh_canvas_state } from './drawing.js'
import { init_interaction, enableInteraction, disableInteraction } from './interaction.js'
import { ringDrop_play_sound, markersRemoved_play_sound } from './audio.js'

//////////// GLOBAL DEFINITIONS

    // inits global event target for core logic
    globalThis.core_et = new EventTarget(); // <- this semicolon is very important

    // moves
    core_et.addEventListener('ring_picked', ringPicked_handler, false);
    core_et.addEventListener('ring_moved', ringMoved_handler, false);
    core_et.addEventListener('ring_drop', ringDrop_handler, false);
   
    // server comms
    core_et.addEventListener('srv_next_action', server_actions_handler, false);
    
    // scoring
    core_et.addEventListener('score_handling_on', scoring_options_handler, false);
    core_et.addEventListener('mk_sel_picked', scoring_options_handler, false);
    core_et.addEventListener('mk_sel_hover_ON', mk_sel_hover_handler, false);
    core_et.addEventListener('mk_sel_hover_OFF', mk_sel_hover_handler, false);
    


//////////// FUNCTIONS FOR INITIALIZING GAMES (NEW or JOIN)

// retrieve data from server (as originator or joiner) and init new game
export async function init_game_fromServer(originator = false, joiner = false, game_code = '', ai_game = false){

    // input could be changed to a more general purpose object, also to save/send game setup settings
    //_setup = {originator: false, joiner: false, game_code: undefined, ai_game: false}

    console.log(' -- Requesting new game --');
    const request_start_time = Date.now()

    try{

        // inits global object (globalThis.yinsh) + constants used throughout the game
        init_global_obj_params();

        // initialize empty game objects
        init_empty_game_objects();

        // initializes websocket and connects to game server
        await init_ws();
    
        if (joiner) {
            // asks to join existing game
            await server_ws_joinWithCode(game_code);
        } else if (originator) {
            // requests a new game and writes response (as originator)
            await server_ws_genNewGame();
        } else if (ai_game) {
            // requests a new game and writes response (as originator vs AI server)
            await server_ws_genNewGame_AI();
        };
        
        // maps data from server to game objects
        // sets up drop zones and rings
        init_new_game_data();

        // Bind canvas
        // IDs different than 'canvas' seem not to work :|
        globalThis.canvas = document.getElementById('canvas');
        globalThis.ctx = canvas.getContext('2d', { alpha: true });        
        
            // draw everything
            refresh_canvas_state();

            // initialize event listeners for canvas interaction
            init_interaction();

        // log local game ready
        console.log(`LOG - Game setup time: ${Date.now() - request_start_time}ms`);

        // log game code (later should be in the UI)
        console.log(`LOG - Your game code is: ${yinsh.server_data.game_id}`);

        // ask server what to do -> it will emit event on response
        await server_ws_whatNow();

    } catch (err){

        // log error
        console.log(`LOG - Game setup ERROR. ${Date.now() - request_start_time}ms`);
        console.log(err);
        throw err;

    };
};




//////////// EVENT HANDLERS FOR TURNS

async function server_actions_handler (event) {

    const _next_action = event.detail.next_action_code;

    if (_next_action == 'move') {

        // replay move by opponent (if we have delta data)
        await replay_opponent_move();

        // handle scoring by opponent if necessary (multiple rows too) :|
        // TODO

        // prepare data, objects, and canvas for next turn
        prep_next_turn(event.detail.turn_no);

        // -> start player's turn
        turn_start(); 

        // from here on, it should go to the client turn manager
        enableInteraction();
        console.log(`LOG - It's yout turn, make a move! - # ${event.detail.turn_no}`); // -> this should go to the UI

    } else if (_next_action == 'wait') {

        disableInteraction(); // a bit redundant, is disabled by default
        console.log(`LOG - Wait for your opponent.`); // -> this should bubble up to a UI component

    };

};


//////////// UTILS


class Task {
    constructor(task_data) {
        this.task_data = task_data;
        this.promise = new Promise((resolve, reject)=> {
            this.task_success = resolve
            this.task_fail = reject
        })
    }
};

async function replay_opponent_move(){

    // do something only if we have delta data
    // dispatch should be smarter
    if (typeof yinsh.delta !== "undefined") {

        console.log(`LOG - Replaying opponent's move`);
        const replay_start_time = Date.now();

        console.log(`LOG - Delta: `, yinsh.delta);

        // add opponent's marker
            const _marker_add_wait = 1000;
            await sleep(_marker_add_wait);
            const _added_mk_index = yinsh.delta.added_marker.cli_index;
            add_marker(_added_mk_index, true); // -> as opponent
            refresh_canvas_state();

        // move and drop ring
            const _ring_move_wait = 1000;
            await sleep(_ring_move_wait);
            await synthetic_ring_move_drop(yinsh.delta.moved_ring);
            ringDrop_play_sound(); 
        
        // flipped markers 
            let _flip_wait = 0;
            if (yinsh.delta.flip_flag == true) {

                _flip_wait = 100;
                await sleep(_flip_wait);
                flip_markers(yinsh.delta.markers_toFlip);
                refresh_canvas_state();
            };
            

        // removed markers (scoring)
        // removed ring (scoring)

        // total sleep time
        const _tot_sleep_time = array_sum([_marker_add_wait, _ring_move_wait, _flip_wait])
        const _tot_time = Date.now() - replay_start_time;
        const _net_time = _tot_time - _tot_sleep_time

        // log replay done
        console.log(`LOG - Move replay time - Total: ${_tot_time}ms - Net: ${_net_time}ms`);

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

    // clean up game state for starting position
    update_game_state(_mr_start_index, "");

    // move ring to end of array (top for drawing)
    const _mr_index_in_array = yinsh.objs.rings.findIndex(r => r.loc.index == _mr_start_index);
    reorder_rings(_mr_index_in_array);

    // grab start/end (x,y) coordinates
    const _drop_start = yinsh.objs.drop_zones.find(d => d.loc.index == _mr_start_index);
    const _drop_end = yinsh.objs.drop_zones.find(d => d.loc.index == _mr_end_index);

        const _x_start = _drop_start.loc.x;
        const _y_start = _drop_start.loc.y;

        const _x_end = _drop_end.loc.x;
        const _y_end = _drop_end.loc.y;

    // animate move via synthetic mouse event
    const _steps = 30; 
    let _progress = 0;

    for(let i=1; i <= _steps; i++){ 

        // compute cumulative integral for sin
        // results in non-linear progress for having ease-in/out effect
        if (i == _steps) { // force 100% as integral is very approximated
            _progress = 1;
        } else {
            _progress += (Math.sin(Math.PI*((i)/_steps)) * Math.PI/_steps )/2;
        };
    
        const _new_x = _x_start + _progress*(_x_end - _x_start);
        const _new_y = _y_start + _progress*(_y_end - _y_start);

        await sleep(15);

        const synthetic_mouse_move = {x:_new_x, y:_new_y};
        core_et.dispatchEvent(new CustomEvent('ring_moved', { detail: synthetic_mouse_move }));

    };

    // update dropping ring loc information 
    updateLoc_last_ring(_drop_end.loc);

    // retrieve ring and its index details
    const dropping_ring = yinsh.objs.rings.at(-1); // last ring
    const dropping_ring_loc_index = dropping_ring.loc.index;

    // update game state
    const gs_value = dropping_ring.type.concat(dropping_ring.player); // -> RB, RW
    update_game_state(dropping_ring_loc_index, gs_value);

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

    // remove the element and put it back at the end of the array, so it's always drawn last => appear on top
    // we could also move ring to dedicated structure that is drawn last and then put back in, but roughly same copying work
    reorder_rings(index_picked_ring_in_array);
    
    // wipe game state for location
    update_game_state(picked_ring_loc_index, "");

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

    // event.detail -> mousePos

    // the last ring in the array is the one being moved
    const id_picked_ring = getIndex_last_ring();

        // updates x and y ring location
        yinsh.objs.rings[id_picked_ring].loc.x = event.detail.x;
        yinsh.objs.rings[id_picked_ring].loc.y = event.detail.y;

    // redraw everything
    refresh_canvas_state();

};



// listens to ring snaps/drops -> flips markers -> triggers score handling -> refresh states
async function ringDrop_handler (event) {

    // retrieves loc object of snapping drop zone
    const snap_drop_loc = event.detail;

    // retrieves ids of legal drops for the ring that was picked up
    const _current_legal_drops = yinsh.objs.current_move.legal_drops;

    // check if drop coordinates are valid -> drop rings
    if (_current_legal_drops.includes(snap_drop_loc.index)){

        // update ring loc information (last)
        updateLoc_last_ring(snap_drop_loc);

        // retrieve ring and its index details (last)
        const dropping_ring = yinsh.objs.rings.at(-1);
        const dropping_ring_loc_index = dropping_ring.loc.index;
    
        // update game state
        // if ring is dropped in same location, this automatically overrides the existing marker (MB/MW)
        const gs_value = dropping_ring.type.concat(dropping_ring.player); // -> RB, RW
        update_game_state(dropping_ring_loc_index, gs_value);

        // resets data for current move (move is complete/off), but let's save starting index first
        const start_move_index = yinsh.objs.current_move.start_index;
        update_current_move(); // -> important to close the move to prevent side effects
        
        // updates legal cues (all will be turned off as move is no longer in progress)
        update_legal_cues();

        // re-draw everything and play sound
        refresh_canvas_state(); 
        ringDrop_play_sound(); 

        // logging
        console.log(`LOG - Ring ${dropping_ring.player} moved to index ${dropping_ring_loc_index}`);


        ////// handle markers removal, flipping, and trigger score handling
        // CASE: same location drop, nothing to flip, remove added marker
        if (dropping_ring_loc_index == start_move_index){
             
            remove_markers([dropping_ring_loc_index]); // removes markers from their array and game state
        
            // TO HANDLE
            console.log(`LOG TO HANDLE -> TURN SHOULD CONTINUE FOR USER`)

        // CASE: ring moved -> something happens -> look at scenarioTree to check
        } else {

            // retrieve scenario as scenarioTree.index_start_move.index_end_move
            const move_scenario = yinsh.server_data.scenarioTree[start_move_index][dropping_ring_loc_index];
            console.log(move_scenario);

            // CASE: some markers must be flipped
            if (move_scenario.flip_flag == true){
                // flip and re-draw
                flip_markers(move_scenario.markers_toFlip);
                refresh_canvas_state(); 
            };

            // CASE: scoring was made -> score handling is triggered
            if (move_scenario.score_flag == true){

                console.log("LOG - Score! Pick scoring option");

                // create task to be waited on
                const task_score_handling = new Task(move_scenario.scores_toHandle);
                update_scoring_data(task_score_handling); // save scoring options

                // turn will be ended by score handling function 
                core_et.dispatchEvent(new CustomEvent('score_handling_on', {detail: task_score_handling}));
                await task_score_handling.promise // wait for task to be completed

            }
        };
                
        // turn completed
        await end_turn_wait_opponent(start_move_index, dropping_ring_loc_index);

    } else{ // invalid location for drop attempt

        console.log("LOG - Invalid drop location");
        // NOTE: we could play specific sound 
    };
};


// can be called from different points to terminate turn
async function end_turn_wait_opponent(start_index, end_index) {

    turn_end(); // local turn ends

    disableInteraction();

    // -> notify server about completed move (next turn)
    await server_ws_whatNow({start: start_index, end: end_index}); 

};

       

// listens to scoring events -> begins/ends score handling 
function scoring_options_handler(event){

    // CASE: score handling started
    if (event.type === "score_handling_on") {

        console.log("LOG - Handling score");

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
        markersRemoved_play_sound();

        // complete score handling task
        complete_score_handling_task();

        // wipe score handling data
        update_scoring_data();
    
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




/*


// handling case of window resizing and first load -> impacts canvas, board, and objects 
["load", "resize"].forEach(event => window.addEventListener(event, sizing_handler));

// add to window onMount
// https://docs.solidjs.com/references/api-reference/lifecycles/onMount


function sizing_handler() {

    win_height = window.innerHeight;
    win_width = window.innerWidth;

    update_sizing(win_height, win_width); // adjusts canvas and computes new S & H values

    init_drop_zones(); // -> drop zones are re-created from scratch as S changes
    refresh_objects(); // -> all objects are updated as S changes

    refresh_draw_state();

};


*/