//////////////////////////////
//////////// CORE LOGIC


//////////// IMPORTS
import { server_newGame_gen } from './server.js'
import { init_global_obj_params, init_empty_game_objects, save_srv_response_NewGame, init_new_game_data } from './data.js'
import { rings_reordering, update_game_state, update_current_move, add_marker, init_legal_moves_cues } from './data.js'
import { refresh_canvas_state } from './drawing.js'
import { init_interaction } from './interaction.js'

//////////// GLOBAL DEFINITIONS

    // inits global event target for core logic
    globalThis.core_et = new EventTarget(); // <- this semicolon is very important

    ['ring_picked'].forEach(event => core_et.addEventListener(event, ringPicked_handler, false));
    ['ring_moved'].forEach(event => core_et.addEventListener(event, ringMoved_handler, false));


//////////// FUNCTIONS FOR INITIALIZING GAMES (NEW or JOIN)

// ask for new game to server
export async function init_newGame_fromServer(){

    console.log(' -- Requesting new game --');
    const request_start_time = Date.now()

    try{

        // inits global object (globalThis.yinsh) + constants used throughout the game
        init_global_obj_params();

        // initialize empty game objects
        init_empty_game_objects();

        // asks new game to server and saves response in object init above
        save_srv_response_NewGame(await server_newGame_gen());

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
        console.log(`LOG - Game ready, time-to-first-move: ${Date.now() - request_start_time}ms`);


    } catch (err){

        // log error
        console.log(`LOG - Game setup ERROR. ${Date.now() - request_start_time}ms`);
        console.log(err);
        throw err;

    };

};


//////////// EVENT HANDLERS FOR GAME MECHANICS

// listens to ring picks and updates game state
function ringPicked_handler(event) {

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
    rings_reordering(index_picked_ring_in_array);
    
    // wipe game state for location
    update_game_state(picked_ring_loc_index, "");

    // write start of the currently active move to a global variable
    update_current_move(true, picked_ring_loc_index);

    // place marker in same location (it's assumed client player)
    add_marker(picked_ring_loc);

    // initializes array of visual cues for starting index
    init_legal_moves_cues(picked_ring_loc_index);

    // draw changes
    refresh_canvas_state();

};



// listens to a ring being moved -> updates ring location & triggers re-draw
function ringMoved_handler (event) {

    // event.detail -> mousePos

    // the last ring in the array is the one being moved
    const id_last_ring = yinsh.objs.rings.length-1;

        // updates x and y ring location
        yinsh.objs.rings[id_last_ring].loc.x = event.detail.x;
        yinsh.objs.rings[id_last_ring].loc.y = event.detail.y;

    // redraw everything
    refresh_canvas_state();

};


//////////////////////////////////////////////////////////////////////////////// <-- refactoring progress
/*




// listens to ring drops, makes checks, and updates game state + redraw
game_state_target.addEventListener("ring_drop_attempt", 
    async function (event) {

    drop_coord_loc = event.detail;

    // check if drop coordinates are valid 
    if (current_legal_moves.includes(drop_coord_loc.index) == true){

        // the active ring is always last in the array
        id_last_ring = rings.length-1;

        // update ring loc information -> should go to dedicated function
        rings[id_last_ring].loc = structuredClone(drop_coord_loc);

        drop_index = drop_coord_loc.index;
        value = rings[id_last_ring].type.concat(rings[id_last_ring].player); // -> RB, RW

        // update game state
        // if ring dropped in same location, this automatically overrides MB/MW -> no need to handle it in funcion to remove marker(s)
        update_game_state(drop_index, value);
        console.log(`${value} dropped at ${event.detail.m_row}:${event.detail.m_col} -> ${drop_index}`);

        // empty array of legal moves & matching drawing objects
        current_legal_moves = [];
        update_highlight_zones()

        // re-draw everything and play sound (don't wait for server-dependent checks)
        refresh_draw_state(); 
        ring_drop_sound.play(); 

        if (drop_index == current_move.start_index){
             // CASE: same location drop, nothing to flip (no server call needed for this)

            remove_markers(drop_index);
            // ring dropped in same location, overrides MB/MW -> no need to handle it explicitly

            console.log(`Marker removed from index: ${drop_index}`);
            
        // ring moved -> asks the server about markers and scoring options
        } else {

            // play sound (don't wait for server response)
            ring_drop_sound.play(); 

            const srv_mk_resp = await server_markers_check(drop_index);

            // CASE: something to flip
            if (srv_mk_resp.flip_flag == true){
                // update drawing objects
                flip_markers(srv_mk_resp.markers_toFlip);

                // update game state
                flip_markers_game_state(srv_mk_resp.markers_toFlip)
            };

            // CASE: scoring was made -> create and dispatch event for other handler

            if (srv_mk_resp.num_scoring_rows.tot > 0){

                const score_handling_start = new CustomEvent("score_handling_start", {detail: {num_scoring_rows: srv_mk_resp.num_scoring_rows, scoring_details: srv_mk_resp.scoring_details}});
                game_state_target.dispatchEvent(score_handling_start);

            };
        };

        // MOVE COMPLETED
        // mark move as completed and redraw changes
        update_current_move(on = false);
        refresh_draw_state(); 
    
    } else{

        console.log("Invalid drop location");
        // NOTE: we could play specific sound 
    };
});




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