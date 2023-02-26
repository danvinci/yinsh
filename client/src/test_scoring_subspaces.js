// creates and destroys highlight intersection zones (for allowable moves)
function update_ss_scoring_zones(reset = false){
    // manipulates global variable of allowed moves for current ring
    
        // if passed true, the array will be emptied
        if (reset === true){
            ss_scoring_zones = [];
    
        } else {
            // for each linear id of the allowed moves (reads from global variable)
            for (const id of temp_global.values()) {
    
                // let's check which is the matching drop_zone and retrieve the matching (x,y) coordinates
                for(let i=0; i<drop_zones.length; i++){
                    if (drop_zones[i].loc.index == id) {
    
                        // create shape + coordinates and store in the global array
                        let h_path = new Path2D()
                        h_path.arc(drop_zones[i].loc.x, drop_zones[i].loc.y, S*0.1, 0, 2*Math.PI);
                        ss_scoring_zones.push({path: h_path});
                
                    };
                };        
            };
        }
    };


// highlight subspaces scoring 
function draw_ss_scoring_zones(){
    ctx.save();

    ctx.globalAlpha = 1; 
    ctx.strokeStyle = "#f50";
    ctx.fillStyle = "#ff0";
    ctx.lineWidth = 1;

    for(let i=0; i<ss_scoring_zones.length; i++){
    
        ctx.fill(ss_scoring_zones[i].path); 
        ctx.stroke(ss_scoring_zones[i].path); 
        
    };        
    
    ctx.restore();
};


