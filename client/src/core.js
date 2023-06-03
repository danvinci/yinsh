//////////////////////////////
//////////// CORE LOGIC


//////////// IMPORTS
import { init_ws, server_ws_genNewGame, server_ws_joinWithCode, server_ws_genNewGame_AI, server_ws_whatNow} from './server.js'
import { init_global_obj_params, init_empty_game_objects, init_new_game_data } from './data.js'
import { reorder_rings, update_game_state, update_current_move, add_marker, update_legal_cues, getIndex_last_ring, updateLoc_last_ring, remove_markers } from './data.js'
import { turn_start, turn_end} from './data.js' 
import { refresh_canvas_state } from './drawing.js'
import { init_interaction, enableInteraction, disableInteraction } from './interaction.js'
import { ringDrop_play_sound, markersRemoved_play_sound } from './audio.js'

//////////// GLOBAL DEFINITIONS

    // inits global event target for core logic
    globalThis.core_et = new EventTarget(); // <- this semicolon is very important

    core_et.addEventListener('ring_picked', ringPicked_handler, false);
    core_et.addEventListener('ring_moved', ringMoved_handler, false);
    core_et.addEventListener('ring_drop', ringDrop_handler, false);

//////////// SLEEP UTIL

    function sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

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

        // log game ready (not really ready)
        console.log(`LOG - Game setup time: ${Date.now() - request_start_time}ms`);

        // log game code (later should be in the UI)
        console.log(`LOG - Your game code is: ${yinsh.server_data.game_id}`);

       
        // ask server what to do (who moves / wait)
        const next_action = await server_ws_whatNow();

        if (next_action == 'move') {

            turn_start(); // -> start player's turn

            // from here on, it should go to the client turn manager
            enableInteraction();
            console.log(`LOG - It's yout turn, make a move!`); // -> this should go to the UI

        };
            

    } catch (err){

        // log error
        console.log(`LOG - Game setup ERROR. ${Date.now() - request_start_time}ms`);
        console.log(err);
        throw err;

    };
};




//////////// EVENT HANDLERS FOR TURNS




//////////// EVENT HANDLERS FOR GAME MECHANICS

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

    // place marker in same location (it's assumed client player)
    add_marker(picked_ring_loc);

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

        // the active ring is always last in the array
        const index_dropping_ring_in_array = getIndex_last_ring();

            // update ring loc information 
            updateLoc_last_ring(snap_drop_loc);

            // retrieve ring and its index details
            const dropping_ring = yinsh.objs.rings[index_dropping_ring_in_array];
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
        console.log(`LOG - Ring ${dropping_ring.player} dropped at index ${dropping_ring_loc_index}`);


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

            /////////////////////////////////// -> refactoring progress
            // CASE: some markers must be flipped
            if (move_scenario.flip_flag == true){
                // update drawing objects
                console.log("UNHANDLED - MARKERS FLIP");
                //flip_markers(srv_mk_resp.markers_toFlip);

                // update game state
                //flip_markers_game_state(srv_mk_resp.markers_toFlip)
            };

            // CASE: scoring was made -> score handling is triggered
            if (move_scenario.score_flag == true){

                console.log("UNHANDLED - SCORE HANDLING");

                //const score_handling_start = new CustomEvent("score_handling_start", {detail: {num_scoring_rows: srv_mk_resp.num_scoring_rows, scoring_details: srv_mk_resp.scoring_details}});
                //game_state_target.dispatchEvent(score_handling_start);

            };
        };

        // MOVE COMPLETED (but turn might not be over yet)
        // redraw changes
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