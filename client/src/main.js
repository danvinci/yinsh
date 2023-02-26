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
    const allowed_moves = await server_allowed_moves();

    if (allowed_moves != "no_moves"){

        // writes allowed moves to a global variable
        current_allowed_moves = allowed_moves;

        // init highlight zones
        update_highlight_zones()

        

    };

    // place marker in same location and update game_state (after asking for allowed moves)
    // this allows for scoring to be computed correclty from game_state, as this marker will stay in place at ring_drop
    // location must be copied and not referenced -> otherwise the marker will be drawn along the ring as it inherits the same location
    add_marker(loc = structuredClone(p_ring.loc), player = p_ring.player);

    update_ss_scoring_zones(reset = true); // to be deleted

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

        index = drop_coord_loc.index;
        value = rings[id_last_ring].type.concat(rings[id_last_ring].player); // -> RB, RW

        // update game state
        // if ring dropped in same location, this automatically overrides MB/MW -> no need to handle it in remove_marker()
        update_game_state(index, value);
        console.log(`${value} dropped at ${evt.detail.m_row}:${evt.detail.m_col} -> ${index}`);

        // empty array of allowed zones
        update_highlight_zones(reset = true)

        // drop row/col
        end_row = drop_coord_loc.m_row;
        end_col = drop_coord_loc.m_col;

        // this removes the marker if the ring is dropped where picked
        console.log(`Start row: ${current_move.loc.m_row}, start col: ${current_move.loc.m_col}`);
        console.log(`End row: ${end_row}, end col: ${end_col}`);

        if (end_row == current_move.loc.m_row && end_col == current_move.loc.m_col){
            
            remove_marker(index);
            // ring dropped in same location, overrides MB/MW -> no need to handle it explicitly

            console.log(`Marker removed from index: ${index}`);

            // CASE: same location drop, nothing to flip (no server call needed for this)
            // -> do nothing

        // ring moved -> asks the server about markers and scoring options
        } else {

            const markers_response = await server_markers_check(end_row, end_col);

            // NOTE: replace array with dictionary (so to use field names instead of 0/1/2/etc)

            // CASE: something to flip
            if (markers_response[0] == true){
                // update drawing objects
                flip_markers(markers_response[1]);

                // update game state
                flip_markers_game_state(markers_response[1])
            };

        };

        // complete move, redraw, and play sound
        reset_current_move()
        refresh_draw_state(); 
        sfxr.play(ring_drop_sound); 

        // temp test on drawing ss subspacess
        update_ss_scoring_zones();
        draw_ss_scoring_zones();

        
        // handle scoring cases
        // see if server was called, pause, act
        // NOTE: need to prevent interaction during pauses
        
        // this check should be done on response from the server
        if (temp_mk_to_remove.length > 0) {

            await sleep(1);
            // markers removed both from object and game state 
            remove_marker_multiple(temp_mk_to_remove);
            
            for (const mk_index of temp_mk_to_remove.values()) {
                // clean markers from game state as well
                update_game_state(mk_index, "");
            };
        
            reset_mk_toRemove_scoring();
            refresh_draw_state(); 
       
        };

        await sleep(0.5);
        refresh_draw_state(); 
        
    
    } else{

        console.log("Invalid drop location");
        // NOTE: we could play specific sound 
    };
});



async function sleep(sec) {
    return new Promise(resolve => setTimeout(resolve, sec * 1000));
  }