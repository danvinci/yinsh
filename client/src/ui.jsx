import { createSignal, Show, Switch, Match, createResource, createEffect, on, onMount, onCleanup } from "solid-js";
import { init_game_fromServer, draw_empty_game_board } from "./core.js";


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
  const [userText, set_userText] = createSignal("Click < PLAY > to start");

  // event target for UI
  globalThis.ui_et = new EventTarget(); 
  ui_et.addEventListener('new_user_text', userTxt_handler, false);

  function userTxt_handler(event) {
  
    // add text
    set_userText(userText() + "\n" + event.detail);
    
    // scroll text to end
    let txt_div = document.getElementById('user_txt_id');
    txt_div.scrollTop = txt_div.scrollHeight;
  } 

  return (
    <div class="user_text_div" id="user_txt_id">{userText}</div>
  );
}



// game setup controls should be different if game is in progress (eg. resign/abandon game)
export function GameSetup() {

  // flag for keeping track if game is ongoing or not (changes controls mode)
  const [game_ongoing, set_game_ongoing] = createSignal(false);
  const toggle_game_ongoing = () => set_game_ongoing(!game_ongoing()); // called by event from core (?)
  // hide core controls, display option to abandon game + similar for when other game is over
  // think about animations
  
  // manage initial 'play' call to action 
  const [play, set_play] = createSignal(false);
  const toggle_Play = () => set_play(!play());

      // manage 'play with a friend' option
      const [playFriend, set_playFriend] = createSignal(false);
      const toggle_PlayFriend = () => set_playFriend(!playFriend());

          // manage 'play w/ friend > generate new game' option
          const [op_newGame, set_op_newGame] = createSignal(false);
          const toggle_op_newGame = () => set_op_newGame(!op_newGame());

          // manage 'play w/ friend > join existing game with code' option
          const [op_join_wCode, set_op_join_wCode] = createSignal(false);
          const toggle_op_join_wCode = () => set_op_join_wCode(!op_join_wCode());

      // manage 'play with AI' option
      const [playAI, set_playAI] = createSignal(false);
      const toggle_PlayAI = () => set_playAI(!playAI());


  return (
    <div class="game_setup_controls">
      <Show 
        when={play()}
        fallback={
          <div class="back_nav_controls"> 
            <button type = "button" onClick={toggle_Play}>Play</button>
          </div>}
      >
        <Switch
          fallback={
            <>
              <div class="back_nav_controls">
                <button type="button" onClick={toggle_Play}>&#60</button>
              </div>
              <div class="core_controls">
                <button type="button" onClick={toggle_PlayFriend}>Human</button>
                <button type="button" onClick={toggle_PlayAI}>AI</button> 
              </div>
            </>
          }
        >
          <Match when={playFriend()}> 
            <>
              <Switch
                fallback={
                  <>
                  <div class="back_nav_controls">
                    <button type="button" onClick={toggle_PlayFriend}>&#60</button>
                  </div>
                  <div class="core_controls">
                    <button type="button" onClick={toggle_op_newGame}>New game</button>
                    <button type="button" onClick={toggle_op_join_wCode}>Join with code</button>
                  </div>
                  </>
                }
              >
                <Match when={op_newGame()}>
                  <div class="back_nav_controls">
                    <button type="button" onClick={toggle_op_newGame}>&#60</button> 
                  </div>
                  <div class="core_controls">
                    <Handler_newGame></Handler_newGame>
                  </div>
                </Match>

                <Match when={op_join_wCode()}>
                  <>
                  <div class="back_nav_controls">
                    <button type="button" onClick={toggle_op_join_wCode}>&#60</button> 
                  </div>
                  <div class="core_controls">
                      <Handler_joinWithCode></Handler_joinWithCode>
                  </div>
                  </>
                </Match>
              </Switch>
            </>
          </Match>

          <Match when={playAI()}>
            <>
              <div class="back_nav_controls">
                <button type="button" onClick={toggle_PlayAI}>&#60</button>
              </div>
              <div class="core_controls">
                <Handler_playAI></Handler_playAI>
              </div>
            </>
          </Match>
        </Switch>
      </Show>
    </div>
  );
}



export function InGameSettings() {
  // component for in-game settings (sound, visual cues)

  return (
    <div class="in_game_settings">
      <p>In-game settings (coming soon)</p>
    </div>
  );
}



function Handler_newGame(){

  // signal for button interaction
  const [reqTriggered, set_reqTriggered] = createSignal(false); 

  // function wrapper for requesting new game as originator
  const req_newGame = async () => (await init_game_fromServer(true));
  
  // resource handler for new games
  const [request_handler] = createResource(reqTriggered, req_newGame);
  
  // handling interaction and resource fetching
  // createResource is triggered for anything other than: false, null, undefined onMount
  // so we initialize the signal value false -> is then swapped to false/true to re-trigger fetching
  const triggerRequest = () => doubleSwitch(set_reqTriggered, reqTriggered);
  

  return (
    <>
    <button type="button" onClick={triggerRequest}>Play vs Human</button>
    </>
  );
  
}


function Handler_joinWithCode(){

  // signal for button interaction
  const [reqTriggered, set_reqTriggered] = createSignal(false); 

  // function wrapper for requesting new game
  let code_input_field; // -> this is later attached to the input field
  const req_newGame = async () => (await init_game_fromServer(false, true, code_input_field.value.replaceAll(/\s/, ''))); // removing any whitespace from input string
  
  // resource handler for new games
  const [request_handler] = createResource(reqTriggered, req_newGame);
  
  // handling interaction and resource fetching
  // createResource is triggered for anything other than: false, null, undefined onMount
  // so we initialize the signal value false -> is then swapped to false/true to re-trigger fetching
  const triggerRequest = () => doubleSwitch(set_reqTriggered, reqTriggered);
  
  return (
    <>
    <input size="10" type="text" ref={code_input_field} placeholder="Code here..."></input>
    <button type="button" onClick={triggerRequest}>Join!</button>

    <Switch
      fallback={<p class="fetching_info">{""}</p>}
    >
      
      <Match when = {request_handler.loading}>
        <p class="fetching_info">{"Joining game..."}</p>
      </Match>

      <Match when = {request_handler.error}>
        <p class="fetching_info">{"An error occurred."}</p>
      </Match>

    </Switch>
    </>
  );
}


function Handler_playAI(){

  // signal for button interaction
  const [reqTriggered, set_reqTriggered] = createSignal(false); 

  // function wrapper for requesting new game
  const req_newGame_AI = async () => (await init_game_fromServer(false, false, undefined, true));
  
  // resource handler for new games
  const [request_handler] = createResource(reqTriggered, req_newGame_AI);
  
  // handling interaction and resource fetching
  // createResource is triggered for anything other than: false, null, undefined onMount
  // so we initialize the signal value false -> is then swapped to false/true to re-trigger fetching
  const triggerRequest = () => doubleSwitch(set_reqTriggered, reqTriggered);
  
  return (
    <>
    <button type="button" onClick={triggerRequest}>Play vs AI</button>

    <Switch
      fallback={<p class="fetching_info">{""}</p>}
    >
      
      <Match when = {request_handler.loading}>
      </Match>

      <Match when = {request_handler.error}>
        <p class="fetching_info">{"An error occurred."}</p>
      </Match>

    </Switch>
    </>
  );
  
}



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
