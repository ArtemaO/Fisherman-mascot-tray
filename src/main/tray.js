import { Menu, Tray, nativeImage } from 'electron';
import path from 'node:path';

export function createTray(appRoot, actions) {
  const iconPath = path.join(appRoot, 'assets', 'mascot', 'fisherman-base.png');
  const tray = new Tray(nativeImage.createFromPath(iconPath));

  const buildMenu = () =>
    Menu.buildFromTemplate([
      { label: 'Test alert', click: actions.onTestAlert },
      {
        label: actions.isMuted() ? 'Unmute sound' : 'Mute sound',
        click: actions.onToggleMute
      },
      {
        label: actions.isWatchingPaused() ? 'Resume watching' : 'Pause watching',
        click: actions.onToggleWatching
      },
      { type: 'separator' },
      { label: 'Exit', click: actions.onExit }
    ]);

  tray.setToolTip('Codex Fishing Mascot');
  tray.setContextMenu(buildMenu());

  return {
    tray,
    refresh() {
      tray.setContextMenu(buildMenu());
    }
  };
}
