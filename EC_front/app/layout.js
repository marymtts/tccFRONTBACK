import Providers from './Providers';
import './globals.css';

export const metadata = {
  title: 'Eventos Cotil',
  description: 'Plataforma de eventos, palestras e workshops do Cotil.',
};

export default function RootLayout({ children }) {
  return (
    <html lang="pt-br">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}