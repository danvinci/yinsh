

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

// Audio effects
const sound = {
                "p_hpf_freq": 0.104,
                "p_duty": 0.457,
                "p_pha_offset": 0.142,
                "p_env_sustain": 0.047,
                "wave_type": 2,
                "preset": "click",
                "p_lpf_freq": 1,
                "p_env_decay": 0.467,
                "sample_size": 8,
                "p_arp_speed": 0,
                "p_vib_speed": 0,
                "p_freq_limit": 0,
                "p_vib_strength": 1,
                "p_pha_ramp": 0.526,
                "p_lpf_ramp": 0,
                "p_lpf_resonance": 0.633,
                "name": null,
                "p_base_freq": 0.348,
                "p_hpf_ramp": 0,
                "ctime": 1674601289935,
                "p_repeat_speed": 0,
                "p_freq_ramp": -0.47,
                "sound_vol": 0.25,
                "p_arp_mod": -1,
                "p_env_punch": 0.083,
                "oldParams": true,
                "p_env_attack": 0,
                "p_freq_dramp": -1,
                "sample_rate": 22050,
                "p_duty_ramp": 0.537,
                "mtime": 1674604666633
                }


// NOTE:
// pre-draw board and store it for later 


/* SAVE FOR LATER
// TAKEN FROM https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Optimizing_canvas
// Get the DPR and size of the canvas
const dpr = window.devicePixelRatio;
const rect = canvas.getBoundingClientRect();

// Set the "actual" size of the canvas
canvas.width = rect.width * dpr;
canvas.height = rect.height * dpr;

// Scale the context to ensure correct drawing operations
ctx.scale(dpr, dpr);

// Set the "drawn" size of the canvas
canvas.style.width = `${rect.width}px`;
canvas.style.height = `${rect.height}px`;
*/


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

// instatiate event target for changes to the game state
let game_state_target = new EventTarget()

// Empty game state, string -> it will be reshaped to a matrix on the server side
let game_state = Array(19*11).fill(""); 

// listens to ring drops and updates game state
game_state_target.addEventListener("ring_drop_attempt", 
    async function (evt) {

    drop_coord_loc = evt.detail;

    // check if drop coordinates are valid
    if (current_allowed_moves.includes(drop_coord_loc.index) == true){

        // the active ring is always last in the array
        id_last_ring = rings.length-1;

        // update ring loc information
        rings[id_last_ring].loc = structuredClone(drop_coord_loc);

        index = drop_coord_loc.index;
        value = rings[id_last_ring].type.concat(rings[id_last_ring].player); // -> RB, RW

        game_state[index] = value;

        console.log(`${value} dropped at ${evt.detail.m_row}:${evt.detail.m_col} -> ${index}`);

        // empty array of allowed zones
        update_highlight_zones(reset = true)

        // drop row/col
        end_row = drop_coord_loc.m_row;
        end_col = drop_coord_loc.m_col;

        // this removes the marker if the ring is dropped where picked
        // if yes, remove marker, otherwise check markers to flip and flip them
        // should be moved to separate function !!
        console.log(`Start row: ${current_move.loc.m_row}, start col: ${current_move.loc.m_col}`);
        console.log(`End row: ${end_row}, end col: ${end_col}`);

        if (end_row == current_move.loc.m_row && end_col == current_move.loc.m_col){
            
            remove_marker(index);
            console.log(`Marker removed from index: ${index}`);

        } else {

            // check if any markers needs to be flipped
            const markers_to_flip = await server_markers_check(game_state, current_move.loc.m_row, current_move.loc.m_col, end_row, end_col);
            // trigger event to other listener -> change player for marker -> update game status -> retrigger drawing 

            if (markers_to_flip != "no_markers_to_flip"){
                flip_markers(markers_to_flip);
            };

        };

        // reset global variable for the current move
        reset_current_move()

        // re-draw everything
        refresh_draw_state(); 

        // play sound
        sfxr.play(sound); 

    } else{

        console.log("Invalid drop location");
    };
});

// listens to a ring being moved -> updates ring state & redraws
game_state_target.addEventListener("ring_moved", 
    function (evt) {

        // evt.detail -> mousePos

        id_last_ring = rings.length-1;

        rings[id_last_ring].loc.x = evt.detail.x;
        rings[id_last_ring].loc.y = evt.detail.y;
        refresh_draw_state();

});


// listens to ring picks and updates game state
game_state_target.addEventListener("ring_picked", 
    async function (evt) {

    // detail contains index of picked ring in the rings array (array was already looped over once)
    id_ring_evt = evt.detail;

    // remove the element and put it back at the end of the array, so it's always drawn last => on top
    // note: splice returns the array of removed elements
    rings.push(rings.splice(id_ring_evt,1)[0]); 
    
    id_last_ring = rings.length-1; // could be computed once and stored in current_move variable
    p_ring = rings[id_last_ring];
    
    // clean game state for location
    game_state[p_ring.loc.index] = "";

    value = p_ring.type.concat(p_ring.player); // -> RB, RW, MB, MW

    console.log(`${value} picked from ${p_ring.loc.m_row}:${p_ring.loc.m_col} at -> ${index}`);

    // write start of the currently active move to a global variable
    current_move.active = true;
    current_move.loc = p_ring.loc;        

    // get allowed moves from the server
    // NOTE : allowed moves are requested considering no ring nor marker at their location (game state was wiped)
    const allowed_moves = await server_allowed_moves(game_state, p_ring.loc.m_row, p_ring.loc.m_col);

    if (allowed_moves != "no_moves"){

        // writes allowed moves to a global variable
        current_allowed_moves = allowed_moves;

        // init highlight zones
        update_highlight_zones()

    };

    // place marker in same location
    // location must be copied and not referenced -> otherwise the marker will be drawn along the ring
    add_marker(loc = structuredClone(p_ring.loc), player = p_ring.player);

    refresh_draw_state();

});


// listens to marker being initialized -> updates game state
game_state_target.addEventListener("ring_init", 
    function (evt) {

    index = evt.detail.loc.index
    value = evt.detail.type.concat(evt.detail.player); // -> RB, RW

    game_state[index] = value;
    console.log(`${value} init at ${evt.detail.loc.m_row}:${evt.detail.loc.m_col} -> ${evt.detail.loc.index}`);
    // console.log(`Rings on the board: ${rings.length}`);

    refresh_draw_state();
});

// listens to marker being initialized -> updates game state
game_state_target.addEventListener("marker_init", 
    function (evt) {

    index = evt.detail.loc.index;
    value = evt.detail.type.concat(evt.detail.player); // -> MB, MW

    game_state[index] = value;
    console.log(`${value} init at ${evt.detail.loc.m_row}:${evt.detail.loc.m_col} -> ${evt.detail.loc.index}`);
    // console.log(`Markers on the board: ${markers.length}`);

    refresh_draw_state();
});

// initialize drop zones
init_drop_zones();

// init random rings and markers
init_rings();
init_markers();

// board and initial state drawn for the first time
// this function is then called by the single events when they change the state
refresh_draw_state(); 

function refresh_draw_state(){
    
    // clears everything
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw board
    draw_board();

    // keep drop zones up
    draw_drop_zones();

    // draw highlight zones
    draw_highlight_zones();

    // Re-draw all markers and rings
    draw_markers();
    draw_rings();

}; 

    function draw_board(){

        ctx.save();
        /* RECIPE
        - get to first starting point for column
        - draw triangle, if first extra bit
            -- only if next colum is bigger
        - translate down
        - draw triangle
        - repeat
        - drawn triangle, if last extra bit 
            -- only if next colum is bigger
        - column before last, 2 vertical strokes
        - last column, 3 vertical strokes
        */

        // drawing settings
        ctx.lineJoin = "round";
        ctx.strokeStyle = '#1e52b7';
        ctx.lineWidth = 2;
        ctx.globalAlpha = 0.35;


        for (let k = 1; k <= mm_points_cols-1; k++) {
            
            // number of triangles we're expected to draw for each column
            triangle_ToDraw = numTriangles(getCol(mm_points, k-1));
            triangle_Drew = 0;

            // move right for each new column (-H/3 reduces left canvas border)
            ctx.translate(H*k - H/3, H);

            // going down the individual columns
            for (let j = 1; j <= mm_points_rows; j++) {
                
                let point = mm_points[j-1][k-1];

                // manual handling of last column 
                if (k == mm_points_cols-1 && (j == 4 || j > 13) ){point = 0;}
                

                // if point is not active just translate down
                if (point == 0) {
                    ctx.translate(0,S/2);
                
                // DRAWING LOOP!
                // draw triangle but only if we're not done drawing them all
                } else if (point == 1 && triangle_Drew < triangle_ToDraw) {
                    ctx.beginPath();
                    ctx.moveTo(0,0); // starting point for drawing
                    ctx.lineTo(0,S); // first point down
                    ctx.lineTo(H,S/2); // mid-point to the right
                    ctx.closePath(); // close shape
                    ctx.stroke();
                    triangle_Drew ++;

                    
                    // check if the next column has more triangles
                    let mustDraw_stick = triangle_ToDraw < numTriangles(getCol(mm_points, k));
                    
                    // we do this for all columns except last
                    if (mustDraw_stick && k < mm_points_cols) {

                        // first triangle bridging up
                        if (triangle_Drew == 1){
                            ctx.beginPath();
                            ctx.moveTo(0,0); 
                            ctx.lineTo(H,-S/2); 
                            //ctx.strokeStyle = "#FA5537";
                            ctx.stroke();
                            
                            //ctx.strokeStyle = colT;
                        }

                        // last triangle bridging down
                        if (triangle_Drew == triangle_ToDraw){
                            ctx.beginPath();
                            ctx.moveTo(0,S);
                            ctx.lineTo(H,S+S/2);
                            //ctx.strokeStyle = "#32CBFF";
                            ctx.stroke();
                            
                            //ctx.strokeStyle = colT; // reset color
                        }

                    }

                    // draw vertical strokes 
                    // last column, last triangle done (+2 hack as we disqualify points above)
                    if (k == mm_points_cols-1 && triangle_ToDraw == triangle_Drew + 2) {
                        // stroke down
                        ctx.beginPath();
                        ctx.moveTo(0,S); 
                        ctx.lineTo(0,2*S); 
                        //ctx.strokeStyle = "#C21313";
                        ctx.stroke();
                        
                        // stroke up
                        ctx.beginPath();
                        ctx.moveTo(0,-3*S); 
                        ctx.lineTo(0,-4*S); 
                        //ctx.strokeStyle = "#E79B33";
                        ctx.stroke();
                        
                        // stroke up
                        ctx.beginPath();
                        ctx.moveTo(H,-S*2-S/2); 
                        ctx.lineTo(H,S/2); 
                        //ctx.strokeStyle = "#C21313";
                        ctx.stroke();
                        
                        //ctx.strokeStyle = colT; // reset color 
                    }
                    
                // move down (considering last active point when drawing)
                ctx.translate(0,S/2);

            
                } // stop going down the column and drawing if you're done 
                else if ( triangle_Drew == triangle_ToDraw) {
                    break;
                }
            }
            // reset canvas transformations before moving to next column
            ctx.setTransform(1, 0, 0, 1, 0, 0);
        }
            
        ctx.restore();
    }

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

    function draw_drop_zones(){
        ctx.save();

        ctx.globalAlpha = 0; 
        //ctx.strokeStyle = "#666";
        ctx.fillStyle = "#666";
        //ctx.lineWidth = 0.5;

        for(let i=0; i<drop_zones.length; i++){
        
            ctx.fill(drop_zones[i].path); 
            //ctx.stroke(drop_zones[i].path); 
        
        };   
        
        ctx.restore();
    };


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
    
    function draw_highlight_zones(){
        ctx.save();

        ctx.globalAlpha = 1; 
        ctx.strokeStyle = "#668bd2";
        ctx.fillStyle = "#a0b5dd";
        ctx.lineWidth = 1;

        for(let i=0; i<highlight_zones.length; i++){
        
            ctx.fill(highlight_zones[i].path); 
            ctx.stroke(highlight_zones[i].path); 
            
        };        
        
        ctx.restore();
    };


    function draw_rings(){
        ctx.save();

        // reads the global rings object
        for (const s of rings.values()) {

            let inner = S*0.42;
            let ring_lineWidth = inner/3;

            // draw black ring
            if (s.player == player_black_id){ 
                
                ctx.strokeStyle = "#1A1A1A";
                ctx.lineWidth = ring_lineWidth;            
                
                let ring_path = new Path2D()
                ring_path.arc(s.loc.x, s.loc.y, inner, 0, 2*Math.PI);
                ctx.stroke(ring_path);

                // update path shape definition -> needed for rings (click within shape)
                s.path = ring_path;
        
            // draw white ring
            } else if (s.player == player_white_id){

                //inner white ~ light gray
                ctx.strokeStyle = "#F6F7F6";
                ctx.lineWidth = ring_lineWidth*0.9;            
                
                let ring_path = new Path2D()
                ring_path.arc(s.loc.x, s.loc.y, inner, 0, 2*Math.PI);
                ctx.stroke(ring_path);

                // outer border
                ctx.strokeStyle = "#000";
                ctx.lineWidth = ring_lineWidth/12; 
                
                let outerB_path = new Path2D()
                outerB_path.arc(s.loc.x, s.loc.y, inner*1.15, 0, 2*Math.PI);
                ctx.stroke(outerB_path);
                
                ring_path.addPath(outerB_path);

                // inner border
                ctx.strokeStyle = "#000";
                ctx.lineWidth = ring_lineWidth/12;  

                let innerB_path = new Path2D()
                innerB_path.arc(s.loc.x, s.loc.y, inner*0.85, 0, 2*Math.PI);
                ctx.stroke(innerB_path);

                ring_path.addPath(outerB_path);

                // update path shape definition
                s.path = ring_path;

            };
        };

        ctx.restore();
    };

    function draw_markers(){
        ctx.save();

        // reads the global markers object
        for (const s of markers.values()) {

            let inner = S*0.25;
            let marker_lineWidth = inner/5;

            // draw black marker
            if (s.player == player_black_id){ 

                ctx.fillStyle = "#1A1A1A";
                
                let marker_path = new Path2D()
                marker_path.arc(s.loc.x, s.loc.y, inner, 0, 2*Math.PI);
                ctx.stroke(marker_path);
                ctx.fill(marker_path);
        
            // draw white marker
            } else if (s.player == player_white_id){ 
                
                ctx.strokeStyle = "#000";
                ctx.fillStyle = "#F6F7F6";
                ctx.lineWidth = marker_lineWidth/2;            
                
                let marker_path = new Path2D()
                marker_path.arc(s.loc.x, s.loc.y, inner, 0, 2*Math.PI);
                ctx.stroke(marker_path);
                ctx.fill(marker_path);
        
            };
        };

        ctx.restore();
    };


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
            const ringInit_event = new CustomEvent("ring_init", { detail: init_ring });
            game_state_target.dispatchEvent(ringInit_event);

        };
        
    };

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
            const markInit_event = new CustomEvent("marker_init", { detail: init_marker });
            game_state_target.dispatchEvent(markInit_event);

        };
    };


    function flip_markers(markers_to_flip){
    // works with linear index instead of row/col
    
        for (const marker of markers.values()) {
            if (markers_to_flip.includes(marker.loc.index)) {

                marker.player = (marker.player == player_black_id ? player_white_id : player_black_id);   
                
            };
        
        };
    };
    
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

    function reset_current_move(){
        // reset global variable for the current move
        current_move.active = false;
        current_move.loc = {};
    };


// from col/row in a matrix to a linear index 
// Julia expects col-major for building a matrix from an index
// also, js arrays start at 0, hence the -1 offset
function reshape_index(row, col) { return (col-1)*19 + row -1; };

// function to return location object of closest drop zone
function closest_snap(xp, yp){

    to_return = "no_snap";

    // test which drop zone the mouse is selecting and return its center coordinates
    for(let i=0; i<drop_zones.length; i++){
        if (ctx.isPointInPath(drop_zones[i].path, xp, yp)){
            to_return = structuredClone(drop_zones[i].loc); 
            break;
        };
    };

    return to_return;

};

// CAPTURE MOUSE EVENTS AND DO SOMETHING
// https://bencentra.com/code/2014/12/05/html5-canvas-touch-events.html

let mousePos = { x:0, y:0 };
let some_var = false;
canvas.addEventListener("mousedown", 
    function (evt) {
        mousePos = getMousePos(canvas, evt);
        //console.log("down");

        // check if move currently underway
        // If not, check which ring is being picked and emit event
        if (current_move.active == false){

            // test which ring the mouse is selecting and send an event
            for(let i=0; i<rings.length; i++){
                if (ctx.isPointInPath(rings[i].path, mousePos.x, mousePos.y)){

                    // create and dispatch event for what the ring being picked up -> game state should change
                    const ringPick_event = new CustomEvent("ring_picked", { detail: i});
                    game_state_target.dispatchEvent(ringPick_event);
                    
                    break; 
                    
                };
            };

        } else {
            
            // move is active, ring drop attempt
            // check snapping (geometric) coordinates
            drop_coord_loc = closest_snap(mousePos.x, mousePos.y);
            
            // geometric check first 
            if (drop_coord_loc !== "no_snap"){

                // create and dispatch event for dropping attempt
                const ringDropAttempt_event = new CustomEvent("ring_drop_attempt", { detail: drop_coord_loc });
                game_state_target.dispatchEvent(ringDropAttempt_event);

                // game state target responsible for validity check, here we only take care of interaction

            };  
        };
    });

canvas.addEventListener("mouseup", 
    function (evt) {
        //console.log("up");
    });

canvas.addEventListener("mousemove", 
    function (evt) {
        mousePos = getMousePos(canvas, evt);
        //console.log("move");

        // if a ring is active, let's drag it -> refresh everything as you move it
        if (current_move.active == true){

            // create and dispatch event for mouse moving while move is active
            // we could listen directly to this event from the game state target, but this way SOC is explicit AND we only send an event when a move is active
            const ringMove_event = new CustomEvent("ring_moved", {detail: mousePos});
            game_state_target.dispatchEvent(ringMove_event);
            
        };

    });

// Get the position of the mouse relative to the canvas
function getMousePos(canvasDom, mouseEvent) {
var canvasRect = canvasDom.getBoundingClientRect();
return {
    x: mouseEvent.clientX - canvasRect.left,
    y: mouseEvent.clientY - canvasRect.top
};
}


// Set up touch events 
// Touch events are mapped to and dispatch mouse events, all events are handled from those!
canvas.addEventListener("touchstart", 
    function (evt) {
        //mousePos = getTouchPos(canvas, evt); //might be redundant
        let touch = evt.touches[0];
        let mouseEvent = new MouseEvent("mousedown", {
            clientX: touch.clientX,
            clientY: touch.clientY
            });
        
        canvas.dispatchEvent(mouseEvent);
    });

canvas.addEventListener("touchend", 
    function (evt) {
        let mouseEvent = new MouseEvent("mouseup", {});
        canvas.dispatchEvent(mouseEvent);
    });

canvas.addEventListener("touchmove", 
    function (evt) {
        let touch = evt.touches[0];
        let mouseEvent = new MouseEvent("mousemove", {
            clientX: touch.clientX,
            clientY: touch.clientY
        });
        canvas.dispatchEvent(mouseEvent);
    });

/* NOT SURE IF NEEDED, as we trigger the mouse evt and coordinates are adjusted already once
// Get the position of a touch relative to the canvas
function getTouchPos(canvasDom, touchEvent) {
var canvasRect = canvasDom.getBoundingClientRect();
return {
    x: touchEvent.touches[0].clientX - canvasRect.left,
    y: touchEvent.touches[0].clientY - canvasRect.top
};
}
*/


// Prevent scrolling when touching the canvas given conflict with touch/drag gestures
document.body.addEventListener("touchstart", 
    function (evt) {
        if (evt.target == canvas) {
            evt.preventDefault();
        }
    });

document.body.addEventListener("touchend", 
    function (evt) {
        if (evt.target == canvas) {
            evt.preventDefault();
        }
    });

document.body.addEventListener("touchmove", 
    function (evt) {
        if (evt.target == canvas) {
            evt.preventDefault();
        }
    });

    
// SERVER INTERFACE FUNCTIONS
port_number = "1038"

// server call for checking allowable moves 
async function server_allowed_moves(state, start_row, start_col){

    // https://stackoverflow.com/questions/48708449/promise-pending-why-is-it-still-pending-how-can-i-fix-this
    // https://stackoverflow.com/questions/40385133/retrieve-data-from-a-readablestream-object
    

    response = await fetch(`http://localhost:${port_number}/api/v1/allowed_moves`, {
        method: 'POST', // GET requests cannot have a body
        body: JSON.stringify({
                                "game_id": 'game_unique_id', 
                                "state": state, 
                                "row": start_row,
                                "col": start_col

                            })
    });

    // note: passing the state could be redundant, only game id should be necessary
    
    // get allowed moves back from the server (array)
    const srv_allowed_moves = await response.json(); // note: json() is async and must be awaited, otherwise we print the promise object itself 
    
    // parse and store allowed moves
    let allowed_moves = [];

    if (srv_allowed_moves.length > 0) {
        for (const move of srv_allowed_moves.values()) {
            // note: reshaping could be moved to the server, as well as the length check -> keep the client dumb and lean
            allowed_moves.push(reshape_index(move.I[0], move.I[1]));
        };

        console.log("Allowed moves from the server: "); console.log(allowed_moves);
        return allowed_moves;

    } else {

        console.log("no_moves");
        return "no_moves";
    };

};

// server call for checking which markers must be flipped
async function server_markers_check(state, start_row, start_col, end_row, end_col){

    response = await fetch(`http://localhost:${port_number}/api/v1/markers_check`, {
        method: 'POST', 
        body: JSON.stringify({
                                "game_id": 'game_unique_id', 
                                "state": state, 
                                "start_row": start_row,
                                "start_col": start_col,
                                "end_row": end_row,
                                "end_col": end_col

                            })
    });

    // note: passing the state could be redundant, only game id should be necessary
    
    // get markers to be flipped back from the server (array)
    const srv_markers_check = await response.json(); // note: json() is async and must be awaited, otherwise we print the promise object itself 
    
    // parse and store indexes of markers
    let markers_to_flip = [];

    if (srv_markers_check.length > 0) {
        for (const mk_index of srv_markers_check.values()) {
            // note: reshaping could be moved to the server, as well as the length check -> keep the client dumb but lean
            markers_to_flip.push(reshape_index(mk_index.I[0], mk_index.I[1]));
        };

        console.log("Markers to flip from the server: "); 
        console.log(markers_to_flip);
        return markers_to_flip;

    } else {

        console.log("No markers to flip");
        return "no_markers_to_flip";
    };

};

