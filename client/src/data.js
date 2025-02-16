// DATA
// data objects + functions operating on them + data utils (like reshape_index)


// cues go off with the setting, but back on only with setting + mouseMove (handled by interaction.js), so user won't see effect of setting immediately
// as highlights depend on game state (ie. player is about to make move or score), better to avoid replicating logic here, so we mock a mouseMove
globalThis.cues_rings_flag = true; // global property for rings cues on/off
export const enableRingsCues = () => {cues_rings_flag = true; update_ring_cues(); canvas.dispatchEvent(new MouseEvent('mousemove', {clientX: 1, clientY: 1}));}; 
export const disableRingsCues = () => {cues_rings_flag = false; update_ring_cues(); refresh_canvas_state();};

globalThis.cues_moves_flag = true; // global property for legal moves cues on/off
export const enableLegalMovesCues = () => {cues_moves_flag = true; update_legal_cues(); refresh_canvas_state();};
export const disableLegalMovesCues = () => {cues_moves_flag = false; update_legal_cues(); refresh_canvas_state();};

import { setup_ok_codes, next_ok_codes, joiner_ok_code} from './server.js'
import { GS_progress_rings, GS_progress_game, GS_completed } from './core.js'
import { refresh_canvas_state } from './drawing.js';

// UTILITY FUNCTIONS

// from row/col julia matrix indexes to linear index in js
const reshape_index = (row, col) => ( (col-1)*19 + row - 1); // js arrays start at 0, hence the -1 offset

// elegant way of comparing sets for equality
// https://stackoverflow.com/questions/31128855/comparing-ecma6-sets-for-equality
const areSetsEqual = (a, b) => a.size === b.size && [...a].every(value => b.has(value));


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

    // note: these should come from the server as well at some point (ids etc, so I can change them from one-side only)
    _params.ring_id =  "R";
    _params.marker_id =  "M";
    _params.player_black_id = "B";
    _params.player_white_id = "W";
    _params.winning_score = 3; // set for now, can/should be altered with server payload in quick game mode


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


export function get_winning_score(){

    return yinsh.constant_params.winning_score;
};

export function init_game_objs(){

    const game_objs_start_time = Date.now()

    // setups drop zones (FIRST)
    init_drop_zones();

    // inits slots for placing scoring rings
    init_scoring_slots();

    // inits visual cues for legal moves (all off by default)
    init_legal_moves_cues();

    // init markers
    init_markers();

    // init rings (uses data from server)
    init_rings();

    // logging time 
    console.log(`LOG - Game objects initialized: ${Date.now() - game_objs_start_time}ms`);

};

// keeps canvas size and drawing constants compatible with div parent size
export function bind_adapt_canvas(){

    // info on details for making this work here:
    // https://stackoverflow.com/questions/32230690/resize-div-containing-a-canvas

    // grab canvas
    // IDs different than 'canvas' seem not to work :|
    globalThis.canvas = document.getElementById('canvas');
    globalThis.ctx = canvas.getContext('2d', { alpha: true }); 

    // grab parent div
    let canvasParent = canvas.parentNode;

    // hide canvas for a bit (so that we can measure the parent without canvas, and avoid increasing sizes at every loop)
    const dispStyle_backup = canvas.style.display;
    canvas.style.display = "none";

    // resize canvas to match parent container, but measuring parent without canvas in it
    canvas.width = canvasParent.clientWidth;
    canvas.height = canvasParent.clientHeight; 

        /*
        console.log(`parent height: ${canvasParent.clientHeight}, width: ${canvasParent.clientWidth}`);
        console.log(`canvas height: ${canvas.height}, width: ${canvas.width}`);
        */

    // restore canvas visibility
    canvas.style.display = dispStyle_backup;

    // SET DRAWING CONSTANTS
    // compute S_h and S_w (H) taking into account height and width of the canvas

    const h_ratio_factor = 10.5; // empirical value ~ number of triangle sides in height + 3 (proxy for scoring slots)
    const w_ratio_factor = h_ratio_factor + 2; // +2 as we need space for the scoring slots

        // find out if height or width is the constraint for fittng triangles of the board
        const S_by_height = canvas.height/h_ratio_factor;
        const S_by_width = canvas.width/w_ratio_factor;
        
        const S_param = Math.round(Math.min(S_by_width, S_by_height));
        const H_param = Math.round(S_param * Math.sqrt(3)/2);

    // compute X & Y offset for drawing board and drop zones
    const _off_x = canvas.width/2 - 5.7*H_param;
    const _off_y = H_param/2 - 0.7*S_param;

        // compute offset for drawing scoring slots
        //const _start_BL_point = {x: H_param, y: H_param/4.4 + h_ratio_factor*H_param }
        const _start_BL_point = {x: H_param, y: S_param * 9.27}
        const _start_TR_point = {x: canvas.width - H_param, y: H_param*1.09}
 
    // save to global obj and log
    yinsh.drawing_params = structuredClone({S: S_param, H: H_param, x_offset: _off_x, y_offset: _off_y, start_BL: _start_BL_point, start_TR: _start_TR_point});
    console.log('LOG - Drawing constants set');

};


// inits/resets game objects (rings, markers, visual cues) ->  yinsh.objs.rings/markers/drop_zones/etc
export function init_empty_game_objects(){

    // init temporary object
    const _game_objects = {};

        // objects on canvas
        _game_objects.rings = []; // -> array for rings
        _game_objects.markers = []; // -> array for markers
        _game_objects.drop_zones = []; // -> array for drop zones (markers and rings are placed at their coordinates only)
        _game_objects.scoring_slots = []; // -> array for drop zones used for rings taken from board after scoring

        // turns, moves, score handling
        _game_objects.current_turn = {in_progress: false}; // to track if this is the client's turn 
        _game_objects.game_status = ""; // updated by core with new server events

        //_game_objects.ring_place_action = -1 // -> WE USE THE SAME move_action VAR FOR TRACKING THIS TOO, USE CASE SET BY GAME STATUS
        _game_objects.preMove_scoring_actions = []; // save details in case pre-move scoring took place
        _game_objects.move_action = {in_progress: false, start_index: -1, end_index: -1, legal_drops: []}; // -> details for move in progress/done, both for gameplay or manual rings setup 
        _game_objects.scoring_actions = []; // save details in case scoring took place
       
        _game_objects.legal_moves_cues = []; // -> array for cues paths (drawn on/off based on legal drops ids)
        _game_objects.ring_setup_spots = []; // -> array of valid ring drops for manual placement 
        
        _game_objects.current_mk_scoring = {in_progress: false, task_ref: {}}; // referencing task of general score handling
        _game_objects.current_ring_scoring = {in_progress: false, task_ref: {}}; // referencing task of ring picking within score handling
        _game_objects.current_animation = {in_progress: false, task_ref: {}}; // task for tracking animations and prevent game resets from UI (only supports 1 task/time)

        _game_objects.mk_halos = []; // -> halos objects
        _game_objects.ring_cues = []; // -> highlights for rings

        _game_objects.player_score = 0;
        _game_objects.opponent_score = 0;

    // save to global obj and log
    yinsh.objs = structuredClone(_game_objects);
    console.log('LOG - Empty game objects initialized');

};
export function set_game_status(gs){
    yinsh.objs.game_status = gs;
};

export function get_game_status(){
    return structuredClone(yinsh.objs.game_status);
};


// saving server response data - internally handles if it's setup or next move data
// assumes input data has msg_code field, and are returning w/ OK code
export function save_server_response(srv_input){

    // check if it's SETUP or NEXT MOVE data
    const f_setup = setup_ok_codes.includes(srv_input.msg_code);
    const f_next_event = next_ok_codes.includes(srv_input.msg_code);
    const f_next_save = f_next_event && ('delta' in srv_input); // save/overwrite next data only if we have a delta

    // init temporary object
    let _srv_response = {};

    // save NEXT MOVE data
    if (f_next_save) {

            _srv_response.rings = srv_input.rings; // rings
            _srv_response.markers = srv_input.markers; // markers
            _srv_response.scenario_trees = srv_input.scenario_trees; // scenario tree
            _srv_response.ring_setup_spots = srv_input.ring_setup_spots; // ring setup spots (for manual ring placement)
            _srv_response.turn_no = srv_input.turn_no; // turn number
            _srv_response.delta = srv_input.delta; // delta data for replaying opponent's move

        // save to global obj and log
        yinsh.next_server_data = structuredClone(_srv_response);

        console.log('LOG - Server NEXT MOVE data saved');

    //////////////////////////////

    // save SETUP data
    } else if (f_setup) {

            // save specific fields 
            _srv_response.game_id = srv_input.game_id; // game ID
            _srv_response.rings = srv_input.rings; // rings
            _srv_response.markers = srv_input.markers; // markers (empty array on setup, unless testing otherwise)
            _srv_response.scenario_trees = srv_input.scenario_trees; // pre-computed scenario trees, for each possible move
            _srv_response.ring_setup_spots = srv_input.ring_setup_spots; // ring setup spots (for manual ring placement)
            _srv_response.turn_no = srv_input.turn_no; // turn number

            // determine if we're originator or joiner -> assign color to client (player_black_id / player_white_id)
            const f_joiner = srv_input.msg_code == joiner_ok_code;

            // client and opponent IDs (B | W)
            _srv_response.client_player_id = f_joiner ? srv_input.join_player_id : srv_input.orig_player_id;
            _srv_response.opponent_player_id = f_joiner ? srv_input.orig_player_id : srv_input.join_player_id;  
        
        // save to global obj and log
        yinsh.server_data = structuredClone(_srv_response);
        
        // make local working copy that we can alter, and from which markers/rings will be re-init in case of window resize
        // this way we can preserve local state without messing with server data
        yinsh.local_server_data = structuredClone(yinsh.server_data);

        console.log('LOG - Server SETUP data saved');      

    };

    // inform core anytime we receive an "advance_game_OK" message - but not always overwrite
    if (f_next_event) {

        // dispatch event for core game logic with action code from server | pass also data about game ending, if present
        if ('won_by' in srv_input && 'outcome' in srv_input){
            core_et.dispatchEvent(new CustomEvent('srv_next_action', { detail: { next_action_code: srv_input.next_action_code, game_status: srv_input.game_status, next_turn_no: srv_input.turn_no, outcome: srv_input.outcome, won_by: srv_input.won_by}}));
        } else {
            core_et.dispatchEvent(new CustomEvent('srv_next_action', { detail: { next_action_code: srv_input.next_action_code, game_status: srv_input.game_status, next_turn_no: srv_input.turn_no }}));
        };
    };
    
 };


export function get_local_server_data(){
    return yinsh.local_server_data;
};

// do we have delta data to replay? -> expected to return false only on setup for white player
export function delta_replay_check(){

    if ('next_server_data' in yinsh){
        return ('delta' in yinsh.next_server_data); 
        // always true if we have next_server_data saved
        // be aware the replay_opponent_turn wipes delta after each replay (by design)
        // so it will be true but empty
    } else {
        return false;
    };
};

export function get_delta(){
    return structuredClone(yinsh.next_server_data.delta);
};

// to avoid weird replays at end of the game, we wipe every time after replay
export function wipe_delta(){
    yinsh.next_server_data.delta = [];
};

// updates rings, markers, and scenario tree so to match data for next turn
export function swap_data_next_turn() {

        yinsh.server_data.rings = structuredClone(yinsh.next_server_data.rings);  // rings
        yinsh.server_data.markers = structuredClone(yinsh.next_server_data.markers); // markers
        yinsh.server_data.scenario_trees = structuredClone(yinsh.next_server_data.scenario_trees); // trees
        yinsh.server_data.ring_setup_spots = structuredClone(yinsh.next_server_data.ring_setup_spots); // ring spots
        yinsh.server_data.turn_no = yinsh.next_server_data.turn_no; // turn number

    // make local working copy
    yinsh.local_server_data = structuredClone(yinsh.server_data);

    console.log('LOG - Data ready for next turn');

};

// check if we have pre-move scoring opportunities
// this function is called even when we might not have scenario data
export function preMove_score_op_check(){

    return 'scores_preMove_avail' in yinsh.server_data.scenario_trees; // ref object should exist to avoid 'in' checks against undefined objects

};

// get pre-move scoring opportunities
export function get_preMove_score_op_data(){

    return structuredClone(yinsh.server_data.scenario_trees.scores_preMove_avail); // [{}]

};


// return tree among trees given input, otherwise return the only one
export function select_apply_scenarioTree(input_s_set, input_s_rings){

    const f_ret_default = (input_s_set.length == 0 && input_s_rings.length == 0); // passing empty arrays
    let _tree = undefined;

    try{
        // pick default/only tree
        if (f_ret_default) {

            _tree = structuredClone(yinsh.server_data.scenario_trees.treepots[0].tree); // first/only tree in array
        
        } else { // pick specific tree

            // NOTE: JS sets need an ad-hoc fn (defined above) for equality comparison
            // here we're building two arrays of sets (for s_set and s_rings) and finding all matches with sets built from inputs
            // at the intersection of the two vector of indexes we have the 0-based index of the correct treepot in the tp array
            // btw, serializing/de-serializing turns sets into arrays 

            // array to search in
            const _treepots = yinsh.server_data.scenario_trees.treepots;

            // preparing sets to use as comparison
            const in_sset = new Set(input_s_set);
            const in_srings = new Set(input_s_rings);

            // extracting/re-building arrays of sets from _treepots
            const gsid_v_sset = _treepots.map(tp => new Set(tp.gs_id.s_set));
            const gsid_v_srings = _treepots.map(tp => new Set(tp.gs_id.s_rings));

            // keep indexes at which the sets match, within each array
            const indexes_sset = gsid_v_sset.map( (s,index) => areSetsEqual(s, in_sset) ? index : -1 ).filter(s => s >= 0);
            const indexes_srings = gsid_v_srings.map( (s,index) => areSetsEqual(s, in_srings) ? index : -1 ).filter(s => s >= 0);

            // find first intersection (element in both arrays) -> there should be only one
            const tree_index = indexes_srings.find(s => indexes_sset.includes(s));

            // prevent error and leave tree undefined -> error is handled downstream
            if (typeof tree_index == 'number' && 0 <= tree_index < _treepots.length){ 
                _tree = structuredClone(_treepots[tree_index].tree);
            };

        };

        // check if we're returning something
        if (typeof _tree != 'undefined'){
            
            yinsh.objs.tree = _tree; // write tree in place
            const tree_id = f_ret_default ? '[ default ]' : `[ s_set: ${input_s_set}, s_rings: ${input_s_rings} ]`;

            console.log(`LOG - Tree ${tree_id} applied`);

        } else {
            throw(`Tree not found for s_set: ${input_s_set}, s_rings: ${input_s_rings}`);
        };

    } catch(err) {
        
            console.log(`ERROR - ${err}`);
    };
};

export function get_tree(){
    // here we write the tree that gets selected depending on the scenario
    // next_server_data -> server_data -> local_server_data (-> objs) 
    // issue: next_server_data & server_data are mostly to handle next & current inputs
    // but data is mixed in usage between the local copy and active objects (objs)
    return structuredClone(yinsh.objs.tree);
};

export function get_ring_setup_spots(){
    return yinsh.local_server_data.ring_setup_spots;
};


// Used by interaction
export function get_move_status(){
    return yinsh.objs.move_action.in_progress;
};


export function reset_preMove_scoring_actions(){
    yinsh.objs.preMove_scoring_actions = [];
};


export function pushTo_preMove_scoring_actions(mk_removed, score_ring_id){

    const pm_score_action = {mk_locs: mk_removed, ring_score: score_ring_id}
    yinsh.objs.preMove_scoring_actions.push(pm_score_action);
};

export function get_preMove_scoring_actions_done(){

    // return defaults if the array is empty
    if (yinsh.objs.preMove_scoring_actions.length > 0) {
       
        //console.log(`TEST - returning preMove: `, yinsh.objs.preMove_scoring_actions);
        return yinsh.objs.preMove_scoring_actions; 

    } else { // pass on default values if container is empty
 
        //console.log(`TEST - returning preMove: `, { mk_locs: [], ring_score: -1 });
        return [{ mk_locs: [], ring_score: -1 }];
    };
};


export function reset_scoring_actions(){

    yinsh.objs.scoring_actions = [];
};

export function pushTo_scoring_actions(mk_removed, score_ring_id){

    const score_action = {mk_locs: mk_removed, ring_score: score_ring_id}
    yinsh.objs.scoring_actions.push(score_action);
};

export function get_scoring_actions_done(){

    // return defaults if the array is empty
    if (yinsh.objs.scoring_actions.length > 0) {
        //console.log(`TEST - returning move: `, yinsh.objs.scoring_actions);
        return yinsh.objs.scoring_actions; 

    } else { // pass on default values if container is empty
        //console.log(`TEST - returning move: `, { mk_locs: [], ring_score: -1 });
        return [{ mk_locs: [], ring_score: -1 }];
    };

};

export function get_player_score(){

    return yinsh.objs.player_score;
};

export function get_opponent_score(){

    return yinsh.objs.opponent_score;
};

// increate player score and mark first available scoring slot as filled
export function increase_player_score(){

    // increase player score
    yinsh.objs.player_score += 1;
    const _player_score = get_player_score(); // 1,2,3

    // find scoring slot for the score and mark it as filled, otherwise leave it unaltered
    yinsh.objs.scoring_slots.map(s => (s.slot_no == _player_score && s.player == "this_player") ? fill_scoring_slot(s) : s)

    return yinsh.objs.player_score;
};

// acts on both logged score and the scoring slots
export function increase_opponent_score(){

    // increase player score
    yinsh.objs.opponent_score += 1;
    const _opponent_score = get_opponent_score(); // 1,2,3

    // find scoring slot for the score and mark it as filled, otherwise leave it unaltered
    yinsh.objs.scoring_slots.map(s => (s.slot_no == _opponent_score && s.player == "opponent") ? fill_scoring_slot(s) : s)

    return yinsh.objs.opponent_score;
};

// mark slot as filled and put ring shape in it
function fill_scoring_slot(s) {

    let new_s = s
        new_s.filled = true;
    return new_s
};


// log task in registry and mark it as in-progress
export function activate_task(task){

    if (task.name == 'mk_scoring_task') {

        yinsh.objs.current_mk_scoring.in_progress = true;
        yinsh.objs.current_mk_scoring.task_ref = task;

    } else if (task.name == 'ring_scoring_task') {

        yinsh.objs.current_ring_scoring.in_progress = true;
        yinsh.objs.current_ring_scoring.task_ref = task;

    } else if (task.name == 'canvas_animation_task') {

        yinsh.objs.current_animation.in_progress = true;
        yinsh.objs.current_animation.task_ref = task;
    };
};


// returns scoring options in the task (should be for current player only)
export function get_scoring_options_fromTask(){

    return structuredClone(yinsh.objs.current_mk_scoring.task_ref.data);
};

// function that allows caller to await for task completion
export async function task_completion(task_name){

    if (task_name == 'canvas_animation_task') {
        await yinsh.objs.current_animation.task_ref.promise;
    };
};


// return current state of task -> used mostly by interaction
// NOTE: could be cleaned up and made more general, use task_name directly as an index
export function get_task_status(task_name){

    if (task_name == 'mk_scoring_task') {

        return yinsh.objs.current_mk_scoring.in_progress;

    } else if (task_name == 'ring_scoring_task') {

        return yinsh.objs.current_ring_scoring.in_progress;

    } else if (task_name == 'canvas_animation_task') {

        return yinsh.objs.current_animation.in_progress;
    };
};


export function reset_scoring_tasks(){
    
    // overall scoring
    yinsh.objs.current_mk_scoring.in_progress = false;
    yinsh.objs.current_mk_scoring.task_ref = {};

    // ring scoring
    yinsh.objs.current_ring_scoring.in_progress = false;
    yinsh.objs.current_ring_scoring.task_ref = {};

};


// resolves task-promises so that they can return a value to the task initiator
export function complete_task(task_name, success_msg_payload){

    if (task_name == 'mk_scoring_task') {

        yinsh.objs.current_mk_scoring.in_progress = false;
        yinsh.objs.current_mk_scoring.task_ref.task_success(success_msg_payload);

    } else if (task_name == 'ring_scoring_task') {

        yinsh.objs.current_ring_scoring.in_progress = false;
        yinsh.objs.current_ring_scoring.task_ref.task_success(success_msg_payload);

    } else if (task_name == 'canvas_animation_task') {

        yinsh.objs.current_animation.in_progress = false;
        yinsh.objs.current_animation.task_ref.task_success(success_msg_payload);

    };

};


export function update_objects_next_turn(){

    init_rings();
    init_markers();
};

export function turn_start(){
   yinsh.objs.current_turn.in_progress = true;
   console.log(`USER - Turn #${get_current_turn_no()} started`); 
};

export function get_current_turn_no(){
    return yinsh.server_data.turn_no;
}

export function turn_end(){
   yinsh.objs.current_turn.in_progress = false;
   console.log(`USER - Turn completed`);
};

export function get_player_id() {
    return yinsh.server_data.client_player_id;
};

export function get_opponent_id() {
    return yinsh.server_data.opponent_player_id;
};

export function get_game_id() {
    return yinsh.server_data.game_id;
};


// initialize drop zones -> used to propagate location data to rings, markers, and visual cues
function init_drop_zones(){

    // recovering constants
    const mm_points = yinsh.constant_params.mm_points;
    const mm_points_rows = yinsh.constant_params.mm_points_rows;
    const mm_points_cols = yinsh.constant_params.mm_points_cols;

    // recovering S & H constants for drawing
    const S = yinsh.drawing_params.S;
    const H = yinsh.drawing_params.H;

    // recover offset values for starting to draw (centering board and zones)
    const _offset_x = yinsh.drawing_params.x_offset;
    const _offset_y = yinsh.drawing_params.y_offset;

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
                
                const apoint_x = _offset_x + H * k; // H/3 adj factor to slim margin left to canvas
                const apoint_y = _offset_y + H + S/2 * (j-1); // S/2 shift kicks in only from 2nd row
                
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

// initialize scoring slots (for rings)
export function init_scoring_slots(){

    // this function depends on having already determined who is who

    const _this_player_slot_name = "this_player";
    const _opponent_slot_name = "opponent"; // get other id 

    const local_score = get_player_score();
    const oppon_score = get_opponent_score();

    // recovering S & H constants for drawing
    const S = yinsh.drawing_params.S;
    const H = yinsh.drawing_params.H;

    const _start_BL_point = yinsh.drawing_params.start_BL;
    const _start_TR_point = yinsh.drawing_params.start_TR;

    // init temp empty array for scoring slots
    let _scoring_slots = [];

    /* RECIPE
    - pick top/right point and draw 3 in a row, leftward or downward (other player)
    - pick bottom/left point and draw 3 in a row, rightward or upward (this player)
    */

    // player slots
    for (let k = 1; k <=3; k++){

        //// HORIZONTAL
        //const s_point_x = _start_BL_point.x + k*1.05*S; // goes rightward
        //const s_point_y = _start_BL_point.y; // doesn't change

        //// VERTICAL
        const s_point_x = _start_BL_point.x + 0.3*S; // doesn't change
        const s_point_y = _start_BL_point.y - k*1.05*S; // goes up

        // score can be 1 -> 3, fill slot accordingly as we go through them
        const _score_flag = local_score >= k ? true : false;

        const _bl_slot = {  x: s_point_x, 
                            y: s_point_y,  
                            slot_no: k,
                            player: _this_player_slot_name,
                            filled: _score_flag
                        }

        // push object to temp array
        _scoring_slots.push(_bl_slot);

    };

     // opponent slots
     for (let k = 1; k <=3; k++){

        //// HORIZONTAL
        //const s_point_x = _start_TR_point.x - k*1.05*S; // goes leftward
        //const s_point_y = _start_TR_point.y; // doesn't change

        //// VERTICAL RIGHT
        //const s_point_x = _start_TR_point.x - 0.3*S; // doesn't change
        //const s_point_y = _start_TR_point.y + k*1.05*S; // goes down

        //// VERTICAL LEFT
        const s_point_x = _start_BL_point.x + 0.3*S; // doesn't change
        const s_point_y = _start_TR_point.y + k*1.05*S; // goes down

        // score can be 1 -> 3, fill slot accordingly as we go through them (negative)
        const _score_flag = oppon_score >= k ? true : false;

        const _tr_slot = {  x: s_point_x, 
                            y: s_point_y, 
                            slot_no: k,
                            player: _opponent_slot_name,
                            filled: _score_flag
                        }

        // push object to temp array
        _scoring_slots.push(_tr_slot);

    };

    // save to global obj and log (for some reason structuredClone fails)
    yinsh.objs.scoring_slots = _scoring_slots;
    console.log('LOG - Scoring slots initialized')
    
};

// return coordinates of first free slot for either current player or opponent
// caller is responsible for ensuring conditions for this function to always return x,y = i.e. score <=3
export function get_coord_free_slot(this_player = true){

    const _player = this_player == true ? "this_player" : "opponent"; 

    const _slot = yinsh.objs.scoring_slots.find(s => s.player == _player && s.filled == false);

    return {x: _slot.x, y:_slot.y}

};


// initializes visual cues for legal moves (all off by default)
function init_legal_moves_cues(){

    // retrieve drop_zones & S parameter
    const _drop_zones = yinsh.objs.drop_zones;
    
    // init empty array
    let _legal_moves_cues = [];

    if (cues_moves_flag) {
            
        // init a cue for each drop zone
        for(const d_zone of _drop_zones){

            // init cue object, shape will be drawn by drawing fn (also to handle hover state change)
            _legal_moves_cues.push({path: {}, loc: structuredClone(d_zone.loc), on: false, hover: false});
        
        };
    };

    // saves/overwrites updated array of visual cues and moves for picked ring
    yinsh.objs.legal_moves_cues = _legal_moves_cues;
    
    // logs operation
    console.log('LOG - Legal moves cues initialized');

}; 
        

// initializes rings and updates game state -> reads from rings data in DB
function init_rings(){

    const _ring_setup_id = 0;

    try {

        // initial locations of rings from server (use local working copy)
        const server_rings = yinsh.local_server_data.rings; 

        // constants used in logic
        const ring_id = yinsh.constant_params.ring_id;

        // init temporary rings array
        let _rings_array = [];

        // retrieve drop_zones
        const _drop_zones = yinsh.objs.drop_zones;
        
        // INITIALIZE RINGS
        // loop and match rings over drop zones
        for (const d_zone of _drop_zones) {
            for (const s_ring of server_rings) {

                if (s_ring.id == d_zone.loc.index){ // rings with a pre-defined location/id

                    // create ring object
                    const ring = {  path: {}, //  will hold the path, filled in by drawing function
                                    loc: structuredClone(d_zone.loc), // pass as value -> as we'll change the x,y for drawing we don't mess the original drop zone
                                    type: ring_id, 
                                    player: s_ring.player
                                };            

                    // add to temporary array
                    _rings_array.push(ring); 

                };
            };
        };

            // handling orphan ring without a drop zone
            // ring was alredy added to the array, and now it's being re-initialized
            // it's assumed there's only one ring with index 0, as the opponent ones' all have a determined loc_id
            const _ring_setup = server_rings.filter((ring) => (ring.id === _ring_setup_id));
            if (_ring_setup.length == 1) { // ring that is yet to be placed (by manual setup)

                const _init_player_loc = {  x: yinsh.drawing_params.x_offset + yinsh.drawing_params.H*12, 
                                            y: yinsh.drawing_params.start_BL.y - yinsh.drawing_params.S*1.7,
                                            index: _ring_setup_id };

                // create ring object
                const ring = {  path: {}, //  will hold the path, filled in by drawing function
                                loc: structuredClone(_init_player_loc), 
                                type: ring_id, 
                                player: structuredClone(_ring_setup[0].player)
                            };            

                // add to temporary array
                _rings_array.push(ring); 
            };

        // save rings and log
        yinsh.objs.rings = structuredClone(_rings_array);
        
        console.log('LOG - Rings initialized');

    } catch {
        console.log('LOG - No rings initialized');
    }
};

// initializes markers (only called after 1st+ turn)
function init_markers(){

    // check if we have any markers available -> this allows to call this function whenever
    try {

        // initial locations of rings from server
        const server_markers = yinsh.local_server_data.markers; 

        // constants used in logic
        const marker_id = yinsh.constant_params.marker_id;

        // init temporary rings array
        let _markers_array = [];

        // retrieve drop_zones
        const _drop_zones = yinsh.objs.drop_zones;
        
        // INITIALIZE RINGS
        // loop and match rings over drop zones
        for (const d_zone of _drop_zones) {
            for (const s_marker of server_markers) {

                if (s_marker.id == d_zone.loc.index){

                // create ring object
                const marker = {  path: {}, //  will hold the path, filled in by drawing function
                                loc: structuredClone(d_zone.loc), // pass as value -> we'll change the x,y for drawing and not mess the original drop zone
                                type: marker_id, 
                                player: s_marker.player
                            };            

                // add to temporary array
                _markers_array.push(marker); 
                
                };
            };
        };

        // save rings and log
        yinsh.objs.markers = structuredClone(_markers_array);
        
        console.log(`LOG - Markers initialized [ ${_markers_array.length} ]`);


    } catch {
        console.log('LOG - No markers to initialize');

    };
};


// keeps up to date the array of visual cues for legal moves, turning them on or off
// if move is NOT in progress, this function will turn them off
export function update_legal_cues(hover_cue_index = -1){

    // retrieves info on active move
    const _gstatus = get_game_status();
    const move_in_progress = get_move_status(); // -> true/false
    const _legal_moves_ids = structuredClone(yinsh.objs.move_action.legal_drops); // -> [11,23,90,etc]

    // retrieves array of visual cues (to be modified)
    let _legal_cues = yinsh.objs.legal_moves_cues;

    // turn matching cues on if a move was started
    if (cues_moves_flag && move_in_progress && _gstatus != GS_completed) {
        for (let cue of _legal_cues) {
            if (_legal_moves_ids.includes(cue.loc.index)) { 
                
                cue.on = true;
                
                // mark hover state for specific cue (loc.index given in fn input)
                if (hover_cue_index != -1 && hover_cue_index == cue.loc.index) {
                    cue.hover = true;
                } else {
                    cue.hover = false; 
                };
            };      
        };
        
    // otherwise turn everything off
    } else {
        for (let cue of _legal_cues) { cue.on = false, cue.hover = false };
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
    const matching_drop = _drop_zones.find(d => (d.loc.index == loc_index));

    
    // instate new marker object 
    const m = { path: {}, // <- to be filled in at drawing time
                loc: structuredClone(matching_drop.loc),
                type: _marker_id, 
                player: as_opponent ? _opponent_id : _player_id 
            }; 
          
    // add to temp array and to global object
    _markers.push(m);  
    yinsh.objs.markers = _markers;

    // update local server data ref copy
    const _new_m = {id: structuredClone(m.loc.index), player: structuredClone(m.player)};
    yinsh.local_server_data.markers.push(_new_m);

    // log change
    console.log(`LOG - Marker ${m.player} added at index ${m.loc.index}`);
        
};


// removes markers -> called when ring dropped in same location or scoring row is selected
export function remove_markers(mk_indexes_array){ 

    // retrieve array of markers 
    const _markers = yinsh.objs.markers;

    // updates global object
    yinsh.objs.markers = _markers.filter(m => !mk_indexes_array.includes(m.loc.index));

    // update local working data ref (keep all markers which id is not included in markers to be removed)
    yinsh.local_server_data.markers = yinsh.local_server_data.markers.filter(m => !mk_indexes_array.includes(m.id));

    console.log(`LOG - Marker(s) removed from indexes: ${mk_indexes_array}`);
    
};

// adds ring -> called when ring is manually placed
// 0 && false (outside right to board) - 0 && true (outside up to board)
// if opponent true, adds marker of the opponent's color (used for replaying moves)
export function add_ring(loc_index = 0, as_opponent = false){ 

    const _ring_setup_id = 0 

    // retrieve current player and id for markers
    const _player_id = structuredClone(yinsh.server_data.client_player_id);
    const _opponent_id = structuredClone(yinsh.server_data.opponent_player_id);
    const _ring_id = structuredClone(yinsh.constant_params.ring_id);

    // retrieve array of rings (to be modified) 
    let _rings = yinsh.objs.rings;

    // set initial ring location (loc_index -> known, 0 -> place at preset spot)
    // for replay of ring setup by opponent -> entry from outside/above board
    // for manual ring placement -> ready for pick up outside/right board
    const _init_player_loc = {  x: yinsh.drawing_params.x_offset + yinsh.drawing_params.H*12, 
                                y: yinsh.drawing_params.start_BL.y - yinsh.drawing_params.S*1.7, 
                                index: _ring_setup_id };

    const _init_opp_loc = { x: canvas.width/2, 
                            y: 0 - yinsh.drawing_params.S,
                            index: loc_index };
    
    // match init location to preset or find matching drop zone
    let _init_loc = as_opponent ? _init_opp_loc : _init_player_loc; 
    
    // instate new ring object 
    const r = { path: {}, // <- to be filled in at drawing time
                loc: structuredClone(_init_loc), 
                type: _ring_id, 
                player: as_opponent ? _opponent_id : _player_id 
            }; 
          
    // add to temp array and to global object
    _rings.push(r);  
    yinsh.objs.rings = _rings;

    // update local server data ref copy
    const _new_r = {id: structuredClone(r.loc.index), player: structuredClone(r.player)};
    yinsh.local_server_data.rings.push(_new_r);

    // log change
    console.log(`LOG - Ring ${r.player} added at index ${r.loc.index}`);
        
};

// removes ring -> called when scoring and picking ring to be removed
export function remove_ring(ring_loc_index){

    // updates global object -> remove picked ring
    yinsh.objs.rings = yinsh.objs.rings.filter(r => r.loc.index != ring_loc_index);

    // update local working data ref
    yinsh.local_server_data.rings = yinsh.local_server_data.rings.filter(r => r.id != ring_loc_index);
    
    console.log(`LOG - Ring removed from index ${ring_loc_index}`);
    
};
    

// flips markers (swaps player for objects & updates game state)
export function flip_markers(mk_indexes_array){

    // retrieve consts for player ids and marker type
    const _player_black_id = structuredClone(yinsh.constant_params.player_black_id);
    const _player_white_id = structuredClone(yinsh.constant_params.player_white_id);

    // retrieve array of markers 
    let _markers = yinsh.objs.markers;

    // helper function for doing the swapping
    const swap_m_player = (m_player) => (m_player == _player_black_id ? _player_white_id : _player_black_id);

    // flips markers 
    for (let m of _markers) {
        if (mk_indexes_array.includes(m.loc.index)) {
            
            // flips
            m.player = swap_m_player(m.player);   

        };
    };

    // updates global markers object 
    yinsh.objs.markers = _markers;

    // update local server data ref copy
    const _new_ref_markers = _markers.map((m) => ({id: m.loc.index, player: m.player}));
    yinsh.local_server_data.markers = structuredClone(_new_ref_markers);

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


// update loc information for last ring in the array (picked one) in both rings array and local working copy of server data
export function updateLoc_last_ring(new_loc){

    // retrieve index and old index loc of last ring in array (about to drop)
    const id_dropping_ring_inArray = getIndex_last_ring();
    const _old_ring_loc_id = structuredClone(yinsh.objs.rings[id_dropping_ring_inArray].loc.index);

    // save new location for last ring
    yinsh.objs.rings[id_dropping_ring_inArray].loc = structuredClone(new_loc);

    // update ring index also in working copy of server ref data
    const _index_ring_inArray = yinsh.local_server_data.rings.findIndex(r => r.id == _old_ring_loc_id);
    yinsh.local_server_data.rings[_index_ring_inArray].id = structuredClone(new_loc.index)

};


export function reset_move_action(){
    
    // editable copy
    let _move_action = structuredClone(yinsh.objs.move_action)

            _move_action.in_progress = false;
            _move_action.start_index = -1;
            _move_action.end_index = -1;
            _move_action.legal_drops = [];

    // save to global object
    yinsh.objs.move_action = structuredClone(_move_action);

};

   
// manipulates global variable ontaining data on current move underway
export function start_move_action(start_index){
    
    // editable copy
    let _move_action = structuredClone(yinsh.objs.move_action)
       
        _move_action.in_progress = true;
        _move_action.start_index = start_index;
        _move_action.end_index = -1;
        _move_action.legal_drops = getIndexes_legal_drops(start_index);

     // save to global object
     yinsh.objs.move_action = structuredClone(_move_action);

};

export function end_move_action(end_index){
    
    // editable copy
    let _move_action = structuredClone(yinsh.objs.move_action)
       
        _move_action.in_progress = false;
        // start_index stays as-is;
        _move_action.end_index = end_index;
        _move_action.legal_drops = [];

    // save to global object
    yinsh.objs.move_action = structuredClone(_move_action);

};


// both functions read from the same underlying move_action variable
// need to ensure that defaults are returned when only one action was done
export function get_ring_setup_action_done(){

    if (get_game_status() == GS_progress_rings) { // manual rings setup
        return structuredClone(yinsh.objs.move_action.end_index);
    } else { // normal gameplay
        return -1; // default
    };
};

export function get_move_action_done(){

    if (get_game_status() == GS_progress_game) { // normal gameplay
        return structuredClone({start: yinsh.objs.move_action.start_index, end: yinsh.objs.move_action.end_index});
    } else {
        return {start: -1, end: -1};
    };
};



// retrieve indexes of legal moves/drops from saved server data
// depending on game state, these might be ring drop locations for manual rings setup or a normal gameplay move
function getIndexes_legal_drops(start_index){

    let _gs = get_game_status()

    if (_gs == GS_progress_game){

        //console.log(`TEST - searching for legal drops starting at ${start_index}`);

        // keys (possible moves) are the first level of the branch for a ring loc
        const tree_branch = get_tree()[start_index];

        //console.log(`TEST - tree ${typeof tree_branch} found for ${start_index}`, tree_branch);

        // only keep keys that can be interpreted as numbers
        // javascript forces object keys to be strings, we need to parse them ¯\_(ツ)_/¯
        let _legal_drops = Object.keys(tree_branch).filter(Number).map(k => parseInt(k));
        
        return structuredClone(_legal_drops);

    } else if (_gs == GS_progress_rings) {

        return get_ring_setup_spots();

    };
};


// creates and destroys highlight around markers for row selection/highlight in scoring
// assumes that we either have all cold or all hot halos
export function update_mk_halos(mk_ids = [], hot_flag = false){

    // empty inner var
    let _mk_halos = [];
        
    if (mk_ids.length > 0) {

        // drawing param
        const S = yinsh.drawing_params.S;
        
        // retrieve drop zones
        const _drop_zones = yinsh.objs.drop_zones;
        
        for (const mk_id of mk_ids) {

            // let's check which is the matching drop_zone and retrieve the matching (x,y) coordinates
            for(const d_zone of _drop_zones){
                if (d_zone.loc.index == mk_id) {

                    // create coordinates and store in the global array
                    _mk_halos.push({x: d_zone.loc.x, y: d_zone.loc.y, hot: hot_flag});
            
                };
            };  
        };      
    };

    // acts as a reset function if arguments stay as default
    yinsh.objs.mk_halos = _mk_halos;
 
};


// creates and destroys highlight inside rings for cueing/selection in scoring, manual rings setup, or normal gameplay
// assumes that we either have all cold or all cold with 1 hot highlight
export function update_ring_cues(rings_ids = [], sel_ring = -1){

    const _ring_setup_id = 0 // index of setup ring
    const move_in_progress = get_move_status();
    const _gstatus = get_game_status();

    // drawing param
    const S = yinsh.drawing_params.S;
    const _mult_base = 0.13;
    const _mult_hover = 0.17;

    // empty inner var
    let _ring_cues = [];

    if (cues_rings_flag && _gstatus != GS_completed) { // CASE (for game status check): prevent cues being drawn for terminations mid-replay/move
        if (!move_in_progress && rings_ids.length > 1) { // CASE: ring scoring (we always have at least 2 rings to choose from)
            
            // retrieve drop zones
            const _drop_zones = yinsh.objs.drop_zones;
            
            for (const r_id of rings_ids) {

                // let's check which is the matching drop_zone and retrieve the matching (x,y) coordinates
                for(const d_zone of _drop_zones){
                    if (d_zone.loc.index == r_id) {

                        // create shape + coordinates and store in the global array
                        let h_path = new Path2D()

                        const hot_flag = (r_id == sel_ring) ? true : false;
                        const shape_diam = (r_id == sel_ring) ? S*_mult_hover : S*_mult_base;

                        h_path.arc(d_zone.loc.x, d_zone.loc.y, shape_diam, 0, 2*Math.PI);

                        _ring_cues.push({path: h_path, hot: hot_flag});
                
                    };
                };  
            };      
        } else if (!move_in_progress && rings_ids === _ring_setup_id) { // CASE: manual rings setup (which has index 0 by definition)

            // in this case we will draw the highlight directly at the {x,y} coordinates of the ring with index 0
            // we don't have a drop zone there
            const _ring_setup_id = 0 // <- should be in global const ?
            const _ring_setup = yinsh.objs.rings.filter((ring) => (ring.loc.index == _ring_setup_id))[0];

            // create shape + coordinates and store in the global array
            let h_path = new Path2D()

            const hot_flag = (_ring_setup_id == sel_ring) ? true : false;
            const shape_diam = (_ring_setup_id == sel_ring) ? S*_mult_hover : S*_mult_base;

            h_path.arc(_ring_setup.loc.x, _ring_setup.loc.y, shape_diam, 0, 2*Math.PI);

            _ring_cues.push({path: h_path, hot: hot_flag});

        };
    };

    // acts as a reset function if arguments stay as default
    // !move_in_progress ensures highlights go off when move starts
    // also enable/disable ring visual cues from UI makes sure array always stays empty
    yinsh.objs.ring_cues = _ring_cues;
 
};
