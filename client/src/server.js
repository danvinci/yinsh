// SERVER INTERFACE FUNCTIONS

// https://javascript.info/websocket
// https://stackoverflow.com/questions/1349404/generate-random-string-characters-in-javascript
// https://javascript.info/promise-basics


import { save_first_server_response } from './data.js'

const ws_port = 8092;
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

//////////////////////////// MESSAGE SENDERS (called by core)

// Send message for generating new game 
export async function server_ws_genNewGame(){
    
    try {

        // get time and generate id
        const [msg_time, msg_id] = gen_time_id(); // used later to recognize response and log times
        
        // prepare message payoload
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


// Send message for generating new game 
export async function server_ws_joinWithCode(input_game_code){
    
    try {

        // get time and generate id
        const [msg_time, msg_id] = gen_time_id(); // used later to recognize response and log times
        
        // prepare message payoload
        const payload = {msg_code: "join_game", game_code: input_game_code, msg_time: msg_time, msg_id: msg_id};
        
        // log message that is about to be sent
        const local_msg = new MessagePromise(payload, msg_id, msg_time);
        try_logOutbound(local_msg);

        // send message
        ws.send(JSON.stringify(payload));

        // end timing
        console.log(`LOG - Join game (${input_game_code}) requested, message ID: ${msg_id}`);                         

        // wait to receive a response
        // -> will get resolved by message handler when we receive a response
        await local_msg.promise;
        
        const resp_code = messagePromises_log[msg_id].server_response.msg_code
        
        if (resp_code == "join_game_ok"){

            // save response (as joiner) in dedicate objects
            save_first_server_response(messagePromises_log[msg_id].server_response, true);
            
            console.log(`LOG - Join game response received - RTT ${Date.now()-msg_time}ms`);
       
        } else {
            
            throw new Error(`LOG - Join game (${input_game_code}) error - msg ID : ${msg_id}`);
        };
        

    } catch (err) {

        console.log(`LOG - Error fulfilling join game request`);
        throw err;

    };
};



//////////////////////////// UTILS

function gen_time_id() {
    
    const msg_time = Date.now();
    const msg_id = msg_time.toString(36)

    return [msg_time, msg_id]

};