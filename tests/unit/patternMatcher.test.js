import { describe, expect, it } from 'vitest';
import { matchAttentionLine } from '../../src/main/patternMatcher.js';

describe('pattern matcher', () => {
  it('detects reply prompts', () => {
    expect(matchAttentionLine('?')).toMatchObject({ kind: 'needs-reply' });
  });

  it('detects confirmation prompts', () => {
    expect(matchAttentionLine('Do you want to allow this action?')).toMatchObject({
      kind: 'needs-confirmation'
    });
  });

  it('detects task-finished prompts', () => {
    expect(matchAttentionLine('Task complete. Waiting for your review.')).toMatchObject({
      kind: 'finished'
    });
  });

  it('ignores ordinary output', () => {
    expect(matchAttentionLine('Running tests...')).toBeNull();
  });
});
