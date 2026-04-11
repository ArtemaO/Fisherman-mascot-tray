import { describe, expect, it } from 'vitest';
import { createAlertState } from '../../src/main/alertState.js';

describe('alert state', () => {
  it('activates a new alert and deduplicates the same key', () => {
    const state = createAlertState({ repeatMs: 30000 });

    expect(state.activate({ key: 'reply', kind: 'needs-reply' })).toEqual({
      changed: true,
      active: true,
      kind: 'needs-reply'
    });
    expect(state.activate({ key: 'reply', kind: 'needs-reply' })).toEqual({
      changed: false,
      active: true,
      kind: 'needs-reply'
    });
  });

  it('clears the current alert manually', () => {
    const state = createAlertState({ repeatMs: 30000 });

    state.activate({ key: 'confirm', kind: 'needs-confirmation' });

    expect(state.clear('manual')).toEqual({ cleared: true, reason: 'manual' });
    expect(state.current()).toBeNull();
  });

  it('marks a repeat as due after the interval', async () => {
    const state = createAlertState({ repeatMs: 1 });

    state.activate({ key: 'reply', kind: 'needs-reply' });
    await new Promise(resolve => setTimeout(resolve, 5));

    expect(state.isRepeatDue()).toBe(true);
  });
});
