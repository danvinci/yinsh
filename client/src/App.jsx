import {GameCanvas, TextDialog, GameSetup, InGameSettings} from './ui';

function App() {
  return (
    <div class = "game_main">

      <div id = "canvas_parent_div" class = "canvas_parent">
        <GameCanvas></GameCanvas>
      </div>

      <div class ="side_panel">
        <TextDialog></TextDialog>
        <GameSetup></GameSetup>
        <InGameSettings></InGameSettings>
      </div>

    </div>
    
  );
}

export default App;
