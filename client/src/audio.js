// Audio effects

const ring_drop_sound = new Audio('src/assets/wood.wav');
const markers_row_removed_sound = new Audio('src/assets/coin_up_high.wav');

export function ringDrop_play_sound() { ring_drop_sound.play() };
export function markersRemoved_play_sound() { markers_row_removed_sound.play() };


