// SERVER INTERFACE FUNCTIONS

import { save_first_server_response } from './data.js'

const port_number = "1099"

// server call for generating new game
// NOTE: should handle errors directly (e.g. server unavailable)
export async function server_genNewGame(){

    // start timing
    let call_start = Date.now();

    const srv_new_game_resp = (await fetch(`http://localhost:${port_number}/v1/new_game`, {method: 'GET'})).json();

    // end timing
    console.log(`LOG - RTT for new game request: ${Date.now() - call_start}ms`);

    return srv_new_game_resp;

};

// server call for generating new game
export async function server_joinWithCode(game_code){

    let call_start = Date.now();

    const resp_promise = await fetch(`http://localhost:${port_number}/v1/join_game`, {
        method: 'POST',
        body: JSON.stringify({"game_code": game_code})

    });
    
    const srv_join_game_resp = await resp_promise.json(); 

    // logging time
    let delta_time = Date.now() - call_start;
    console.log(`LOG - RTT for join with code request: ${delta_time}ms`);

    return srv_join_game_resp;

};


////////////////// WEBSOCKETS
// https://javascript.info/websocket
// https://stackoverflow.com/questions/1349404/generate-random-string-characters-in-javascript
// https://javascript.info/promise-basics

const ws_port = 8092;
const ip_address = "127.0.0.1"

globalThis.log_sentMessages = {}; // initialize log of message payloads (for msgs sent to server)

// write to log
function log_msgPayload(msg_payload){ 
    try {
        // retrieve id
        const msg_id = msg_payload.msg_id
    
        // tests if key is in log
        if (msg_id in log_sentMessages) {
            throw new Error("LOG - Error logging payload, already logged");

        } else {
            log_sentMessages[msg_id] = msg_payload;
            console.log('LOG - Message payload logged');
        };  

    } catch(err) {
        console.log(err);
    };
};

// retrieve when a message was sent 
function get_time_msgSent(msg_id){ 
    
    try {

        // tests if key is in log
        if (msg_id in log_sentMessages) {
            
            return log_sentMessages[msg_id].msg_time;

        } else {
            throw new Error(`LOG - Message payload not found in log`);
        };

    } catch (err) {
        console.log(err);

    };
};


// web socket initializers, called by core
export async function init_ws () {
    return new Promise((resolve,reject) => {


        // if ws is defined and connection is already open -> resolve directly
        if (typeof ws != "undefined" && ws.readyState == 1) {

            console.log(`LOG - WebSocket - connection already OPEN`);
            resolve('ws_connection_already_open'); // -> resolve promise

        } else { // tries opening a new websocket connection

            try{
                
                // logging
                let connection_start = Date.now();

                globalThis.ws = new WebSocket(`ws://${ip_address}:${ws_port}`);

                // adds event listeners 
                // ws.addEventListener('open', onOpen_handler, false); // -> directly handled here
                ws.addEventListener('message', onMessage_handler, false);
                ws.addEventListener('error', onError_handler, false);
                ws.addEventListener('close', onClose_handler, false);

                // resolve on open
                ws.onopen = (event) => {
                    console.log(`LOG - WebSocket - connection OPEN in ${Date.now() - connection_start}ms`);
                    resolve('ws_connection_open'); // -> resolve promise
                };
                
            } catch (err) { // if connection doesn't work

                reject(err); 

            };
        };
    });
};

//////////////////////////// WEBSOCKET EVENT HANDLERS

/*
// only invoked when connection is opened
function onOpen_handler (event) {
    console.log(`LOG - WebSocket - connection OPEN`);
};

*/

// dispatches incoming messages
function onMessage_handler (event) {

    console.log(`LOG - Websocket - received new MESSAGE`);
    
    // parse message payload
    const server_data = JSON.parse(event.data);

    // dispatch based on message codes in responses from the server 
    switch(server_data.msg_code){

        // new game ready from server 
        case "new_game_ready":

            // retrieves id of original request and logs RTT time (serialization/de-serialization contributes too)
            const msg_id = server_data.msg_id;
            
            // logs RTT time
            console.log(`LOG - RTT for new game request: ${Date.now() - get_time_msgSent(msg_id)}ms`);
            
            // saves server response
            save_first_server_response(server_data);

            break;

    };
};



function onError_handler (event) {

    console.log(`LOG - Websocket - ERROR`);
    console.log(event);

};

function onClose_handler (event) {

    console.log(`LOG - WebSocket - connection CLOSED - `, event.reason);

};

//////////////////////////// MESSAGE SENDERS

// Send message for generating new game 
export function server_ws_genNewGame(){

    // message body
    const msg_time = Date.now();
    const msg_id = msg_time.toString(36); // generate random id for the message -> we can use it later to log response times
    const payload = {msg_code: "new_game", msg_time: msg_time, msg_id: msg_id};
    
    // package message
    const msg = JSON.stringify(payload)
    
    // send message
    ws.send(msg);

    // end timing
    console.log(`LOG - New game requested`);

    // save message payload to log
    log_msgPayload(payload);

};




export function send_testMsg_socket(){

    server_ws_genNewGame()
};




/*
// server call for checking allowable moves  // OBSOLETE -> PRE-COMPUTED IN ADVANCE
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

*/