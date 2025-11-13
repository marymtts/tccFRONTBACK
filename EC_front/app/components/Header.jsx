'use client';

import React from 'react';
import { Menu, User } from 'lucide-react';
// Corrigido para usar um caminho relativo, o que resolve o erro de compilação do alias '@'.
import { useAuth } from '../context/AuthContext';

export default function Header({ onToggleSidebar }) {
  const { user } = useAuth();

  return (
    <header className="bg-gray-800 shadow-md p-4 flex items-center justify-between md:justify-end">
       {/* Botão de Menu (Mobile) */}
       <button onClick={onToggleSidebar} className="md:hidden text-gray-300 hover:text-white">
            <Menu size={24} />
       </button>
       
      {/* Informações do Usuário */}
      <div className="flex items-center">
        <span className="text-gray-300 mr-3 hidden md:inline">Olá, {user?.name}</span>
        <div className="w-10 h-10 rounded-full bg-yellow-600 flex items-center justify-center text-white font-bold">
          <User size={20} />
        </div>
      </div>
    </header>
  );
}