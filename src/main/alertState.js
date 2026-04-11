export function createAlertState({ repeatMs }) {
  let active = null;
  let repeatAt = 0;

  return {
    activate(signal) {
      if (active?.key === signal.key) {
        return { changed: false, active: true, kind: signal.kind };
      }

      active = signal;
      repeatAt = Date.now() + repeatMs;

      return { changed: true, active: true, kind: signal.kind };
    },
    clear(reason) {
      if (!active) {
        return { cleared: false, reason };
      }

      active = null;
      repeatAt = 0;
      return { cleared: true, reason };
    },
    current() {
      return active;
    },
    isRepeatDue() {
      return Boolean(active) && Date.now() >= repeatAt;
    },
    bumpRepeat() {
      if (!active) {
        return;
      }

      repeatAt = Date.now() + repeatMs;
    }
  };
}
