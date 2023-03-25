// instatiate event target for UI
let ui_target = new EventTarget()


function showMenu_ui() {
    
    document.getElementById('play_button').style.display = "none";
    document.getElementById('back_button').style.display = "inline";
    document.getElementById('option_new_game_button').style.display = "inline";
    document.getElementById('option_enter_code_button').style.display = "inline";
    

};

function goBack_ui() {
    
    document.getElementById('play_button').style.display = "inline";
    document.getElementById('back_button').style.display = "none";
    document.getElementById('option_new_game_button').style.display = "none";
    document.getElementById('option_enter_code_button').style.display = "none";

    document.getElementById('game_code_text').style.display = "none";
    document.getElementById('game_code_input').style.display = "none";
    document.getElementById('join_game_code_button').style.display = "none";

};


function newGame_ui() {
    
    // "new game" option selected, hide option for joining existing game
    document.getElementById('option_enter_code_button').style.display = "none";

    // dispatch event to ask server for new game code
    const new_game_event = new CustomEvent("new_game");
    game_state_target.dispatchEvent(new_game_event);

}

// listens to event of new game being ready
ui_target.addEventListener("newGame_ready", 
    function (event) {

    // prints new game code in place of the other option
    document.getElementById('game_code_text').innerHTML=`${event.detail.id}`;
    document.getElementById('game_code_text').style.display = "inline";

    // write message to user and un-hide the text for guiding users
    document.getElementById('text_explainer').innerHTML=`You'll be playing as ${event.detail.msg}`;
    document.getElementById('text_explainer').style.display = "inline";
 
});


function enter_gameCode_ui() {
    
    // hide level 2 options
    document.getElementById('option_new_game_button').style.display = "none";
    document.getElementById('option_enter_code_button').style.display = "none";

    // display input text for game code and 'join' button
    document.getElementById('game_code_input').style.display = "inline";
    document.getElementById('join_game_code_button').style.display = "inline";

};

function join_with_code_ui() {
    
    // reads game code from text input
    let game_code_input = document.getElementById('game_code_input').value

    // if input is not undefined / empty
    if (!(game_code_input === undefined)){

         // dispatch event to ask server to join existing game
        const join_game_event = new CustomEvent("join_game", { detail: game_code_input.trim()});
        game_state_target.dispatchEvent(join_game_event);

    };

};

// listens to event of game joined
ui_target.addEventListener("joinGame_ready", 
    function (event) {


    // write message to user and un-hide the text for guiding users
    document.getElementById('text_explainer').innerHTML=`You'll be playing as ${event.detail.msg}`;
    document.getElementById('text_explainer').style.display = "inline";
     
});