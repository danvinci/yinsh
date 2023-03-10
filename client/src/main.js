// MAIN 
// game logic and orchestration

// start
console.log('<<< NEW GAME >>>');

// init drop zones + markers y rings -> setup and first draw
init_objects()
refresh_draw_state(); 


// instatiate event target for game state (orchestrator)
let game_state_target = new EventTarget()


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
    if (current_allowed_moves.includes(drop_coord_loc.index) == true){

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

        // empty array of allowed moves & matching drawing objects
        current_allowed_moves = [];
        update_highlight_zones()


        if (drop_index == current_move.start_index){
            
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

                const score_handling_start = new CustomEvent("score_handling_start", {detail: {num_scoring_rows: srv_mk_resp.num_scoring_rows, scoring_details: srv_mk_resp.scoring_details}});
                game_state_target.dispatchEvent(score_handling_start);

            };
        };

        // complete move, redraw, and play sound
        update_current_move(on = false);


        refresh_draw_state(); 
        sfxr.play(ring_drop_sound); 
    
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
    sfxr.play(markers_row_removed_sound);

    // re-draw everything
    refresh_draw_state();

});


// handling case of window resizing, impacts board and objects 
// NOTE: could be revisited so to fire on first load
window.addEventListener("resize", 
    function () {

        win_height = window.innerHeight;
        win_width = window.innerWidth;
        update_sizing(win_height);

        init_drop_zones(); // -> drop zones are re-created from scratch
        refresh_objects();

        canvas.height = win_height;
        canvas.width = win_width;

        refresh_draw_state();

});