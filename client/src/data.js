// DATA
// data objects and functions operating on them + data utils like reshape_index

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

//////////////////////////////////////////////////////////////////////////////
///// DATA FUNCTIONS (REWRITE) ////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

// from col-major julia matrix to linear index in js
const reshape_index = (row, col) => ( (col-1)*19 + row - 1); // js arrays start at 0, hence the -1 offset


// init global object / wipe all data
export function init_global_obj_y_params(){

    // init/wipe global object
    globalThis.yinsh = {};

    // write constants in -> yinsh.data.params
    init_const_parameters();
    
};

// sets IDs and values used by other functions ->  yinsh.data.params
function init_const_parameters(){

    // constant used across the game for:
    // defining rings/markers, log status, and check conditions within functions

    // init temporary object
    const _params = {};

    // note: these should come from the server as well (ids etc, so I can change them from one-side only)
    _params.ring_id =  "R";
    _params.marker_id =  "M";
    _params.player_black_id = "B";
    _params.player_white_id = "W";


        // matrix of active points on the grid
    _params.mm_points = [
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

    _params.mm_points_rows = 19;
    _params.mm_points_cols = 11;


    // save to global obj and log
    yinsh.constant_params = structuredClone(_params);
    console.log('LOG - Constant params set');

};

export function init_new_game_data(){

    const game_objs_start_time = Date.now()

    // init drawing constants -> ideally should be adjusted automatically or take parameter
    init_drawing_constants();
    
    // initialize new game with data in the server response (saved at previous step)
    init_empty_game_objects();

    // setups drop zones
    init_drop_zones();

    // init rings
    init_rings();

    // logging time 
    console.log(`LOG - All game objects initialized: ${Date.now() - game_objs_start_time}ms`);

};

// sets S and H for drawing the board and game objects -> yinsh.drawing.params
// these would be updated when a window is resied
function init_drawing_constants(){

    // init temporary object
    const _params = {};

    _params.S = 47 // defaul values, ideally should be set depending on window size
    _params.H = Math.round(47 * Math.sqrt(3)/2);


    // save to global obj and log
    yinsh.drawing_params = structuredClone(_params);
    console.log('LOG - Drawing constants set');

};

// inits/resets game objects (rings, markers, visual cues) ->  yinsh.objs.rings/markers/drop_zones/etc
function init_empty_game_objects(){

    // init temporary object
    const _game_objects = {};

    // game state
    _game_objects.game_state = Array(19*11).fill("");

    // objects on canvas
    _game_objects.rings = []; // -> array for rings
    _game_objects.markers = []; // -> array for markers
    _game_objects.drop_zones = []; // -> array for drop zones (markers and rings are placed at their coordinates only)

    // moves
    _game_objects.legal_moves_ids = []; // -> location IDs for legal moves
    _game_objects.legal_moves_cues = []; // -> array for cues paths (drawn on/off based on legal moves)
    _game_objects.current_move = {on: false, start_index: 0}; // -> details for move currently in progress 

    // score handling
    _game_objects.markers_halos = []; // -> halos around markers when scoring
        
        // NOTE: rename the keys below, I don't like them
    _game_objects.mk_sel_scoring = {ids:[], hot:false}; // -> tracking IDs of markers/halos that can be selected for finalizing the score
    _game_objects.score_handling_var = {on: false, mk_sel_array: [], num_rows: {}, details: []}; // // -> object with all scoring information, used for handling scoring scenarios


    // save to global obj and log
    yinsh.objs = structuredClone(_game_objects);
    console.log('LOG - Empty game objects initialized');

};

// saving server response data when asking for new game -> server_data.game_id/client_player_id/etc
export function save_srv_response_NewGame(srv_resp_NewGame){
    
    // init temporary object
    const _server_response = {};

    _server_response.game_id = srv_resp_NewGame.game_id; // game ID

    // assign color to local player (this client is the caller)
    _server_response.client_player_id = srv_resp_NewGame.caller_color; // player ID (B ~ Black, W ~ White)

    // initial rings locations
    _server_response.whiteRings_ids = srv_resp_NewGame.whiteRings_ids; 
    _server_response.blackRings_ids = srv_resp_NewGame.blackRings_ids;

    // pre-computed possible legal moves / now just for WHITE player, later expose as a setting?
    _server_response.next_legal_moves = srv_resp_NewGame.next_legalMoves;
    
     // save to global obj and log
     yinsh.server_data = structuredClone(_server_response);
     console.log('LOG - Server response saved');

};

// initialize drop zones -> used to propagate location data to rings, markers, and visual cues
// NOTE: sensitive to canvas size
function init_drop_zones(){

    // recovering constants
    const mm_points = yinsh.constant_params.mm_points;
    const mm_points_rows = yinsh.constant_params.mm_points_rows;
    const mm_points_cols = yinsh.constant_params.mm_points_cols;

    // recovering S & H constants for drawing
    const S = yinsh.drawing_params.S;
    const H = yinsh.drawing_params.H;

    // init temp empty array for drop zones
    let _drop_zones = [];

    // create paths for listening to click events on all intersections
    for (let j = 1; j <= mm_points_rows; j++) {
        for (let k = 1; k <= mm_points_cols; k++) {

            // using indexes 1:N for accessing the matrix
            // these indexes then become row/col coordinates for rings & markers as inherited post-snapping
            const point = mm_points[j-1][k-1];

            if (point == 1) {

                // ACTIVE POINTS COORDINATES
                // we move by x = (H * k) & y = H for each new column
                // we also move by y = S/2 in between each row (active and non-active points)
                
                const apoint_x = H * k - H/3; // H/3 adj factor to slim margin left to canvas
                const apoint_y = H + S/2 * (j-1); // S/2 shift kicks in only from 2nd row
                
                // create paths and add them to the global array
                let d_zone_path = new Path2D();
                    d_zone_path.arc(apoint_x, apoint_y, S*0.35, 0, 2*Math.PI);

                // create temporary object, loc/index data is in a nested object
                const d_zone = {path: d_zone_path, 
                                loc: {
                                    x: apoint_x, 
                                    y: apoint_y, 
                                    m_row: j, 
                                    m_col: k, 
                                    index: reshape_index(j,k)
                                    }
                                };

                // push object to temp array
                _drop_zones.push(d_zone);

            };
        };
    };


    // save to global obj and log (for some reason structuredClone fails)
    yinsh.objs.drop_zones = _drop_zones;
    console.log('LOG - Drop zones initialized')
    
};

// initializes rings and updates game state -> reads from rings data in DB
function init_rings(){

    // initial locations of rings from server
    const whiteRings_ids = yinsh.server_data.whiteRings_ids; 
    const blackRings_ids = yinsh.server_data.blackRings_ids;

    // constants used in logic
    const ring_id = yinsh.constant_params.ring_id;
    const player_black_id = yinsh.constant_params.player_black_id;
    const player_white_id = yinsh.constant_params.player_white_id;

    // init temporary rings array
    let _rings_array = [];
    // retrieve game state
    let _game_state = yinsh.objs.game_state;

    // retrieve drop_zones
    const drop_zones = yinsh.objs.drop_zones;
    
    // INITIALIZE RINGS
    // loop over drop zones and init rings in matching their loc indexes
    // note: we could get a single array from the server? there shouldn't be code repetition
    for (const d_zone of drop_zones){

        let index_match_flag = false; // use this to minimze loops
        let player_to_write = "" // keep track of which player/color we're writing
        
        // loop and match over WHITE rings ids first 
        for (const index of whiteRings_ids) {
            if (index == d_zone.loc.index){

                index_match_flag = true; // at this drop zone we'll place a white ring
                player_to_write = player_white_id;
            };
        };

        // loop and match over BLACK rings
        // skip check on this drop_zone if we already found a white ring
        if (!index_match_flag) {
            for (const index of blackRings_ids) {
                if (index == d_zone.loc.index){

                    index_match_flag = true; // at this drop zone we'll place a white ring
                    player_to_write = player_black_id;
                };
            };
        };
        
        // save ring object if match found
        if (index_match_flag){
        
            // create ring object
            const ring = {  path: {}, //  will hold the path, filled in by drawing function
                            loc: structuredClone(d_zone.loc), // pass as value -> we'll change the x,y for drawing and not mess the original drop zone
                            type: ring_id, 
                            player: player_to_write
                        };            
    
            // add to temporary array
            _rings_array.push(ring); 

                
            // update game state
            _game_state[ring.loc.index] = ring.type.concat(ring.player); // -> RB, RW at index
            
        };
        
        // continue iteration

    };

    // save rings, updated game state, and log
    yinsh.objs.game_state = structuredClone(_game_state);
    yinsh.objs.rings = structuredClone(_rings_array);
    
    console.log('LOG - Rings initialized & game state updated');

};




////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

