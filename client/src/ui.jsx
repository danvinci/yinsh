import { createSignal, Show, Switch, Match, createResource, createEffect, on } from "solid-js";
import { init_game_fromServer } from "./core.js";

export function Play() {
  
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
    <div>
      <Show 
        when={play()}
        fallback={
          <div>
            <p>Welcome!</p>      
            <button type = "button" onClick={toggle_Play}>Play Yinsh</button>
          </div>}
      >
        <Switch
          fallback={
            <div>
              <button type="button" onClick={toggle_Play}>Go back</button>
              <button type="button" onClick={toggle_PlayFriend}>Play with a friend</button>
              <button type="button" disabled="true" onClick={toggle_PlayAI}>Play with AI</button>
            </div>
          }
        >
          <Match when={playFriend()}> 
            <>
              <Switch
                fallback={
                  <>
                    <button type="button" onClick={toggle_PlayFriend}>Go back</button>
                    <button type="button" onClick={toggle_op_newGame}>New game</button>
                    <button type="button" onClick={toggle_op_join_wCode}>Join with code</button>
                  </>
                }
              >
                <Match when={op_newGame()}>
                  <button type="button" onClick={toggle_op_newGame}>Go back</button> 
                  <Option_new_game></Option_new_game>
                </Match>

                <Match when={op_join_wCode()}>
                  <>
                    <button type="button" onClick={toggle_op_join_wCode}>Go back</button>
                    <Option_join_with_code></Option_join_with_code>
                  </>
                </Match>
              </Switch>
            </>
          </Match>

          <Match when={playAI()}>
            <div>
              <button type="button" onClick={toggle_PlayAI}>Go back</button>
            </div>
          </Match>
        </Switch>
      </Show>
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
      <GameCanvas></GameCanvas>
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
      <GameCanvas></GameCanvas>
    </Show>
  );

}



function Handler_newGame(){

  // signal for button interaction
  const [reqTriggered, set_reqTriggered] = createSignal(false); 

  // function wrapper for requesting new game
  const req_newGame = async () => (await init_game_fromServer());
  
  // resource handler for new games
  const [request_handler] = createResource(reqTriggered, req_newGame);
  
  // handling interaction and resource fetching
  // createResource is triggered for anything other than: false, null, undefined onMount
  // so we initialize the signal value false -> is then swapped to false/true to re-trigger fetching
  const triggerRequest = () => {
    if (reqTriggered() == false) {
      // if NOT triggered 
      set_reqTriggered(!reqTriggered()); // -> set to true -> triggers refetch
    } else {
      // if already triggered
      set_reqTriggered(!reqTriggered()); // -> set to false 
      set_reqTriggered(!reqTriggered()); // -> and then to true again -> triggers refetch
    }
  };
  

  return (
    <>
    <button type="button" onClick={triggerRequest}>New game!</button>

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
  const req_newGame = async () => (await init_game_fromServer(code_input_field.value, true));
  
  // resource handler for new games
  const [request_handler] = createResource(reqTriggered, req_newGame);
  
  // handling interaction and resource fetching
  // createResource is triggered for anything other than: false, null, undefined onMount
  // so we initialize the signal value false -> is then swapped to false/true to re-trigger fetching
  const triggerRequest = () => {
    if (reqTriggered() == false) {
      // if NOT triggered 
      set_reqTriggered(!reqTriggered()); // -> set to true -> triggers refetch
    } else {
      // if already triggered
      set_reqTriggered(!reqTriggered()); // -> set to false 
      set_reqTriggered(!reqTriggered()); // -> and then to true again -> triggers refetch
    }
  };
  

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



function GameCanvas(){

  return (
    <>
    <canvas id="canvas" width="500" height="500"></canvas>
    </>
  );
}



export default Play;
