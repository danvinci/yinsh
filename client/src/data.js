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
export function init_global_obj_params(){

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

    // setups drop zones
    init_drop_zones();

    // init rings (uses data from server)
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
export function init_empty_game_objects(){

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
        _game_objects.current_move = {in_progress: false, start_index: 0}; // -> details for move currently in progress 

        // score handling
        _game_objects.markers_halos = []; // -> halos around markers when scoring
            
            // NOTE: rename the keys below, I don't like them
        _game_objects.mk_sel_scoring = {ids:[], hot:false}; // -> tracking IDs of markers/halos that can be selected for finalizing the score
        _game_objects.score_handling_var = {in_progress: false, mk_sel_array: [], num_rows: {}, details: []}; // // -> object with all scoring information, used for handling scoring scenarios


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
        _server_response.client_player_id = srv_resp_NewGame.caller_color; // player ID (B ~ Black, W ~ White), one of player_black_id / player_white_id 

        // initial rings locations
        _server_response.whiteRings_ids = srv_resp_NewGame.whiteRings_ids; 
        _server_response.blackRings_ids = srv_resp_NewGame.blackRings_ids;

        // pre-computed possible legal moves / now just for WHITE player, later expose as a setting?
        _server_response.next_legal_moves = srv_resp_NewGame.next_legalMoves;
    
    // save to global obj and log
    yinsh.server_data = structuredClone(_server_response);
    console.log('LOG - Server response saved');
    
    console.log(`LOG - You're player ${_server_response.client_player_id}`);

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
    const _drop_zones = yinsh.objs.drop_zones;
    
    // INITIALIZE RINGS
    // loop over drop zones and init rings in matching their loc indexes
    // note: we could get a single array from the server? there shouldn't be code repetition
    for (const d_zone of _drop_zones){

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


// function to update the game state array at specific arrays
// to minimize copies when doing lots of updates, some functions replicate the same functionality
export function update_game_state(index, value){

    // retrieves current game state
    let _game_state = structuredClone(yinsh.objs.game_state);

    // edits it
    _game_state[index] = value;

    // writes it back in
    yinsh.objs.game_state = _game_state

};

// keeps up to date the array of visual cues for legal moves
// retrieves legal moves from server data (possible legal moves are pre-computed before each turn)
export function init_legal_moves_cues(start_index){

    // assumes valid start_index -> no input checks done
   
    // retrieves ids of legal moves
    // possible legal moves look like this {start_id_1 -> [lm 1, lm2, lm3], start_id_2 -> [lm 1, lm2, lm3], etc}
    const _legal_moves_ids = structuredClone(yinsh.server_data.next_legal_moves[start_index]);

    // inits empty cues array
    let _legal_cues = [];
    
        if (_legal_moves_ids.length > 0) {

            // retrieve drop_zones & S parameter
            const _drop_zones = yinsh.objs.drop_zones;
            const S = yinsh.drawing_params.S;

            // for each linear id of the legal moves
            for (const id of _legal_moves_ids) {

                // let's check which is the matching drop_zone and retrieve the matching (x,y) coordinates
                for(const d_zone of _drop_zones){
                    
                    if (d_zone.loc.index == id){

                        // create shape + coordinates and push to array
                        let cue_path = new Path2D()
                            cue_path.arc(d_zone.loc.x, d_zone.loc.y, S*0.1, 0, 2*Math.PI);
                        
                        _legal_cues.push({path: cue_path});
                
                    };
                };        
            };
        };

    // saves/overwrites updated array of visual cues and logs operation
    yinsh.objs.legal_moves_cues = _legal_cues;
    
    console.log('LOG - Cues for legal moves updated');
        
};


// adds marker -> called when ring is picked, can only add one marker per time
export function add_marker(ref_loc_object){ // input should be copy of loc from drop zone (?)

    // retrieve current player and id for markers
    const _player_id = structuredClone(yinsh.server_data.client_player_id);
    const _marker_id = structuredClone(yinsh.constant_params.marker_id);

    // retrieve array of markers 
    let _markers = structuredClone(yinsh.objs.markers);
    
    // instate new marker object 
    const m = { path: {}, // <- to be filled in at drawing time
                loc: structuredClone(ref_loc_object),
                type: _marker_id, 
                player: _player_id 
            }; 
          
    // add to temp array and to global object
    _markers.push(m);  
    yinsh.objs.markers = _markers;
    
    // update game state and log change
    update_game_state(m.loc.index, m.type.concat(m.player)); // -> MB, MW at index
    console.log(`LOG - Marker ${m.player} added at index ${m.loc.index}`);
        
};


// removes markers -> called when ring dropped in same location or scoring row is selected
function remove_markers(mk_indexes_array){ // input is array of loc indexes

    // retrieve array of markers and latest game_state
    const _markers = structuredClone(yinsh.objs.markers);
    let _game_state = structuredClone(yinsh.objs.game_state);

    // filters and updates global object
    yinsh.objs.markers = _markers.filter(m => !mk_indexes_array.includes(m.loc.index));

    // cleans game_state copy at selected indexes and updates global object
    mk_indexes_array.forEach(index => _game_state[index]='');
    yinsh.objs.game_state = _game_state
    
    console.log(`LOG - Marker(s) removed from indexes: ${mk_indexes_array}`);

};
    



// flips markers (swaps player for objects & updates game state)
function flip_markers(mk_indexes_array){

    // retrieve consts for player ids and marker type
    const _player_black_id = structuredClone(yinsh.constant_params.player_black_id);
    const _player_white_id = structuredClone(yinsh.constant_params.player_white_id);

    // retrieve array of markers and latest game_state
    let _markers = structuredClone(yinsh.objs.markers);
    let _game_state = structuredClone(yinsh.objs.game_state);

        // flips markers and logs change to game state
        for (let m of _markers) {
            if (mk_indexes_array.includes(m.loc.index)) {
                
                // flips
                m.player = (m.player == _player_black_id ? _player_white_id : _player_black_id);   
                _game_state[m.loc.index] = ( _game_state[m.loc.index] == m.type.concat(_player_black_id) ? m.type.concat(_player_white_id) : m.type.concat(_player_black_id) );

            };
        };

    // updates global markers object and game state
    yinsh.objs.markers = _markers;
    yinsh.objs.game_state = _game_state;

    console.log(`LOG - Marker(s) flipped at indexes: ${mk_indexes_array}`);
    
};
    
// re-order rings array so picked ring is on top
export function rings_reordering(picked_ring_index){

    // retrieve rings data (local copy)
    let _rings = yinsh.objs.rings; // should be done with structuredClone, but it doesn't work on Path2D objects
    
    // re-order array
    _rings.push(_rings.splice(picked_ring_index,1)[0]);

    // write modified array back in
    yinsh.objs.rings = _rings;


};

    
// manipulates global variable ontaining data on current move underway
export function update_current_move(in_progress = false, start_index = 0){
    
    // editable copy
    let _current_move = structuredClone(yinsh.objs.current_move)

        // reset global variable in case of defaults
        if(in_progress == false){
            _current_move.in_progress = false;
            _current_move.start_index = 0;

        // save data if different arguments are passed
        } else if (in_progress == true){
            _current_move.in_progress = true;
            _current_move.start_index = start_index;

        };

    // save to global object
    yinsh.objs.current_move = structuredClone(_current_move);

};

// DONE
    // add_marker + remove_marker (move)
    // update_current_move (move)
    // flip_markers + update game state (next move)
    // rings re-ordering
    // update current move


// TODO
    // update_score_handling (next move)
    // update mk scoring (next move)
    // update mk halos (score handling)
    // refresh_objects (window resize)
    // when data model consolidated, serve objects operations through specialized functions (e.g. retrieve drop_zones, single/bulk update game state)
    // DEFINE GETTERS FOR USED OBJECTS -> REDUCE COUPLING (could use structuredClone for returning specific values)



////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// (OLD) DATA functions below
////////////////////////////////////





// glue function to setup new game
function init_objects(){

    // initialize drop zones
    init_drop_zones();

    // init random rings and markers
    init_rings();
    init_markers();

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

