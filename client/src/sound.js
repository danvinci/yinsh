// Audio effects

globalThis.sound_flag = true; // global property for audio on/off

export const enableSound = () => {sound_flag = true};
export const disableSound = () => {sound_flag = false};

// bind audio files
const ring_drop_sound = document.getElementById('ring_drop'); 
const markers_removed_sound_player = document.getElementById('score_player');
const markers_removed_sound_oppon = document.getElementById('score_opponent'); 
const end_game_win = document.getElementById('end_game_win'); 
const end_game_draw = document.getElementById('end_game_draw'); 
const end_game_lose = document.getElementById('end_game_lose'); 

// callable functions (only play if audio_flag is true)
export function ringDrop_playSound() { sound_flag && ring_drop_sound.play() };
export function markersRemoved_player_playSound() { sound_flag && markers_removed_sound_player.play() };
export function markersRemoved_oppon_playSound() { sound_flag && markers_removed_sound_oppon.play() };
export function endGame_win_playSound() { sound_flag && end_game_win.play() };
export function endGame_draw_playSound() { sound_flag && end_game_draw.play() };
export function endGame_lose_playSound() { sound_flag && end_game_lose.play() };

