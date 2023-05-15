// CORE LOGIC
// init games, game logic, and responding to interaction

import { server_newGame_gen } from './server.js'
import { init_global_obj_params, init_empty_game_objects, init_new_game_data } from './data.js'
import { refresh_canvas_state } from './drawing.js'


// init function to be called from ui/dispatcher -> creates global object and logic event target 
export function init_core_logic(){

    // inits global object (globalThis.yinsh) + non-changing parameters
    init_global_obj_params();

    // inits event target
    yinsh.core_logic_et = new EventTarget()

    // bind the canvas to a global variable -> also move canvas binding inside yinsh global object?
    globalThis.ctx = document.getElementById('canvas').getContext('2d', { alpha: true });
    
};

// tiggered once we have game data from server
export function init_newGame_wServerData(){

    // initialize empty game objects
    init_empty_game_objects();

    // maps data from server to game objects + sets up drop zones and rings (sensitive to window size)
    init_new_game_data();

    // draw everything
    refresh_canvas_state();

};

/*

// listens to ring picks and updates game state
game_state_target.addEventListener("ring_picked", 
    async function (event) {

    // detail contains index of picked ring in the rings array (array was already looped over once)
    id_ring_evt = event.detail;

    // remove the element and put it back at the end of the array, so it's always drawn last => on top
    // note: splice returns the array of removed elements
    rings.push(rings.splice(id_ring_evt,1)[0]); 
    
    id_last_ring = rings.length-1; // could be computed once and stored in current_move variable
    p_ring = rings[id_last_ring];
    
    // clean game state for location
    update_game_state(p_ring.loc.index, "");

    value = p_ring.type.concat(p_ring.player); // -> RB, RW

    console.log(`${value} picked from ${p_ring.loc.m_row}:${p_ring.loc.m_col} at -> ${p_ring.loc.index}`);

    // write start of the currently active move to a global variable
    update_current_move(on = true, index = structuredClone(p_ring.loc.index))

    // place marker in same location & draw changes
    add_marker(loc = structuredClone(p_ring.loc), player = p_ring.player);
    refresh_draw_state();

    // get legal moves from the server
    // game_state and current move are read from global variables
    // NOTE : legal moves are requested considering no ring nor marker at their current location due to game_state updates
    const srv_legal_moves = await server_legal_moves();

    if (srv_legal_moves.length > 0){

        // writes legal moves to a global variable
        current_legal_moves = srv_legal_moves;

        // init highlight zones
        update_highlight_zones()

        console.log(`Legal moves: ${current_legal_moves}`); 
        
    };

    // draw changes
    refresh_draw_state();

});


// listens to a ring being moved -> updates ring state & redraws
game_state_target.addEventListener("ring_moved", 
    function (event) {

    // event.detail -> mousePos

    id_last_ring = rings.length-1;

    rings[id_last_ring].loc.x = event.detail.x;
    rings[id_last_ring].loc.y = event.detail.y;

    refresh_draw_state();

});


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

function sizing_handler() {

    win_height = window.innerHeight;
    win_width = window.innerWidth;

    update_sizing(win_height, win_width); // adjusts canvas and computes new S & H values

    init_drop_zones(); // -> drop zones are re-created from scratch as S changes
    refresh_objects(); // -> all objects are updated as S changes

    refresh_draw_state();

};


*/