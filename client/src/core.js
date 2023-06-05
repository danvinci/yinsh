//////////////////////////////
//////////// CORE LOGIC


//////////// IMPORTS
import { init_ws, server_ws_genNewGame, server_ws_joinWithCode, server_ws_genNewGame_AI, server_ws_whatNow} from './server.js'
import { init_global_obj_params, init_empty_game_objects, init_new_game_data, save_next_server_response } from './data.js'
import { reorder_rings, update_game_state, update_current_move, add_marker, update_legal_cues, getIndex_last_ring, updateLoc_last_ring, flip_markers, remove_markers } from './data.js'
import { swap_data_next_turn, update_objects_next_turn, turn_start, turn_end} from './data.js' 
import { refresh_canvas_state } from './drawing.js'
import { init_interaction, enableInteraction, disableInteraction } from './interaction.js'
import { ringDrop_play_sound, markersRemoved_play_sound } from './audio.js'

//////////// GLOBAL DEFINITIONS

    // inits global event target for core logic
    globalThis.core_et = new EventTarget(); // <- this semicolon is very important

    core_et.addEventListener('ring_picked', ringPicked_handler, false);
    core_et.addEventListener('ring_moved', ringMoved_handler, false);
    core_et.addEventListener('ring_drop', ringDrop_handler, false);
    core_et.addEventListener('srv_next_action', server_actions_handler, false);



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
        
            // player's turn should continue 

        // CASE: ring moved -> looking into scenarioTree to see what happens
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

            /////////////////////////////////// -> refactoring progress

            // CASE: scoring was made -> score handling is triggered
            if (move_scenario.score_flag == true){

                console.log("UNHANDLED - SCORE HANDLING");

                //const score_handling_start = new CustomEvent("score_handling_start", {detail: {num_scoring_rows: srv_mk_resp.num_scoring_rows, scoring_details: srv_mk_resp.scoring_details}});
                //game_state_target.dispatchEvent(score_handling_start);

            };
        };

        // MOVE COMPLETED (but turn might not be over yet)
        // draw any changes
        refresh_canvas_state(); 

        turn_end(); // local turn ends

        disableInteraction();

        // -> notify server about completed move (next turn)
        await server_ws_whatNow({start: start_move_index, end: dropping_ring_loc_index}); 
    
    } else{

        console.log("LOG - Invalid drop location");
        // NOTE: we could play specific sound 
    };
};




       



/*



// listens to scoring events -> begins score handling 
game_state_target.addEventListener("score_handling_start", 
    function (event) {

    console.log("Score!");

    // TEMP values passed in event detail 
    let num_scoring_rows = event.detail.num_scoring_rows;
    let scoring_details = event.detail.scoring_details;
    let markers_sel_array = [];


    // exrtract mk_sel from each scoring row
    for (const row of scoring_details.values()) {
        markers_sel_array.push(row.mk_sel);
    };
    
    // flag score handling action underway and save data in global var
    update_score_handling(on = true, mk_sel_array = markers_sel_array, num_rows = num_scoring_rows, details = scoring_details)


    // highlight each mk_sel in array
    update_mk_sel_scoring(markers_sel_array);
    update_mk_halos();
    refresh_draw_state();


    // NOTE: to revisit to handle player detail ?

});


// listens to hovering event over sel_markers in scoring rows -> handle highlighting
game_state_target.addEventListener("mk_sel_hover_ON", 
    function (event) {

    // retrieve index of marker being hovered on
    mk_sel_hover_index = event.detail;

    // retrieve indexes of markers of matching scoring row and highlight them
    for (const row of score_handling_var.details.values()) {
        if (mk_sel_hover_index == row.mk_sel){

            // highlight each marker in array
            update_mk_sel_scoring(row.mk_locs, true);
            update_mk_halos();
            refresh_draw_state();

            break;
        };
        
    };

});


// listens to hovering event over sel_markers in scoring rows -> handle highlighting
game_state_target.addEventListener("mk_sel_hover_OFF", 
    function (event) {

    // turn everything off except original mk_sel
    update_mk_sel_scoring(score_handling_var.mk_sel_array);
    update_mk_halos();

    refresh_draw_state();

});


// listens to click event over sel_markers in scoring rows -> handle markers removal and ends score_handling
game_state_target.addEventListener("mk_sel_clicked", 
    function (event) {

   // retrieve index of marker being clicked on
   mk_sel_clicked_index = event.detail;

    // turn mk halos off
    update_mk_sel_scoring(); // -> empties array
    update_mk_halos();

    // retrieve indexes of markers of matching scoring row and remove them
    for (const row of score_handling_var.details.values()) {
        if (mk_sel_clicked_index == row.mk_sel){

             // remove markers objects from game
            remove_markers(row.mk_locs);

            // update game state -> function above should be evolved to operate on both objects (?)
            for (const mk_id of row.mk_locs.values()) {
                update_game_state(mk_id, "");
            };
        
            break;
        };
        
    };

    // conclude scoring handling
    update_score_handling(on = false);

    // play sound
    markers_row_removed_sound.play();

    // re-draw everything
    refresh_draw_state();

});


// creates new game and instatiate it
game_state_target.addEventListener("new_game", 
    async function (event) {

        // ask the server for a new game code and state
        const srv_newGame_resp = await server_newGame_gen();

        // update global variables
        game_id = srv_newGame_resp.game_id;

        // assign color to local player (this client is the caller)
        client_player_id = srv_newGame_resp.caller_color;
        client_player_msg = (client_player_id == "W") ? "WHITE" : "BLACK"
        
        // save rings locations
        whiteRings_ids = srv_newGame_resp.whiteRings_ids;
        blackRings_ids = srv_newGame_resp.blackRings_ids;

        // save pre-computed possible legal moves
        next_legal_moves = srv_newGame_resp.next_legalMoves;
        
        console.log(`<< NEW GAME (CREATED)>>`);

        console.log(`Game ID: ${game_id}`);
        // create and dispatch event for the UI
        const new_game_ready_uiEvent = new CustomEvent("newGame_ready", {detail: {id: game_id, msg: client_player_msg}});
        ui_target.dispatchEvent(new_game_ready_uiEvent);
        

        // clean everything up => shouldn't be needed later, this is here because we already have a starting state
        destroy_objects();

        // init rings objects & update game state
        init_rings(rings_ids = whiteRings_ids, rings_player = player_white_id);
        init_rings(rings_ids = blackRings_ids, rings_player = player_black_id);

        // redraw everything
        refresh_draw_state();

        
});


// creates new game and instatiate it
game_state_target.addEventListener("join_game", 
    async function (event) {

        let game_code = event.detail;

        // ask the server for a new game code and state
        const srv_joinGame_resp = await server_joinGame(game_code);

        // update global variables
        game_id = srv_joinGame_resp.game_id;

        // this client is the non-starting player
        client_player_id = (srv_joinGame_resp.caller_color == "W") ? "B" : "W";
        client_player_msg = (client_player_id == "W") ? "WHITE" : "BLACK"
        
        // save rings locations
        whiteRings_ids = srv_joinGame_resp.whiteRings_ids;
        blackRings_ids = srv_joinGame_resp.blackRings_ids;

        // save pre-computed possible legal moves
        next_legal_moves = srv_joinGame_resp.next_legalMoves;
        
        console.log(`<< NEW GAME (JOINING)>>`);

        console.log(`Game ID: ${game_id}`);
        // create and dispatch event for the UI
        const join_game_ready_uiEvent = new CustomEvent("joinGame_ready", {detail: {id: game_id, msg: client_player_msg}});
        ui_target.dispatchEvent(join_game_ready_uiEvent);
        
        // clean everything up => shouldn't be needed later, this is here because we already have a starting state
        destroy_objects();

        // init rings objects & update game state
        init_rings(rings_ids = whiteRings_ids, rings_player = player_white_id);
        init_rings(rings_ids = blackRings_ids, rings_player = player_black_id);

        // redraw everything
        refresh_draw_state();

        
});




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