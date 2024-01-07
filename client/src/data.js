// DATA
// data objects + functions operating on them + data utils (like reshape_index)

import { setup_ok_codes, next_ok_codes, joiner_ok_code} from './server.js'

// utility function: from col-major julia matrix to linear index in js
const reshape_index = (row, col) => ( (col-1)*19 + row - 1); // js arrays start at 0, hence the -1 offset


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

    // note: these should come from the server as well (ids etc, so I can change them from one-side only)
    _params.ring_id =  "R";
    _params.marker_id =  "M";
    _params.player_black_id = "B";
    _params.player_white_id = "W";


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

    const h_ratio_factor = 12; // empirical value ~ number of triangle sides in height + 3 (proxy for scoring slots)
    const w_ratio_factor = h_ratio_factor + 2 ; // +2 as we want more H space for scoring slots

        // find out if height or width is the constraint for fittng triangles of the board
        const S_by_height = canvas.height/h_ratio_factor;
        const S_by_width = canvas.width/w_ratio_factor;
        
        const S_param = Math.round(Math.min(S_by_width, S_by_height));
        const H_param = Math.round(S_param * Math.sqrt(3)/2);

    // compute X & Y offset for drawing board and drop zones
    const _off_x = canvas.width/2 - 6*H_param;
    const _off_y = H_param/2;

        // compute offset for drawing scoring slots
        const _start_BL_point = {x: H_param, y: H_param/3 + h_ratio_factor*H_param }
        const _start_TR_point = {x: canvas.width - H_param, y: H_param}
 
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

        _game_objects.pre_move_scoring = {mk_sel: -1, ring_score: -1, mk_locs : []}; // save details in case pre-move scoring took place
       
        _game_objects.current_move = {in_progress: false, start_index: 0, legal_drops: []}; // -> details for move currently in progress 
        _game_objects.legal_moves_cues = []; // -> array for cues paths (drawn on/off based on legal drops ids)
        
        _game_objects.current_mk_scoring = {in_progress: false, task_ref: {}}; // referencing task of general score handling
        _game_objects.current_ring_scoring = {in_progress: false, task_ref: {}}; // referencing task of ring picking within score handling
        _game_objects.mk_halos = []; // -> halos objects
        _game_objects.ring_highlights = []; // -> highlights for rings

        _game_objects.player_score = 0; // -> player score 
        _game_objects.opponent_score = 0; // -> opponent score 


    // save to global obj and log
    yinsh.objs = structuredClone(_game_objects);
    console.log('LOG - Empty game objects initialized');

};


// saving server response data - internally handles if it's setup or next move data
// assumes input data has msg_code field, and are returning w/ OK code
export function save_server_response(srv_input){

    // check if it's SETUP or NEXT MOVE data
    const f_setup = setup_ok_codes.includes(srv_input.msg_code);
    const f_next_event = next_ok_codes.includes(srv_input.msg_code);
    const f_next_save = next_ok_codes.includes(srv_input.msg_code) && ('delta_array' in srv_input); // save/overwrite next data only if we have a delta

    // init temporary object
    let _srv_response = {};

    // save NEXT MOVE data
    if (f_next_save) {

            _srv_response.rings = srv_input.rings; // rings
            _srv_response.markers = srv_input.markers; // markers
            _srv_response.scenarioTree = srv_input.scenarioTree; // scenario tree
            _srv_response.turn_no = srv_input.turn_no; // turn number

            _srv_response.delta_array = srv_input.delta_array; // delta array
            _srv_response.TEMP_scenario = srv_input.new_scenario; // new scenario tree(s)


        // save to global obj and log
        yinsh.next_server_data = structuredClone(_srv_response);

        // save delta data separately if present - TO BE REVISITED: CORE DOES AN UNDEF CHECK + IT SHOULD BE W/ THE REST OF SRV DATA
        yinsh.delta_array = structuredClone(srv_input.delta_array);
        
        console.log(`TEST - DELTA: `, yinsh.delta_array);

        console.log('LOG - Server NEXT MOVE data saved');

    //////////////////////////////

    // save SETUP data
    } else if (f_setup) {

            // save specific fields 
            _srv_response.game_id = srv_input.game_id; // game ID
            _srv_response.rings = srv_input.rings; // rings
            _srv_response.markers = srv_input.markers; // markers (empty array on setup, unless testing otherwise)
            _srv_response.scenarioTree = srv_input.scenarioTree; // pre-computed scenario tree for each possible move
            _srv_response.turn_no = srv_input.turn_no; // turn number

            _srv_response.TEMP_scenario = srv_input.new_scenario; // new scenario tree(s)

            // determine if we're originator or joiner -> assign color to client (player_black_id / player_white_id)
            const f_joiner = srv_input.msg_code == joiner_ok_code;

            // client and opponent IDs (B | W)
            _srv_response.client_player_id = f_joiner ? srv_input.join_player_id : srv_input.orig_player_id;
            _srv_response.opponent_player_id = f_joiner ? srv_input.orig_player_id : srv_input.join_player_id;  
        
        // save to global obj and log
        yinsh.server_data = structuredClone(_srv_response);
        
        // make local working copy that we can alter, and from which markers/rings will be re-init in case of window resize
        // this way we can preserve local state without messing with server data
        yinsh.local_server_data_ref = structuredClone(yinsh.server_data);

        console.log('LOG - Server SETUP data saved');      

    };

    // inform core anytime we receive an "advance_game_OK" message - but not always overwrite
    if (f_next_event) {

        // dispatch event for core game logic -> action handling 
        // NOTE: what's the point of saving this if we're passing srv_input to the handler anyway, save/event firing should be smarter
        core_et.dispatchEvent(new CustomEvent('srv_next_action', { detail: srv_input }));

    };
    
 };


 export function get_local_server_data_ref(){

    return yinsh.local_server_data_ref;

 };


// updates rings, markers, and scenario tree so to match data for next turn
export function swap_data_next_turn() {

        // rings
        yinsh.server_data.rings = structuredClone(yinsh.next_server_data.rings);

        // markers
        yinsh.server_data.markers = structuredClone(yinsh.next_server_data.markers);

        // tree
        yinsh.server_data.scenarioTree = structuredClone(yinsh.next_server_data.scenarioTree);

        // new (TEMP) tree
        yinsh.server_data.TEMP_scenario = structuredClone(yinsh.next_server_data.TEMP_scenario);

        // turn number
        yinsh.server_data.turn_no = yinsh.next_server_data.turn_no;

    // make local working copy
    yinsh.local_server_data_ref = structuredClone(yinsh.server_data);

    console.log('LOG - Data ready for next turn');

};


// check if we have pre-move scoring opportunities
export function preMove_score_op_check(){

    return f_check = ('score_preMove_avail' in yinsh.server_data.TEMP_scenario);

};

// get pre-move scoring opportunities
export function get_preMove_score_op_data(){

    return structuredClone(yinsh.server_data.TEMP_scenario.score_preMove_avail);

};

// return tree among trees given input, otherwise return the only one
export function select_apply_scenarioTree(mk_s = -1, ring_s = -1){

    f_ret_default = mk_s == -1 && ring_s == -1;
    let _tree = {};

    try{
        // pick default/only tree
        if (f_ret_default) {

            _tree = structuredClone(yinsh.server_data.TEMP_scenario.move_trees[0].tree); // first/only tree in array
        
        } else { // pick specific tree

            _trees_array = yinsh.server_data.TEMP_scenario.move_trees;
            _tree = _trees_array.find( t => (t.gs_id.mk_sel == mk_s && t.gs_id.ring_score == ring_s) ).tree;

        };

        // check if we're returning something
        if (typeof _tree != 'undefined'){
            
            yinsh.server_data.scenarioTree = _tree // write tree in place
            const tree_id = f_ret_default ? 'default' : `{mk_sel:${mk_s}, ring_score:${ring_s}}`

            console.log(`LOG - Tree ${tree_id} selected`);

            return _tree; 
        } else {
            throw(`Tree not found for mk_sel: ${mk_s} ring_score: ${ring_s}`);
        };

    } catch(err) {
        
            console.log(`ERROR - ${err}`);
    };
};

// return relevant tree given input choices of scoring

export function get_move_status(){
    return yinsh.objs.current_move.in_progress;
};

export function activate_task(task){

    if (task.name == 'mk_scoring_task') {

        yinsh.objs.current_mk_scoring.in_progress = true;
        yinsh.objs.current_mk_scoring.task_ref = task;

    } else if (task.name == 'ring_scoring_task') {

        yinsh.objs.current_ring_scoring.in_progress = true;
        yinsh.objs.current_ring_scoring.task_ref = task;

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

export function set_preMove_scoring_pick(mk_sel_id = -1, score_ring_id = -1){

    // if called without arguments it will reset the var (-1 def)

    yinsh.objs.pre_move_scoring.mk_sel_pick = mk_sel_id;
    yinsh.objs.pre_move_scoring.score_ring_pick = score_ring_id;

};

export function get_preMove_scoring_pick(){

    return yinsh.objs.pre_move_scoring; 

};


export function get_task_status(task_name){

    if (task_name == 'mk_scoring_task') {

        return yinsh.objs.current_mk_scoring.in_progress;

    } else if (task_name == 'ring_scoring_task') {

        return yinsh.objs.current_ring_scoring.in_progress;

    };
};

export function get_current_turn_no(){
    return yinsh.server_data.turn_no;
}

// returns scoring options in the task (should be for current player only)
export function get_scoring_options(){

    return structuredClone(yinsh.objs.current_mk_scoring.task_ref.data);
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



// resolves task-promises so that they can return a value to the task initiator
export function complete_task(task_name, success_msg){

    if (task_name == 'mk_scoring_task') {

        yinsh.objs.current_mk_scoring.in_progress = false;
        yinsh.objs.current_mk_scoring.task_ref.task_success(success_msg);

    } else if (task_name == 'ring_scoring_task') {

        yinsh.objs.current_ring_scoring.in_progress = false;
        yinsh.objs.current_ring_scoring.task_ref.task_success(success_msg);

    };

};


export function update_objects_next_turn(){

    init_rings();
    init_markers();
};

export function turn_start(){
   yinsh.objs.current_turn.in_progress = true;
   console.log(`USER - Turn started`);
};

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
// NOTE: sensitive to canvas size
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

    // canvas parameters
    const _width = canvas.width;
    const _height = canvas.height;

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
    - pick top/right point and draw 3 in a row, leftward (other player)
    - pick bottom/left point and draw 3 in a row, rightward (this player)
    */

    // bottom left slots (local player)
    for (let k = 1; k <=3; k++){

        const s_point_x = _start_BL_point.x + k*1.05*S; // goes rightward
        const s_point_y = _start_BL_point.y; // doesn't change

        // create paths and add them to the global array
        let slot_path = new Path2D();
            slot_path.arc(s_point_x, s_point_y, S*0.3, 0, 2*Math.PI);

        // score can be 1 -> 3, fill slot accordingly as we go through them
        const _score_flag = local_score >= k ? true : false;

        const _bl_slot = {  x: s_point_x, 
                            y: s_point_y,  
                            path: slot_path,
                            slot_no: k,
                            player: _this_player_slot_name,
                            filled: _score_flag
                        }

        // push object to temp array
        _scoring_slots.push(_bl_slot);

    };

     // top right slots
     for (let k = 1; k <=3; k++){

        const s_point_x = _start_TR_point.x - k*1.05*S; // goes leftward
        const s_point_y = _start_TR_point.y; // doesn't change

        // create paths and add them to the global array
        let slot_path = new Path2D();
            slot_path.arc(s_point_x, s_point_y, S*0.3, 0, 2*Math.PI);

        // score can be 1 -> 3, fill slot accordingly as we go through them (negative)
        const _score_flag = oppon_score >= k ? true : false;

        const _tr_slot = {  x: s_point_x, 
                            y: s_point_y, 
                            path: slot_path,
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
    const S = yinsh.drawing_params.S;

    // init empty array
    let _legal_moves_cues = [];
            
        // init a cue for each drop zone
        for(const d_zone of _drop_zones){

            // create shape + coordinates and push to array
            let cue_path = new Path2D()
                cue_path.arc(d_zone.loc.x, d_zone.loc.y, S*0.08, 0, 2*Math.PI);
            
            _legal_moves_cues.push({path: cue_path, loc: structuredClone(d_zone.loc), on: false});
        
        };


    // saves/overwrites updated array of visual cues and moves for picked ring
    yinsh.objs.legal_moves_cues = _legal_moves_cues;
    
    // logs operation
    console.log('LOG - Visual cues for legal moves initialized');

}; 
        

// initializes rings and updates game state -> reads from rings data in DB
function init_rings(){

    try {

        // initial locations of rings from server (use local working copy)
        const server_rings = yinsh.local_server_data_ref.rings; 

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

                if (s_ring.id == d_zone.loc.index){

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

        // save rings and log
        yinsh.objs.rings = structuredClone(_rings_array);
        
        console.log('LOG - Rings initialized & game state updated');

    } catch {
        
        console.log('LOG - No rings initialized');

    }

};

// initializes markers (only called after 1st+ turn)
function init_markers(){

    // check if we have any markers available -> this allows to call this function whenever
    try {

        // initial locations of rings from server
        const server_markers = yinsh.local_server_data_ref.markers; 

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
        
        console.log('LOG - Markers initialized & game state updated');


    } catch {

        console.log('LOG - No markers to initialize');

    };

};



// keeps up to date the array of visual cues for legal moves, turning them on or off
// if move is NOT in progress, this function will turn them off
export function update_legal_cues(){

    // retrieves info on active move
    const move_in_progress = yinsh.objs.current_move.in_progress; // -> true/false
    const _legal_moves_ids = yinsh.objs.current_move.legal_drops; // -> [11,23,90,etc]

    // retrieves array of visual cues (to be modified)
    let _legal_cues = yinsh.objs.legal_moves_cues

    // turn matching cues on if a move was started
    if (move_in_progress) {

        for (let cue of _legal_cues) {
    
            if (_legal_moves_ids.includes(cue.loc.index)) { cue.on = true };      
        };
        
    // otherwise turn everything off
    } else {
        for (let cue of _legal_cues) { cue.on = false };
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
    yinsh.local_server_data_ref.markers.push(_new_m);

    // log change
    console.log(`LOG - Marker ${m.player} added at index ${m.loc.index}`);
        
};


// removes markers -> called when ring dropped in same location or scoring row is selected
export function remove_markers(mk_indexes_array){ // input is array of loc indexes

    // retrieve array of markers 
    const _markers = yinsh.objs.markers;

    // updates global object
    yinsh.objs.markers = _markers.filter(m => !mk_indexes_array.includes(m.loc.index));

    // update local working data ref (keep all markers which id is not included in markers to be removed)
    yinsh.local_server_data_ref.markers = yinsh.local_server_data_ref.markers.filter(m => !mk_indexes_array.includes(m.id));

    console.log(`LOG - Marker(s) removed from indexes: ${mk_indexes_array}`);
    
};

// removes ring -> called when scoring and picking ring to be removed
export function remove_ring_scoring(ring_loc_index){

    // updates global object -> remove picked ring
    yinsh.objs.rings = yinsh.objs.rings.filter(r => r.loc.index != ring_loc_index);

    // update local working data ref
    yinsh.local_server_data_ref.rings = yinsh.local_server_data_ref.rings.filter(r => r.id != ring_loc_index);
    
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
    yinsh.local_server_data_ref.markers = structuredClone(_new_ref_markers);

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
    const _index_ring_inArray = yinsh.local_server_data_ref.rings.findIndex(r => r.id == _old_ring_loc_id);
    yinsh.local_server_data_ref.rings[_index_ring_inArray].id = structuredClone(new_loc.index)

};

    
// manipulates global variable ontaining data on current move underway
export function update_current_move(in_progress = false, start_index = 0){
    
    // editable copy
    let _current_move = structuredClone(yinsh.objs.current_move)

        // reset global variable in case of defaults
        if(in_progress == false){
            _current_move.in_progress = false;
            _current_move.start_index = 0;
            _current_move.legal_drops = [];

        // save data if different arguments are passed
        } else if (in_progress == true){
            _current_move.in_progress = true;
            _current_move.start_index = start_index;
            _current_move.legal_drops = getIndexes_legal_drops(start_index);

        };

    // save to global object
    yinsh.objs.current_move = structuredClone(_current_move);

};


// retrieve indexes of legal moves/drops from saved server data
function getIndexes_legal_drops(start_index){

    // keys (possible moves) are the first level of the branch for a ring
    const tree_branch = yinsh.server_data.scenarioTree[start_index];

    let _legal_drops = [];
    for (const key in tree_branch){
        _legal_drops.push(parseInt(key)); // javascript forces object keys to be strings, we need to parse them ¯\_(ツ)_/¯
    };
    
    return structuredClone(_legal_drops);

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

                    // create shape + coordinates and store in the global array
                    let h_path = new Path2D()
                    h_path.arc(d_zone.loc.x, d_zone.loc.y, S*0.33, 0, 2*Math.PI);
            
                    _mk_halos.push({path: h_path, hot: hot_flag});
            
                };
            };  
        };      
    };

    // acts as a reset function if arguments stay as default
    yinsh.objs.mk_halos = _mk_halos;
 
};


// creates and destroys highlight inside rings for cueing/selection in scoring
// assumes that we either have all cold or all cold with 1 hot highlight
export function update_ring_highlights(rings_ids = [], sel_ring = -1){

    // empty inner var
    let _ring_highlights = [];
        
    if (rings_ids.length > 0) {

        // drawing param
        const S = yinsh.drawing_params.S;
        
        // retrieve drop zones
        const _drop_zones = yinsh.objs.drop_zones;
        
        for (const r_id of rings_ids) {

            // let's check which is the matching drop_zone and retrieve the matching (x,y) coordinates
            for(const d_zone of _drop_zones){
                if (d_zone.loc.index == r_id) {

                    // create shape + coordinates and store in the global array
                    let h_path = new Path2D()

                    const hot_flag = (r_id == sel_ring) ? true : false;
                    const shape_diam = (r_id == sel_ring) ? S*0.2 : S*0.14;

                    h_path.arc(d_zone.loc.x, d_zone.loc.y, shape_diam, 0, 2*Math.PI);

                    _ring_highlights.push({path: h_path, hot: hot_flag});
            
                };
            };  
        };      
    };

    // acts as a reset function if arguments stay as default
    yinsh.objs.ring_highlights = _ring_highlights;
 
};
