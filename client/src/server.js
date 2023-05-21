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

// custom class for managing the lifecycle of messages
class MessagePromise {
    constructor(payload, msg_id, msg_time) {
        this.payload = payload;
        this.msg_id = msg_id;
        this.msg_time = msg_time;
        this.server_response = {}; // -> we'll later use it for storing responses
        this.promise = new Promise((resolve, reject)=> {
            this.resolve = resolve

            // automatic rejection 100s after creation
            setTimeout(()=> {reject(new Error("LOG - Request timed out - ID: msg_id"))}, 100000);
        })
    }
    getTimeSent() {return this.msg_time;}
};

globalThis.messagePromises_log = {}; // initialize log for message promises

// write to log on the way out
function try_logOutbound(msg_prom){ 
    try {
        // retrieve id
        const msg_id = msg_prom.msg_id
    
        // tests if key is in log
        if (msg_id in messagePromises_log) {
            throw new Error(`LOG - Error logging outbound - ID : ${msg_id}`);

        } else {
            messagePromises_log[msg_id] = msg_prom;
            console.log(`LOG - Outbound message logged - ID: ${msg_id}`);
        };  

    } catch(err) {
        console.log(err);
    };
};

// saves server response for each message
function try_logInbound(msg_id, server_response_data){ 
    try {
        
        // tests if key is in log
        if (msg_id in messagePromises_log) {
            messagePromises_log[msg_id].server_response = server_response_data;
            console.log(`LOG - Server response added to messages log - ID: ${msg_id}`);

        } else {
            throw new Error(`LOG - inbound error - Message promise not found - ID: ${msg_id}`);
        };  

    } catch(err) {
        console.log(err);
    };
};

// resolves promise associated with sent message (called by message handler)
function mark_msg_handled(msg_id){

    messagePromises_log[msg_id].resolve();

};



//////////////////////////// WEBSOCKET INIT + EVENT HANDLERS

// initialize web socket, called by core
export async function init_ws () {
    return new Promise((resolve,reject) => {

        // if ws is defined and connection is already open -> resolve directly
        if (typeof ws != "undefined" && ws.readyState == 1) {

            console.log(`LOG - WebSocket - connection already OPEN`);
            resolve('ws_connection_already_open'); // -> resolve promise

        } else { // tries opening a new websocket connection

            try{
                
                // logging
                let connection_start = Date.now(); //-> we should throw a timeout error

                globalThis.ws = new WebSocket(`ws://${ip_address}:${ws_port}`);

                // adds event listeners 
                // ws.addEventListener('open', onOpen_handler, false); // -> directly handled here
                ws.addEventListener('message', onMessage_handler, false);
                ws.addEventListener('error', onError_handler, false);
                ws.addEventListener('close', onClose_handler, false);

                // resolve on open
                ws.onopen = (event) => {
                    console.log(`LOG - WebSocket - connection OPEN: ${Date.now() - connection_start}ms`);
                    resolve('ws_connection_open'); // -> resolve promise
                };
                
            } catch (err) { // if connection doesn't work

                reject(err); 

            };
        };
    });
};

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

    // retrieve message id
    const msg_id = server_data.msg_id;

    // save response
    try_logInbound(msg_id, server_data);

    // mark message as handled -> resolve its promise
    mark_msg_handled(msg_id);

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
export async function server_ws_genNewGame(){
    
    try {

        // message body
        const msg_time = Date.now();
        const msg_id = msg_time.toString(36); // generate random id for the message -> we can use it later to log response times
        const payload = {msg_code: "new_game", msg_time: msg_time, msg_id: msg_id};
        
        // log message that is about to be sent
        const local_msg = new MessagePromise(payload, msg_id, msg_time);
        try_logOutbound(local_msg);

        // send message
        ws.send(JSON.stringify(payload));

        // end timing
        console.log(`LOG - New game requested, message ID: ${msg_id}`);                         

        // wait to receive a response
        // -> will get resolved by message handler when we receive a response
        await local_msg.promise;

        console.log(`LOG - New game response received - RTT ${Date.now()-msg_time}ms`);
        
        // save response in dedicate objects
        save_first_server_response(messagePromises_log[msg_id].server_response);


    } catch (err) {

        console.log(`LOG - Error fulfilling new game request`);
        throw err;

    };
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