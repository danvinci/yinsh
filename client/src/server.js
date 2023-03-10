// SERVER INTERFACE FUNCTIONS

port_number = "1131"

// server call for checking allowable moves 
async function server_allowed_moves(){

    let call_start = Date.now();
    // https://stackoverflow.com/questions/48708449/promise-pending-why-is-it-still-pending-how-can-i-fix-this
    // https://stackoverflow.com/questions/40385133/retrieve-data-from-a-readablestream-object

    // reads directly global variables for game_state and current move
    response = await fetch(`http://localhost:${port_number}/api/v1/allowed_moves`, {
        method: 'POST', // GET requests cannot have a body
        body: JSON.stringify({
                                "game_id": 'game_unique_id', 
                                "state": game_state, 
                                "start_index": current_move.start_index
                            })
    });

    // the failed fetch should be handled -> game pause or automatic retry?
    // note: passing the state could be redundant, only game id should be necessary
    
    // get allowed moves back from the server (array)
    const srv_allowed_moves = await response.json(); // note: json() is async and must be awaited, otherwise we print the promise object itself 

    // logging time
    let delta_time = Date.now() - call_start;
    console.log(`RTT: ${delta_time}ms`);

    // return response to game status handler
    return srv_allowed_moves;

};

// server call for checking which markers must be flipped
// change endpoint name to markers_action
async function server_markers_check(end_move_index){

    let call_start = Date.now();
    // reads directly global variables for game_state and current move
    response = await fetch(`http://localhost:${port_number}/api/v1/markers_check`, {
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
    const srv_response = await response.json(); // note: json() is async and must be awaited, otherwise we print the promise object itself 

    // logging time
    let delta_time = Date.now() - call_start;
    console.log(`RTT: ${delta_time}ms`);

    // return response to game status handler
    return srv_response;


    /*
    // UNPACK RESPONSE FROM SERVER
    // flipping flag + markers to be flipped 
    const markers_flip_flag = srv_response.flip_flag;
    const markers_toFlip_indexes = srv_response.markers_toFlip;
    
    // scoring rows and scoring details
    const num_scoring_rows = srv_response.num_scoring_rows.tot;
    const scoring_details = srv_response.scoring_details;



    // if there are scoring rows

    if (num_scoring_rows >= 1) {

        // getting scoring rows details (sel marker, ids to be removed from board, player) -> game_state should be handling whole response
        for (const row of srv_response.scoring_details.values()) {

            for (const mk_index of row.locs.values()){
                temp_mk_to_remove.push(mk_index);
            };
        };
    
        console.log(`Markers to remove - scoring: ${temp_mk_to_remove}`); 
    };

    

    // this should be returned and not wrote to a global variable (scoring options)
    // only data functions should write
    // and they are only called by the game state


    if (srv_response.flip_flag == true) {
        
        console.log(`Markers to flip: ${srv_markers_toFlip}`); 

        // logging time
        let delta_time = Date.now() - call_start;
        console.log(`RTT: ${delta_time}ms`);

        return [srv_response.flip_flag, srv_markers_toFlip];

    } else {

        console.log("No markers to flip");
        
        // logging time
        let delta_time = Date.now() - call_start;
        console.log(`RTT: ${delta_time}ms`);

        return [srv_response.flip_flag];
       
    };


    */

};

