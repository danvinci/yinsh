// DRAWING FUNCTIONS

import {get_player_id, get_opponent_id} from './data.js'

// glue function called by orchestrator after data manipulation
export function refresh_canvas_state(alpha_param = 1, scale_param = 1, line_param = 1, offset_param = {x:0, y:0}, board_flag = false){

    // https://docs.solidjs.com/references/api-reference/lifecycles/onMount

    const painting_start_time = Date.now()

    try {
        // clear canvas (assumes canvas already binded)
        ctx.clearRect(0, 0, canvas.width, canvas.height);

            // Draw board
            // pass params onto board only w/ flag enabled, otherwise only affects scoring_slots
            if (board_flag) {
                draw_board(alpha_param, scale_param, line_param, offset_param);
            } else {
                draw_board();
            };
            
            // keep drop zones up
            draw_drop_zones();

            // scoring slots 
            draw_scoring_slots(alpha_param);

            // draw cues for legal moves
            draw_legal_moves_cues();

            // Re-draw all rings and markers
            draw_markers();
            draw_rings();
            
            // Draw markers halos (score handling)
            draw_markers_halos();
            draw_rings_highlight();

        // logging time 
        //console.log(`LOG - Drawing time: ${Date.now() - painting_start_time}ms`);

    } catch(err) {

        console.log(`LOG - Canvas refresh ERROR: ${Date.now() - painting_start_time}ms`);
        throw err;

    };
}; 


// NOTE:
// pre-draw board and store it?

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

// game board
function draw_board(alpha_param = 1, scale_param = 1, line_param = 1, offset_param = {x:0, y:0}){

    // const painting_start_time = Date.now()

    // this whole function should be simplified at some point -> re-using premade paths?

    // function arguments - used for animations involving the board
    // alpha_param -> transparency 0 -> 1
    // scale_param -> ref size 1 -> N
    // offset_param -> {x, y} -> drawing starting position

    // retrieve constants + drawing params
    // recovering constants
    const mm_points = yinsh.constant_params.mm_points;
    const mm_points_rows = yinsh.constant_params.mm_points_rows;
    const mm_points_cols = yinsh.constant_params.mm_points_cols;

    // recovering S & H constants for drawing
    const S = yinsh.drawing_params.S*scale_param;
    const H = yinsh.drawing_params.H*scale_param;
 
     // recover offset values for starting to draw (centering board and zones)
     const _offset_x = yinsh.drawing_params.x_offset+offset_param.x;
     const _offset_y = yinsh.drawing_params.y_offset+offset_param.y;

    // hardcoding triangles to be drawn for each column (fn call results in silent error)
    const triangles_toPaint_byCol = {0:3, 1:6, 2:7, 3:8, 4:9, 5:8, 6:9, 7:8, 8:7, 9:6, 10:3};

    // save current canvas drawing settings
    // this points to globalThis.ctx
    ctx.save();

        // http://diveintohtml5.info/canvas.html#pixel-madness

        // drawing settings -> these should go to the DB too at some point
        ctx.lineJoin = "round";
        ctx.strokeStyle = '#4b85c3';
        ctx.lineWidth = 2*line_param;
        ctx.globalAlpha = 0.4*alpha_param;

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

        for (let k = 1; k <= mm_points_cols-1; k++) {

            // number of triangles we're expected to draw for each column
            //let t_toPaint = triangles_toDraw_byCol(mm_points, k-1);
            let t_toPaint = triangles_toPaint_byCol[k-1]; 
            let t_Painted = 0;

            // move right for each new column (-H/3 reduces left canvas border)
            ctx.translate(_offset_x + H*k,_offset_y + H);

            // going down the individual columns
            for (let j = 1; j <= mm_points_rows; j++) {
                
                let point = mm_points[j-1][k-1];

                // manually adjusting values to handle last column 
                if (k == mm_points_cols-1 && (j == 4 || j > 13) ){
                    point = 0;
                };

                // if point is not active just translate the drawing point down
                if (point == 0) {
                    ctx.translate(0,S/2);
                
                // DRAWING LOOP!
                // draw triangle, but only if we got some to paint
                } else if (point == 1 && t_Painted < t_toPaint) {
                    
                    ctx.beginPath();
                    ctx.moveTo(0,0); // starting point for drawing
                    ctx.lineTo(0,S); // first point down
                    ctx.lineTo(H,S/2); // mid-point to the right
                    ctx.closePath(); // close shape
                    ctx.stroke();
                    t_Painted ++; // increment counter of triangles drew

                    // check if the following column (k) has more triangles to be painted
                    // if yes, we need to draw an extra edge as a bridge
                    let paint_edge_flag = (t_toPaint < triangles_toPaint_byCol[k]);

                        // we draw the extra edge for all columns except the last one 
                        if (paint_edge_flag && k < mm_points_cols) {

                            // first triangle bridging up
                            if (t_Painted == 1){
                                ctx.beginPath();
                                ctx.moveTo(0,0); 
                                ctx.lineTo(H,-S/2); 
                                //ctx.strokeStyle = "#FA5537";
                                ctx.stroke();
                                //ctx.strokeStyle = colT;
                            };

                            // last triangle bridging down
                            if (t_Painted == t_toPaint){
                                ctx.beginPath();
                                ctx.moveTo(0,S);
                                ctx.lineTo(H,S+S/2);
                                //ctx.strokeStyle = "#32CBFF";
                                ctx.stroke();
                                //ctx.strokeStyle = colT; // reset color
                            };
                        };

                    // draw vertical strokes 
                    // last column, last triangle done (+2 hack as we disqualify points above)
                    if (k == mm_points_cols-1 && t_toPaint == t_Painted + 2) {
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
                    };
                    
                // move down (considering last active point when drawing)
                ctx.translate(0,S/2);

                } // stop going down the column and drawing if you're done 
                else if ( t_Painted == t_toPaint ) {
                    break;
                };
            };

            // reset canvas transformations before moving to next column
            ctx.setTransform(1, 0, 0, 1, 0, 0);
        };
        
    ctx.restore();
    
    // logging time 
    // console.log(`LOG - Board painted on canvas: ${Date.now() - painting_start_time}ms`);

};

// drop zones
function draw_drop_zones(){

    // const painting_start_time = Date.now()
    
    // retrieve drop_zones data
    const _drop_zones = yinsh.objs.drop_zones;

    // drawing
    ctx.save();

        ctx.globalAlpha = 0; 
        //ctx.strokeStyle = "#666";
        ctx.fillStyle = "#666";
        //ctx.lineWidth = 0.5;

        for(const d_zone of _drop_zones){
            ctx.fill(d_zone.path); 
            //ctx.stroke(d_zone[i].path); 
        };   
    
    ctx.restore();
    // console.log(`LOG - Drop zones painted on canvas: ${Date.now() - painting_start_time}ms`);
};

// drop zones for scoring rings // TESTING-ONLY, to see how to define boundary with rings
// is the array is non-empty all the time, we can also draw them on the empty board
function draw_scoring_slots(alpha_param = 1){

    // alpha_param can  be used for progressive fading, as the function is invoked w/ a lower value over time

    // retrieve scoring slots data
    const _scoring_slots = yinsh.objs.scoring_slots;

    const _local_player = "this_player";
    const _oppon_player = "opponent";

    const S = yinsh.drawing_params.S;

    // ref color
    const _empty_score_color = "#d3dbf0";

    for(const slot of _scoring_slots){

        if (slot.filled == false) {

            // drawing
            ctx.save();

                ctx.globalAlpha = 0.16*alpha_param; 
                ctx.fillStyle = _empty_score_color;

                ctx.fill(slot.path);

            ctx.restore();

        // we call this case only when at least one slot is filled -> we have server data on which player has a given ID/color
        } else {

            const _local_color_id = get_player_id(); // B, W
            const _oppon_color_id = get_opponent_id();
        
            if (slot.player == _local_player) {

                // draw ring  
                const _ring_spec = {x: slot.x, y: slot.y, id: _local_color_id, alpha:0.8*alpha_param}
                draw_rings(_ring_spec);

            } else {
                
                // draw ring  
                const _ring_spec = {x: slot.x, y: slot.y, id: _oppon_color_id, alpha:0.8*alpha_param}
                draw_rings(_ring_spec);

            };
            
        };
    };
};

// rings
// can also be called as external function by scoring_slots to draw rings in such locations
function draw_rings(ring_spec = {}){

    // const painting_start_time = Date.now()

    const player_black_id = yinsh.constant_params.player_black_id;
    const player_white_id = yinsh.constant_params.player_white_id;

    // drawing parameters
    const S = yinsh.drawing_params.S;
    const inner = S*0.38;
    const ring_lineWidth = inner/3;

    // ref colors
    const _black_col = "#1e1e1e";
    const _white_col = "#f8f8f8";
    const _lgray_col = "#828e82";

    // check for valid input to decide which flow to enact
    const _ring_spec_flag = ring_spec.hasOwnProperty('x'); 

    // draw rings (normally)
    if (!_ring_spec_flag) {

        // retrieve rings data (local copy) and other constants
        let _rings = yinsh.objs.rings;

        // starts painting - normal flow using rings array
        ctx.save();

            // reading from local copy
            for (let ring of _rings) {

                // draw black ring
                if (ring.player == player_black_id){ 
                    
                    ctx.strokeStyle = _black_col;
                    ctx.lineWidth = ring_lineWidth;            
                    
                    let ring_path = new Path2D()
                        ring_path.arc(ring.loc.x, ring.loc.y, inner, 0, 2*Math.PI);
                    ctx.stroke(ring_path);

                    // update path shape definition -> needed for rings (click within shape)
                    ring.path = ring_path;
            
                // draw white ring
                } else if (ring.player == player_white_id){

                    //inner almost white
                    ctx.strokeStyle = _white_col;
                    ctx.lineWidth = ring_lineWidth*0.9;            
                    
                    let ring_path = new Path2D()
                        ring_path.arc(ring.loc.x, ring.loc.y, inner, 0, 2*Math.PI);
                    ctx.stroke(ring_path);

                    // outer border
                    ctx.strokeStyle = _lgray_col;
                    ctx.lineWidth = ring_lineWidth/12; 
                    
                    let outerB_path = new Path2D()
                        outerB_path.arc(ring.loc.x, ring.loc.y, inner*1.15, 0, 2*Math.PI);
                    ctx.stroke(outerB_path);
                    
                    ring_path.addPath(outerB_path);

                    // inner border
                    ctx.strokeStyle = _lgray_col;
                    ctx.lineWidth = ring_lineWidth/12;  

                    let innerB_path = new Path2D()
                        innerB_path.arc(ring.loc.x, ring.loc.y, inner*0.85, 0, 2*Math.PI);
                    ctx.stroke(innerB_path);

                    ring_path.addPath(outerB_path);

                    // update path shape definition
                    ring.path = ring_path;

                };
            };

        // save updated rings definitions (with new paths) 
        // note: structured clone doesn't work for writing into nested objects -> as long as I have a deep copy barrier at the entrance, I should be good
        yinsh.objs.rings = _rings;

        ctx.restore();

        // console.log(`LOG - ${_rings.length} Rings painted on canvas: ${Date.now() - painting_start_time}ms`);
    
    } else { // draw ring as specified

        // retrieve specifications
        const _ring_x = ring_spec.x;
        const _ring_y = ring_spec.y;
        const _ring_id = ring_spec.id;
        const _ring_alpha = ring_spec.alpha;

        // starts painting - special flow using ring specification from scoring slot function
        ctx.save();

            // rings in scoring slots should look not look available for interaction - playing w/ transparency, not sure if it's good
            ctx.globalAlpha = _ring_alpha;

            // draw black ring
            if (_ring_id == player_black_id){ 
                    
                ctx.strokeStyle = _black_col;
                ctx.lineWidth = ring_lineWidth;            
                
                let ring_path = new Path2D()
                    ring_path.arc(_ring_x, _ring_y, inner, 0, 2*Math.PI);
                ctx.stroke(ring_path);

            // draw white ring
            } else if (_ring_id == player_white_id){

                //inner white 
                ctx.strokeStyle = _white_col;
                ctx.lineWidth = ring_lineWidth*0.9;            
                
                let ring_path = new Path2D()
                    ring_path.arc(_ring_x, _ring_y, inner, 0, 2*Math.PI);
                ctx.stroke(ring_path);

                // outer border
                ctx.strokeStyle = _lgray_col;
                ctx.lineWidth = ring_lineWidth/12; 
                
                let outerB_path = new Path2D()
                    outerB_path.arc(_ring_x, _ring_y, inner*1.15, 0, 2*Math.PI);
                ctx.stroke(outerB_path);

                // inner border
                ctx.strokeStyle = _lgray_col;
                ctx.lineWidth = ring_lineWidth/12;  

                let innerB_path = new Path2D()
                    innerB_path.arc(_ring_x, _ring_y, inner*0.85, 0, 2*Math.PI);
                ctx.stroke(innerB_path);

            };

        ctx.restore();

    };
};

// markers
function draw_markers(){

    // const painting_start_time = Date.now()

    // retrieve markers data (local copy) + other constants
    let _markers = yinsh.objs.markers;

    const player_black_id = yinsh.constant_params.player_black_id;
    const player_white_id = yinsh.constant_params.player_white_id;

    const S = yinsh.drawing_params.S;

    // ref colors
    const _black_col = "#1e1e1e";
    const _white_col = "#f8f8f8";
    const _lgray_col = "#828e82";

    // drawing
    ctx.save();

        // iterate over markers
        for (let m of _markers) {

            let inner = S*0.25;
            let marker_lineWidth = inner/5;

            // draw black marker
            if (m.player == player_black_id){ 

                ctx.fillStyle = _black_col;
                
                let marker_path = new Path2D()
                    marker_path.arc(m.loc.x, m.loc.y, inner, 0, 2*Math.PI);
                ctx.stroke(marker_path);
                ctx.fill(marker_path);

                // update path shape definition -> needed for marker selection (scoring)
                m.path = marker_path;
        
            // draw white marker
            } else if (m.player == player_white_id){ 
                
                ctx.strokeStyle = _lgray_col;
                ctx.fillStyle = _white_col;
                ctx.lineWidth = marker_lineWidth/2;            
            
                let marker_path = new Path2D()
                    marker_path.arc(m.loc.x, m.loc.y, inner, 0, 2*Math.PI);
                ctx.stroke(marker_path);
                ctx.fill(marker_path);
                
                // update path shape definition -> needed for marker selection (scoring)
                m.path = marker_path;
        
            };
        };

    // save updated markers definitions (with new paths) 
    // note: structured clone doesn't work for writing into nested objects -> as long as I have a deep copy barrier at the entrance, I should be good
    yinsh.objs.markers = _markers;

    ctx.restore();

    // console.log(`LOG - ${_markers.length} Markers painted on canvas: ${Date.now() - painting_start_time}ms`);


};

// highlight markers in scoring row 
function draw_markers_halos(){

    // const painting_start_time = Date.now()
    
    // retrieve mk halos data (local copy) + other constants
    const _mk_halos = yinsh.objs.mk_halos;

    const S = yinsh.drawing_params.S;

    // colors that work w/ alpha 0.75
    const hot_color = "#5286ba";
    const cold_color = "#8ab9d0";

    
    ctx.save();

        // to be checked only if any markers halos have been created
        // the whole function is called anyway at each refresh

        ctx.globalAlpha = 0.75; 
        ctx.lineWidth = S/10; 

        // can paint hot/cold dynamically, for each specific halo's properties
        for(const mk_halo of _mk_halos){

            if (mk_halo.hot == true) {
                ctx.strokeStyle = hot_color;
                ctx.stroke(mk_halo.path); 
            } else {
                ctx.strokeStyle = cold_color;
                ctx.stroke(mk_halo.path); 
            };
            
        };        
    
    ctx.restore();

    // console.log(`LOG - ${_mk_halos.length} Markers halos painted on canvas: ${Date.now() - painting_start_time}ms`);
    
};

// cues for picking score ring
function draw_rings_highlight(){

    // const painting_start_time = Date.now()
    
    // retrieve ring highlights data and other constants
    const _r_high = yinsh.objs.ring_highlights; // the function is called at each refresh, if array is empty nothing happens

    const S = yinsh.drawing_params.S;

    // colors that work w/ alpha 0.75
    const hot_color = "#5286ba";
    const cold_color = "#8ab9d0";

    
    ctx.save();

        ctx.globalAlpha = 0.75; 

        // can paint hot/cold dynamically, for each specific halo's properties
        for(const h of _r_high){

            if (h.hot == true) {

                ctx.fillStyle = hot_color;
                ctx.fill(h.path); 

            } else {

                ctx.fillStyle = cold_color;
                ctx.fill(h.path); 
            };
            
        };        
    
    ctx.restore();

    // console.log(`LOG - ${_r_high.length} Rings highlights painted on canvas: ${Date.now() - painting_start_time}ms`);
    
};

// highlight legal moves
function draw_legal_moves_cues(){

    // const painting_start_time = Date.now()

    // retrieve mk halos data (local copy)
    const _legal_moves_cues = yinsh.objs.legal_moves_cues;
    
    // drawing
    ctx.save();


        ctx.globalAlpha = 0.8; 
        ctx.fillStyle = "#80b3ce";
        ctx.lineWidth = 0.5;

        for(const cue of _legal_moves_cues){

            // draw only cues turned on
            if (cue.on == true) {

                ctx.fill(cue.path); 

            };
        };        
    
    ctx.restore();

    // console.log(`LOG - ${_legal_moves_cues.length} Moves cues painted on canvas: ${Date.now() - painting_start_time}ms`);
   
};

