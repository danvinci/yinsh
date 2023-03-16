// SERVER INTERFACE FUNCTIONS

// https://www.pubnub.com/guides/what-are-websockets-and-when-should-you-use-them/
// https://www.pubnub.com/blog/http-long-polling/
// trying with long polling before digging into websockets

port_number = "1104"

// server call for generating new game
async function server_newGame_gen(){

    let call_start = Date.now();

    response = await fetch(`http://localhost:${port_number}/v1/new_game`, {method: 'GET'});
    
    const srv_new_game_resp = await response.json(); 

    // logging time
    let delta_time = Date.now() - call_start;
    console.log(`RTT new game: ${delta_time}ms`);

    // return response to game status handler
    return srv_new_game_resp;

};


// server call for checking allowable moves 
async function server_legal_moves(){

    let call_start = Date.now();
    // https://stackoverflow.com/questions/48708449/promise-pending-why-is-it-still-pending-how-can-i-fix-this
    // https://stackoverflow.com/questions/40385133/retrieve-data-from-a-readablestream-object

    // reads directly global variables for game_state and current move
    response = await fetch(`http://localhost:${port_number}/v1/legal_moves`, {
        method: 'POST', // GET requests cannot have a body
        body: JSON.stringify({
                                "game_id": 'game_unique_id', 
                                "state": game_state, 
                                "start_index": current_move.start_index
                            })
    });

    // the failed fetch should be handled -> game pause or automatic retry?
    // note: passing the state could be redundant, only game id should be necessary
    
    // get legal moves back from the server (array)
    const srv_legal_moves = await response.json(); // note: json() is async and must be awaited, otherwise we print the promise object itself 

    // logging time
    let delta_time = Date.now() - call_start;
    console.log(`RTT legal moves: ${delta_time}ms`);

    // return response to game status handler
    return srv_legal_moves;

};

// server call for checking which markers must be flipped
// change endpoint name to markers_action
async function server_markers_check(end_move_index){

    let call_start = Date.now();
    // reads directly global variables for game_state and current move
    response = await fetch(`http://localhost:${port_number}/v1/markers_check`, {
        method: 'POST', 
        body: JSON.stringify({
                                "game_id": 'game_unique_id', 
                                "state": game_state, 
                                "start_index": current_move.start_index,
                                "end_index": end_move_index

                            })
    });

    // note: passing the state could be redundant, only game id should be necessary
    
    // get markers to be flipped back from the server (array)
    const srv_mk_response = await response.json(); // note: json() is async and must be awaited, otherwise we print the promise object itself 

    // logging time
    let delta_time = Date.now() - call_start;
    console.log(`RTT markers check: ${delta_time}ms`);

    // return response to game status handler
    return srv_mk_response;

};

