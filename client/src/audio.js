// Audio effects

//const ring_drop_sound = new Audio('src/assets/wood.wav');
const ring_drop_sound = document.getElementById("wood_sound"); 

//const markers_row_removed_sound = new Audio('src/assets/coin_up_high.wav');
const markers_row_removed_sound = document.getElementById("coin_sound"); 


export function ringDrop_play_sound() { ring_drop_sound.play() };
export function markersRemoved_play_sound() { markers_row_removed_sound.play() };

// should be sensitive to a disable_audio_effect setting
