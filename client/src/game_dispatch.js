import { server_newGame_gen } from "./server.js"
import { set, get } from 'idb-keyval'


// using idb-keyval for storage -> avoid having a global object



// INIT FUNCTION
// instatiate event target for an events dispatcher between the game 'engine' and the UI
// adds event listeners to the target (main)
export function init_game_dispatch() {

    // define global event target
    globalThis.game_dispatch_et = new EventTarget()


    // creates new LOCAL GAME and instatiate it
    game_dispatch_et.addEventListener("test_event_from_UI", 
        async function (event) {

            console.log("TEST EVENT RECEIVED")

            const srv_newGame_resp = await server_newGame_gen();

            // call above could also return error
                // if okay -> write everything to local storage
                
                console.log(`Game ID from server: ${srv_newGame_resp.game_id}`);

                // SAVE data to indexedDB via idb-keyval library
                set("game_id", srv_newGame_resp.game_id) // game ID
                //get("game_id").then( (val) => console.log(`Game ID written in DB: ${val}`) ); // test

                // assign color to local player (this client is the caller)
                set("client_player_id", srv_newGame_resp.caller_color); // player ID (B ~ Black, W ~ White)
                get("client_player_id").then( (val) => console.log(`This client will be the ${val} player`) ); // test

                // save initial rings locations
                set("whiteRings_initial_locs", srv_newGame_resp.whiteRings_ids); 
                set("blackRings_initial_locs", srv_newGame_resp.blackRings_ids);

                // save pre-computed possible legal moves if this client is the WHITE player
                if (srv_newGame_resp.caller_color == "W") {
                    set("next_legal_moves", srv_newGame_resp.next_legalMoves);
                };

        });

    // creates new LOCAL GAME and instatiate it
    game_dispatch_et.addEventListener("new_local_game", 
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

};


// CALLER FUNCTIONS - exposed to the UI module
// dispatch event to ask server for new game code

// NOTE -> turn everything into function calls ?
export function test_event_from_UI() {
    game_dispatch_et.dispatchEvent(new CustomEvent("test_event_from_UI"));
  };
