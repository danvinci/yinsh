// INTERACTION
// handle mouse events and relays events to orchestrator

// https://bencentra.com/code/2014/12/05/html5-canvas-touch-events.html

let mousePos = { x:0, y:0 };

canvas.addEventListener("mousedown", 
    function (event) {
        mousePos = getMousePos(canvas, event);
        //console.log("down");

        // check if move currently underway
        // If not, check which ring is being picked and emit event
        if (current_move.on == false){

            // test which ring the mouse is selecting and send an event
            for(let i=0; i<rings.length; i++){
                if (ctx.isPointInPath(rings[i].path, mousePos.x, mousePos.y)){

                    // create and dispatch event for what the ring being picked up -> game state should change
                    const ringPick_event = new CustomEvent("ring_picked", { detail: i});
                    game_state_target.dispatchEvent(ringPick_event);
                    
                    break; 
                    
                };
            };

        // move on -> ring is being dropped
        } else if (current_move.on == true){
            
            // move is active, ring drop attempt
            // check snapping (geometric) coordinates
            drop_coord_loc = closest_snap(mousePos.x, mousePos.y);
            
            // geometric check first 
            if (drop_coord_loc !== "no_snap"){

                // create and dispatch event for dropping attempt
                const ringDropAttempt_event = new CustomEvent("ring_drop_attempt", { detail: drop_coord_loc });
                game_state_target.dispatchEvent(ringDropAttempt_event);

                // game state target responsible for validity check
                // here we only take care of interaction and checking there's actually a nearby drop zone

            };  
        };
        // scoring action is in progress -> scoring row is being selected via mk_sel
        if (score_handling_var.on == true){

            // check which marker the mouse is clicking on
            for(let i=0; i<markers.length; i++){
                if (ctx.isPointInPath(markers[i].path, mousePos.x, mousePos.y)){

                    // check that index of marker is among ones in mk_sel_array (selectable markers)
                    if (score_handling_var.mk_sel_array.includes(markers[i].loc.index) == true){

                        // create and dispatch event, send location index for matching marker
                        const mk_sel_click_event = new CustomEvent("mk_sel_clicked", { detail: markers[i].loc.index});
                        game_state_target.dispatchEvent(mk_sel_click_event);
                        
                        break; // no need to keep cycling

                    };
                };
            };
        };
    });

canvas.addEventListener("mouseup", 
    function (event) {
        //console.log("up");
    });

canvas.addEventListener("mousemove", 
    function (event) {
        mousePos = getMousePos(canvas, event);
        //console.log("move");

        // if a move is underway, dispatch event for moving ring
        if (current_move.on == true){

            // create and dispatch event for mouse moving while move is active
            const ringMove_event = new CustomEvent("ring_moved", {detail: mousePos});
            game_state_target.dispatchEvent(ringMove_event);
            
        };

        
        // if a scoring action is in progress, check on markers and dispatch events to turn on/off highlighting if hovering on the right one(s)
        if (score_handling_var.on == true){

            let on_sel_marker = false;

            // check which markers the mouse is passing on
            for(let i=0; i<markers.length; i++){
                if (ctx.isPointInPath(markers[i].path, mousePos.x, mousePos.y)){

                    // check that index of marker is among ones in mk_sel_array (selectable markers)
                    if (score_handling_var.mk_sel_array.includes(markers[i].loc.index) == true){

                        // create and dispatch event, send location index for matching marker
                        const mk_sel_hover_event_ON = new CustomEvent("mk_sel_hover_ON", { detail: markers[i].loc.index});
                        game_state_target.dispatchEvent(mk_sel_hover_event_ON);

                        on_sel_marker = true; // -> to inform default behavior
                        
                        break; // as you get the one

                    };
                };
            };

            if (on_sel_marker == false){

                // score handling underway but not on mk_sel_array, only original mk_sel should stay highlighted until handling is over
                const mk_sel_hover_event_OFF = new CustomEvent("mk_sel_hover_OFF");
                game_state_target.dispatchEvent(mk_sel_hover_event_OFF);

            };
            
        };

    });





// HELPER FUNCTIONS 

// Get the position of the mouse relative to the canvas
function getMousePos(canvasDom, mouseEvent) {
var canvasRect = canvasDom.getBoundingClientRect();
return {
    x: mouseEvent.clientX - canvasRect.left,
    y: mouseEvent.clientY - canvasRect.top
};
}


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






/// SUPPORT FOR TOUCH EVENTS

/*
// Set up touch events 
// Touch events are mapped to and dispatch mouse events, all events are handled from those!
canvas.addEventListener("touchstart", 
    function (event) {
        //mousePos = getTouchPos(canvas, event); //might be redundant
        let touch = event.touches[0];
        let mouseEvent = new MouseEvent("mousedown", {
            clientX: touch.clientX,
            clientY: touch.clientY
            });
        
        canvas.dispatchEvent(mouseEvent);
    });

canvas.addEventListener("touchend", 
    function (event) {
        let mouseEvent = new MouseEvent("mouseup", {});
        canvas.dispatchEvent(mouseEvent);
    });

canvas.addEventListener("touchmove", 
    function (event) {
        let touch = event.touches[0];
        let mouseEvent = new MouseEvent("mousemove", {
            clientX: touch.clientX,
            clientY: touch.clientY
        });
        canvas.dispatchEvent(mouseEvent);
    });

// NOT SURE IF NEEDED, as we trigger the mouse event and coordinates are adjusted already once
// Get the position of a touch relative to the canvas
function getTouchPos(canvasDom, touchEvent) {
var canvasRect = canvasDom.getBoundingClientRect();
return {
    x: touchEvent.touches[0].clientX - canvasRect.left,
    y: touchEvent.touches[0].clientY - canvasRect.top
};
}



// Prevent scrolling when touching the canvas given conflict with touch/drag gestures
document.body.addEventListener("touchstart", 
    function (event) {
        if (event.target == canvas) {
            event.preventDefault();
        }
    });

document.body.addEventListener("touchend", 
    function (event) {
        if (event.target == canvas) {
            event.preventDefault();
        }
    });

document.body.addEventListener("touchmove", 
    function (event) {
        if (event.target == canvas) {
            event.preventDefault();
        }
    });
    
*/