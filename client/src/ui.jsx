import { createSignal, Show, Switch, Match } from "solid-js";
import { init_game_dispatch, test_event_from_UI } from "./game_dispatch";

function Play() {
  
  // manage initial 'play' call to action 
  const [play, set_play] = createSignal(false);
  const toggle_Play = () => set_play(!play());

    // manage 'enter game code' option
    const [playInput, set_playInput] = createSignal(false);
    const toggle_PlayInput = () => set_playInput(!playInput());

    // manage 'generate game code' option
    const [playAsk, set_playAsk] = createSignal(false);
    const toggle_PlayAsk = () => set_playAsk(!playAsk());

     // manage 'play local' option
     const [playLocal, set_playLocal] = createSignal(false);
     const toggle_PlayLocal = () => set_playLocal(!playLocal());

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
              <button type="button" onClick={toggle_PlayLocal}>Local game</button>
              <button type="button" onClick={toggle_PlayAsk}>Generate game code</button>
              <button type="button" onClick={toggle_PlayInput}>Enter game code</button>
            </div>
          }
        >
          <Match when={playInput()}>
            <div>
              <button type="button" onClick={toggle_PlayInput}>Go back</button>
              <C_input_gameCode></C_input_gameCode>
            </div>
          </Match>

          <Match when={playAsk()}>
            <div>
              <button type="button" onClick={toggle_PlayAsk}>Go back</button>
              <C_ask_gameCode></C_ask_gameCode>
            </div>
          </Match>

          <Match when={playLocal()}>
            <div>
              <button type="button" onClick={toggle_PlayLocal}>Go back</button>
              <C_playLocal></C_playLocal>
            </div>
          </Match>
          
        </Switch>
       
      </Show>
          
    </div>
  );
}


function C_ask_gameCode() {

  const fn_askNewGame = () => {

    // dispatch event to ask server for new game code
    const new_game_event = new CustomEvent("new_game");
    game_state_target.dispatchEvent(new_game_event);

  };

  return (<button type="button" onClick={fn_askNewGame}>Generate game code!</button>);

}


function C_input_gameCode() {

  return (
    <>
      <input type="text" placeholder="Input game code"></input>
      <button type="button">Go!</button>
    </>
  );

}

function C_playLocal() {

  // manage 'start play' option
  const [startLocal, set_startLocal] = createSignal(false);
  const toggle_StartLocal = () => set_startLocal(!startLocal());  

  return (
    <Show
    when = {startLocal()}
    fallback = {<button type="button" onClick={toggle_StartLocal}>Start local game</button>}
    >
      <GameCanvas></GameCanvas>

    </Show>
  );

}

function GameCanvas(){

  // initializes game dispatcher (NOTE: should be inside a function call depending on user action)
  init_game_dispatch()

  // manage 'state of game started' option 
  // NOTE: could also use setResource here for fetching data 
  const [local_gameReady, set_local_gameReady] = createSignal(false);

  return (
    <Show
    when={local_gameReady()}
    fallback={<><p>Loading game...</p><button onClick={test_event_from_UI}>TEST EVENT</button></>}>

    </Show>

  );
  
}

export default Play;
