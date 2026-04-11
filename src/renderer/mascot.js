const appElement = document.querySelector('#app');
const bubbleElement = document.querySelector('#bubble');

let muted = false;
let audioContext = null;

function ensureAudioContext() {
  if (audioContext) {
    return audioContext;
  }

  const AudioCtor = window.AudioContext || window.webkitAudioContext;
  if (!AudioCtor) {
    return null;
  }

  audioContext = new AudioCtor();
  return audioContext;
}

function playBellChime() {
  if (muted) {
    return;
  }

  const context = ensureAudioContext();
  if (!context) {
    return;
  }

  const now = context.currentTime;
  const frequencies = [1320, 1760];

  for (const [index, frequency] of frequencies.entries()) {
    const oscillator = context.createOscillator();
    const gain = context.createGain();

    oscillator.type = 'triangle';
    oscillator.frequency.setValueAtTime(frequency, now);

    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.exponentialRampToValueAtTime(0.16, now + 0.01 + index * 0.03);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.42 + index * 0.05);

    oscillator.connect(gain);
    gain.connect(context.destination);

    oscillator.start(now + index * 0.03);
    oscillator.stop(now + 0.5 + index * 0.05);
  }
}

function showAlert() {
  appElement.classList.remove('hidden');
  appElement.classList.add('visible', 'alerting');
  bubbleElement.hidden = false;
  playBellChime();
}

function hideAlert() {
  appElement.classList.remove('visible', 'alerting');
  appElement.classList.add('hidden');
  bubbleElement.hidden = true;
}

window.addEventListener('mascot:test-alert', showAlert);
appElement.addEventListener('click', () => {
  hideAlert();
  window.codexMascot?.dismiss();
});

window.codexMascot?.onShowAlert(showAlert);
window.codexMascot?.onRepeatAlert(showAlert);
window.codexMascot?.onHideAlert(hideAlert);
window.codexMascot?.onSettings(settings => {
  muted = Boolean(settings?.muted);
});
