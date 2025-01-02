import { createSignal, Show, Switch, Match, createResource, createEffect, on, onMount, onCleanup } from "solid-js";
import { init_game_fromServer, draw_empty_game_board } from "./core.js";
import { enableSound, disableSound } from "./sound.js";
import { enableRingsCues, disableRingsCues } from "./data.js";
import { enableLegalMovesCues, disableLegalMovesCues } from "./data.js";
import svg_sound_OFF from "/src/assets/sound-0.svg";
import svg_sound_ON from "/src/assets/sound-2.svg";
import rings_cues_OFF from "/src/assets/circle.svg";
import rings_cues_ON from "/src/assets/circle_dot.svg";
import moves_cues_OFF from "/src/assets/cross.svg";
import moves_cues_ON from "/src/assets/cross_dot.svg";


// event target for UI
globalThis.ui_et = new EventTarget(); 


export function GameCanvas() {
  // canvas component
  // auto-sizes based on size of outer container div -> div is already in place when component is rendering
  
  // paint empty canvas after canvas elem rendering is done
  onMount(() => {draw_empty_game_board()}); 

  return (
    <canvas id="canvas"></canvas>
  );
}


// component for giving the player game tips and instructions
export function UserText() {

  // setter is called from core component, and text re-rendered when value changes

  const _welcome_txt = 'Click < PLAY > to start a new game';
  const [userText, set_userText] = createSignal(_welcome_txt);

  // handle incoming events from CORE
  ui_et.addEventListener('new_user_text', userTxt_handler, false);
  ui_et.addEventListener('reset_dialog', userTxt_handler, false);

    function userTxt_handler(event) {

      if (event.type === 'new_user_text') {

        // add text
        const _new_text = (userText().length > 0) ? (userText() + "\n" + "\n" + event.detail) : event.detail;
        set_userText(_new_text);
        
        // scroll text to end
        let txt_div = document.getElementById('user_txt_id');
        txt_div.scrollTop = txt_div.scrollHeight; 

      };

      if (event.type === 'reset_dialog') {
        set_userText("");
      };
    
    } 

  return (
    <div class="user_text_div" id="user_txt_id">{userText}</div>
  );
}



// game setup controls should be different if game is in progress (eg. resign/abandon game)
export function GameSetup() {

  // flag for keeping track if game is ongoing or not (changes controls mode)
  const [game_inProgress, set_game_inProgress] = createSignal(false);
  //const toggle_gameInProgress = () => set_gameInProgress(!gameInProgress()); // called by event from core (?)
  // hide core controls, display option to abandon game + similar for when other game is over -> ask for confirmation?
  
  ui_et.addEventListener('game_status_update', game_status_handler, false);

  // setting var to true so to show option to exit/resign/abandon game
  function game_status_handler(event){

    // 
    if (event.detail == 'game_in_progress') {
      set_game_inProgress(true);
    };

    if (event.detail == 'game_exited') {

      // reset all signals to false, to ensure UI flow is unwrapped
      set_play(false);
      set_joinClick(false);
      set_game_inProgress(false);
      set_exitGame(false);

      set_joinnewgmsettings(false);
      set_new_gm_ai_settings(false);


    }; 
  };

  // tell CORE the user has decided to exit the game
  function fn_game_exited_by_user(){
    core_et.dispatchEvent(new CustomEvent('game_exited'));

  };

  // first 'PLAY' button
  const [play, set_play] = createSignal(false);
  const toggle_Play = () => set_play(!play());

  // vars for interrupting/abandoning game once it starts
  const [exitGame, set_exitGame] = createSignal(false);
  const toggle_exitGame = () => set_exitGame(!exitGame());


  ////\\\\ NEW GAME vs FRIEND OPTION

      // signal for button interaction
      const [req_new_VSfriend, set_reqTrig_newVSfriend] = createSignal(false); 

      // function wrapper for requesting new game as originator
      const fn_req_newVSfriend = async () => (await init_game_fromServer(true, false, undefined, false, randomRings()));
      
      // resource handler for new games
      const [res_handler_newVSfriend] = createResource(req_new_VSfriend, fn_req_newVSfriend);
      
      // handling interaction and resource fetching
      // createResource is triggered for anything other than: false, null, undefined onMount
      // so we initialize the signal value false -> is then swapped to false/true to re-trigger fetching
      const triggerRequest_newVSfriend = () => doubleSwitch(set_reqTrig_newVSfriend, req_new_VSfriend);

  ////\\\\ JOIN GAME vs FRIEND OPTION
    
        // show/display "text field for entering code"
        const [joinClick, set_joinClick] = createSignal(false); 
        const toggle_joinClick = () => set_joinClick(!joinClick());

        // NOTE => REPLACE WITH LEVELS show/display
        const [newGameVSHuman_settings, set_joinnewgmsettings] = createSignal(false); 
        const toggle_newgm_settings = () => set_joinnewgmsettings(!newGameVSHuman_settings());

        // NOTE => REPLACE WITH LEVELS show/display
        const [new_gm_ai_setttings, set_new_gm_ai_settings] = createSignal(false); 
        const toggle_newai_settings = () => set_new_gm_ai_settings(!new_gm_ai_setttings());

    // signal for join/request button interaction
    const [req_join_VSfriend, set_reqTrig_joinVSfriend] = createSignal(false); 

    // function wrapper for requesting new game
    let code_input_field; // -> this is later attached to the input field
    const fn_req_joinVSfriend = async () => (await init_game_fromServer(false, true, code_input_field.value.replace(/ /g, ''))); // removing any whitespace from input string
    
    // resource handler for new games
    const [res_handler_joinVSfriend] = createResource(req_join_VSfriend, fn_req_joinVSfriend);
    
    // handling interaction and resource fetching
    // createResource is triggered for anything other than: false, null, undefined onMount
    // so we initialize the signal value false -> is then swapped to false/true to re-trigger fetching
    const triggerRequest_joinVSfriend = () => doubleSwitch(set_reqTrig_joinVSfriend, req_join_VSfriend);


  ////\\\\ JOIN GAME vs AI OPTION

    // signal for button interaction
    const [req_join_VS_AI, set_req_join_VS_AI] = createSignal(false); 

    // function wrapper for requesting new game
    const fn_req_newGame_AI = async () => (await init_game_fromServer(false, false, undefined, true, randomRings()));
    
    // resource handler for new games
    const [res_handler_joinVS_AI] = createResource(req_join_VS_AI, fn_req_newGame_AI);
    
    // handling interaction and resource fetching
    const triggerRequest_joinVS_AI = () => doubleSwitch(set_req_join_VS_AI, req_join_VS_AI);


  /// just to trigger one-off tests
  function trigger_test_fn(){
    core_et.dispatchEvent(new CustomEvent('test_triggered'));
  };


  //// NEW: need to turn Show into an IF so that I can handle multiple cases
  // create new component for settings 
  // create toggle for joinVS_AI -> triggerRequest used a level down
  // checkbox/toggle to start with random ring placements or manual in UI
  // find new icon, similar to sound settings
  // pass value to triggerRequest fn wrapper -> how?
  return (
    <div class="game_controls">

      <Show 
        when={!game_inProgress()}
        fallback={
          <Show 
            when={exitGame()}
            fallback={<button type="button" class="exit_button" onClick={toggle_exitGame}>Resign</button>}
          >
            <span class="exit_game_txt">Are you sure?</span>
            <hr></hr>
            <div class="exit_game_div">
              <button type="button" class="exit_button_back" onClick={toggle_exitGame}>No</button>
              <button type="button" class="exit_button_confirm" onClick={fn_game_exited_by_user}>Yes</button>
            </div>
          </Show>}
      >
        <Show
          when={play()}
          fallback={<button type = "button" class="play_btn" onClick={toggle_Play}>PLAY</button>}
        >
          <Switch
            fallback={
              <>
                <button type="button" class="back_nav_btn" onClick={toggle_Play}>&#9665;</button>
                <hr class="menu_line"></hr>
                <button type="button" onClick={toggle_newgm_settings}>Invite a Friend</button>
                <button type="button" onClick={toggle_joinClick}>Join a Friend</button> 
                <button type="button" onClick={toggle_newai_settings}>Play vs AI</button>
                {/* <button type="button" onClick={trigger_test_fn}>- test button -</button> -- */}
              </>
            }
          >
            <Match when={newGameVSHuman_settings()}>
              <>
                <button type="button" class="back_nav_btn" onClick={toggle_newgm_settings}>&#9665;</button>
                <hr class="menu_line"></hr>
                <p>Game options</p>
                <RingsMode_Settings></RingsMode_Settings>
                <hr class="menu_line"></hr>
                <button type="button" onClick={triggerRequest_newVSfriend}>PLAY</button>
              </>
            </Match>
            <Match when={joinClick()}>
              <>
                <button type="button" class="back_nav_btn" onClick={toggle_joinClick}>&#9665;</button>
                <hr class="menu_line"></hr>
                <div class="join_input_div">
                  <input size="10" type="text" class="join_input_txt_class" ref={code_input_field} placeholder="Code here..."></input>
                  <button type="button" onClick={triggerRequest_joinVSfriend}>JOIN</button>
                </div>
              </>
            </Match>
            <Match when={new_gm_ai_setttings()}>
              <>
                <button type="button" class="back_nav_btn" onClick={toggle_newai_settings}>&#9665;</button>
                <hr class="menu_line"></hr>
                <p>Game options</p>
                <RingsMode_Settings></RingsMode_Settings>
                <hr class="menu_line"></hr>
                <button type="button" onClick={triggerRequest_joinVS_AI}>PLAY</button>
              </>
            </Match>
          </Switch>
        </Show>        
      </Show>
    </div>
  );
}



//// SETTINGS
// signal definition needs to be outside of fn scope, so I can call value elsewhere 
const [randomRings, set_randomRings] = createSignal(true); 
const toggle_randomRings = () => set_randomRings(!randomRings());

// component for ring settings on/off
function RingsMode_Settings() {

  return (
    <div class="">
      <Show
      when={randomRings()}
      fallback={
        <div onClick={toggle_randomRings}>
          <img src={svg_sound_OFF} height="24px" width="24px"></img>
          <span>Manual rings</span>
        </div>
      }>
        <div onClick={toggle_randomRings}>
          <img src={svg_sound_ON} height="24px" width="24px"></img>
          <span>Random rings</span>
        </div>
      </Show>  
    </div>
  );
}


///// SETTINGS BLOCK
export function Settings(){

  return(
    <div class="component_settings_wrapper">
      <SoundSettings></SoundSettings>
      <RingsCuesSettings></RingsCuesSettings>
      <LegalMovesCuesSettings></LegalMovesCuesSettings>
    </div>

  );
}



// component for sounds on/off
function SoundSettings() {

  const [sound, set_sound] = createSignal(true); 
  
  // toggle that calls functions exported by sound module
  function toggle_sound () {

    // this for swapping UI component
    set_sound(!sound());

    // flag audio on/off accordingly
    sound() ? enableSound() : disableSound();
    
  };  

  return (
      <Show
      when={sound()}
      fallback={
        <div class="settings_item set_off item_bottom_space" onClick={toggle_sound}>
          <img class="set_img set_off" src={svg_sound_OFF} height="28px" width="28px"></img>
          <span class="set_off">Sound effects OFF</span>
        </div>
      }>
        <div class="settings_item set_on item_bottom_space" onClick={toggle_sound}>
          <img class="set_img set_on" src={svg_sound_ON} height="28px" width="28px"></img>
          <span class="set_on">Sound effects ON</span>
        </div>
      </Show>  
  );
}

// component for rings cues on/off
function RingsCuesSettings() {

  const [rings_cues, set_rings_cues] = createSignal(true); 
  
  // toggle that calls functions exported by this module
  function toggle_rings_cues () {

    // this for swapping UI component
    set_rings_cues(!rings_cues());

    // flag rings cues on/off accordingly
    rings_cues() ? enableRingsCues() : disableRingsCues();
    
  };  

  return (
      <Show
      when={rings_cues()}
      fallback={
        <div class="settings_item set_off item_bottom_space" onClick={toggle_rings_cues}>
          <img class="set_img set_off" src={rings_cues_OFF} height="28px" width="28px"></img>
          <span class="set_off">Rings visual cues OFF</span>
        </div>
      }>
        <div class="settings_item sfx_on item_bottom_space" onClick={toggle_rings_cues}>
          <img class="set_img set_on" src={rings_cues_ON} height="28px" width="28px"></img>
          <span class="set_on">Rings visual cues ON</span>
        </div>
      </Show>  
  );
}

// component for legal moves cues on/off
function LegalMovesCuesSettings() {

  const [lm_cues, set_lm_cues] = createSignal(true); 
  
  // toggle that calls functions exported by this module
  function toggle_lm_cues () {

    // this for swapping UI component
    set_lm_cues(!lm_cues());

    // flag rings cues on/off accordingly
    lm_cues() ? enableLegalMovesCues() : disableLegalMovesCues();
    
  };  

  return (
      <Show
      when={lm_cues()}
      fallback={
        <div class="settings_item set_off" onClick={toggle_lm_cues}>
          <img class="set_img set_off" src={moves_cues_OFF} height="28px" width="28px"></img>
          <span class="set_off">Moves visual cues OFF</span>
        </div>
      }>
        <div class="settings_item set_on" onClick={toggle_lm_cues}>
          <img class="set_img set_on" src={moves_cues_ON} height="28px" width="28px"></img>
          <span class="set_on">Moves visual cues ON</span>
        </div>
      </Show>  
  );
}


// HELPER FN
// used to retrigger resource-wrapped fetch: if on -> off and then on again
function doubleSwitch(setter, value){

  if (value() == false) {
    // if NOT triggered 
    setter(!value()); // -> set to true -> triggers refetch
  } else {
    // if already triggered
    setter(!value()); // -> set to false 
    setter(!value()); // -> and then to true again -> triggers refetch
  }
};
