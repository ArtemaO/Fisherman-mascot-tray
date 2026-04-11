import { describe, expect, it } from 'vitest';
import { parseBridgeBody } from '../../src/main/eventBridge.js';

describe('event bridge', () => {
  it('parses an activate payload', () => {
    expect(
      parseBridgeBody(
        JSON.stringify({
          action: 'activate',
          key: 'needs-reply:test',
          kind: 'needs-reply',
          sourceLine: '?'
        })
      )
    ).toEqual({
      action: 'activate',
      key: 'needs-reply:test',
      kind: 'needs-reply',
      sourceLine: '?'
    });
  });
});
