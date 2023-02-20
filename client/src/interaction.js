// INTERACTION
// handle mouse events and relays events to orchestrator

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

// NOT SURE IF NEEDED, as we trigger the mouse evt and coordinates are adjusted already once
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
    
*/