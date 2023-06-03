// DATA
// data objects + functions operating on them + data utils (like reshape_index)


// utility function: from col-major julia matrix to linear index in js
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

    // inits visual cues for legal moves (all off by default)
    init_legal_moves_cues();

    // init rings (uses data from server)
    init_rings();

    // logging time 
    console.log(`LOG - Game objects initialized: ${Date.now() - game_objs_start_time}ms`);

};

// sets S and H for drawing the board and game objects -> yinsh.drawing.params
// these would be updated when a window is resied
function init_drawing_constants(){

    // init temporary object
    const _params = {};

    _params.S = 55 // defaul values, ideally should be set depending on window size
    _params.H = Math.round(_params.S * Math.sqrt(3)/2);


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

        // turns, moves, score handling
        _game_objects.current_turn = {in_progress: false}; // to track if this is the client's turn 
       
        _game_objects.current_move = {in_progress: false, start_index: 0, legal_drops: []}; // -> details for move currently in progress 
        _game_objects.legal_moves_cues = []; // -> array for cues paths (drawn on/off based on legal drops ids)
        
        _game_objects.current_score_handling = {in_progress: false};; // tracking if score handling is in progress
        _game_objects.markers_halos = []; // -> halos around markers when scoring

            // NOTE: revisit if these are necessary, or if temp values within functions are enough
            // score handling
            _game_objects.mk_sel_scoring = {ids:[], hot:false}; // -> tracking IDs of markers/halos that can be selected for finalizing the score
            _game_objects.score_handling_var = {in_progress: false, mk_sel_array: [], num_rows: {}, details: []}; // // -> object with all scoring information, used for handling scoring scenarios


    // save to global obj and log
    yinsh.objs = structuredClone(_game_objects);
    console.log('LOG - Empty game objects initialized');

};

// saving server response data when asking for new game -> server_data.game_id/client_player_id/etc
export function save_first_server_response(srv_response_input, joiner=false){
    
    // init temporary object
    const _server_response = {};

        _server_response.game_id = srv_response_input.game_id; // game ID

        // assign color to client (player_black_id / player_white_id)
        // if this client is joining the game, it will be the joiner
        if (joiner) {
            _server_response.client_player_id = srv_response_input.join_player_id;
            _server_response.opponent_player_id = srv_response_input.orig_player_id;  
        } else {
            _server_response.client_player_id = srv_response_input.orig_player_id; 
            _server_response.opponent_player_id = srv_response_input.join_player_id;  
        };
        
        // initial rings setup
        _server_response.rings = srv_response_input.rings; 

        // pre-computed scenario tree for each possible move (except pick/drop in same location)
        _server_response.scenarioTree = srv_response_input.scenarioTree;
    
    // save to global obj and log
    yinsh.server_data = structuredClone(_server_response);
    console.log('LOG - Server response saved');
    
    console.log(`LOG - You're player ${_server_response.client_player_id}`);

};


// saving server response data when asking for new game -> server_data.game_id/client_player_id/etc
export function save_next_server_response(srv_response_input){
    
    // init temporary object
    const _server_response = {};
        
        // new rings locations
        _server_response.whiteMarkers_ids = srv_response_input.whiteMarkers_ids; 
        _server_response.blackRings_ids = srv_response_input.blackRings_ids;

        // new markers locations
        _server_response.whiteRings_ids = srv_response_input.whiteRings_ids; 
        _server_response.blackMarkers_ids = srv_response_input.blackMarkers_ids; 

        // pre-computed scenario tree for each possible move (except pick/drop in same location)
        _server_response.scenarioTree = srv_response_input.scenarioTree;
    
    // save to global obj and log
    yinsh.next_server_data = structuredClone(_server_response);

    if (Object.keys(srv_response_input).includes('delta')) {

        yinsh.delta = structuredClone(srv_response_input.delta);

    } else {

        yinsh.delta = undefined;

    };

    console.log('LOG - Next server response saved');
    
};




export function turn_start(){
   yinsh.objs.current_turn.in_progress = true;
   console.log(`LOG - Turn started`);
};

export function turn_end(){
   yinsh.objs.current_turn.in_progress = false;
   console.log(`LOG - Turn completed`);
};

export function get_player_id () {
    return yinsh.server_data.client_player_id;
};

export function get_game_id () {
    return yinsh.server_data.game_id;
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


// initializes visual cues for legal moves (all off by default)
function init_legal_moves_cues(){

    // retrieve drop_zones & S parameter
    const _drop_zones = yinsh.objs.drop_zones;
    const S = yinsh.drawing_params.S;

    // init empty array
    let _legal_moves_cues = [];
            
        // init a cue for each drop zone
        for(const d_zone of _drop_zones){

            // create shape + coordinates and push to array
            let cue_path = new Path2D()
                cue_path.arc(d_zone.loc.x, d_zone.loc.y, S*0.1, 0, 2*Math.PI);
            
            _legal_moves_cues.push({path: cue_path, loc: structuredClone(d_zone.loc), on: false});
        
        };


    // saves/overwrites updated array of visual cues and moves for picked ring
    yinsh.objs.legal_moves_cues = _legal_moves_cues;
    
    // logs operation
    console.log('LOG - Visual cues for legal moves initialized');

}; 
        


// initializes rings and updates game state -> reads from rings data in DB
function init_rings(){

    // initial locations of rings from server
    const server_rings = yinsh.server_data.rings; 

    // constants used in logic
    const ring_id = yinsh.constant_params.ring_id;

    // init temporary rings array
    let _rings_array = [];
    // retrieve game state
    let _game_state = yinsh.objs.game_state;

    // retrieve drop_zones
    const _drop_zones = yinsh.objs.drop_zones;
    
    // INITIALIZE RINGS
    // loop and match rings over drop zones
    for (const d_zone of _drop_zones) {
        for (const s_ring of server_rings) {

            if (s_ring.id == d_zone.loc.index){

            // create ring object
            const ring = {  path: {}, //  will hold the path, filled in by drawing function
                            loc: structuredClone(d_zone.loc), // pass as value -> we'll change the x,y for drawing and not mess the original drop zone
                            type: ring_id, 
                            player: s_ring.player
                        };            

            // add to temporary array
            _rings_array.push(ring); 
                
            // update game state
            _game_state[ring.loc.index] = ring.type.concat(ring.player); // -> RB, RW at index
            
            };
        };
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

// keeps up to date the array of visual cues for legal moves, turning them on or off
// if move is NOT in progress, this function will turn them off
export function update_legal_cues(){

    // retrieves info on active move
    const move_in_progress = yinsh.objs.current_move.in_progress; // -> true/false
    const _legal_moves_ids = yinsh.objs.current_move.legal_drops; // -> [1,2,3,4,etc]

    // retrieves array of visual cues (to be modified)
    let _legal_cues = yinsh.objs.legal_moves_cues

    // turn matching cues on if a move was started
    if (move_in_progress) {

        for (let cue of _legal_cues) {
                
            if (_legal_moves_ids.includes(cue.loc.index)) { cue.on = true };
                
        };
        
    // otherwise turn everything off
    } else {

        for (let cue of _legal_cues) { cue.on = false };

    };
   
    // saves/overwrites updated array of visual cues
    yinsh.objs.legal_moves_cues = _legal_cues;
    
    // logs operation
    console.log('LOG - Visual cues updated');
        
};


// adds marker -> called when ring is picked, can only add one marker per time
// if opponent true, adds marker of the opponent's color (used for replaying moves)
export function add_marker(loc_index, as_opponent = false){ 

    // retrieve current player and id for markers
    const _player_id = structuredClone(yinsh.server_data.client_player_id);
    const _opponent_id = structuredClone(yinsh.server_data.opponent_player_id);
    const _marker_id = structuredClone(yinsh.constant_params.marker_id);


    // retrieve array of markers 
    let _markers = yinsh.objs.markers;

    // retrieve drop zones
    const _drop_zones = yinsh.objs.drop_zones;

    // get loc for matching drop zones at loc_index
    const matching_drop = _drop_zones.filter(d => (d.loc.index == loc_index))[0];

    
    // instate new marker object 
    const m = { path: {}, // <- to be filled in at drawing time
                loc: structuredClone(matching_drop.loc),
                type: _marker_id, 
                player: as_opponent ? _opponent_id : _player_id 
            }; 
          
    // add to temp array and to global object
    _markers.push(m);  
    yinsh.objs.markers = _markers;
    
    // update game state and log change
    update_game_state(m.loc.index, m.type.concat(m.player)); // -> MB, MW at index
    console.log(`LOG - Marker ${m.player} added at index ${m.loc.index}`);
        
};


// removes markers -> called when ring dropped in same location or scoring row is selected
export function remove_markers(mk_indexes_array){ // input is array of loc indexes

    // retrieve array of markers and latest game_state
    const _markers = yinsh.objs.markers;
    const _marker_id = yinsh.constant_params.marker_id;

    let _game_state = structuredClone(yinsh.objs.game_state);

    // updates global object
    yinsh.objs.markers = _markers.filter(m => !mk_indexes_array.includes(m.loc.index));

    // cleans game_state copy at selected indexes
    mk_indexes_array.forEach( (index) => {

        if (_game_state[index].includes(_marker_id)) {
            
            _game_state[index]= ''; // cleans state only if a marker is there 
        };
        
    });
    
    // updates global object
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
    
// re-order rings array so picked ring is last in the array -> on top when drawing
export function reorder_rings(picked_ring_index){

    // retrieve rings data (local copy)
    let _rings = yinsh.objs.rings; // should be done with structuredClone, but it doesn't work on Path2D objects
    
    // re-order array
    _rings.push(_rings.splice(picked_ring_index,1)[0]);

    // write modified array back in
    yinsh.objs.rings = _rings;

};

export function getIndex_last_ring(){

    return yinsh.objs.rings.length-1;
};


// update loc information for last ring in the array (picked one)
export function updateLoc_last_ring(new_loc){

    // retrieve index of last ring in array (about to drop)
    const id_dropping_ring = getIndex_last_ring();

    // save new location for last ring
    yinsh.objs.rings[id_dropping_ring].loc = structuredClone(new_loc);

};

    
// manipulates global variable ontaining data on current move underway
export function update_current_move(in_progress = false, start_index = 0){
    
    // editable copy
    let _current_move = structuredClone(yinsh.objs.current_move)

        // reset global variable in case of defaults
        if(in_progress == false){
            _current_move.in_progress = false;
            _current_move.start_index = 0;
            _current_move.legal_drops = [];

        // save data if different arguments are passed
        } else if (in_progress == true){
            _current_move.in_progress = true;
            _current_move.start_index = start_index;
            _current_move.legal_drops = getIndexes_legal_drops(start_index);

        };

    // save to global object
    yinsh.objs.current_move = structuredClone(_current_move);

};


// retrieve indexes of legal moves/drops from saved server data
function getIndexes_legal_drops(start_index){

    // keys (possible moves) are the first level of the branch for a ring
    const tree_branch = yinsh.server_data.scenarioTree[start_index];

    let _legal_drops = [];
    for (const key in tree_branch){
        _legal_drops.push(parseInt(key)); // javascript forces object keys to be strings, we need to parse them ¯\_(ツ)_/¯
    };
    
    return structuredClone(_legal_drops);

};

// DONE
    // add_marker + remove_marker (move)
    // update_current_move (move)
    // flip_markers + update game state (next move)
    // rings re-ordering
    // update current move
    // getter for ids of legal drops
    // getter for id (in array) of last ring
    // setter for updating loc of dropping ring


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

