import { expect, test } from '@playwright/test';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

test('speech bubble becomes visible on alert', async ({ page }) => {
  const filePath = pathToFileURL(path.join(process.cwd(), 'src/renderer/mascot.html')).href;

  await page.goto(filePath);
  await expect(page.locator('#bubble')).toBeHidden();

  await page.evaluate(() => {
    window.dispatchEvent(new CustomEvent('mascot:test-alert'));
  });

  await expect(page.locator('#bubble')).toContainText('Клюет, подсекай!');
  await expect(page.locator('#bubble')).toBeVisible();
});
