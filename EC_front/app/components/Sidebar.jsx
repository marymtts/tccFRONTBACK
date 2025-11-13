'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '../context/AuthContext';
// ... seus outros imports
import {
  Bell,
  Calendar,
  Home,
  BellDot,
  CalendarPlus,
  X,
  LogOut
} from 'lucide-react';

//
// 1. O 'NavItem' é movido para FORA do Sidebar
//
// 2. Adicionamos 'pathname' e 'setIsOpen' como props
//
const NavItem = ({ icon, label, page, count, pathname, setIsOpen, hasUnreadNotifications }) => {
  const isActive = pathname === page;
  return (
      <Link
          href={page}
          onClick={() => setIsOpen(false)} // <-- Agora usa a prop
          className={`
              flex items-center w-full px-4 py-3 text-sm font-medium rounded-lg transition-colors duration-200
              ${isActive // <-- Agora usa a prop 'pathname'
                ? 'bg-yellow-600 text-white'
                : 'text-gray-300 hover:bg-gray-700 hover:text-white'
              }
          `}
      >
        {icon}
        <span className="ml-3 flex-1">{label}</span>
        {count > 0 && (
          <span className="bg-red-500 text-white text-xs font-bold rounded-full h-5 w-5 flex items-center justify-center">
            {count}
          </span>
        )}
        {/* Eu movi a lógica do 'hasUnreadNotifications' para dentro do NavItem também para simplificar */}
        {page === '/notificacoes' && hasUnreadNotifications && !count && (
          <span className="bg-red-500 rounded-full h-2.5 w-2.5 ml-auto" />
        )}
      </Link>
  );
};


//
// Agora o Sidebar apenas USA o NavItem
//
export default function Sidebar({ isOpen, setIsOpen, hasUnreadNotifications }) {
  const { logout, user } = useAuth();
  const pathname = usePathname(); // Hook do Next.js para saber a rota atual

  // O 'NavItem' NÃO está mais definido aqui

  return (
    <>
      {/* Overlay para fechar no mobile */}
      {isOpen && <div onClick={() => setIsOpen(false)} className="fixed inset-0 bg-black/50 z-10 md:hidden" />}

      {/* Conteúdo do Sidebar */}
      <aside className={`
        fixed md:static inset-y-0 left-0 z-20
        w-64 bg-gray-800 shadow-lg
        flex flex-col p-4
        transform ${isOpen ? 'translate-x-0' : '-translate-x-full'} md:translate-x-0
        transition-transform duration-300 ease-in-out
      `}>
        {/* ... (cabeçalho do sidebar) ... */}
        
        <nav className="flex-1 space-y-2">
          {/* // 3. Agora passamos 'pathname' e 'setIsOpen' em CADA NavItem
          */}
          <NavItem 
            icon={<Home size={20} />} 
            label="Início" 
            page="/inicio" 
            pathname={pathname} 
            setIsOpen={setIsOpen} 
          />
          <NavItem 
            icon={<Calendar size={20} />} 
            label="Calendário" 
            page="/calendario" 
            pathname={pathname} 
            setIsOpen={setIsOpen} 
          />
          <NavItem 
            icon={hasUnreadNotifications ? <BellDot size={20} /> : <Bell size={20} />} 
            label="Notificações" 
            page="/notificacoes" 
            pathname={pathname} 
            setIsOpen={setIsOpen}
            hasUnreadNotifications={hasUnreadNotifications} // Passa a prop para o ícone e bolinha
          />
          
          {/* Itens Específicos do Professor */}
          {user?.type === 'professor' && (
            <>
              <hr className="border-gray-600 my-4" />
              <p className="px-4 py-2 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Admin
              </p>
              <NavItem 
                icon={<CalendarPlus size={20} />} 
                label="Gerenciar Eventos" 
                page="/admin" 
                pathname={pathname} 
                setIsOpen={setIsOpen} 
              />
            </>
      )}_)     )
        </nav>

        {/* ... (resto do sidebar / botão de logout) ... */}
      </aside>
    </>
  );
}