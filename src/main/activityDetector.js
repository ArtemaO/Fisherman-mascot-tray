const WORKING_PATTERN = /Working\s*\([\s\S]*?esc to interrupt\s*\)/i;

export function createActivityDetector() {
  let status = 'idle';
  let consecutiveHits = 0;
  let consecutiveMisses = 0;

  return {
    update(text) {
      const matches = WORKING_PATTERN.test(text ?? '');

      if (matches) {
        consecutiveHits += 1;
        consecutiveMisses = 0;
        if (status !== 'working' && consecutiveHits >= 2) {
          status = 'working';
          return { status, changed: true };
        }
        return { status, changed: false };
      }

      consecutiveMisses += 1;
      consecutiveHits = 0;
      if (status !== 'idle' && consecutiveMisses >= 2) {
        status = 'idle';
        return { status, changed: true };
      }
      return { status, changed: false };
    },
    current() {
      return status;
    }
  };
}
