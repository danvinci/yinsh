import { createSignal, Show, Switch, Match, createResource, createEffect, on } from "solid-js";
import { init_game_fromServer } from "./core.js";


export function TextDialog() {
  // component for giving the player game tips and instructions

  return (
    <div class="text_dialog">
      <textarea class="game_text">Game instructions here</textarea>
    </div>
  );

}

export function GameSetup() {
  
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
    <div class="game_setup">
      <Show 
        when={play()}
        fallback={
          <div>   
            <button type = "button" onClick={toggle_Play}>New game</button>
          </div>}
      >
        <Switch
          fallback={
            <div>
              <button type="button" onClick={toggle_Play}>&#60</button>
              <button type="button" onClick={toggle_PlayFriend}>Play with a friend</button>
              <button type="button" disabled onClick={toggle_PlayAI}>Play with AI</button>
            </div>
          }
        >
          <Match when={playFriend()}> 
            <>
              <Switch
                fallback={
                  <>
                    <button type="button" onClick={toggle_PlayFriend}>&#60</button>
                    <button type="button" onClick={toggle_op_newGame}>New game</button>
                    <button type="button" onClick={toggle_op_join_wCode}>Join with code</button>
                  </>
                }
              >
                <Match when={op_newGame()}>
                  <button type="button" onClick={toggle_op_newGame}>&#60</button> 
                  <Option_new_game></Option_new_game>
                </Match>

                <Match when={op_join_wCode()}>
                  <>
                    <button type="button" onClick={toggle_op_join_wCode}>&#60</button>
                    <Option_join_with_code></Option_join_with_code>
                  </>
                </Match>
              </Switch>
            </>
          </Match>

          <Match when={playAI()}>
            <>
              <button type="button" onClick={toggle_PlayAI}>&#60</button>
              <Option_playAI></Option_playAI>
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
      <p>In-game settings</p>
    </div>
  );
}


function Option_new_game() {

  // handle option confirmation -> shows handler and canvas
  const [confirm, set_confirm] = createSignal(false);
  const toggle_confirm = () => set_confirm(!confirm());  

  return (
    <Show
    when = {confirm()}
    fallback = {<button type="button" onClick={toggle_confirm}>Confirm new game</button>}
    >
      <Handler_newGame></Handler_newGame>
    </Show>
  );
}


function Option_join_with_code() {

  // handle option confirmation -> shows handler and canvas
  const [confirm, set_confirm] = createSignal(false);
  const toggle_confirm = () => set_confirm(!confirm());  

  return (
    <Show
    when = {confirm()}
    fallback = {<button type="button" onClick={toggle_confirm}>Confirm join with code</button>}
    >
      <Handler_joinWithCode></Handler_joinWithCode>
    </Show>
  );
}


function Option_playAI() {

  // handle option confirmation -> shows handler and canvas
  const [confirm, set_confirm] = createSignal(false);
  const toggle_confirm = () => set_confirm(!confirm());  

  return (
    <Show
    when = {confirm()}
    fallback = {<button type="button" onClick={toggle_confirm}>Confirm play with AI</button>}
    >
      <Handler_playAI></Handler_playAI>
    </Show>
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
  
  // NOTE: snippet below should be reusable component
  return (
    <>
    <button type="button" onClick={triggerRequest}>Start!</button>

    <Switch
      fallback={<p>{""}</p>}
    >
      
      <Match when = {request_handler.loading}>
        <p>{"Loading..."}</p>
      </Match>

      <Match when = {request_handler.error}>
        <p>{"ERROR !"}</p>
      </Match>

    </Switch>
    </>
  );
  
}


function Handler_joinWithCode(){

  // signal for button interaction
  const [reqTriggered, set_reqTriggered] = createSignal(false); 

  // function wrapper for requesting new game
  let code_input_field; // -> this is later attached to the input field
  const req_newGame = async () => (await init_game_fromServer(false, true, code_input_field.value));
  
  // resource handler for new games
  const [request_handler] = createResource(reqTriggered, req_newGame);
  
  // handling interaction and resource fetching
  // createResource is triggered for anything other than: false, null, undefined onMount
  // so we initialize the signal value false -> is then swapped to false/true to re-trigger fetching
  const triggerRequest = () => doubleSwitch(set_reqTriggered, reqTriggered);
  
  // NOTE: snippet below should be reusable component
  return (
    <>
    <input type="text" ref={code_input_field} placeholder="Input game code"></input>
    <button type="button" onClick={triggerRequest}>Join!</button>

    <Switch
      fallback={<p>{""}</p>}
    >
      
      <Match when = {request_handler.loading}>
        <p>{"Loading..."}</p>
      </Match>

      <Match when = {request_handler.error}>
        <p>{"ERROR !"}</p>
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
    <button type="button" onClick={triggerRequest}>Start!</button>

    <Switch
      fallback={<p>{""}</p>}
    >
      
      <Match when = {request_handler.loading}>
        <p>{"Loading..."}</p>
      </Match>

      <Match when = {request_handler.error}>
        <p>{"ERROR !"}</p>
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
