import { BrowserWindow, screen } from 'electron';
import path from 'node:path';

export function createMascotWindow(appRoot) {
  const workArea = screen.getPrimaryDisplay().workArea;
  const width = 360;
  const height = 360;

  const window = new BrowserWindow({
    width,
    height,
    x: workArea.x + workArea.width - width - 12,
    y: workArea.y + workArea.height - height - 12,
    frame: false,
    transparent: true,
    resizable: false,
    maximizable: false,
    minimizable: false,
    show: false,
    alwaysOnTop: true,
    skipTaskbar: true,
    hasShadow: false,
    webPreferences: {
      preload: path.join(appRoot, 'src', 'preload', 'index.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  window.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });
  window.loadFile(path.join(appRoot, 'src', 'renderer', 'mascot.html'));

  return window;
}
