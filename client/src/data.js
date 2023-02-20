// DATA
// global data objects and functions operating on them

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

// helper function to extract array columns from matrix
function getCol(matrix, n_col){
    return matrix.map(v => v[n_col]);
}

// helper function to know how many triangles we should draw
function numTriangles(array) {
    let counter = 0;
    for (item of array.flat()) {
        if (item) {
            counter++;
        }
    }
    return counter - 1;
}

// bind canvas to variable
var canvas = document.getElementById('canvas'); 
var ctx = canvas.getContext('2d', { alpha: true }); 

// initialize array for markers and rings + drop zones + highlight zones
let rings = [];
let markers = [];
let drop_zones = [];
let highlight_zones = [];
let current_allowed_moves = [];
let current_move = {active: false, loc: {}};

// these values are used in defining rings/markers, log status, and check conditions within functions
const ring_id = "R";
const marker_id = "M";
const player_black_id = "B";
const player_white_id = "W";

// specify dimensions for the triangles in the grid
// for now outside, so they can be set depending on possible canvas size
let S = 40;
let H = Math.round(S * Math.sqrt(3)/2);


// Empty game state, string -> it will be reshaped to a matrix on the server side
let game_state = Array(19*11).fill(""); 



// DATA functions below

// from col/row in a matrix to a linear index 
// Julia expects col-major for building a matrix from an index
// also, js arrays start at 0, hence the -1 offset
function reshape_index(row, col) { return (col-1)*19 + row -1; };

// initialize drop zones -> used propagate location data
function init_drop_zones(){
    
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

// creates and destroys highlight intersection zones (for allowable moves)
function update_highlight_zones(reset = false){
// manipulates global variable of allowed moves for current ring

    // if passed true, the array will be emptied
    if (reset === true){
        highlight_zones = [];

    } else {
        // for each linear id of the allowed moves (reads from global variable)
        for (const id of current_allowed_moves.values()) {

            // let's check which is the matching drop_zone and retrieve the matching (x,y) coordinates
            for(let i=0; i<drop_zones.length; i++){
                if (drop_zones[i].loc.index == id) {

                    // create shape + coordinates and store in the global array
                    let h_path = new Path2D()
                    h_path.arc(drop_zones[i].loc.x, drop_zones[i].loc.y, S*0.1, 0, 2*Math.PI);
                    highlight_zones.push({path: h_path});
            
                };
            };        
        };
    }
};

// initializes rings
function init_rings(){

    // pick N drop zones at random (note: it should be random)
    random_picks_ids = [15, 36, 55, 82]; // max = 85

    for (const id of random_picks_ids.values()) {
        const ref_drop_zone = drop_zones[id];   
            
        let init_ring = {   path: {}, // needed as we check if we're clicking it
                            loc: structuredClone(ref_drop_zone.loc), // pass as value -> we'll change the x,y for drawing and not mess the original drop zone
                            type: ring_id, 
                            player: (id % 2 == 0) ? player_black_id : player_white_id 
                        };            
        
        rings.push(init_ring);  
                    
        // create and dispatch event for the ring being initiated (as if it was dropped) so that game state can be updated
        // event obsolete, we redraw state everytime anyway -> should be removed and game state calling init and not the other way around

        const ringInit_event = new CustomEvent("ring_init", { detail: init_ring });
        game_state_target.dispatchEvent(ringInit_event);
        //

    };
    
};

// initializes markers
function init_markers(){

    // pick N drop zones at random (note: it should be random)
    random_picks_ids = [18, 35, 54, 58, 77, 7, 11, 16, 19, 38, 43, 59]; // max = 85

    for (const id of random_picks_ids.values()) {
        const ref_drop_zone = drop_zones[id];   
        
        let init_marker = { loc: structuredClone(ref_drop_zone.loc),
                            type: marker_id, 
                            player: (id % 2 == 0) ? player_black_id : player_white_id 
                        };            
        
        markers.push(init_marker);  
                    
        // create and dispatch event for the marker being initiated (as if it was dropped) so that game state can be updated
        // event obsolete, we redraw state everytime anyway -> should be removed and game state calling init and not the other way around
        const markInit_event = new CustomEvent("marker_init", { detail: init_marker });
        game_state_target.dispatchEvent(markInit_event);
        //

    };
};

// flips markers (changes their player)
function flip_markers(markers_to_flip){
// works with linear index instead of row/col

    for (const marker of markers.values()) {
        if (markers_to_flip.includes(marker.loc.index)) {

            marker.player = (marker.player == player_black_id ? player_white_id : player_black_id);   
            
        };
    
    };
};

// adds marker -> called when ring is picked
function add_marker(loc = {}, player = ""){
// this is just for adding a new marker when a ring is picked             

    // handling locations should be reduced to a single (nested) object
    let init_marker = { loc: loc, 
                        type: marker_id, 
                        player: player 
                    };            
    
    markers.push(init_marker);  
                
    // create and dispatch event for the marker being initiated (as if it was dropped) so that game state can be updated
    const markInit_event = new CustomEvent("marker_init", { detail: init_marker });
    game_state_target.dispatchEvent(markInit_event);
        
};

// removes markers -> called when ring dropped in same location
function remove_marker(mk_index){
// this is just for removing a marker when a ring is dropped in the same location
// could be reused for removing markers when scoring
    
    // we have to find the marker with the matching index and remove it
    for (let i=0; i<markers.length; i++){
        if (markers[i].loc.index == mk_index){
            
            markers.splice(i, 1);
            break; // we're supposed to only find one marker
        };
    };
        
};

// resets global variable of current move data
function reset_current_move(){
    // reset global variable for the current move
    current_move.active = false;
    current_move.loc = {};
};



