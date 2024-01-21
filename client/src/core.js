//////////////////////////////
//////////// CORE LOGIC


//////////// IMPORTS
import { server_ws_send, close_ws } from './server.js'
import { CODE_new_game_human, CODE_new_game_server, CODE_join_game, CODE_advance_game, CODE_resign_game } from './server.js'

import { init_global_obj_params, init_empty_game_objects, init_game_objs, get_game_id, get_player_id, get_winning_score, get_player_score } from './data.js'
import { get_move_status, start_move_action, end_move_action, get_move_action_done, reset_move_action, update_legal_cues } from './data.js'
import { bind_adapt_canvas, reorder_rings, add_marker, getIndex_last_ring, updateLoc_last_ring, flip_markers, remove_markers } from './data.js'
import { swap_data_next_turn, update_objects_next_turn, turn_start, turn_end, get_current_turn_no, update_ring_highlights, get_coord_free_slot} from './data.js' 
import { activate_task, get_scoring_options_fromTask, update_mk_halos, complete_task, reset_scoring_tasks, remove_ring, increase_player_score, increase_opponent_score, init_scoring_slots} from './data.js' 
import { preMove_score_op_check, get_preMove_score_op_data, select_apply_scenarioTree  } from './data.js'
import { delta_replay_check, get_delta, wipe_delta, get_preMove_scoring_actions_done, reset_preMove_scoring_actions, pushTo_preMove_scoring_actions, get_tree } from './data.js'
import { reset_scoring_actions, pushTo_scoring_actions, get_scoring_actions_done, get_task_status, task_completion } from './data.js'

import { refresh_canvas_state } from './drawing.js'
import { init_interaction, enableInteraction, disableInteraction } from './interaction.js'
import { ringDrop_playSound, markersRemoved_player_playSound, markersRemoved_oppon_playSound, endGame_win_playSound, endGame_draw_playSound, endGame_lose_playSound } from './sound.js'

//////////// GLOBAL DEFINITIONS

    // redefining console log function for production
    // console.log = function() {};

    // inits global event target for core logic
    globalThis.core_et = new EventTarget(); // <- this semicolon is very important

    // moves
    core_et.addEventListener('ring_picked', ringPicked_handler, false);
    core_et.addEventListener('ring_moved', ringMoved_handler, false);
    core_et.addEventListener('ring_drop', ringDrop_handler, false);
    core_et.addEventListener('marker_moved', markerMoved_handler, false);
   
    // server comms
    core_et.addEventListener('srv_next_action', server_actions_handler, false);
    
    // mk scoring
    core_et.addEventListener('mk_score_handling_on', mk_scoring_options_handler, false);
    core_et.addEventListener('mk_sel_picked', mk_scoring_options_handler, false);
    core_et.addEventListener('mk_sel_hover_ON', mk_sel_hover_handler, false);
    core_et.addEventListener('mk_sel_hover_OFF', mk_sel_hover_handler, false);
    
    // ring scoring
    core_et.addEventListener('ring_picked_scoring', ring_scoring_handler, false);
    core_et.addEventListener('ring_sel_hover_ON', ring_sel_hover_handler, false);
    core_et.addEventListener('ring_sel_hover_OFF', ring_sel_hover_handler, false);

    // action codes
    const CODE_action_play = 'play'
    const CODE_action_wait = 'wait'
    const CODE_action_end_game = 'end_game'

    // window resizing -> canvas and object adjustments
    window.addEventListener("resize", window_resize_handler);

    // game termination by user (via UI)
    core_et.addEventListener('game_exited', game_exit_handler, false);

    // handler for tests triggered from the UI - used only in DEV
    core_et.addEventListener('test_triggered', text_exec_from_ui_handler, false);


//////////// FUNCTIONS FOR INITIALIZING GAMES (NEW or JOIN)

// paint empty game board on canvas (called before any game is started)
export function draw_empty_game_board() {

    // inits global object (globalThis.yinsh) + constants used throughout the game
    init_global_obj_params();

    // initialize empty game objects
    init_empty_game_objects();

    // bind and make canvas size match its parent -> redraw everything
    window_resize_handler();

    disableInteraction();  // just in case -> when it's to move, other functions take care of enabling it again
}

// window resizing -> impacts canvas, board, and objects (via drawing constants)
function window_resize_handler() {

    // if move is in-progress -> drop ring in place, to avoid weird stuff, due to rings re-ordering in array while last should be the one moving
    // important to be called before objects are re-initialized
    if (get_move_status()) {

        // drop ring in-place and remove marker
        const start_move_index = get_move_action_done().start;
        end_move_action(start_move_index); 
        remove_markers([start_move_index]);

        // turns off cues
        reset_move_action(); 
        update_legal_cues();

        refresh_canvas_state();
    };

    // bind and make canvas size match its parent
    bind_adapt_canvas();
        
    // initialize other objects as well drop zones, rings, markers, scoring slots, cues - using new S/H constants
    init_game_objs(); 

    // if scoring tasks are in progress -> re-emit events so that options are regenerated
    if (get_task_status('mk_scoring_task')) {
        core_et.dispatchEvent(new CustomEvent('mk_score_handling_on'));
    };

    if (get_task_status('ring_scoring_task')) {
        core_et.dispatchEvent(new CustomEvent('ring_sel_hover_OFF'));
    };


    refresh_canvas_state();

};



// retrieve data from server (as originator or joiner) and init new game
export async function init_game_fromServer(originator = false, joiner = false, game_code = '', ai_game = false){

    // input could be changed to a more general purpose object, also to save/send game setup settings
    //_setup = {originator: false, joiner: false, game_code: undefined, ai_game: false}

    console.log(' -- Requesting new game --');

    // wait for any animation in progress to be done
    if (get_task_status('canvas_animation_task')) {
        ui_et.dispatchEvent(new CustomEvent('reset_dialog'));
        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `< A new game will start as the animation ends >` }));
        await task_completion('canvas_animation_task');
    };
    
    // wipe clean dialog box anytime a new game is requested
    ui_et.dispatchEvent(new CustomEvent('reset_dialog'));

    const request_start_time = Date.now()

    try{

        // inits global object (globalThis.yinsh) + constants used throughout the game
        init_global_obj_params();

        // initialize empty game objects
        init_empty_game_objects();
    
        if (joiner) {
            await server_ws_send(CODE_join_game, {game_id: game_code}); // asks to join existing game by ID
            
        } else if (originator) {
            await server_ws_send(CODE_new_game_human); // requests new game vs a friend

        } else if (ai_game) {
            await server_ws_send(CODE_new_game_server); // requests new game vs server/AI
        };
        
        // Bind canvas
        bind_adapt_canvas();
        
            // maps data from server to game objects
            // sets up drop zones and rings
            init_game_objs();
        
            // draw everything
            refresh_canvas_state();

            // initialize event listeners for canvas interaction
            init_interaction();

        // log local game ready
        console.log(`LOG - Game setup time: ${Date.now() - request_start_time}ms`);

        // log game code (later should be in the UI)
        console.log(`USER - Your GAME CODE is: ${yinsh.server_data.game_id}`);

        // inform the user which color they are
        const _player_id_string = get_player_id() == 'B' ? 'BLACK' : 'WHITE and move first';
        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `You'll play as ${_player_id_string}` }));

        // display code in the text prompt depending on player
        if (originator) {
            ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `Share this code to play: ${yinsh.server_data.game_id}` }));
        };

        // ask server what to do -> it will emit event on response
        await server_ws_send(CODE_advance_game, { game_id: get_game_id(), player_id: get_player_id(), turn_recap: false });

    } catch (err) {

        // log error
        console.log(`LOG - Game setup ERROR. ${Date.now() - request_start_time}ms`);

        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `< Sorry, something went wrong >` }));
        ui_et.dispatchEvent(new CustomEvent('game_status_update', { detail: `game_exited` }));

        console.log(err);

    };
};




//////////// EVENT HANDLERS FOR TURNS
async function server_actions_handler (event) {

    // triggered by data function, assumes next turn data has been saved by calling function

    const next_action_code = event.detail.next_action_code;
    const next_turn_no = event.detail.next_turn_no;

    if (next_action_code == CODE_action_play) {

        disableInteraction(); // a bit redundant, should be off from end of prev. turn

            console.log(`LOG - ${CODE_action_play} msg from server`);

            // hide game setup controls in the first turns in which the player moves (either 1 or 3)
            if (get_current_turn_no() <= 3) {
                ui_et.dispatchEvent(new CustomEvent('game_status_update', { detail: `game_in_progress` }));
            };

            // replay whole turn by opponent (if we have delta data)
            await replay_opponent_turn();

            // prepare data, objects, and canvas for next turn
            prep_next_turn(next_turn_no);

            // flag turn as in-progress
            turn_start(); 

        enableInteraction(); 

        // check if pre-move scoring opportunity is available -> handle it
        // once scoring is done, resume normal turn playing -> handle edge cases of game ending at pre-move stage -> how ?
        let pm_s_set = []; 
        let pm_s_rings = [];
        
        if (preMove_score_op_check()) {

            // wait a bit after move_replay is complete
            await sleep(300);

            const _player_scores_options = get_preMove_score_op_data();
            
            // handle (multiple) scoring for current player
            [ pm_s_set, pm_s_rings ] = await scoring_handler(_player_scores_options, true);

        };

        // check if game is over -> return early
        if (get_player_score() == get_winning_score()){
            
            disableInteraction();
           
            await end_turn_wait_opponent();
        
        } else { // otherwise enable move
            
            // pick correct scenario tree to move on
            select_apply_scenarioTree(pm_s_set, pm_s_rings);

            // inform user that they should still move
            ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `> Make your move` }));

        };

    } else if (next_action_code == CODE_action_wait) {

        console.log(`LOG - ${CODE_action_wait} msg from server`);

        disableInteraction(); // a bit redundant, is disabled by default
        console.log(`USER - Wait for your opponent.`); 

        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `Wait for your opponent` }));


    } else if (next_action_code == CODE_action_end_game) { // handling case of winning/losing game

        disableInteraction(); 

        close_ws(); // disconnect from server

        // replay turn by opponent (if we have delta data)
        await replay_opponent_turn();
        await sleep(600);
        refresh_canvas_state(); 

        const winning_player = event.detail.won_by;
        const outcome = event.detail.outcome;
        const _player_id = get_player_id();

        let user_comm_txt = "";

            if (winning_player == _player_id){ // local player wins 

                if (outcome == 'resign') { // winning as the other player resigns
                    user_comm_txt = `Your opponent resigned. You win! :)`;

                } else if (outcome == 'score') { // winning by score
                    user_comm_txt = `You win! :)`;

                } else if (outcome == 'mk_limit_score') {
                    user_comm_txt = `All markers placed. You win! :)`;
                };

                ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: user_comm_txt })); // inform user
                ui_et.dispatchEvent(new CustomEvent('game_status_update', { detail: `game_exited` })); // reset UI

                // trigger sound & winning animation
                endGame_win_playSound();
                await win_animation(); 

            } else if (winning_player == '' && outcome == 'mk_limit_draw') {  // nobody won, it's a draw

                user_comm_txt = `All markers placed. It's a draw!`;
                ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: user_comm_txt }));
                ui_et.dispatchEvent(new CustomEvent('game_status_update', { detail: `game_exited` }));

                await sleep(150); // draw animation is bit faster, adding extra pause post-replay/last-move
                endGame_draw_playSound();
                await draw_animation();

            } else { // opponent wins

                if (outcome == 'resign') { // winning as the other player resigns
                    user_comm_txt = `You resigned and lost! :(`;

                } else if (outcome == 'score') { // winning by score
                    user_comm_txt = `You lose! :(`;

                } else if (outcome == 'mk_limit_score') {
                    user_comm_txt = `All markers placed. You lose! :(`;
                };

                ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: user_comm_txt }));
                ui_et.dispatchEvent(new CustomEvent('game_status_update', { detail: `game_exited` }));

                endGame_lose_playSound(); // sound only

            };

        
        console.log("LOG - GAME COMPLETED");

    };
};


//////////// UTILS

// this entity is used to create instances of tasks/interactions the user is expected to complete, 
// like picking a row of markers or scoring ring - on resolution, they return information that can be given by who triggers promise resolution from the outside
// this is used for passing along ID information, that is then shared w/ the server
class Task {
    constructor(name, data = {}) {
        this.name = name;
        this.data = data;
        this.promise = new Promise((resolve, reject) => {
            this.task_success = (success_msg_payload) => resolve(success_msg_payload) // this msg is passed externally and returned as value by the promise
            this.task_failure = () => reject(new Error(`ERROR - ${name} - Task failure`))
        })
    }
};

// replays opponent's turn using DELTA data from server
async function replay_opponent_turn(){

    /* structure of delta replay data 
    
    note: fields included only if valued, order of execution as listed

        :scores_preMove_done => [ { :mk_locs => [locs], :ring_score => loc) } ]
		:move_done => (:mk_add => (loc, player), :ring_move = (start, end, player))
		:mk_flip => [locs]
		:scores_done => [ { :mk_locs => [locs], :ring_score => loc } ]
    
    */

    // only executes if we have delta data
    if (delta_replay_check()) {

        // log points made by opponent
        let num_opp_preMove_scores = 0;
        let num_opp_scores = 0;

        // activate single task for all the animations
        activate_task(new Task('canvas_animation_task'));

            const delta = get_delta(); // get a copy of the data

            console.log(`USER - Replaying opponent's moves`);
            // console.log(`LOG - Delta: `, delta);
            // ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `Your opponent is moving` }));

            const replay_start_time = Date.now();

            // any part of the turn is replayed only if we have data about it (server includes data only if actionable)

            // replay pre-move scoring 
            if('scores_preMove_done' in delta) {

                // replay move and increase score (handle scoring slot too)
                await replay_opponent_scoring(delta.scores_preMove_done);

                num_opp_preMove_scores = delta.scores_preMove_done.length;
            };

            // check if game is over -> ? now handled by payload code, but implies full replay -> need to handle server-side first detection of game ending at pre-move score

            // replay move (mk-add + ring move)
            if ('move_done' in delta) {

                // add opponent's marker
                await sleep(700);
                const _added_mk_index = delta.move_done.mk_add.loc; 
                add_marker(_added_mk_index, true); // -> as opponent
                refresh_canvas_state();

                // move and drop ring
                await sleep(650);
                await replay_ring_move_drop(delta.move_done.ring_move);
                ringDrop_playSound(); 

            };

            // replay flipped markers
            if ('mk_flip' in delta) {

                await sleep(150);
                flip_markers(delta.mk_flip);
                refresh_canvas_state();

            };

            // replay score
            if ('scores_done' in delta) {
                await replay_opponent_scoring(delta.scores_done);

                num_opp_scores = delta.scores_done.length;
            };

            // total replay time
            const _tot_time = Date.now() - replay_start_time;

            // log replay done
            console.log(`LOG - Total replay time: ${_tot_time}ms`);

            wipe_delta(); // clean up delta data to avoid weird replays at next turn, in case of last move - it's prevented server-side anyway

        // complete task
        complete_task('canvas_animation_task');

        // inform user
        const num_tot_opp_scores = num_opp_preMove_scores + num_opp_scores;
        // line below is ugly > reading from next, as data for upcoming turn not swapped yet > if there's delta, there's also next_server_data
        const num_player_preMove_rows = ('scores_preMove_avail' in yinsh.next_server_data.scenario_trees) ? yinsh.next_server_data.scenario_trees.scores_preMove_avail.s_rows.length : 0; 

        if (num_tot_opp_scores > 0) {

            let comm_string = (num_tot_opp_scores > 1) ? `Your opponent scored ${num_tot_opp_scores} points` : `Your opponent scored`;

            if (num_player_preMove_rows > 0) {

                comm_string += (num_player_preMove_rows > 1) ? `, but also formed rows for you` : `, but also formed a row for you`;
            };

            console.log(`USER - ${comm_string}`)
            ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: comm_string }));

        };

    } else {
        console.log(`LOG - No delta to replay`);
    };
};



// called by replay_opponent_turn, used for both pre-move and post-move scoring replay
// also takes care of increasing opponent's score and fill scoring slot
async function replay_opponent_scoring(score_actions_array){
 
    for (const sc_action of score_actions_array){

        const mk_removed_locs = sc_action.mk_locs;
        const ring_score_loc = sc_action.ring_score;

        const _score_mk_wait = 550;
        const _score_ring_wait = 600;
                    
        // MARKERS ROW 
            await sleep(_score_mk_wait);
            
            update_mk_halos(mk_removed_locs, true); // highlight markers
            refresh_canvas_state();
            
            await sleep(_score_mk_wait); // wait to let user see visual changes
    
            remove_markers(mk_removed_locs); // remove markers
            update_mk_halos(); // turn off markers highlight
            refresh_canvas_state(); // materialize changes on canvas
    
            markersRemoved_oppon_playSound(); // play sound
    
        //// RING SCORING
            await sleep(_score_ring_wait);
    
            // move scoring ring on top (need for animation)
            const _ring_index_in_array = yinsh.objs.rings.findIndex(r => r.loc.index == ring_score_loc);
            reorder_rings(_ring_index_in_array); // put ring last
    
            // grab start (x,y) coordinates   
            const _start = yinsh.objs.drop_zones.find(d => d.loc.index == ring_score_loc); // from matching drop zone
            const _start_xy = {x:_start.loc.x, y:_start.loc.y};
    
            // grab end coordinates -> these will be of the scoring slots for the opponent (hence input is false)
            const _slot_coord = get_coord_free_slot(false);
            const _end_xy = {x:_slot_coord.x, y:_slot_coord.y};    
    
            // animate ring move via synthetic mouse event
            await syn_object_move(_start_xy, _end_xy, 45, 15);
            
            // increases player's score by one and mark scoring slot as filled
            const new_opponent_score = increase_opponent_score();
            console.log(`LOG - New opponent score: ${new_opponent_score}`);
    
            // remove ring from rings array 
            remove_ring(ring_score_loc); // remove ring 
    
            // refresh canvas (ring is drawn as part of the scoring slot now)
            refresh_canvas_state();

    };

};

// update current/next data -> reinit/redraw everything (on-canvas nothing should change)
function prep_next_turn(_turn_no){

    // do something only for turns no 1+ (no delta data at turn 1)
    if (_turn_no > 1) {

        swap_data_next_turn(); // -> takes data from next
        update_objects_next_turn(); // -> update objcts
        
        // -> set variables clean to avoid sending bad data to the server -> ghost replays on the other side, as they're sent in each move-end payload
        reset_preMove_scoring_actions(); 
        reset_move_action();
        reset_scoring_actions();
        
        refresh_canvas_state(); 

    };
};


// useful for pauses during move replay
const sleep = ms => new Promise(r => setTimeout(r, ms));

// move ring between start and end location and drop it
async function replay_ring_move_drop(moved_ring_details) {

    // start/end indexes for moved ring
    const _mr_start_index = moved_ring_details.start;
    const _mr_end_index = moved_ring_details.end;
    const _mr_player = moved_ring_details.player_id;

    console.log(`LOG - Ring ${_mr_player} picked from index ${_mr_start_index}`);

    // move ring to end of array (top for drawing)
    const _mr_index_in_array = yinsh.objs.rings.findIndex(r => r.loc.index == _mr_start_index);
    reorder_rings(_mr_index_in_array);

    // grab start/end (x,y) coordinates
    const _drop_start = yinsh.objs.drop_zones.find(d => d.loc.index == _mr_start_index);
    const _drop_end = yinsh.objs.drop_zones.find(d => d.loc.index == _mr_end_index);

        const start_xy = {x:_drop_start.loc.x, y:_drop_start.loc.y};
        const end_xy = {x:_drop_end.loc.x, y:_drop_end.loc.y};

    // animate move via synthetic mouse event
    await syn_object_move(start_xy, end_xy, 30, 15);

    // update dropping ring loc information 
    updateLoc_last_ring(_drop_end.loc);

    // retrieve ring and its index details
    const dropping_ring = yinsh.objs.rings.at(-1); // last ring
    const dropping_ring_loc_index = dropping_ring.loc.index;

    console.log(`LOG - Ring ${dropping_ring.player} moved to index ${dropping_ring_loc_index}`);

};

//////////// EVENT HANDLERS FOR LOCAL GAME MECHANICS

// listens to ring picks and updates game state
function ringPicked_handler (event) {

    // detail contains index in rings array of picked ring
    const index_picked_ring_in_array = event.detail;
    
    // retrieve ring and its loc details
    const picked_ring = yinsh.objs.rings[index_picked_ring_in_array];
    const picked_ring_loc = structuredClone(picked_ring.loc)
    const picked_ring_loc_index = picked_ring_loc.index;

        // logging
        console.log(`LOG - Ring ${picked_ring.player} picked from index ${picked_ring_loc_index}`);

    // remove the element and put it back at the end of the array, so it's always drawn last => appears on top of all other rings, useful when moving it
    // we could also move ring to dedicated structure that is drawn last and then put back in, but roughly same copying work
    reorder_rings(index_picked_ring_in_array);

    // write start of the currently active move to a global variable
    start_move_action(picked_ring_loc_index);

    // place marker in same location (it's assumed this player)
    add_marker(picked_ring_loc_index);

    // initializes array of legal drop ids + visual cues for starting index
    // will read from current move to see which moves to consider
    update_legal_cues();

    // draw changes
    refresh_canvas_state();

};

// listens to a ring being moved -> updates ring location & triggers re-draw
function ringMoved_handler (event) {

    // event.detail.coord -> mousePos as {x, y}

    // if index of ring in rings array is given, use it (multi-ring animation)
    if ('id_in_array' in event.detail) {
        
        // updates x and y ring location
        yinsh.objs.rings[event.detail.id_in_array].loc.x = event.detail.coord.x;
        yinsh.objs.rings[event.detail.id_in_array].loc.y = event.detail.coord.y;
    
    } else { // pick last ring 

        // the last ring in the array is the one being moved (drawn last / on top)
        const id_picked_ring = getIndex_last_ring();

        // updates x and y ring location
        yinsh.objs.rings[id_picked_ring].loc.x = event.detail.coord.x;
        yinsh.objs.rings[id_picked_ring].loc.y = event.detail.coord.y;

    };
    
    // redraw everything
    refresh_canvas_state();

};

function markerMoved_handler (event) {

    // event.detail.coord -> mousePos as {x, y}

    // if index of marker in array is given, use it (multi-markers animation)
    if ('id_in_array' in event.detail) {
        
        // updates x and y ring location
        yinsh.objs.markers[event.detail.id_in_array].loc.x = event.detail.coord.x;
        yinsh.objs.markers[event.detail.id_in_array].loc.y = event.detail.coord.y;
    
    } else { // pick last marker 

        // the last marker in the array is the one being moved (drawn last / on top)
        const id_last_marker = yinsh.objs.markers.length-1;

        // updates x and y ring location
        yinsh.objs.markers[id_last_marker].loc.x = event.detail.coord.x;
        yinsh.objs.markers[id_last_marker].loc.y = event.detail.coord.y;

    };
    
    // redraw everything
    refresh_canvas_state();

};



// listens to ring snaps/drops -> flips markers -> triggers score handling -> refresh states
async function ringDrop_handler (event) {

    // retrieves loc object of snapping drop zone
    const snap_drop_loc = event.detail;

    // retrieves ids of legal drops for the ring that was picked up
    const _current_legal_drops = yinsh.objs.move_action.legal_drops;

    // save move starting index
    const start_move_index = get_move_action_done().start;

    // retrieve ring and its index details (last)
    const dropping_ring = yinsh.objs.rings.at(-1);
    
    // retrieve index of drop location
    const drop_loc_index = structuredClone(snap_drop_loc.index);

    // check if drop coordinates belong to possible moves or dropped in-place
    if (_current_legal_drops.includes(drop_loc_index) || drop_loc_index == start_move_index){

        // drops ring -> update ring loc information 
        updateLoc_last_ring(snap_drop_loc);

        // // -> important to close the move to prevent side effects when it comes to visual cues
        end_move_action(drop_loc_index); 
        
        // updates legal cues (all will be turned off as move is no longer in progress)
        update_legal_cues();

        // re-draw everything and play sound
        refresh_canvas_state(); 
        ringDrop_playSound(); 

        // logging
        console.log(`LOG - Ring ${dropping_ring.player} moved to index ${drop_loc_index}`);

        // CASE: same location drop, nothing to flip, remove added marker
        if (drop_loc_index == start_move_index){

            reset_move_action(); // just in case - wipe move data if same-loc drop, won't be used

            // remove marker
            remove_markers([drop_loc_index]);
            refresh_canvas_state(); 

            // log
            console.log(`LOG - Ring dropped in-place. Turn is still on.`)

        } else {

            // CASE: ring moved to a legal destination -> look at scenarioTree to see what happens
            // retrieve scenario as tree.index_start_move.index_end_move
            // THE tree was written in place by server_actions fn, among several possible if a preMove score was available
            const move_scenario = get_tree()[start_move_index][drop_loc_index];
            console.log(`LOG - Move scenario: `, move_scenario);

            // CASE: some markers must be flipped
            if ('mk_flip' in move_scenario){
                // flip and re-draw
                await sleep(150);
                flip_markers(move_scenario.mk_flip);
                refresh_canvas_state(); 
            };

            // CASE: scoring was made -> score handling is triggered

            const f_score_av_player = 'scores_avail_player' in move_scenario;
            const f_score_av_opp = 'scores_avail_opp' in move_scenario;

            // communications towards the user if we have a some outcome | own score vs also scored for the opponent
            if (f_score_av_player || f_score_av_opp) {

                let comm_string = ``;

                    if (f_score_av_player) { // scored

                        comm_string = `You scored`;

                        if (f_score_av_opp) { // but also formed row(s) for the opponent
                            comm_string += (move_scenario.scores_avail_opp.s_rows.length > 1) ? `, but also formed rows for your opponent` : `, but also formed a row for your opponent`;
                        };
    
                    } else if (f_score_av_opp) { // only formed row(s) for the opponent
                        comm_string += (move_scenario.scores_avail_opp.s_rows.length > 1) ? `You formed rows for your opponent` : `You formed a row for your opponent`;        
                    };

                console.log(`USER - ${comm_string}`);
                ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: comm_string }));
                
            };

            // HANDLE (MULTIPLE) SCORING
            if (f_score_av_player){

                // retrieve scoring information for player
                const _player_scores = structuredClone(move_scenario.scores_avail_player);

                await scoring_handler(_player_scores);

            };

            // TURN COMPLETED -> notify server with info on what happened in the turn
            await end_turn_wait_opponent();
        
        };

    // CASE: invalid location for drop attempt
    } else { 

        console.log("USER - Invalid drop location");

        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `You can't drop the ring there` }));


    };
};


// can be called from different points to terminate turn
async function end_turn_wait_opponent() {

    // turn completed -> wrap up info to send back on actions taken by player
    const turn_recap_info = {   score_actions_preMove : get_preMove_scoring_actions_done(), 
                                move_action: get_move_action_done(),
                                score_actions: get_scoring_actions_done(), 
                                completed_turn_no: get_current_turn_no() 
                            }; 

    console.log(`LOG - Completed player turn no: ${get_current_turn_no()}`);
    
    turn_end(); // local turn ends

    // prep msg payload
    let msg_payload = {};
    msg_payload.turn_recap = turn_recap_info;
    msg_payload.game_id = get_game_id();
    msg_payload.player_id = get_player_id();

    // notify server about completed turn
    try{
        
        
        await server_ws_send(CODE_advance_game, msg_payload); 

    } catch(err) {

        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `< Sorry, something went wrong >` }));
        ui_et.dispatchEvent(new CustomEvent('game_status_update', { detail: `game_exited` }));

        console.log(err);
    };
   
};



// wrapper around splice for easier array manipulation
// modifies array in-place if v is found, otherwise left as-is 
function remove_fromArray(array, v){

    if (array.includes(v)){
        array.splice(array.indexOf(v),1);
    };
};

// function for retrieving active scoring rows, given raw scoring info + id of row taken
function active_scoring_rows(s_rows, s_sets_obj, row_id) {
    // given the if of the row taken, we're looking for matching sets 
    // they should contain the id of the row we took, and have other rows available for picking -> otherwise we return empty
    // w_s_sets is updated every time we call this function, in progressive refinements

    let sets_vec = structuredClone(s_sets_obj.v); // working copy, before modifying vec in passed obj

    console.log(`TEST - input w_s_sets: `, s_sets_obj.v);
    console.log(`TEST - picked row_id: `, row_id);
    
    // keep only sets for which row_id is a possibility
    sets_vec = sets_vec.filter(s => s.includes(row_id));
    
    if (sets_vec.flat().length > 0) { // using flat() as we might get a bunch of empty arrays

        console.log(`TEST - filtered w_s_sets: `, sets_vec);

        // remove from surviving sets the row that was picked/removed
        sets_vec.map(s => remove_fromArray(s, row_id));
        
        // overwrite vector inside object, as starting point for next pick
        // https://stackoverflow.com/questions/21978392/modify-a-variable-inside-a-function -> modifying var by reference
        s_sets_obj.v = structuredClone(sets_vec);

        console.log(`TEST - new w_s_sets: `, sets_vec);

        // take unique rows ids across all valid sets, and get 0-based index of matching rows
        const rows_ids = [ ...new Set(sets_vec.flat()) ].map(k => k - 1); 

        // retrieve scoring rows data by id
        const active_rows = s_rows.filter( (row, id) => rows_ids.includes(id) );

        console.log(`TEST - new active_rows: `, active_rows);

        return active_rows;

    } else { // return directly empty array if we got nothing to work with
       
        s_sets_obj.v = [];
        return [];
    };

};

// function for retrieving 1-based index of removed scoring row, taking mk_sel in input
function index_removed_sRow(s_rows, mk_sel) {

    // remove taken rows ids from all ids, and shift all by one
    // mk_sel is assumed unique among all scoring rows 
    let taken_row_id = s_rows.findIndex(r => r.mk_sel == mk_sel); 

    if (taken_row_id != -1){
        taken_row_id += 1 // shifted by 1
    } else {
        throw new Error(`LOG - Error finding scoring row for mk_sel : ${mk_sel}`);
    };

    return taken_row_id;

};


// general function for handling scoring -> creates tasks & events
async function scoring_handler(player_scoring_ops, pre_move = false){

    // extract relevant info from scoring_ops
    const s_rows = player_scoring_ops.s_rows; // -> [ {mk_locs, mk_sel} ]
    const s_sets = player_scoring_ops.s_sets; // -> [ [1,2,4], [2,3,5], [3,4] ] (1-based indexes of items in scores)

    // for multiple scoring, the player first sees all rows lit up
    // after first pick, one or more sets are picked to repeat the logic
    // using an utility function to filter over the 

    // save results of actions taken in dedicated variables (preMove_score_actions, score_actions) through setters
    let s_sets_obj = {v: structuredClone(s_sets)};
    let done_flag = false; // we'll set this to true once we run out of set options
    let active_rows = structuredClone(s_rows);
    let taken_rows_ids = [];
    let taken_rings_ids = [];
    while (!done_flag) {
        
        // vars to be returned, initialized to default values
        let _mk_sel_pick = -1;
        let _mk_locs_removed = [];
        let _ring_score_pick = -1;

        // MK SCORING
        // create task for markers scoring, with data on scoring options (=rows)
        const mk_scoring = new Task('mk_scoring_task', active_rows);
        activate_task(mk_scoring); // save scoring options and activate task

            // event to light up mk scoring options first
            core_et.dispatchEvent(new CustomEvent('mk_score_handling_on'));

            // user communications
            if (active_rows.length > 1){
                ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `> Pick a row of markers` }));
            } else {
                ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `> Pick the row of markers` }));
            }

            [ _mk_sel_pick, _mk_locs_removed ]= await mk_scoring.promise // wait for mk to be picked -> return value of loc_id

            // identify picked row index and save it
            const row_id = index_removed_sRow(s_rows, _mk_sel_pick);
            taken_rows_ids.push(row_id);


        // RING SCORING
        // create task for ring scoring
        const ring_scoring = new Task('ring_scoring_task');
        activate_task(ring_scoring); 

            // highlight rings - need to pass player own rings ids to the function
            await sleep(300);
            core_et.dispatchEvent(new CustomEvent('ring_sel_hover_OFF'));

            // user communications
            console.log("USER - Pick a ring to be removed from the board!");
            ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `> Pick a ring` }));
            
            // wait for ring to be picked -> return value of loc_id 
            _ring_score_pick = await ring_scoring.promise 
            taken_rings_ids.push(_ring_score_pick);


        // reset scoring tasks
        reset_scoring_tasks();

        // save scoring action 
        if (pre_move) {
            pushTo_preMove_scoring_actions(_mk_locs_removed, _ring_score_pick);
        } else {
            pushTo_scoring_actions(_mk_locs_removed, _ring_score_pick);
        };

            
        // update available scoring sets -> change flag if needed OR repeat
        active_rows = active_scoring_rows(s_rows, s_sets_obj, row_id)

        if (active_rows.length == 0){
            done_flag = true; // -> exit loop
        } else {
            await sleep(200); // -> wait before turning on new rows
        };

    };

    // return relevant values -> picked set and rings (sorted)
    return [ taken_rows_ids, taken_rings_ids ];

};    

// listens to scoring events -> begins/ends score handling 
function mk_scoring_options_handler(event){

    // CASE: score handling started
    if (event.type === 'mk_score_handling_on') {

        // retrieve scoring options
        const scoring_options = get_scoring_options_fromTask();

        // retrieve ids of selectable markers
        const mk_sel = scoring_options.map(option => option.mk_sel);

        // paint selectable markers in cold color
        update_mk_halos(mk_sel, false);
        refresh_canvas_state();

    // CASE: marker was picked -> score handling is completed
    } else if (event.type === "mk_sel_picked") {

        disableInteraction(); // disable/enable interaction to avoid surprises

            console.log("LOG - Scoring option selected");

            // retrieve index of marker being clicked on
            const mk_sel_picked_id = event.detail;

            // get markers for selected row
            const scoring_options = get_scoring_options_fromTask();
            const _mk_row_to_remove = (scoring_options.find(option => option.mk_sel == mk_sel_picked_id)).mk_locs;

            // remove markers for selected row
            remove_markers(_mk_row_to_remove);

            // turn halos off and refresh canvas
            update_mk_halos();
            refresh_canvas_state();

            // play sound
            markersRemoved_player_playSound();

            // complete score handling task (success)
            const success_msg = [mk_sel_picked_id, _mk_row_to_remove]; // value to be returned by completed task (mk_sel marker + mk_locs removed)
            complete_task('mk_scoring_task', success_msg);

        enableInteraction();

    };
};

// listens to hovering event over sel_markers in scoring rows -> handle highlighting
function mk_sel_hover_handler (event) {

    // CASE: mk sel hovered on -> need to highlight markers of a specific row
    if (event.type === 'mk_sel_hover_ON') {

        // retrieve index of marker
        const hovered_marker_id = event.detail;

        // retrieve markers to highlight for row
        const scoring_options = get_scoring_options_fromTask();
        const _mk_row_to_highlight = (scoring_options.find(option => option.mk_sel == hovered_marker_id)).mk_locs;

        // prepare halo objects and refresh canvas
        update_mk_halos(_mk_row_to_highlight, true);
        refresh_canvas_state();


    // CASE: mk sel hovered off -> need to restore baseline highlighting
    } else if (event.type === 'mk_sel_hover_OFF') {

        // retrieve scoring options
        const scoring_options = get_scoring_options_fromTask();

        // retrieve ids of selectable markers
        const mk_sel = scoring_options.map(option => option.mk_sel);

        // paint the selectable markers in cold color
        update_mk_halos(mk_sel, false);
        refresh_canvas_state();

    };

};

// listens for scoring ring to be picked, animates its move to the 1st scoring slot and then removes it from the obj array
async function ring_scoring_handler (event) {

    disableInteraction(); // -> prevents further interaction and triggering of 'ring_sel_hover' event and avoid zombie ring highlights to stay on

        // retrieve index of ring (meant as location)
        const picked_ring_id = event.detail;

        // move picked ring on top (need for animation)
        const _ring_index_in_array = yinsh.objs.rings.findIndex(r => r.loc.index == picked_ring_id);
        reorder_rings(_ring_index_in_array);

        // empty array of rings highlights
        update_ring_highlights(); 

        // grab start (x,y) coordinates     
        const _start = yinsh.objs.drop_zones.find(d => d.loc.index == picked_ring_id);
        const _start_xy = {x:_start.loc.x, y:_start.loc.y};

        // grab end coordinates -> these will be of the scoring slots
        const _slot_coord = get_coord_free_slot(true);
        const _end_xy = {x:_slot_coord.x, y:_slot_coord.y};    

        // animate ring move via synthetic mouse event
        await syn_object_move(_start_xy, _end_xy, 30, 15);
        
        // increases player's score by one and fill scoring slot
        const new_player_score = increase_player_score();
        console.log(`LOG - New player score: ${new_player_score}`);

        // refresh canvas (ring is drawn in scoring slot now)
        // scoring slots call draw_rings function with a ring_spec to draw a ring in their x,y coordinates
        refresh_canvas_state();

        // remove ring from rings array 
        remove_ring(picked_ring_id);

        // empty array of rings highlights
        update_ring_highlights(); 
        refresh_canvas_state();

        // completes ring scoring task
        const success_msg = picked_ring_id; // value to be returned by completed task
        complete_task('ring_scoring_task', success_msg);


    enableInteraction(); // restore interaction

};

// listens to hovering event over rings when having to pick a ring for scoring -> handle highlighting
function ring_sel_hover_handler (event) {

    // CASE: ring sel hovered on -> get darker
    if (event.type === 'ring_sel_hover_ON') {

        // retrieve players' rings and index of hovered ring
        const player_rings_ids = event.detail.player_rings;
        const hovered_ring_id = event.detail.hovered_ring;

        // prepare ring cores objects and refresh canvas
        update_ring_highlights(player_rings_ids, hovered_ring_id);
        refresh_canvas_state();

    // CASE: ring sel hovered off -> need to establish/restore baseline highlighting of all rings
    } else if (event.type === 'ring_sel_hover_OFF') {

        // retrieve indexes of rings for player
        const player_rings_ids = yinsh.objs.rings.filter((r) => (r.player == get_player_id())).map(r => r.loc.index);

        // prepare ring cores objects and refresh canvas
        update_ring_highlights(player_rings_ids);
        refresh_canvas_state();

    };
};


async function text_exec_from_ui_handler(){

    /* 
    //// TEST 1 - ring scoring (hover effect + animation)

        console.log('LOG - Test triggered - Ring scoring');
        
        enableInteraction();

        // mark ring selection as true
        yinsh.objs.current_mk_scoring.in_progress = false;
        yinsh.objs.current_ring_scoring.in_progress = true;

        // interaction JS should work its magic from now on
    */ 

    
     /*
    //// TEST 2 - testing win game animation

        await win_animation(); 
    */ 
    
    
};

async function win_animation() {

    console.log('LOG - Win game animation started');

    // activate task to inform rest of application an animation is underway
    activate_task(new Task('canvas_animation_task'));

        const win_anim_start_time = Date.now();


        await sleep(200);

        // loop over every object (rings + markers)
        // pick a different one every 50ms or so
        // accelerate it downwards beyond 900 of height

        // RINGS
        // as we'll pick rings from last in array to the end (easier), we keep track of the virtual array length
        let _rings_vir_len = yinsh.objs.rings.length;
        let _syn_RINGS_moves_prom_array = [];

        while (_rings_vir_len > 0) {

            // pick last ring in array, no need to re-order it
            const r_index_no = _rings_vir_len - 1 ; 
            const r_loc = structuredClone(yinsh.objs.rings[r_index_no].loc); 

            const _start = {x: r_loc.x, y:r_loc.y};
            const _end = {x: r_loc.x, y:r_loc.y + canvas.height};

            const syn_move_prom = syn_object_move(_start, _end, 30, 15, 'ring', r_index_no); // we trigger it but don't await for it to finish, we move onto other objects
            _syn_RINGS_moves_prom_array.push(syn_move_prom);
            await sleep(42);

            _rings_vir_len -= 1; // decrement virtual len 

        };

        // MARKERS
        let _markers_vir_len = yinsh.objs.markers.length;
        let _syn_MARKERS_moves_prom_array = [];

        while (_markers_vir_len > 0) {

            // pick last marker in array
            const mk_index_no = _markers_vir_len - 1 ; 
            const mk_loc = structuredClone(yinsh.objs.markers[mk_index_no].loc); 

            const _start = {x: mk_loc.x, y:mk_loc.y};
            const _end = {x: mk_loc.x, y:mk_loc.y + canvas.height};

            const syn_move_prom = syn_object_move(_start, _end, 30, 15, 'marker', mk_index_no); // we trigger it but don't await for it to finish, we move onto other objects
            _syn_MARKERS_moves_prom_array.push(syn_move_prom);
            await sleep(42);

            _markers_vir_len -= 1; // decrement virtual len 

        };

        // to prevent weird things happening due to a resize, wipe objects data when all moves are done
            // RINGS
            await Promise.all(_syn_RINGS_moves_prom_array);
            yinsh.objs.rings = [];
            yinsh.local_server_data.rings = [];
        
            // MARKERS
            await Promise.all(_syn_MARKERS_moves_prom_array);
            yinsh.objs.markers = [];
            yinsh.local_server_data.markers = [];

        // handle scoring slots - draw them more transparent over time and then delete them
            
            const out_alpha_array = Array(25).fill().map((_, i) => (i)/25).reverse(); // 0.96 -> 0 values
            for (let i = 0; i < out_alpha_array.length; i++) {
                await sleep(3);
                refresh_canvas_state({}, out_alpha_array[i]);
            };
            yinsh.objs.scoring_slots = [];
            yinsh.objs.player_score = 0;
            yinsh.objs.opponent_score = 0;
            

        // BOARD -  fade out & zoom
        await sleep(150);
        let _scale = 1;
        let _line = 1;
        let _offset = {x:0, y:0};

        for (let i = 0; i < out_alpha_array.length; i++) {
            
            await sleep(30);

            _line += 0.7;
            _scale += 0.1;
            _offset.x -= canvas.width/33;
            _offset.y -= canvas.height/25;

            // move start drawing point up left as we zoom in - note: these values are okayish only for desktop
            const board_params = {  alpha: out_alpha_array[i], 
                                    line: _line, 
                                    scale: _scale, // increase scale over time
                                    offset: _offset };

            refresh_canvas_state(board_params, 0); // scoring slots have been deleted, but passing 0 anyway
        };

        // BOARD - fade-in
        init_scoring_slots(); // regenerate empty scoring slots (scores set to zero)
        
        await sleep(350);

        const in_alpha_array = Array(25).fill().map((_, i) => (i)/25); // 0 -> 0.96 values
        for (let i = 0; i < in_alpha_array.length; i++) {
            
            await sleep(25);

            let board_params = { alpha: in_alpha_array[i] }; // other values will be the default ones
            
            refresh_canvas_state(board_params, in_alpha_array[i]); // passing also non-zero alpha for scoring slots

        };
        refresh_canvas_state(); // calling refresh for last alpha step 0.96 -> 1

    // end task 
    complete_task('canvas_animation_task');

    // win animation complete
    console.log(`LOG - Win animation done in: ${Date.now() - win_anim_start_time}ms`);

};


async function draw_animation(){

    console.log('LOG - Draw endgame animation started');

    // activate task to inform rest of application an animation is underway
    activate_task(new Task('canvas_animation_task'));

        const draw_anim_start_time = Date.now();

        // fade away scoring slots
        const out_alpha_array = Array(25).fill().map((_, i) => (i)/25).reverse(); // 0.96 -> 0 values
        for (let i = 0; i < out_alpha_array.length; i++) {
            await sleep(3);
            refresh_canvas_state({}, out_alpha_array[i]);
        };

        // empty scoring slots and wipe scores
        yinsh.objs.scoring_slots = [];
        yinsh.objs.player_score = 0;
        yinsh.objs.opponent_score = 0;


        // remove random markers from the board
        const N_mk = 3;
        const n_mk_loops = Math.ceil(51/N_mk);

        for (let i = 0; i < n_mk_loops; i++) {
                
            await sleep(50);
            const mks_random_picks = sample_n(yinsh.objs.markers, N_mk).map(m => m.loc.index);

            remove_markers(mks_random_picks);
            refresh_canvas_state();

        };

        // remove random rings from the board
        const N_rn = 1;
        const n_rn_loops = Math.ceil(yinsh.objs.rings.length/N_rn);

        for (let i = 0; i < n_rn_loops; i++) {
                
            await sleep(15);
            const ring_random_pick = sample_n(yinsh.objs.rings, N_rn).map(r => r.loc.index);

            remove_ring(ring_random_pick);
            refresh_canvas_state();

        };

        await sleep(100);

        // fade away board - scoring slots have been deleted, but passing 0 anyway
        for (let i = 0; i < out_alpha_array.length; i++) {
            await sleep(20);
            refresh_canvas_state({alpha: out_alpha_array[i]},0);
        };

        // re-init scoring slots
        init_scoring_slots();

        await sleep(100);

        // draw back scoring slots and board
        const in_alpha_array = Array(25).fill().map((_, i) => (i)/25); // 0 -> 0.96 values
        for (let i = 0; i < in_alpha_array.length; i++) {
            
            await sleep(20);
            refresh_canvas_state({alpha: in_alpha_array[i]}, in_alpha_array[i]);
        };

        refresh_canvas_state(); // final refresh with default alpha == 1

    // end task 
    complete_task('canvas_animation_task');

    // win animation complete
    console.log(`LOG - Draw animation done in: ${Date.now() - draw_anim_start_time}ms`);

};


/////////// EXITING GAME - prompted by user via resign action, mediated by server
export async function game_exit_handler(event){

    // wait for any animation in progress to be done
    if (get_task_status('canvas_animation_task')) {
        ui_et.dispatchEvent(new CustomEvent('reset_dialog'));
        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `< You resigned >` })); // acknowledging the user action even if the animation is on
        await task_completion('canvas_animation_task');
    };

    // disable any canvas interaction
    disableInteraction();

    // notify server (game is lost automatically) --> other user is informed by server
    // note: we're keeping turn_recap here to avoid handling exceptions inside the server game_runner -> to be fixed
    const _resign_msg_payload = { game_id: get_game_id(), player_id: get_player_id(), turn_recap: false };
    
    try {

        // we receive formal 'you lost' response from server, handled by next_action_handler
        await server_ws_send(CODE_resign_game, _resign_msg_payload); // server will acknowledge

    } catch(err) {

        // we handle if/when communication w/ server fails, (eg. websocket timeout) so we trigger the game ending anyway and UI can be reset
        ui_et.dispatchEvent(new CustomEvent('new_user_text', { detail: `< Sorry, something went wrong >` }));
        ui_et.dispatchEvent(new CustomEvent('game_status_update', { detail: `game_exited` }));

        console.log(err);
    };
    
    // force close WS connection to avoid surprises on either end 
    close_ws();
};


// HELPER FUNCTIONS

// animate last ring (ie. on top of canvas) to move between start and end points -> as the ring is moved, it triggers redraw of the canvas
// can also be used for moving markers - either last or a specific ID (multi-object animation, without array re-ordering)
async function syn_object_move(start, end, no_steps, sleep_ms, obj = 'ring', id_in_array = -1){

    let _progress = 0;

    for(let i=1; i <= no_steps; i++){ 

        // compute cumulative integral for sin
        // results in non-linear progress for having ease-in/out effect
        if (i == no_steps) { // force 100% as integral is very approximated
            _progress = 1;
        } else {
            _progress += (Math.sin(Math.PI*((i)/no_steps)) * Math.PI/no_steps )/2;
        };
    
        const _new_x = start.x + _progress*(end.x - start.x);
        const _new_y = start.y + _progress*(end.y - start.y);

        await sleep(sleep_ms);

        const synthetic_mouse_coord = {x:_new_x, y:_new_y};

        // we use OBJ parameter to detemine which event we want to dispatch (ring vs marker)

        if (obj == 'ring') {

            // for animating multiple rings, we need to avoid re-shuffling them in the array
            // with the last parameter, we pass directly the ring index in the array, so the handler doesn't reshuffle it
            if (id_in_array == -1) {
                core_et.dispatchEvent(new CustomEvent('ring_moved', { detail: {coord: synthetic_mouse_coord }}));
            } else {
                core_et.dispatchEvent(new CustomEvent('ring_moved', { detail: {coord: synthetic_mouse_coord, id_in_array: id_in_array }}));
            };

        } else if (obj == 'marker') {
            
            if (id_in_array == -1) {
                core_et.dispatchEvent(new CustomEvent('marker_moved', { detail: {coord: synthetic_mouse_coord }}));
            } else {
                core_et.dispatchEvent(new CustomEvent('marker_moved', { detail: {coord: synthetic_mouse_coord, id_in_array: id_in_array }}));
            };

        };

    };
};

// sample without replacement N elements from array
function sample_n(array, N) {

    // early return 
    if (N >= array.length){
        return array;
    };

    let sampled_indexes = [];
    const sample_from = array.map((val, index) => index);
    
    while (sampled_indexes.length < N){

        const picked_index = sample_from[Math.floor(Math.random() * sample_from.length)];

        if (!sampled_indexes.includes(picked_index)){ // save only unique values
            sampled_indexes.push(picked_index);
        };
    };

    return array.filter((val, index) => sampled_indexes.includes(index));

};