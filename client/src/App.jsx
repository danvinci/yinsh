import {GameCanvas, UserText, GameSetup, Settings} from './ui';

function App() {
  return (
    <div class = "game_main">

      <div class = "canvas_parent">
        <GameCanvas></GameCanvas>
      </div>

      <div class ="side_panel">
        <UserText></UserText>
        <GameSetup></GameSetup>
        <Settings></Settings>
      </div>

    </div>
    
  );
}

export default App;
