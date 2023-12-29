import {GameCanvas, UserText, GameSetup, V_A_Settings} from './ui';

function App() {
  return (
    <div class = "game_main">

      <div class = "canvas_parent">
        <GameCanvas></GameCanvas>
      </div>

      <div class ="side_panel">
        <UserText></UserText>
        <GameSetup></GameSetup>
        <V_A_Settings></V_A_Settings>
      </div>

    </div>
    
  );
}

export default App;
