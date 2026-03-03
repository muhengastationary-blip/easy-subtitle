import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.tsx';
import './index.css';

console.log('Muhenga AI: Initializing application...');

try {
  createRoot(document.getElementById('root')!).render(
    <StrictMode>
      <App />
    </StrictMode>,
  );
} catch (error) {
  console.error('Muhenga AI: Critical error during initialization:', error);
  document.body.innerHTML = `<div style="padding: 20px; color: red;"><h1>Muhenga AI: Critical Error</h1><p>${error instanceof Error ? error.message : 'Unknown error'}</p></div>`;
}
