// SERVER INTERFACE FUNCTIONS

// https://javascript.info/websocket
// https://stackoverflow.com/questions/1349404/generate-random-string-characters-in-javascript
// https://javascript.info/promise-basics



// TODO
/*
- uniform server calling functions?
- handle push case

*/

import { save_first_server_response, save_next_server_response, get_game_id, get_player_id, get_current_turn_no } from './data.js'

// how to reach endpoint
const ws_port = 6091;
const ip_address = "localhost"

///// COMMUNICATION CODES
// client -> server codes
const CODE_new_game_human = "new_game_vs_human"
const CODE_new_game_server = "new_game_vs_server"
const CODE_join_game = "join_game"
const CODE_advance_game = "advance_game" // clients asking to progress the game

// server -> client codes
const key_nextActionCode = "next_action_code"
const CODE_action_play = "play" // the other player has joined -> move
const CODE_action_wait = "wait"// the other player has yet to join -> wait 
const CODE_end_game = "end_game" // someone won

// suffixes for code response type
const sfx_CODE_OK = "_OK"
const sfx_CODE_ERR = "_ERROR"


/// EVENT TARGET + HANDLER for push messages

// inits global event target for handling push messages from server
globalThis.server_et = new EventTarget(); // <- this semicolon is very important

// event listener
server_et.addEventListener('new_push_message', push_messages_handler, false);

// event handler
function push_messages_handler(event){
    
    // see if we have the field 
    if ( key_nextActionCode in event.detail ) {

        // advance_game_OK
        if (event.detail.msg_code == CODE_advance_game.concat(sfx_CODE_OK)) {

            console.log('TEST - push event triggered')

             // save data + trigger event towards core
            _handler_next_action_data(event.detail);

        };

    } else {
        console.log("LOG - Action code not found or error");
    };
};


// custom class for managing the lifecycle of messages
class MessagePromise {
    constructor(payload, msg_id, msg_time, timeout = 120000) {
        this.payload = payload;
        this.msg_id = msg_id;
        this.msg_time = msg_time;
        this.server_response = {}; // -> we'll later use it for storing responses
        this.promise = new Promise((resolve, reject)=> {
            this.resolve = resolve

            // automatic rejection 120s after creation if not resolved 
            setTimeout(()=> {reject(new Error("LOG - Request timed out - ID: msg_id"))}, timeout);
        })
    }
    getTimeSent() {return this.msg_time;}
};

// initialize log for message promises 
globalThis.messagePromises_log = {}; 
   

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

    console.log(`LOG - Websocket - received new message`);
    
    // parse message payload
    const server_data = JSON.parse(event.data);

    // retrieve message id (all msgs should have a msg_id anyway)
    const msg_id = server_data.msg_id;

    // save response
    logInbound(msg_id, server_data);
    
    // print it
    console.log(server_data);

};



function onError_handler (event) {

    console.log(`LOG - Websocket - ERROR`);
    console.log(event);

};

function onClose_handler (event) {

    console.log(`LOG - WebSocket - connection CLOSED - `, event.reason);

};





//////////////////////////// MESSAGE SENDERS (called by core)
// could be unified in single function to handle cases/dispatch

// Send message for generating new game 
export async function server_ws_genNewGame(){
    
    try {

        // prepare message payload
        const msg_code = CODE_new_game_human;
        const payload = {msg_code: msg_code};

        // package message, log it, send it
        const [msg_time, msg_id] = fwd_outbound(payload) // used later to recognize response and log times
        
        // wait to receive a response
        // -> will get resolved by message handler when we receive a response
        await msgPromise_lookup(msg_id);

        // check server response
        const resp_code = messagePromises_log[msg_id].server_response.msg_code
        if (resp_code == msg_code.concat(sfx_CODE_OK)){ // these codes could be shared by the server on first connection

            console.log(`LOG - ${resp_code} - RTT ${Date.now()-msg_time}ms`);
            
            // save response in dedicate objects
            save_first_server_response(messagePromises_log[msg_id].server_response);

        } else {
            throw new Error(`LOG - ${msg_code} error - msg ID : ${msg_id}`);
        };

    } catch (err) {

        console.log(err);

    };
};


// Send message for generating new game 
export async function server_ws_joinWithCode(input_game_id){
    
    try {

        // prepare message payload
        const msg_code = CODE_join_game;
        const payload = {msg_code: msg_code, game_id: input_game_id};

        // package message, log it, send it
        const [msg_time, msg_id] = fwd_outbound(payload)
                            
        // wait to receive a response
        await msgPromise_lookup(msg_id);
        
        // check server response
        const resp_code = messagePromises_log[msg_id].server_response.msg_code
        if (resp_code == msg_code.concat(sfx_CODE_OK)){

            // save response (as joiner) in dedicate objects
            save_first_server_response(messagePromises_log[msg_id].server_response, true);
            
            // log time
            console.log(`LOG - ${resp_code} - RTT ${Date.now()-msg_time}ms`);
       
        } else {
            
            throw new Error(`LOG - ${msg_code} error - msg ID : ${msg_id}`);
        };
        

    } catch (err) {

        console.log(err);

    };
};


// Send message for generating new game 
export async function server_ws_genNewGame_AI(){
    
    try {

        // prepare message payload
        const msg_code = CODE_new_game_server;
        const payload = {msg_code: msg_code};

        // package message, log it, send it
        const [msg_time, msg_id] = fwd_outbound(payload) // used later to recognize response and log times
        
        // wait to receive a response
        // -> will get resolved by message handler when we receive a response
        await msgPromise_lookup(msg_id);

        // check server response
        const resp_code = messagePromises_log[msg_id].server_response.msg_code
        if (resp_code == msg_code.concat(sfx_CODE_OK)){ // these codes should be shared by the server on first connection

            console.log(`LOG - ${resp_code} - RTT ${Date.now()-msg_time}ms`);
            
            // save response in dedicate objects
            save_first_server_response(messagePromises_log[msg_id].server_response);

        } else {
            throw new Error(`LOG - ${msg_code} error - msg ID : ${msg_id}`);
        };

    } catch (err) {

        console.log(err);

    };
};

// Send message asking the server what to do (wait or move?)
export async function server_ws_advance_game(scenario_pick = false){
    
    try {

        // prepare message payload
        const msg_code = CODE_advance_game;
        const payload = {msg_code: msg_code, game_id: get_game_id(), player_id: get_player_id(), scenario_pick: scenario_pick};

        // package message, log it, send it
        const [msg_time, msg_id] = fwd_outbound(payload)
                            
        // wait to receive a response
        await msgPromise_lookup(msg_id);

        const srv_response = messagePromises_log[msg_id].server_response;
        const resp_code = srv_response.msg_code;
        
        // check server response
        if (resp_code == msg_code.concat(sfx_CODE_OK)){

            // log server response             
            console.log(`LOG - Server response:`, srv_response);
            console.log(`LOG - ${resp_code} - RTT ${Date.now()-msg_time}ms`);

            // handle response (save + emit event)
            _handler_next_action_data(srv_response);


        } else {
            
            throw new Error(`LOG - ${msg_code} error - msg ID : ${msg_id}`);
        };
        

    } catch (err) {

        console.log(err);

    };
};


///// UNIFY CALLS TO SERVER INTO SINGLE FUNCTION - WORK WITH CODES/DATA FROM CORE (?)

function _handler_next_action_data(server_response_data) {

    // save/overwrite data only if we have turn information data (eg. turn_no key)
    if ("turn_no" in server_response_data) {

        // save server response data, but only if not push
        save_next_server_response(server_response_data);

    };
    
    console.log(`TEST - server response data`, server_response_data);
    console.log(`TEST - current turn number`, get_current_turn_no());

     // dispatch event for core game logic
     core_et.dispatchEvent(new CustomEvent('srv_next_action', { detail: server_response_data }));

};


//////////////////////////// UTILS

function gen_time_id() {
    
    const msg_time = Date.now();
    const msg_id = msg_time.toString(36)

    return [msg_time, msg_id]

};


// adds unique id and timestamp to messages, returns id, logs in outbound, and sends them 
function fwd_outbound(payload){

    try{

        const [msg_time, msg_id] = gen_time_id(); // used later to recognize response and log times

        // add details to message payload -> for the server's consumption
        payload.msg_time = msg_time;
        payload.msg_id = msg_id;
    
        // log message that is about to be sent -> msg_id/msg_time stored separately for client's consumption
        const local_msg = new MessagePromise(payload, msg_id, msg_time);
        try_logOutbound(local_msg);
    
        // send message
        ws.send(JSON.stringify(payload));

        console.log(`LOG - Msg with code "${payload.msg_code}" sent - msg ID: ${msg_id}`);  


        return [msg_time, msg_id];

    } catch (err){
        throw err;
    };
};


// retrieves promise that should be awaited for resolution -> response received
function msgPromise_lookup(msg_id){

    return messagePromises_log[msg_id].promise;

};