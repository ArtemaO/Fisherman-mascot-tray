import { describe, expect, it } from 'vitest';
import { createActivityDetector } from '../../src/main/activityDetector.js';

describe('activity detector', () => {
  it('switches to working after two matching polls', () => {
    const detector = createActivityDetector();

    expect(detector.update('Working (1m 10s • esc to interrupt)')).toEqual({ status: 'idle', changed: false });
    expect(detector.update('Working (2m • esc to interrupt)')).toEqual({ status: 'working', changed: true });
  });

  it('switches back to idle after two misses', () => {
    const detector = createActivityDetector();

    detector.update('Working (1m 10s • esc to interrupt)');
    detector.update('Working (2m • esc to interrupt)');

    expect(detector.update('Running tests...')).toEqual({ status: 'working', changed: false });
    expect(detector.update('Running tests...')).toEqual({ status: 'idle', changed: true });
  });

  it('keeps current status accessible after transitions', () => {
    const detector = createActivityDetector();

    expect(detector.current()).toBe('idle');

    detector.update('Working (1m 10s • esc to interrupt)');
    detector.update('Working (2m • esc to interrupt)');
    expect(detector.current()).toBe('working');

    detector.update('Running tests...');
    detector.update('Running tests...');
    expect(detector.current()).toBe('idle');
  });

  it('resets the debounce when a miss interrupts matching polls', () => {
    const detector = createActivityDetector();

    expect(detector.update('Working (1m 10s • esc to interrupt)')).toEqual({ status: 'idle', changed: false });
    expect(detector.update('Running tests...')).toEqual({ status: 'idle', changed: false });
    expect(detector.update('Working (2m • esc to interrupt)')).toEqual({ status: 'idle', changed: false });
    expect(detector.update('Working (2m 5s • esc to interrupt)')).toEqual({ status: 'working', changed: true });
  });

  it('does not clear working state after a single miss', () => {
    const detector = createActivityDetector();

    detector.update('Working (1m 10s • esc to interrupt)');
    detector.update('Working (2m • esc to interrupt)');

    expect(detector.update('Running tests...')).toEqual({ status: 'working', changed: false });
    expect(detector.current()).toBe('working');
  });
});
