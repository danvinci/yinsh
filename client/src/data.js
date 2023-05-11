import { set, get } from "idb-keyval";

// DATA
// global data objects and functions operating on them + utils like reshape_index

// matrix of active points on the grid
const mm_points = [
    [0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0], 
    [0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0], 
    [0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0], 
    [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
    [0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0], 
    [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
    [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1], 
    [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
    [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1], 
    [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
    [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1], 
    [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
    [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1], 
    [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
    [0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0], 
    [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
    [0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0], 
    [0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0], 
    [0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0] 
    ];

const mm_points_rows = 19 // mm_points.length;
const mm_points_cols = 11 // mm_points[0].length;

// bind canvas to variable
//const canvas = document.getElementById('canvas'); 
//const ctx = canvas.getContext('2d', { alpha: true }); 

// initialize array for markers and rings + drop zones + highlight zones
let rings = [];
let markers = [];
let drop_zones = [];
let highlight_zones = [];

let current_legal_moves = []; // used when server pinged at ring pick
let next_legal_moves = {}; // used when receiving the lock, pre-computed by the server {ring_id => [id, id, id, ...]}

let current_move = {on: false, start_index: null};

let mk_halos = [];
let mk_sel_scoring = {ids:[], hot:false} // -> used for drawing support, stores last request sent 
let score_handling_var = {on: false, mk_sel_array: [], num_rows: {}, details: []}; // -> used for handling scoring scenarios

// these values are used in defining rings/markers, log status, and check conditions within functions
const ring_id = "R";
const marker_id = "M";
const player_black_id = "B";
const player_white_id = "W";

// storing details for current game => updated with response from server
let game_id = "";
let client_player_id = "";

// Empty game state, string -> reshaped to a matrix on the server
let game_state = Array(19*11).fill(""); 

// specify dimensions for the triangles in the grid
// for now outside, so they can be set depending on possible canvas size
let S = 47;
let H = Math.round(S * Math.sqrt(3)/2);


// function to edit S & H
function update_sizing(win_height, win_width) {

    // copy values -> these may change and ref should take into account UI elements
    // note: canvas should be resized first, S & H from there
    let ref_height = win_height
    let ref_width = win_width
   
    // compute S_h and S_w (H) taking into account height and width respectively
    // use the smaller one
    let opt_S_Height = Math.round(ref_height/11.5);

    let opt_H_Width = Math.round(ref_width/11.5);
    let opt_S_Width = Math.round(opt_H_Width / (Math.sqrt(3)/2));
    
    S = Math.min(opt_S_Width, opt_S_Height);
    H = Math.round(S * Math.sqrt(3)/2);

    // update canvas sizing -> note: this should be aware of UI elements on screen
    canvas.height = win_height;
    canvas.width = win_width;

};

////////////////////////////////////////// 
//////////////// DATA FUNCTIONS (REWRITE)
//////////////////////////////////////////

// from col-major julia matrix to linear index in js
const reshape_index = (row, col) => ((col-1)*19 + row -1); // js arrays start at 0, hence the -1 offset

// sets IDs and values used by other functions
export async function init_game_constants(){

    // I should use setMany and getMany !

    // constant used across the game for:
    // defining rings/markers, log status, and check conditions within functions
    
    const s1 = set("ring_id", "R")
    const s2 = set("marker_id", "M")
    const s3 = set("player_black_id", "B")
    const s4 = set("player_white_id", "W")

    // matrix of active points on the grid
    const mm_points = [
        [0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0], 
        [0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0], 
        [0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0], 
        [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
        [0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0], 
        [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1], 
        [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1], 
        [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1], 
        [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
        [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1], 
        [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
        [0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0], 
        [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], 
        [0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0], 
        [0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0], 
        [0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0] 
        ];

    const s5 = set("mm_points", mm_points) // matrix used for drawing game board
    const s6 = set("mm_points_rows", 19)
    const s7 = set("mm_points_cols", 11)

    await Promise.allSettled([s1, s2, s3, s4, s5, s6, s7]).then(()=> console.log('LOG - Game constants initialized'));

};

// sets S and H for drawing the board and game objects
async function init_drawing_constants(){

    // constants for drawing on canvas
    const s1 = set("S", 47);
    const s2 = set("H", Math.round(47 * Math.sqrt(3)/2)); 

    await Promise.allSettled([s1, s2]).then(()=> console.log('LOG - Drawing constants set'));

};

// inits/resets game objects (rings, markers, visual cues)
async function init_empty_game_objects(){

    // game state
    const s1 = set("game_state", Array(19*11).fill(""))

    // objects
    const s2 = set("rings", [])  // -> array for rings
    const s3 = set("markers", []) // -> array for markers
    const s4 = set("drop_zones", []) // -> array for drop zones (markers and rings are placed at their coordinates only)
    const s5 = set("highlight_zones", []) // -> array for highlight_zones (drawn on/off based on legal moves)

    // moves
    const s6 = set("current_legal_moves", []) // -> location IDs for legal moves
    const s7 = set("current_move", {on: false, start_index: null}) // -> details for move currently in progress 

    // scoring 
    const s8 = set("mk_halos", []) // -> halos around markers when scoring
    const s9 = set("mk_sel_scoring", {ids:[], hot:false}) // -> tracking IDs of markers/halos that can be selected for finalizing the score
    const s10 = set("score_handling_var", {on: false, mk_sel_array: [], num_rows: {}, details: []}) // // -> object with all scoring information, used for handling scoring scenarios


    await Promise.allSettled([s1, s2, s3, s4, s5, s6, s7, s8, s9, s10]).then(() => console.log('LOG - Empty game objects initialized'));


};

// dedicated function for saving server response data when asking for new game
export async function save_srv_response_NewGame(srv_resp_NewGame){
    
    // SAVE data to indexedDB via idb-keyval library
    const s1 = set("game_id", srv_resp_NewGame.game_id) // game ID

    // assign color to local player (this client is the caller)
    const s2 = set("client_player_id", srv_resp_NewGame.caller_color); // player ID (B ~ Black, W ~ White)

    // save initial rings locations
    const s3 = set("whiteRings_locs", srv_resp_NewGame.whiteRings_ids); 
    const s4 = set("blackRings_locs", srv_resp_NewGame.blackRings_ids);

    // save pre-computed possible legal moves / now just for WHITE player, later expose as a setting?
    const s5 = set("next_legal_moves", srv_resp_NewGame.next_legalMoves);
    
    await Promise.allSettled([s1, s2, s3, s4, s5]).then(() => console.log('LOG - SRV response saved'));

};

// initialize drop zones -> used to propagate location data to rings, markers, and visual cues
// depends on canvas size !
async function init_drop_zones(){
    
    // empty array
    const drop_zones = await get("drop_zones");

    // recovering constants -> maybe they can be retrieved in parallel and all awaited later?
    const mm_points = await get("mm_points");
    const mm_points_rows = await get("mm_points_rows");
    const mm_points_cols = await get("mm_points_cols");

    // recovering S & H constants for drawing
    const H = await get("H");
    const S = await get("S");

    // create paths for listening to click events on all intersections
    for (let j = 1; j <= mm_points_rows; j++) {
        for (let k = 1; k <= mm_points_cols; k++) {

            // using indexes 1:N for accessing the matrix
            // these indexes then become row/col coordinates for rings & markers as inherited post-snapping
            let point = mm_points[j-1][k-1];

            if (point == 1) {

                // ACTIVE POINTS COORDINATES
                // we move by x = (H * k) & y = H for each new column
                // we also move by y = S/2 in between each row (active and non-active points)
                
                let apoint_x = H * k - H/3; // H/3 adj factor to slim margin left to canvas
                let apoint_y = H + S/2 * (j-1); // S/2 shift kicks in only from 2nd row
                
                // create paths and add them to the global array
                let drop_path = new Path2D()
                drop_path.arc(apoint_x, apoint_y, S*0.35, 0, 2*Math.PI);

                // all location data is in a nested object
                drop_zones.push({   path: drop_path, 
                                    loc: {
                                        x: apoint_x, 
                                        y: apoint_y, 
                                        m_row: j, 
                                        m_col: k, 
                                        index: reshape_index(j,k)
                                        }
                                });

            }
        }
    }

    const s1 = set("drop_zones", drop_zones);

    await Promise.allSettled([s1]).then(() => console.log('LOG - Drop zones initialized'));

};

// initializes rings and updates game state -> reads from rings data in DB
async function init_rings(){

    // retrieve rings data from DB

        // initial locations of rings from server
        const whiteRings_locs = await get("whiteRings_locs"); 
        const blackRings_locs = await get("blackRings_locs");

        // constants used in logic
        const ring_id = await get("ring_id");
        const player_black_id = await get("player_black_id");
        const player_white_id = await get("player_white_id");

        // drop zones (already initialized)
        const drop_zones = await get("drop_zones");

        const temp_rings_array = await get("rings");
        const temp_game_state = await get("game_state");


    // INITIALIZE RINGS
    // loop over drop zones and init rings in matching their loc indexes
    // note: we could get a single array from the server? there shouldn't be code repetition
    for (const d_zone of drop_zones){
        
        // loop and match over WHITE rings
        for (const ring_loc_index of whiteRings_locs) {
            
            let white_found_flag = false; // use this to minimze loops
            if (ring_loc_index == d_zone.loc.index){
                
                white_found_flag = true;

                const ring = {  path: {}, //  will hold the shape + we also use the shape for interaction checks
                                loc: structuredClone(d_zone.loc), // pass as value -> we'll change the x,y for drawing and not mess the original drop zone
                                type: ring_id, 
                                player: player_white_id
                            };            
        
                // add to temporary array
                temp_rings_array.push(ring);  
                    
                // update game state and log change
                temp_gs_value = ring.type.concat(ring.player); // -> RB, RW at index
                temp_game_state[ring.loc.index] = temp_gs_value
                
                // log to console
                console.log(`LOG - ${temp_gs_value} init at row ${ring.loc.m_row} / col ${ring.loc.m_col} -> ${ring.loc.index}`);
            };
        };

        // loop and match over BLACK rings - only if white not found
        if (!white_found_flag) {
            for (const ring_loc_index of blackRings_locs) {
                
                if (ring_loc_index == d_zone.loc.index){
                    
                    const ring = {  path: {}, //  will hold the shape + we also use the shape for interaction checks
                                    loc: structuredClone(d_zone.loc), // pass as value -> we'll change the x,y for drawing and not mess the original drop zone
                                    type: ring_id, 
                                    player: player_black_id
                                };            
            
                    // add to temporary array
                    temp_rings_array.push(ring);  
                        
                    // update game state and log change
                    temp_gs_value = ring.type.concat(ring.player); // -> RB, RW at index
                    temp_game_state[ring.loc.index] = temp_gs_value
                    
                    // log to console
                    console.log(`LOG - ${temp_gs_value} init at row ${ring.loc.m_row} / col ${ring.loc.m_col} -> ${ring.loc.index}`);
                };
            };
        };
    };

    // save temp ring and game_state arrays
    const s1 = set("game_state", temp_game_state);
    const s2 = set("rings", temp_rings_array);

    await Promise.allSettled([s1, s2]).then(() => console.log('LOG - Rings initialized'));
    
};

export async function init_new_game_data(){

    // init drawing constants -> ideally should be adjusted automatically or take parameter
    await init_drawing_constants();
    
    // initialize new game with data in the server response (saved at previous step)
    await init_empty_game_objects();

    // setups drop zones
    await init_drop_zones();

    // init rings
    await init_rings();


};

////////////////////////////////////
////////////////////////////////////
// (OLD) DATA functions below
////////////////////////////////////

// function to write to the game state array
function update_game_state(index, value){
    // there should be some input arguments check

    game_state[index] = value;

};

// glue function to setup new game
function init_objects(){

    // initialize drop zones
    init_drop_zones();

    // init random rings and markers
    init_rings();
    init_markers();

};

// creates and destroys highlights on intersection zones for legal moves
function update_highlight_zones(){
// manipulates global variable of legal moves for current ring

    if (current_legal_moves.length > 0) {
    
        // empty array (to handle refreshes)
        highlight_zones = [];

        // for each linear id of the legal moves (reads from global variable)
        for (const id of current_legal_moves.values()) {

            // let's check which is the matching drop_zone and retrieve the matching (x,y) coordinates
            for(let i=0; i<drop_zones.length; i++){
                if (drop_zones[i].loc.index == id){

                    // create shape + coordinates and store in the global array
                    let h_path = new Path2D()
                    h_path.arc(drop_zones[i].loc.x, drop_zones[i].loc.y, S*0.1, 0, 2*Math.PI);
                    highlight_zones.push({path: h_path});
            
                };
            };        
        };

    // case of empty array of legal moves
    } else {

        highlight_zones = [];

    };
    
};

function update_mk_sel_scoring(input_ids = [], hot_flag = false){
    
    mk_sel_scoring.ids = input_ids;
    mk_sel_scoring.hot = hot_flag;

};

// creates and destroys highlight around markers for row selection/highlight in scoring
function update_mk_halos(){
    // manipulates global variable 

    // empty variable every time before rebuilding it
    mk_halos = [];
        
    if (mk_sel_scoring.ids.length > 0) {
        // for each linear id 
        for (const id of mk_sel_scoring.ids.values()) {

            // let's check which is the matching drop_zone and retrieve the matching (x,y) coordinates
            for(let i=0; i<drop_zones.length; i++){
                if (drop_zones[i].loc.index == id) {

                    // create shape + coordinates and store in the global array
                    let h_path = new Path2D()
                    h_path.arc(drop_zones[i].loc.x, drop_zones[i].loc.y, S*0.33, 0, 2*Math.PI);
            
                    mk_halos.push({path: h_path, hot_flag: mk_sel_scoring.hot});
            
                };
            };  
        };      
    };
 };



// refresh rings, markers, legal moves, and markers halos -> handling case of changes to underlying drop_zones
function refresh_objects(){

    // iterate over all the drop zones
    for (const drop_zone of drop_zones.values()){

        // check rings
        for (let i=0; i<rings.length; i++){
            if (rings[i].loc.index == drop_zone.loc.index){

                // update location of ring
                rings[i].loc = structuredClone(drop_zone.loc);

            };
        };
    
        // check markers
        for (let i=0; i<markers.length; i++){
            if (markers[i].loc.index == drop_zone.loc.index){

                // update location of ring
                markers[i].loc = structuredClone(drop_zone.loc);

            };
        };
    

        // refresh highlight zones (in case move is in progress)
        update_highlight_zones();

        // updates markers' halos (score handling)
        update_mk_halos();

    };
};


// initializes markers
function init_markers(){

    // pick N drop zones at random (note: it should be random)
    random_picks_ids = [18, 35, 54, 58, 77, 7, 11, 16, 19, 38, 43, 59]; // max = 85

    for (const id of random_picks_ids.values()) {
        const ref_drop_zone = drop_zones[id];   
        
        let M = {   path: {},
                    loc: structuredClone(ref_drop_zone.loc),
                    type: marker_id, 
                    player: (id % 2 == 0) ? player_black_id : player_white_id 
                };            
        
        // add to array
        markers.push(M);  

        // update game state and log change
        update_game_state(M.loc.index, M.type.concat(M.player)); // -> MB, MW at index
        console.log(`${M.type.concat(M.player)} init at ${M.loc.m_row}:${M.loc.m_col} -> ${M.loc.index}`);

    };
};

// destroys objects (both global variables and array of objects to draw)
function destroy_objects(){

    // game state
    game_state = Array(19*11).fill(""); 

    // objects
    rings = [];
    markers = [];
    highlight_zones = [];

    // moves
    current_legal_moves = [];
    current_move = {on: false, start_index: null};

    // scoring 
    mk_halos = [];
    mk_sel_scoring = {ids:[], hot:false}
    score_handling_var 


};



// flips markers (changes player of game objects)
function flip_markers(markers_to_flip){
// works with linear index 

    for (const marker of markers.values()) {
        if (markers_to_flip.includes(marker.loc.index)) {

            marker.player = (marker.player == player_black_id ? player_white_id : player_black_id);   
            
        };
    
    };
};

// flips markers in game state
function flip_markers_game_state(markers_to_flip){
    // works with linear index 
    
        for (const marker_id of markers_to_flip.values()) {
            
            if (game_state[marker_id] == "MW"){ 
                
                game_state[marker_id] = "MB"
            
            } else if (game_state[marker_id] == "MB") {
                
                game_state[marker_id] = "MW"
            };
        
        };
    };

// adds marker -> called when ring is picked
function add_marker(loc = {}, player = ""){
// this is just for adding a new marker when a ring is picked             

    let M = { loc: loc, 
                type: marker_id, 
                player: player 
            };            
    
    // add to array
    markers.push(M);  

    // update game state and log change
    update_game_state(M.loc.index, M.type.concat(M.player)); // -> MB, MW at index
    console.log(`${M.type.concat(M.player)} init at ${M.loc.m_row}:${M.loc.m_col} -> ${M.loc.index}`);
        
};

// removes markers -> called when ring dropped in same location or scoring row selected
function remove_markers(mk_index_input){
// handling input as single integer end array -> if array it calls itself N times

    if (Number.isInteger(mk_index_input)){
        
        // we have to find the marker with the matching index and remove it
        for (let i=0; i<markers.length; i++){
            if (markers[i].loc.index == mk_index_input){
                
                markers.splice(i, 1);

                break; // we're supposed to only find one marker
            };
        };
            
    } else if (Array.isArray(mk_index_input)) {

        for (let i=0; i<mk_index_input.length; i++){
        
            remove_markers(mk_index_input[i]); // it calls iself!
        };

    };
};


// manipulates global variable of current move data
function update_current_move(on = false, index = null){
    
    if(on == false){
        // reset global variable for the current move
        current_move.on = false;
        current_move.start_index = null;

    } else if (on == true){
         // write data to global variable for the current move
         current_move.on = true;
         current_move.start_index = index;

    };

};


function update_score_handling(on = false, mk_sel_array = [], num_rows = {}, details = []){
    // let score_handling_var = {on: false, mk_sel_array: [], num_rows: {}, details: []};

    if (on == true){
        score_handling_var.on = true;
        score_handling_var.mk_sel_array = mk_sel_array;
        score_handling_var.num_rows = num_rows;
        score_handling_var.details = details;

    } else if (on == false){
        score_handling_var.on = false;
        score_handling_var.mk_sel_array = null;
        score_handling_var.num_rows = {};
        score_handling_var.details = [];

    };
};

