import { server_newGame_gen } from "./server.js"
import { init_game_constants, save_srv_response_NewGame, init_game_objects } from './data.js'


// initializes new game with information from the server
export async function init_newGame_dispatcher() {

    console.log(' -- Requesting new game --');

    // initialize constants used across the game (do first, used to interpret data from server)
    await init_game_constants()

    try{
        // asks for new game to the server
        const srv_newGame_resp = await server_newGame_gen();

        // save server response to DB
        await save_srv_response_NewGame(srv_newGame_resp);
    
        // initialize new game with data in the server response (saved at previous step)
        await init_game_objects();

        // bind the canvas to a global variable
        globalThis.ctx = document.getElementById('canvas').getContext('2d', { alpha: true }); 


        // drawing test
        ctx.lineJoin = "round";
        ctx.strokeStyle = '#1e52b7';
        ctx.lineWidth = 2;
        ctx.globalAlpha = 0.55;

        ctx.translate(50, 50);
        ctx.beginPath();
        ctx.moveTo(0,0); 
        ctx.lineTo(0,50); 
        ctx.lineTo(40,50/2);
        ctx.closePath(); 
        ctx.stroke();



    } catch (err) {
        
        throw new Error("Something off when requesting new game")
    } 

};



// INIT FUNCTION
// instatiate event target for an events dispatcher between the game 'engine' and the UI
// adds event listeners to the target (main)
export function init_game_dispatch() {

    // define global event target
    globalThis.game_dispatch_et = new EventTarget()


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


