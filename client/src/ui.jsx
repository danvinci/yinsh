import { createSignal, Show, Switch, Match, createResource, createEffect, on } from "solid-js";
import { init_newGame_fromServer } from "./core.js";

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
    fallback = {<button type="button" onClick={toggle_StartLocal}>Start local game (show canvas)</button>}
    >
      <GameHandler></GameHandler>
      <GameCanvas></GameCanvas>

    </Show>
  );

}

function GameCanvas(){

  return (
    <>
    <canvas width="500" height="500" id='canvas'></canvas>
    </>
  );
  
}


function GameHandler(){

  // function wrapper for requesting new game
  const req_newGame = async () => (await init_newGame_fromServer());

  // signal for triggering fetching of game details
  const [reqCount, set_reqCount] = createSignal(false); 
  
  // createResource would otherwise be triggered for anything other than: false, null, undefined
  // the signal is initialized as false, and then treated as an incrementing number 
  const buttonClick = () => {
    if (reqCount !== false) {
      // increments value if was already incremented
      set_reqCount(reqCount()+1)
    } else {
      // otherwise set count at 1 at the first click
      set_reqCount(1);
    }
    //console.log(reqCount());
  };
  
  // createEffect(on(reqCount, () => console.log(`Value for count (defer): ${reqCount()}`), { defer: true }));
  
  const [request_handler] = createResource(reqCount, req_newGame);

  return (
    <>
    <button type="button" onClick={buttonClick}>Request game</button>

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

export default Play;
