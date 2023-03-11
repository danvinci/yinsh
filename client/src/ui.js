function show_menu() {
    
    document.getElementById('play_btn').style.display = "none";
    document.getElementById('back_btn').style.display = "inline";
    document.getElementById('gen_code_btn').style.display = "inline";
    document.getElementById('enter_code_btn').style.display = "inline";
 
}

function go_back() {
    
    document.getElementById('play_btn').style.display = "inline";
    document.getElementById('back_btn').style.display = "none";
    document.getElementById('gen_code_btn').style.display = "none";
    document.getElementById('enter_code_btn').style.display = "none";
 
}