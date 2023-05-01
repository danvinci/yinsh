import { createSignal, Show, Switch, Match } from "solid-js";

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
              <button type="button" onClick={toggle_PlayAsk}>Generate game code</button>
              <button type="button" onClick={toggle_PlayInput}>Enter game code</button>
            </div>
          }
        >
          <Match when={playInput()}>
            <div>
              <button type="button" onClick={toggle_PlayInput}>Go back</button>
              <Input_gameCode></Input_gameCode>
            </div>
          </Match>

          <Match when={playAsk()}>
            <div>
              <button type="button" onClick={toggle_PlayAsk}>Go back</button>
              <Ask_gameCode></Ask_gameCode>
            </div>
          </Match>
          
        </Switch>
       
      </Show>
          
    </div>
  );
}


function Ask_gameCode() {

  return (<button type="button">Generate game code (component)!</button>);

}

function Input_gameCode() {

  return (
    <>
      <input type="text" placeholder="Input game code"></input>
      <button type="button">Go!</button>
    </>
  );

}



export default Play;
