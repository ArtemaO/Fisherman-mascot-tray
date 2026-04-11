const RULES = [
  { kind: 'needs-confirmation', test: /do you want to allow|confirm|approve/i },
  { kind: 'finished', test: /task complete|finished|waiting for your review/i },
  { kind: 'needs-reply', test: /^(\?|reply|your input|waiting for response)/i }
];

export function matchAttentionLine(line) {
  const trimmed = line.trim();

  for (const rule of RULES) {
    if (rule.test.test(trimmed)) {
      return { key: `${rule.kind}:${trimmed}`, kind: rule.kind, sourceLine: trimmed };
    }
  }

  return null;
}
