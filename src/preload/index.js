import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('codexMascot', {
  onShowAlert(handler) {
    ipcRenderer.on('alert:show', (_event, payload) => handler(payload));
  },
  onRepeatAlert(handler) {
    ipcRenderer.on('alert:repeat', (_event, payload) => handler(payload));
  },
  onHideAlert(handler) {
    ipcRenderer.on('alert:hide', () => handler());
  },
  onSettings(handler) {
    ipcRenderer.on('settings:update', (_event, payload) => handler(payload));
  },
  dismiss() {
    ipcRenderer.send('alert:dismiss');
  }
});
