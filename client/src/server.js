// SERVER INTERFACE FUNCTIONS

// https://javascript.info/websocket
// https://stackoverflow.com/questions/1349404/generate-random-string-characters-in-javascript
// https://javascript.info/promise-basics

import { save_server_response } from './data.js'

// API endpoint address
const ws_complete_address = `ws://localhost:6091`; // local test address (pluto)
// const ws_complete_address = `ws://localhost:80/api`; // local test address (docker)
// const ws_complete_address = "wss://yinsh.net/api" // prod deployment


///// COMMUNICATION CODES
// client -> server codes
export const CODE_new_game_human = "new_game_vs_human"
export const CODE_new_game_server = "new_game_vs_server"
export const CODE_join_game = "join_game"
export const CODE_advance_game = "advance_game" // clients asking to progress the game
export const CODE_resign_game = "resign_game" // clients asking to resign from game

const allowed_OUT_codes = [ CODE_new_game_human, CODE_new_game_server, CODE_join_game, CODE_advance_game, CODE_resign_game ]; 

// suffixes for code response type
const sfx_CODE_OK = "_OK"
const sfx_CODE_ERR = "_ERROR"

// creating OK resp codes to distinguish between SETUP (1st time) and NEXT MOVE codes -> data functions will need these
export const setup_ok_codes = [ CODE_new_game_human, CODE_new_game_server, CODE_join_game].map(c => c.concat(sfx_CODE_OK));
export const next_ok_codes = [ CODE_advance_game, CODE_resign_game].map(c => c.concat(sfx_CODE_OK));
export const joiner_ok_code = CODE_join_game.concat(sfx_CODE_OK);

/// EVENT TARGET + HANDLER for push messages

// inits global event target for handling push messages from server
globalThis.server_et = new EventTarget(); // <- this semicolon is very important

// event listener
server_et.addEventListener('new_push_message', push_messages_handler, false);


// custom class for managing the lifecycle of messages
class MessagePromise {
    constructor(payload, msg_id, msg_time, timeout = 900_000) { // 900k ms -> 15 mins timeout - server should replay almost immediately anyway
        this.payload = payload;
        this.msg_id = msg_id;
        this.msg_time = msg_time;
        this.server_response = {}; // -> we'll later use it for storing responses
        this.promise = new Promise((resolve, reject)=> {
            this.resolve = resolve

            // automatic rejection at TIMEOUT after creation if not resolved 
            setTimeout(()=> {reject(new Error("LOG - Request timed out - ID: msg_id"))}, timeout);
        })
    }
    getTimeSent() {return this.msg_time;}
};

// initialize log for message promises 
globalThis.messagePromises_log = {}; 
   

// retrieves promise that should be awaited for resolution -> response received
function msgPromise_lookup(msg_id){

    return messagePromises_log[msg_id].promise;

};

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
function logInbound(msg_id, server_response_data){ 
   
        
    // tests if key is in log
    if (msg_id in messagePromises_log) {
        
        // save server response
        messagePromises_log[msg_id].server_response = server_response_data;
        
        // mark message as handled -> resolve its promise -> resolve await
        mark_msg_handled(msg_id);
        
        console.log(`LOG - Server response added to log - ID: ${msg_id}`);

    } else { // save it from scratch (push message)

        messagePromises_log[msg_id] = {server_response : server_response_data};

        // trigger event for handling
        server_et.dispatchEvent(new CustomEvent('new_push_message', { detail: server_response_data }));

        console.log(`LOG - Server push data added to log - ID: ${msg_id}`);

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

                globalThis.ws = new WebSocket(ws_complete_address);

                // adds event listeners 
                // ws.addEventListener('open', onOpen_handler, false); // -> directly handled here
                ws.addEventListener('message', onMessage_handler, false);
                ws.addEventListener('error', onError_handler, false); // -> let event bubble up
                ws.addEventListener('close', onClose_handler, false);

                // resolve on open
                ws.onopen = (event) => {
                    console.log(`LOG - WebSocket - connection OPEN: ${Date.now() - connection_start}ms`);
                    resolve('ws_connection_open'); // -> resolve promise
                };
                
            } catch (err) { // if connection doesn't work -> event catched by onError_handler first

                console.log(`LOG - WebSocket - something went wrong during connection`);
                ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `Sorry! The server seems unreachable at the moment` }));
                reject(err); 

            };
        };
    });
};

// close connection to WS - called when player resigns
// https://stackoverflow.com/questions/67526503/can-a-browser-execute-on-close-websocket-event-when-closing-the-browser
export function close_ws (){
    ws.close(); // close waits ~30sec and gracefully shuts doen
};


/*
// only invoked when connection is opened, we don't need anything fancy to happen at that time
function onOpen_handler (event) {
    console.log(`LOG - WebSocket - connection OPEN`);
};
*/

// dispatches incoming messages
function onMessage_handler (event) {

    console.log(`LOG - Websocket - received new message`);
    
    // parse message payload
    const server_data = JSON.parse(event.data);

    // retrieve message id (all msgs should have a msg_id anyway)
    const msg_id = server_data.msg_id;

    // save response
    logInbound(msg_id, server_data);
    
    // print it
    console.log(`TEST - Msg handler - Incoming data from server: `, server_data);

};

function onError_handler (event) {

    console.log(`LOG - Websocket - ERROR`);
    console.log(event);
    ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `< server connection error >` })); // inform user

};

function onClose_handler (event) {

    console.log(`LOG - WebSocket - connection CLOSED`);

};

///// HANDLER FOR PUSH MESSAGES FROM SERVER - only events with a specific msg code are handled
function push_messages_handler(event){
    
    // see if we have the msg_code field 
    if ( 'msg_code' in event.detail ) {

        // advance_game_OK -OR- game_resign_OK
        if ( next_ok_codes.includes(event.detail.msg_code) ) {

             // save server data -> data fn will take care of triggering event for core
             save_server_response(event.detail);
        
        } else {
            console.log("ERROR - msg_code ERROR / NOT RECOGNIZED in msg from server");
        };

    } else {
        console.log("ERROR - msg_code NOT FOUND in msg from server");
    };
};



//////////////////////////// MESSAGE SENDER (called by core)
// could be unified in single function and handle cases internally

// Send message for generating new game 
export async function server_ws_send(msg_code, msg_payload = {}){

    // check that code is among allowed ones
    const f_msg_valid = allowed_OUT_codes.includes(msg_code);

    if (f_msg_valid) {

        await init_ws(); // ensure connection is up whenever we're about to send something to the server

        try {

            // prepare message
            const _msg = {msg_code: msg_code, payload: msg_payload};
    
            // package message, log it, send it
            const [msg_time, msg_id] = fwd_outbound(_msg) // used later to recognize response and log times
            
            // wait to receive a response -> will get resolved by message handler when we receive a response
            await msgPromise_lookup(msg_id);
    
            // check server response
            const resp_code = messagePromises_log[msg_id].server_response.msg_code
            if (resp_code == msg_code.concat(sfx_CODE_OK)){ 
    
                console.log(`LOG - ${resp_code} - RTT ${Date.now()-msg_time}ms`);
                
                // save response, read from log (we already wrote the received message)
                save_server_response(messagePromises_log[msg_id].server_response);
    
            } else if (resp_code == msg_code.concat(sfx_CODE_ERR)) {
                throw new Error(`ERROR - ${resp_code} - msg ID : ${msg_id}`);

            } else {
                throw new Error(`ERROR - Unrecognized response code ${resp_code} - msg ID : ${msg_id}`);
            };

        } catch (err) {
            console.log(err);
        };

    } else {

        throw new Error(`ERROR - ${msg_code} is not a valid code`);
    };  
};



//////////////////////////// UTILS

function gen_time_id() {
    
    const msg_time = Date.now();
    const msg_id = msg_time.toString(36) // generating a time-based unique ID

    return [msg_time, msg_id]

};


// adds unique id and timestamp to messages, returns id, logs in outbound, and sends them 
function fwd_outbound(_msg){

    try{

        const [msg_time, msg_id] = gen_time_id(); // used later to recognize response and log times

        // add details to message payload -> for the server's consumption
        _msg.msg_time = msg_time;
        _msg.msg_id = msg_id;
    
        // log message that is about to be sent -> msg_id/msg_time stored separately for client's consumption
        const local_msg = new MessagePromise(_msg, msg_id, msg_time);
        try_logOutbound(local_msg);
    
        // send message
        ws.send(JSON.stringify(_msg));

        console.log(`LOG - Msg "${_msg.msg_code}" sent - msg ID: ${msg_id}`);  


        return [msg_time, msg_id];

    } catch (err){
        throw err;
    };
};


