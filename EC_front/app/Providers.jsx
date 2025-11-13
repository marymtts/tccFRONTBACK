'use client';

// Corrigido para usar um caminho relativo, o que resolve o erro de compilação do alias '@'.
import { AuthProvider } from "./context/AuthContext";

export default function Providers({ children }) {
  return (
    <AuthProvider>
      {/* Tailwind usa 'dark' para modo escuro. 
          Usamos 'bg-gray-900 text-white' como base.
      */}
      <div className="min-h-screen bg-gray-900 text-gray-100 font-sans">
        {children}
      </div>
    </AuthProvider>
  );
}