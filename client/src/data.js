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
const canvas = document.getElementById('canvas'); 
const ctx = canvas.getContext('2d', { alpha: true }); 

// initialize array for markers and rings + drop zones + highlight zones
let rings = [];
let markers = [];
let drop_zones = [];
let highlight_zones = [];

let current_legal_moves = [];
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
let player_id = "";

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




// DATA functions below

// from col/row in a matrix to a linear index 
// Julia expects col-major for building a matrix from an index
// also, js arrays start at 0, hence the -1 offset
function reshape_index(row, col) { return (col-1)*19 + row -1; };

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

// initialize drop zones -> used propagate location data
function init_drop_zones(){
    
    // empty array (this function is also used for refreshing)
    drop_zones = [];

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

// initializes rings
function init_rings(){

    // pick N drop zones at random (note: it should be random)
    random_picks_ids = [15, 36, 55, 82]; // max = 85

    for (const id of random_picks_ids.values()) {
        const ref_drop_zone = drop_zones[id];   
            
        let R = {   path: {}, // needed as we check if we're clicking it
                    loc: structuredClone(ref_drop_zone.loc), // pass as value -> we'll change the x,y for drawing and not mess the original drop zone
                    type: ring_id, 
                    player: (id % 2 == 0) ? player_black_id : player_white_id 
                };            
        
        // add to array
        rings.push(R);  
                    
        // update game state and log change
        update_game_state(R.loc.index, R.type.concat(R.player)); // -> RB, RW at index
        console.log(`${R.type.concat(R.player)} init at ${R.loc.m_row}:${R.loc.m_col} -> ${R.loc.index}`);

    };
    
};

// refresh rings, markers, etc -> handling case of changes to underlying drop_zones
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