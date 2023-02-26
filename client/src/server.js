// SERVER INTERFACE FUNCTIONS

port_number = "1077"

// server call for checking allowable moves 
async function server_allowed_moves(){

    // https://stackoverflow.com/questions/48708449/promise-pending-why-is-it-still-pending-how-can-i-fix-this
    // https://stackoverflow.com/questions/40385133/retrieve-data-from-a-readablestream-object

    // reads directly global variables for game_state and current move
    response = await fetch(`http://localhost:${port_number}/api/v1/allowed_moves`, {
        method: 'POST', // GET requests cannot have a body
        body: JSON.stringify({
                                "game_id": 'game_unique_id', 
                                "state": game_state, 
                                "row": current_move.loc.m_row,
                                "col": current_move.loc.m_col
                            })
    });

    // note: passing the state could be redundant, only game id should be necessary
    
    // get allowed moves back from the server (array)
    const srv_allowed_moves = await response.json(); // note: json() is async and must be awaited, otherwise we print the promise object itself 
    
    // parse and store allowed moves to local array
    let cli_allowed_moves = [];

    if (srv_allowed_moves.length > 0) {
        for (const move of srv_allowed_moves.values()) {
            // note: reshaping could be moved to the server, as well as the length check -> keep the client dumb and lean
            cli_allowed_moves.push(reshape_index(move.I[0], move.I[1]));
        };

        console.log("Allowed moves from the server: "); console.log(cli_allowed_moves);
        return cli_allowed_moves;

    } else {

        console.log("no_moves");
        return "no_moves";
    };

};

// server call for checking which markers must be flipped
// change endpoint name to markers_action
async function server_markers_check(end_row, end_col){

    // reads directly global variables for game_state and current move
    response = await fetch(`http://localhost:${port_number}/api/v1/markers_check`, {
        method: 'POST', 
        body: JSON.stringify({
                                "game_id": 'game_unique_id', 
                                "state": game_state, 
                                "start_row": current_move.loc.m_row,
                                "start_col": current_move.loc.m_col,
                                "end_row": end_row,
                                "end_col": end_col

                            })
    });

    // note: passing the state could be redundant, only game id should be necessary
    
    // get markers to be flipped back from the server (array)
    const srv_response = await response.json(); // note: json() is async and must be awaited, otherwise we print the promise object itself 

    // get markers to be flipped back from the server 
    const srv_markers_toFlip = srv_response.markers_toFlip;

    let arrays_count = 0; // to be deleted
    // getting indexes of scoring sub-spaces    
    for (const mk_index_array of srv_response.scoring_details.sub_spaces_locs.values()) {
        arrays_count = arrays_count+1;

        for (const mk_index of mk_index_array.values()){
            temp_global_ss.push(reshape_index(mk_index.I[0], mk_index.I[1]));
        };

    };

    //console.log('temp global: '); console.log(temp_global_ss);
    console.log(`arrays in temp_global: ${arrays_count}`)

    // if there are scoring rows
    num_scoring_rows = srv_response.num_scoring_rows 
    if (num_scoring_rows >= 1) {

        // getting scoring rows details (sel marker, ids to be removed from board, player) 
        for (const row of srv_response.scoring_details.scoring_details.values()) {

            for (const mk_index of row.locs.values()){
                temp_mk_to_remove.push(reshape_index(mk_index.I[0], mk_index.I[1]));
            };
        };
    
        console.log("Markers to remove - scoring: "); 
        console.log(temp_mk_to_remove);
    };

    

    // this should be returned and not wrote to a global variable
    // only data functions should write
    // and they are only called by the game state

    // parse and store indexes of markers in the client's format
    let cli_markers_toFlip = [];
    

    if (srv_response.flip_flag == true) {
        for (const mk_index of srv_markers_toFlip.values()) {
            // note: reshaping could be moved to the server, as well as the length check -> keep the client dumb but lean
            // this way we get rid of using reshape here 
            cli_markers_toFlip.push(reshape_index(mk_index.I[0], mk_index.I[1]));
        };

        console.log("Markers to flip from the server: "); 
        console.log(cli_markers_toFlip);

        // return original server response -> server should provide indexes already
        return [srv_response.flip_flag, cli_markers_toFlip];

    } else {

        console.log("No markers to flip");
        return [srv_response.flip_flag];
    };

};

