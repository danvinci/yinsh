import {GameCanvas, UserText, GameSetup, InGameSettings} from './ui';

function App() {
  return (
    <div class = "game_main">

      <div class = "canvas_parent">
        <GameCanvas></GameCanvas>
      </div>

      <div class ="side_panel">
        <UserText></UserText>
        <GameSetup></GameSetup>
        <InGameSettings></InGameSettings>
      </div>

    </div>
    
  );
}

export default App;
