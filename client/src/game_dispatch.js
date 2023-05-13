import { server_newGame_gen } from "./server.js"
import { init_game_constants, save_srv_response_NewGame, init_new_game_data } from './data.js'
import { refresh_canvas_state } from './drawing.js'


// initializes new game with information from the server
export async function init_newGame_dispatcher() {

    console.log(' -- Requesting new game --');
    const request_start_time = Date.now()

    // initialize constants used across the game (do first, used to interpret data from server)
    await init_game_constants()

    try{
        // asks for new game to the server
        const srv_newGame_resp = await server_newGame_gen();

        // save server response to DB
        await save_srv_response_NewGame(srv_newGame_resp);

        // bind the canvas to a global variable
        globalThis.ctx = document.getElementById('canvas').getContext('2d', { alpha: true }); 

        // initialize new game with data in the server response (saved at previous step)
        await init_new_game_data();

        await refresh_canvas_state();

        // not really ready
        console.log(`LOG - Game ready. Time-to-first-move: ${Date.now() - request_start_time}ms`);

    } catch (err) {
        
        throw new Error("Something went off when requesting a new game.")
    } 

};

