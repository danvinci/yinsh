// DRAWING

// glue function called by orchestrator after data manipulation
function refresh_draw_state(){

    //let drawing_start = Date.now();
    
    // clear canvas
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

    // Draw markers halos
    draw_mk_halos();

    // logging time -> repaint topping at 1ms 
    //let delta_time = Date.now() - drawing_start;
    //console.log(`Repaint time: ${delta_time}ms`);

}; 


// NOTE:
// pre-draw board and store it for later  ??


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

// drawing main board
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

// drop zones
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

// rings
function draw_rings(){
    ctx.save();

    // reads the global rings object
    for (const s of rings.values()) {

        let inner = S*0.38;
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

// markers
function draw_markers(){
    ctx.save();

    // reads the global markers object
    for (const m of markers.values()) {

        let inner = S*0.25;
        let marker_lineWidth = inner/5;

        // draw black marker
        if (m.player == player_black_id){ 

            ctx.fillStyle = "#13191b";
            
            let marker_path = new Path2D()
            marker_path.arc(m.loc.x, m.loc.y, inner, 0, 2*Math.PI);
            ctx.stroke(marker_path);
            ctx.fill(marker_path);

             // update path shape definition -> needed for marker selection (scoring)
             m.path = marker_path;
    
        // draw white marker
        } else if (m.player == player_white_id){ 
            
            ctx.strokeStyle = "#13191b";
            ctx.fillStyle = "#F6F7F6";
            ctx.lineWidth = marker_lineWidth/2;            
        
            let marker_path = new Path2D()
            marker_path.arc(m.loc.x, m.loc.y, inner, 0, 2*Math.PI);
            ctx.stroke(marker_path);
            ctx.fill(marker_path);
            
            // update path shape definition -> needed for marker selection (scoring)
            m.path = marker_path;
    
        };
    };

    ctx.restore();
};

// highlight legal moves
function draw_highlight_zones(){
    ctx.save();

    ctx.globalAlpha = 1; 
    ctx.strokeStyle = "#668bd2";
    ctx.fillStyle = "#aaccdd";
    ctx.lineWidth = 0.5;

    for(let i=0; i<highlight_zones.length; i++){
    
        ctx.fill(highlight_zones[i].path); 
        ctx.stroke(highlight_zones[i].path); 
        
    };        
    
    ctx.restore();
};

// highlight markers in scoring row
function draw_mk_halos(){
    ctx.save();

    // to be checked only if markers halos have been created
    // this function is called anyway at each refresh
    hot = false;
    if (mk_halos.length > 0) {hot = mk_halos[0].hot_flag;};

    ctx.globalAlpha = 0.8; 
    ctx.strokeStyle = hot ? "#96ce96" : "#98C1D6";
    ctx.lineWidth = S/10; // refer to global sizing var

    for(let i=0; i<mk_halos.length; i++){
    
        ctx.stroke(mk_halos[i].path); 
    };        
    
    ctx.restore();
};


// HELPER FUNCTIONS 

// extract array columns from matrix
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



