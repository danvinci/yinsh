// SERVER INTERFACE FUNCTIONS

port_number = "1038"

// server call for checking allowable moves 
async function server_allowed_moves(state, start_row, start_col){

    // https://stackoverflow.com/questions/48708449/promise-pending-why-is-it-still-pending-how-can-i-fix-this
    // https://stackoverflow.com/questions/40385133/retrieve-data-from-a-readablestream-object
    

    response = await fetch(`http://localhost:${port_number}/api/v1/allowed_moves`, {
        method: 'POST', // GET requests cannot have a body
        body: JSON.stringify({
                                "game_id": 'game_unique_id', 
                                "state": state, 
                                "row": start_row,
                                "col": start_col

                            })
    });

    // note: passing the state could be redundant, only game id should be necessary
    
    // get allowed moves back from the server (array)
    const srv_allowed_moves = await response.json(); // note: json() is async and must be awaited, otherwise we print the promise object itself 
    
    // parse and store allowed moves
    let allowed_moves = [];

    if (srv_allowed_moves.length > 0) {
        for (const move of srv_allowed_moves.values()) {
            // note: reshaping could be moved to the server, as well as the length check -> keep the client dumb and lean
            allowed_moves.push(reshape_index(move.I[0], move.I[1]));
        };

        console.log("Allowed moves from the server: "); console.log(allowed_moves);
        return allowed_moves;

    } else {

        console.log("no_moves");
        return "no_moves";
    };

};

// server call for checking which markers must be flipped
async function server_markers_check(state, start_row, start_col, end_row, end_col){

    response = await fetch(`http://localhost:${port_number}/api/v1/markers_check`, {
        method: 'POST', 
        body: JSON.stringify({
                                "game_id": 'game_unique_id', 
                                "state": state, 
                                "start_row": start_row,
                                "start_col": start_col,
                                "end_row": end_row,
                                "end_col": end_col

                            })
    });

    // note: passing the state could be redundant, only game id should be necessary
    
    // get markers to be flipped back from the server (array)
    const srv_markers_check = await response.json(); // note: json() is async and must be awaited, otherwise we print the promise object itself 
    
    // parse and store indexes of markers
    let markers_to_flip = [];

    if (srv_markers_check.length > 0) {
        for (const mk_index of srv_markers_check.values()) {
            // note: reshaping could be moved to the server, as well as the length check -> keep the client dumb but lean
            markers_to_flip.push(reshape_index(mk_index.I[0], mk_index.I[1]));
        };

        console.log("Markers to flip from the server: "); 
        console.log(markers_to_flip);
        return markers_to_flip;

    } else {

        console.log("No markers to flip");
        return "no_markers_to_flip";
    };

};

