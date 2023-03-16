// instatiate event target for UI
let ui_target = new EventTarget()


function showMenu_ui() {
    
    document.getElementById('play_btn').style.display = "none";
    document.getElementById('back_btn').style.display = "inline";
    document.getElementById('newGame_btn').style.display = "inline";
    document.getElementById('enter_code_btn').style.display = "inline";
    

};

function goBack_ui() {
    
    document.getElementById('play_btn').style.display = "inline";
    document.getElementById('back_btn').style.display = "none";
    document.getElementById('newGame_btn').style.display = "none";
    document.getElementById('enter_code_btn').style.display = "none";

    document.getElementById('game_code_text').style.display = "none";

};


function newGame_ui() {
    const new_game_event = new CustomEvent("new_game");
    game_state_target.dispatchEvent(new_game_event);

}

// listens to event of new game being ready
ui_target.addEventListener("newGame_ready", 
    function (event) {

    document.getElementById('game_code_text').innerHTML=`Game ID: ${event.detail}`;
    document.getElementById('game_code_text').style.display = "inline";
 
});