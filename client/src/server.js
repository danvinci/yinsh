// SERVER INTERFACE FUNCTIONS

// https://javascript.info/websocket
// https://stackoverflow.com/questions/1349404/generate-random-string-characters-in-javascript
// https://javascript.info/promise-basics


import { save_first_server_response, save_next_server_response, get_game_id, get_player_id } from './data.js'

const ws_port = 8090;
const ip_address = "127.0.0.1"

// custom class for managing the lifecycle of messages
class MessagePromise {
    constructor(payload, msg_id, msg_time, timeout = 100000) {
        this.payload = payload;
        this.msg_id = msg_id;
        this.msg_time = msg_time;
        this.server_response = {}; // -> we'll later use it for storing responses
        this.promise = new Promise((resolve, reject)=> {
            this.resolve = resolve

            // automatic rejection 100s after creation
            setTimeout(()=> {reject(new Error("LOG - Request timed out - ID: msg_id"))}, timeout);
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

    console.log(`LOG - Websocket - received new message`);
    
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

//////////////////////////// MESSAGE SENDERS (called by core)
// could be unified in single function to handle cases/dispatch

// Send message for generating new game 
export async function server_ws_genNewGame(){
    
    try {

        // prepare message payload
        const msg_code = 'ask_new_game';
        const payload = {msg_code: msg_code};

        // package message, log it, send it
        const [msg_time, msg_id] = fwd_outbound(payload) // used later to recognize response and log times
        
        // wait to receive a response
        // -> will get resolved by message handler when we receive a response
        await msgPromise_lookup(msg_id);

        // check server response
        const resp_code = messagePromises_log[msg_id].server_response.msg_code
        if (resp_code == msg_code.concat('_OK')){ // these codes should be shared by the server on first connection

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
        const msg_code = 'ask_join_game';
        const payload = {msg_code: msg_code, game_id: input_game_id};

        // package message, log it, send it
        const [msg_time, msg_id] = fwd_outbound(payload)
                            
        // wait to receive a response
        await msgPromise_lookup(msg_id);
        
        // check server response
        const resp_code = messagePromises_log[msg_id].server_response.msg_code
        if (resp_code == msg_code.concat('_OK')){

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
        const msg_code = 'ask_new_game_AI';
        const payload = {msg_code: msg_code};

        // package message, log it, send it
        const [msg_time, msg_id] = fwd_outbound(payload) // used later to recognize response and log times
        
        // wait to receive a response
        // -> will get resolved by message handler when we receive a response
        await msgPromise_lookup(msg_id);

        // check server response
        const resp_code = messagePromises_log[msg_id].server_response.msg_code
        if (resp_code == msg_code.concat('_OK')){ // these codes should be shared by the server on first connection

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
export async function server_ws_whatNow(scenario_pick = false){
    
    try {

        // prepare message payload
        const msg_code = 'what_now';
        const payload = {msg_code: msg_code, game_id: get_game_id(), player_id: get_player_id(), scenario_pick: scenario_pick};

        // package message, log it, send it
        const [msg_time, msg_id] = fwd_outbound(payload)
                            
        // wait to receive a response
        await msgPromise_lookup(msg_id);

        const srv_response = messagePromises_log[msg_id].server_response;
        const resp_code = srv_response.msg_code;
        
        // check server response
        if (resp_code == msg_code.concat('_OK')){

            // log server response             
            
            console.log(`LOG - Server response:`, srv_response);
            console.log(`LOG - ${resp_code} - RTT ${Date.now()-msg_time}ms`);

            // dispatch event for core game logic
            core_et.dispatchEvent(new CustomEvent('srv_next_action', { detail: srv_response }));

        } else {
            
            throw new Error(`LOG - ${msg_code} error - msg ID : ${msg_id}`);
        };
        

    } catch (err) {

        console.log(err);

    };
};


///// UNIFY CALLS TO SERVER INTO SINGLE FUNCTION - WORK WITH CODES/DATA FROM CORE (?)


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