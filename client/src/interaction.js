// INTERACTION
// handle mouse events and relays events to core logic
// https://bencentra.com/code/2014/12/05/html5-canvas-touch-events.html

import { get_player_id, get_move_status, get_task_status, get_scoring_options_fromTask, get_game_status } from './data.js'
import { GS_progress_rings, GS_progress_game } from './core.js'



//////////////////////////////////////// ADD EVENT LISTENERS TO CANVAS
// assumes canvas bound to 'canvas' and context to 'ctx' -> done in core

globalThis.canvas_interaction_flag = false; // global property for trying to prevent side effects

export function init_interaction(){

    canvas.addEventListener('mousedown', mouseDown_handler, false);
    canvas.addEventListener('mousemove', mouseMove_handler, false);

};

export const enableInteraction = () => {canvas_interaction_flag = true};
export const disableInteraction = () => {canvas_interaction_flag = false};


function mouseDown_handler (event) {

    if (canvas_interaction_flag) { // works only if interaction is allowed

        // get relative mouse position
        const mousePos = getMousePos(canvas, event);

        // retrieve current player (we'll use this to only allow interacting with the player's rings)
        const player_id = get_player_id();

        // retrieve variable used to asses if move or score handling is underway
        const move_in_progress = get_move_status();
        
        // check if scoring is underway
        const mk_scoring_in_progress = get_task_status('mk_scoring_task'); 
        const ring_scoring_in_progress = get_task_status('ring_scoring_task'); 
            const mk_or_ring_scoring_in_progress = mk_scoring_in_progress || ring_scoring_in_progress;

        // check if move currently underway, and mk or ring_scoring NOT underway
        // if move not started yet -> check which ring is being picked and send event to core_et
        if (move_in_progress == false && mk_or_ring_scoring_in_progress == false){

            // retrieve array of rings & game status
            const _rings = yinsh.objs.rings;
            const _gstatus = get_game_status();
            let picked_ring_index_inArray = -1;

            // CASE: normal game play, any user ring can be picked up
            if (_gstatus == GS_progress_game) {

                // find index of picked player ring
                picked_ring_index_inArray = _rings.findIndex((ring) => (ring.player == player_id && ctx.isPointInPath(ring.path, mousePos.x, mousePos.y)));

            // CASE: manual rings placement, only setup ring can be picked up
            } else if (_gstatus == GS_progress_rings) {

                // find index of picked player (setup) ring
                const _ring_setup_id = 0 
                picked_ring_index_inArray = _rings.findIndex((ring) => (ring.player == player_id && ring.loc.index === _ring_setup_id && ctx.isPointInPath(ring.path, mousePos.x, mousePos.y)));
            };

            // dispatch event if matching rings
            if (picked_ring_index_inArray != -1) {
                core_et.dispatchEvent(new CustomEvent('ring_picked', { detail: picked_ring_index_inArray }));
            };

        // move in progress -> ring is being dropped -> checking is there's a nearby drop zone
        } else if (move_in_progress == true){
            
            try {
                // get loc of closest snap
                const closest_snap_loc = drop_snap(mousePos.x, mousePos.y);
                
                // create and dispatch event for dropping action started (core logic will complete the drop)
                core_et.dispatchEvent(new CustomEvent('ring_drop', { detail: closest_snap_loc }));

            } catch (err) {
                console.log(err.message);
            };
        };


        // mk scoring action is in progress 
        if (mk_scoring_in_progress == true){

            // retrieve markers/halos eligible for selection
            const _scoring_options = get_scoring_options_fromTask();
            const _mk_sel = _scoring_options.map(option => option.mk_sel);

            // retrieve markers
            const _markers = yinsh.objs.markers;

            // check which marker is being clicked on, among ones that belong to current player
            const picked_marker = _markers.find((mk) => (mk.player == player_id && ctx.isPointInPath(mk.path, mousePos.x, mousePos.y) && _mk_sel.includes(mk.loc.index)));
            if (typeof picked_marker !== 'undefined') {
                core_et.dispatchEvent(new CustomEvent('mk_sel_picked', { detail: picked_marker.loc.index }));
            };
        
        // mk scoring action is completed but ring scoring is in progress
        } else if (mk_scoring_in_progress == false && ring_scoring_in_progress == true){

            // retrieve array of rings
            const _player_rings = yinsh.objs.rings.filter((ring) => (ring.player == player_id));

            // check all the rings and dispatch event to core logic if match found for local player
            const picked_ring = _player_rings.find((ring) => (ctx.isPointInPath(ring.path, mousePos.x, mousePos.y)));
            if (typeof picked_ring !== 'undefined') {
                core_et.dispatchEvent(new CustomEvent('ring_picked_scoring', { detail: picked_ring.loc.index }));
            };
        };
        
    };
};


 
function mouseMove_handler (event) {

    if (canvas_interaction_flag) { // works only if interaction is allowed

        // retrieve current player 
        const player_id = get_player_id();

        // get relative mouse position
        const mousePos = getMousePos(canvas, event);
        //console.log("move");

        // retrieve variable used to asses if move or score handling is underway
        const move_in_progress = get_move_status();
        
        // check if scoring is underway
        const mk_scoring_in_progress = get_task_status('mk_scoring_task'); 
        const ring_scoring_in_progress = get_task_status('ring_scoring_task'); 
        const any_scoring_in_progress = mk_scoring_in_progress || ring_scoring_in_progress;
            
        // if a move is underway, dispatch event for moving ring
        if (move_in_progress == true){

            // create and dispatch event for mouse moving while move is active
            core_et.dispatchEvent(new CustomEvent('ring_moved', {detail: {coord: mousePos} }));

            // if we're hovering on a drop zone -> dispatch event for hover state sending loc_index
            // in core, this will trigger update_legal_cues(loc_index) -> fn will take care of only setting hover true for matching active cues
            // not checking legality here, avoiding double-checks and separating concerns
            // note: cues might be configurable/optional by the user, we might be want sending events when not used
            const _hover_zone = yinsh.objs.drop_zones.find((dz) => (ctx.isPointInPath(dz.path, mousePos.x, mousePos.y)))

            if (typeof _hover_zone !== 'undefined') {
                core_et.dispatchEvent(new CustomEvent('hover_dropzone_ON', {detail: _hover_zone.loc.index}));
            } else {
                core_et.dispatchEvent(new CustomEvent('hover_dropzone_OFF'));
            };
        };

        // if a mk scoring action is in progress, check on markers and dispatch events to turn on/off highlighting if hovering on the right one(s)
        if (mk_scoring_in_progress == true){

            // retrieve markers/halos eligible for selection
            const _scoring_options = get_scoring_options_fromTask();
            const _mk_sel = _scoring_options.map(option => option.mk_sel);

            // retrieve markers
            const _markers = yinsh.objs.markers;

            // check which marker is being hovered on
            const hovered_marker = _markers.find((mk) => (ctx.isPointInPath(mk.path, mousePos.x, mousePos.y) && _mk_sel.includes(mk.loc.index)));
            
            // dispatch event accordingly
            if (typeof hovered_marker !== 'undefined') {
                core_et.dispatchEvent(new CustomEvent('mk_sel_hover_ON', { detail: hovered_marker.loc.index }));
            } else {
                core_et.dispatchEvent(new CustomEvent('mk_sel_hover_OFF'));
            };

        };

        // CASE: mk scoring action is completed but ring scoring is in progress
        const ring_choice_scoring = mk_scoring_in_progress == false && ring_scoring_in_progress == true
        
        // CASE: normal gameplay > user has to pick up ring, we're handling the ring highlight hover state
        const ring_choice_move = get_game_status() == GS_progress_game && !move_in_progress && !any_scoring_in_progress
            // NOTE -> maybe better to condense all cases into a single infer function?
            // we're excluding manual ring pick up, move in progress (picked ring) or scoring
            // as the whole fn runs only when interaction is allowed, all is left is the dead time before picking a ring?

        if (ring_choice_scoring || ring_choice_move){

            // retrieve array of rings
            const _player_rings = yinsh.objs.rings.filter((ring) => (ring.player == player_id));
            const _p_rings_ids = _player_rings.map(ring => ring.loc.index);

            // check which ring is being hovered on (find returns either the first or undefined)
            const hovered_ring = _player_rings.find((ring) => (ctx.isPointInPath(ring.path, mousePos.x, mousePos.y)));
            
            // dispatch event accordingly
            if (typeof hovered_ring !== 'undefined') {
                core_et.dispatchEvent(new CustomEvent('ring_sel_hover_ON', { detail: {player_rings: _p_rings_ids, hovered_ring: hovered_ring.loc.index }}));
            } else {
                core_et.dispatchEvent(new CustomEvent('ring_sel_hover_OFF', { detail: {player_rings: _p_rings_ids }}));
            };
        };

        // OR manual rings setup but ring not picked up yet
        if (get_game_status() == GS_progress_rings && !move_in_progress) {

            // find ring of player with index 0 (starting index for pick-up, not dropped yet)
            const _ring_setup_id = 0 // <- this should be made into a global const
            const _ring_setup = yinsh.objs.rings.filter((ring) => (ring.player == player_id && ring.loc.index === _ring_setup_id));

            // check if setup ring is being hovered on (find returns either the first or undefined) 
            // should be vector of 1 element
            const is_ring_setup_hover = (_ring_setup.length > 0) ? ctx.isPointInPath(_ring_setup[0].path, mousePos.x, mousePos.y) : false;

            // dispatch event accordingly
            // we are using fn in core that can set to OFF multiple rings (OFF = non-hover state for visual cue), here we want only 1 to be on/off
            if (is_ring_setup_hover) {
                core_et.dispatchEvent(new CustomEvent('ring_sel_hover_ON', { detail: {player_rings: _ring_setup_id, hovered_ring: _ring_setup_id }}));
            } else {
                core_et.dispatchEvent(new CustomEvent('ring_sel_hover_OFF', { detail: {player_rings: _ring_setup_id}}));
            };

        };
    };
};



//////////////////////////////////////// HELPER FUNCTIONS 

// Get the position of the mouse relative to the canvas
export function getMousePos(canvasBinding, mouseEvent) {
    
    const canvasRect = canvasBinding.getBoundingClientRect();
    
    return {
        x: mouseEvent.clientX - canvasRect.left,
        y: mouseEvent.clientY - canvasRect.top
    };
}


// function to return location object of closest drop zone (if xp,yp are within drop zone )
function drop_snap(xp, yp){

    // test which drop zone the mouse is closest to -> return loc of drop_zone
    const snap_d_zone = yinsh.objs.drop_zones.find((d_zone) => (ctx.isPointInPath(d_zone.path, xp, yp)));
    
    if (typeof snap_d_zone !== 'undefined') {
        return structuredClone(snap_d_zone.loc);
    } else {
        throw new Error("LOG - Close snap not found");
    };
};




/*

canvas.addEventListener("mouseup", 
    function (event) {
        //console.log("up");
    });


*/


/////////////////////////////////////////////////////////////////
////////////////////////////////////// SUPPORT FOR TOUCH EVENTS

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