// MAIN 
// game logic and orchestration

// init drop zones + markers y rings -> setup and first draw
init_objects()
refresh_draw_state(); 


// instatiate event target for game state (orchestrator)
let game_state_target = new EventTarget()


// listens to ring picks and updates game state
game_state_target.addEventListener("ring_picked", 
    async function (evt) {

    // detail contains index of picked ring in the rings array (array was already looped over once)
    id_ring_evt = evt.detail;

    // remove the element and put it back at the end of the array, so it's always drawn last => on top
    // note: splice returns the array of removed elements
    rings.push(rings.splice(id_ring_evt,1)[0]); 
    
    id_last_ring = rings.length-1; // could be computed once and stored in current_move variable
    p_ring = rings[id_last_ring];
    
    // clean game state for location
    update_game_state(p_ring.loc.index, "");

    value = p_ring.type.concat(p_ring.player); // -> RB, RW, MB, MW

    console.log(`${value} picked from ${p_ring.loc.m_row}:${p_ring.loc.m_col} at -> ${p_ring.loc.index}`);

    // write start of the currently active move to a global variable
    current_move.active = true;
    current_move.loc = p_ring.loc;        

    // get allowed moves from the server
    // game_state and current move are read from global variables
    // NOTE : allowed moves are requested considering no ring nor marker at their current location due to game_state updates
    const srv_allowed_moves = await server_allowed_moves();

    if (srv_allowed_moves.length > 0){

        // writes allowed moves to a global variable
        current_allowed_moves = srv_allowed_moves;

        // init highlight zones
        update_highlight_zones()

        console.log(`Allowed moves: ${current_allowed_moves}`); 
        
    };

    // place marker in same location and update game_state (after asking for allowed moves)
    // this allows for scoring to be computed correclty from game_state, as this marker will stay in place at ring_drop
    // location must be copied and not referenced -> otherwise the marker will be drawn along the ring as it inherits the same location
    add_marker(loc = structuredClone(p_ring.loc), player = p_ring.player);

    refresh_draw_state();

});


// listens to a ring being moved -> updates ring state & redraws
game_state_target.addEventListener("ring_moved", 
    function (evt) {

    // evt.detail -> mousePos

    id_last_ring = rings.length-1;

    rings[id_last_ring].loc.x = evt.detail.x;
    rings[id_last_ring].loc.y = evt.detail.y;

    refresh_draw_state();

});


// listens to ring drops, makes checks, and updates game state + redraw
game_state_target.addEventListener("ring_drop_attempt", 
    async function (evt) {

    drop_coord_loc = evt.detail;

    // check if drop coordinates are valid 
    if (current_allowed_moves.includes(drop_coord_loc.index) == true){

        // the active ring is always last in the array
        id_last_ring = rings.length-1;

        // update ring loc information
        rings[id_last_ring].loc = structuredClone(drop_coord_loc);

        drop_index = drop_coord_loc.index;
        value = rings[id_last_ring].type.concat(rings[id_last_ring].player); // -> RB, RW

        // update game state
        // if ring dropped in same location, this automatically overrides MB/MW -> no need to handle it in funcion to remove marker(s)
        update_game_state(drop_index, value);
        console.log(`${value} dropped at ${evt.detail.m_row}:${evt.detail.m_col} -> ${drop_index}`);

        // empty array of allowed zones
        update_highlight_zones(reset = true)


        if (drop_index == current_move.loc.index){
            
            remove_markers(drop_index);
            // ring dropped in same location, overrides MB/MW -> no need to handle it explicitly

            console.log(`Marker removed from index: ${drop_index}`);

            // CASE: same location drop, nothing to flip (no server call needed for this)
            // -> do nothing

        // ring moved -> asks the server about markers and scoring options
        } else {

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
                const score_event = new CustomEvent("score", {detail: {num_scoring_rows: srv_mk_resp.num_scoring_rows, scoring_details: srv_mk_resp.scoring_details}});
                game_state_target.dispatchEvent(score_event);

            };
        };

        // complete move, redraw, and play sound
        reset_current_move()

        refresh_draw_state(); 
        sfxr.play(ring_drop_sound); 
    
    } else{

        console.log("Invalid drop location");
        // NOTE: we could play specific sound 
    };
});

// listens to scoring events
game_state_target.addEventListener("score", 
    function (evt) {

    // we could use global var to save the state -> useful for interaction later

    console.log("Score!");

    num_scoring_rows = evt.detail.num_scoring_rows;
    scoring_details = evt.detail.scoring_details;

    // CASE SINGLE ROW
    if (num_scoring_rows.tot == 1) {

        // retrieve mk_sel and scoring indexes
        mk_sel = scoring_details[0].mk_sel;
        mk_locs = scoring_details[0].mk_locs;
        
        // highlight mk_sel
        update_mk_halos([mk_sel]);
        refresh_draw_state();

        // on_hover -> highlight all other indexes
        // listen to on_hover and click events on mk_sel -> how to listen to multiple events from 

        // on_click -> remove all markers
        // ask for ring to remove of player's color -> score point for player?
    };

    // CASE MULTIPLE ROWS

    // NOTE: to revisit to handle player detail !!

});

/*

 // handle scoring cases
        // see if server was called, pause, act
        // NOTE: need to prevent interaction during pauses
        
        // this check should be done on response from the server
        if (temp_mk_to_remove.length > 0) {

            await sleep(1);
            // markers removed both from object and game state 
            remove_markers(temp_mk_to_remove);
            
            for (const mk_index of temp_mk_to_remove.values()) {
                // clean markers from game state as well
                update_game_state(mk_index, "");
            };
        
            reset_mk_toRemove_scoring();
            refresh_draw_state(); 
       
        };

        await sleep(0.5);
        refresh_draw_state(); 
*/





// shoud be moved to separate library
async function sleep(sec) {
    return new Promise(resolve => setTimeout(resolve, sec * 1000));
  }