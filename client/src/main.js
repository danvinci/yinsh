// MAIN 
// game logic and orchestration

// game setup and first draw
setup_new_game()
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
    // NOTE : allowed moves are requested considering no ring nor marker at their location (game state was wiped)
    const allowed_moves = await server_allowed_moves(game_state, p_ring.loc.m_row, p_ring.loc.m_col);

    if (allowed_moves != "no_moves"){

        // writes allowed moves to a global variable
        current_allowed_moves = allowed_moves;

        // init highlight zones
        update_highlight_zones()

    };

    // place marker in same location and update game status (after asking for allowed moves)
    // location must be copied and not referenced -> otherwise the marker will be drawn along the ring
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
        // if yes, remove marker, otherwise check markers to flip and flip them
        // should be moved to separate function !!
        console.log(`Start row: ${current_move.loc.m_row}, start col: ${current_move.loc.m_col}`);
        console.log(`End row: ${end_row}, end col: ${end_col}`);

        if (end_row == current_move.loc.m_row && end_col == current_move.loc.m_col){
            
            remove_marker(index);
            console.log(`Marker removed from index: ${index}`);

        } else {

            // check if any markers needs to be flipped
            const markers_to_flip = await server_markers_check(game_state, current_move.loc.m_row, current_move.loc.m_col, end_row, end_col);
            // trigger event to other listener -> change player for marker -> update game status -> retrigger drawing 

            if (markers_to_flip != "no_markers_to_flip"){
                flip_markers(markers_to_flip);
            };

        };

        // reset global variable for the current move
        reset_current_move()

        // re-draw everything
        refresh_draw_state(); 

        // play sound
        sfxr.play(sound); 

    } else{

        console.log("Invalid drop location");
    };
});





