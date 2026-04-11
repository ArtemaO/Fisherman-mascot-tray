import { app, ipcMain } from 'electron';
import { createAlertState } from './alertState.js';
import { startEventBridge } from './eventBridge.js';
import { createTray } from './tray.js';
import { createMascotWindow } from './window.js';

const repeatMs = 30000;

function buildActivateEvent(kind, sourceLine = '') {
  return {
    action: 'activate',
    key: `${kind}:${sourceLine || 'manual'}`,
    kind,
    sourceLine
  };
}

app.whenReady().then(() => {
  const appRoot = app.getAppPath();
  const state = createAlertState({ repeatMs });
  const mascotWindow = createMascotWindow(appRoot);

  let muted = false;
  let watchingPaused = false;

  const syncSettings = () => {
    if (!mascotWindow.isDestroyed()) {
      mascotWindow.webContents.send('settings:update', { muted });
    }
  };

  const hideAlert = () => {
    state.clear('manual');
    if (!mascotWindow.isDestroyed()) {
      mascotWindow.webContents.send('alert:hide');
      mascotWindow.hide();
    }
  };

  const showAlert = event => {
    const result = state.activate({
      key: event.key,
      kind: event.kind,
      sourceLine: event.sourceLine ?? ''
    });

    if (!result.changed && !state.isRepeatDue()) {
      return;
    }

    mascotWindow.showInactive();
    mascotWindow.webContents.send('alert:show', {
      kind: event.kind,
      sourceLine: event.sourceLine ?? '',
      repeat: !result.changed
    });

    if (!result.changed) {
      state.bumpRepeat();
    }
  };

  const trayHandle = createTray(appRoot, {
    onTestAlert: () => {
      showAlert(buildActivateEvent('needs-reply', 'Manual tray test'));
    },
    onToggleMute: () => {
      muted = !muted;
      syncSettings();
      trayHandle.refresh();
    },
    onToggleWatching: () => {
      watchingPaused = !watchingPaused;
      trayHandle.refresh();
    },
    onExit: () => {
      app.quit();
    },
    isMuted: () => muted,
    isWatchingPaused: () => watchingPaused
  });

  ipcMain.on('alert:dismiss', () => {
    hideAlert();
  });

  syncSettings();

  startEventBridge(event => {
    if (watchingPaused) {
      return;
    }

    if (event.action === 'clear') {
      state.clear('auto');
      if (!mascotWindow.isDestroyed()) {
        mascotWindow.webContents.send('alert:hide');
        mascotWindow.hide();
      }
      return;
    }

    if (event.action === 'activate') {
      showAlert(event);
    }
  });

  setInterval(() => {
    if (!state.isRepeatDue()) {
      return;
    }

    const current = state.current();
    if (!current) {
      return;
    }

    mascotWindow.showInactive();
    mascotWindow.webContents.send('alert:repeat', {
      kind: current.kind,
      sourceLine: current.sourceLine ?? '',
      repeat: true
    });
    state.bumpRepeat();
  }, 1000);

  app.on('activate', () => {
    if (!mascotWindow.isVisible() && state.current()) {
      mascotWindow.showInactive();
    }
  });
});

app.on('window-all-closed', event => {
  event.preventDefault();
});
