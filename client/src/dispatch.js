import { server_newGame_gen } from './server.js'
import { init_core_logic , init_newGame_wServerData } from './core_logic.js'
import { save_srv_response_NewGame } from './data.js'


// NOTE: why do I need two clicks??

// initializes new game with information from the server
export async function init_newGame_dispatcher() {

    console.log(' -- Requesting new game --');
    const request_start_time = Date.now()

    try{

        // initializes parameter, event target for game logic handler, binds canvas
        // everything in this function can be done while offline
        init_core_logic();

        // asks for new game to the server and save response
        // note: more of this stuff should go to the core_logic
        // dispatch (if it stays) should limit itself to be a thin wrapper 
        
        save_srv_response_NewGame(await server_newGame_gen());
        
        init_newGame_wServerData();

        // not really ready
        console.log(`LOG - Game ready. Time-to-first-move: ${Date.now() - request_start_time}ms`);

    } catch (err) {
        
        throw new Error("Something went off when requesting a new game.")
    } 

};

