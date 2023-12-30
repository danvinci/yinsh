import {GameCanvas, UserText, GameSetup, SoundSettings} from './ui';

function App() {
  return (
    <div class = "game_main">

      <div class = "canvas_parent">
        <GameCanvas></GameCanvas>
      </div>

      <div class ="side_panel">
        <UserText></UserText>
        <GameSetup></GameSetup>
        <SoundSettings></SoundSettings>
      </div>

    </div>
    
  );
}

export default App;
