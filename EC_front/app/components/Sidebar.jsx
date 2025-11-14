'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '../context/AuthContext';
import {
  Calendar,
  Home,
  User,
  CheckCircle,
  QrCode,
  Users,
  PlusCircle,
  LogOut,
  X
} from 'lucide-react';

const NavItem = ({ icon, label, page, pathname, setIsOpen }) => {
  const isActive = pathname === page;
  return (
      <Link
          href={page}
          onClick={() => setIsOpen(false)}
          className={`
              flex items-center w-full px-4 py-3 text-sm font-medium rounded-lg transition-colors duration-200
              ${isActive
                ? 'bg-gradient-to-r from-orange-500 to-yellow-500 text-white'
                : 'text-gray-300 hover:bg-gray-700 hover:text-white'
              }
          `}
      >
        {icon}
        <span className="ml-3 flex-1">{label}</span>
      </Link>
  );
};

export default function Sidebar({ isOpen, setIsOpen }) {
  const { logout, user } = useAuth();
  const pathname = usePathname();

  const isAdmin = user?.role === 'admin';
  const isAluno = user?.role === 'aluno';

  return (
    <>
      {/* Overlay para fechar no mobile */}
      {isOpen && <div onClick={() => setIsOpen(false)} className="fixed inset-0 bg-black/50 z-10 md:hidden" />}

      {/* Conteúdo do Sidebar */}
      <aside className={`
        fixed md:static inset-y-0 left-0 z-20
        w-64 bg-gray-800 shadow-lg
        flex flex-col
        transform ${isOpen ? 'translate-x-0' : '-translate-x-full'} md:translate-x-0
        transition-transform duration-300 ease-in-out
      `}>
        {/* Header do Sidebar */}
        <div className="bg-gray-900 p-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-white">
                E<span className="text-yellow-500">*</span>C
              </h1>
              <p className="text-sm text-gray-400">Eventos Cotil</p>
            </div>
            <button 
              onClick={() => setIsOpen(false)} 
              className="md:hidden text-gray-400 hover:text-white"
            >
              <X size={24} />
            </button>
          </div>

          {/* Informações do usuário */}
          {user && (
            <div className="mt-6 flex items-center">
              <div className="w-12 h-12 rounded-full bg-gradient-to-r from-orange-500 to-yellow-500 flex items-center justify-center text-white font-bold text-xl">
                {user.nome ? user.nome[0].toUpperCase() : 'U'}
              </div>
              <div className="ml-3 flex-1">
                <p className="text-white font-semibold text-sm truncate">{user.nome}</p>
                <p className="text-gray-400 text-xs truncate">{user.email}</p>
              </div>
            </div>
          )}
        </div>
        
        {/* Navegação */}
        <nav className="flex-1 p-4 space-y-2 overflow-y-auto">
          <NavItem 
            icon={<Home size={20} />} 
            label="Início" 
            page="/inicio" 
            pathname={pathname} 
            setIsOpen={setIsOpen} 
          />
          <NavItem 
            icon={<Calendar size={20} />} 
            label="Próximos Eventos" 
            page="/proximos-eventos" 
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

          {/* Itens para Aluno */}
          {isAluno && (
            <>
              <NavItem 
                icon={<User size={20} />} 
                label="Minha Conta" 
                page="/conta" 
                pathname={pathname} 
                setIsOpen={setIsOpen} 
              />
              <NavItem 
                icon={<CheckCircle size={20} />} 
                label="Meus Eventos" 
                page="/meus-eventos" 
                pathname={pathname} 
                setIsOpen={setIsOpen} 
              />
            </>
          )}
          
          {/* Itens Específicos do Admin */}
          {isAdmin && (
            <>
              <hr className="border-gray-600 my-4" />
              <p className="px-4 py-2 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                Administração
              </p>
              <NavItem 
                icon={<User size={20} />} 
                label="Minha Conta" 
                page="/conta" 
                pathname={pathname} 
                setIsOpen={setIsOpen} 
              />
              <NavItem 
                icon={<QrCode size={20} />} 
                label="Validar Entradas" 
                page="/admin/scanner" 
                pathname={pathname} 
                setIsOpen={setIsOpen} 
              />
              <NavItem 
                icon={<Users size={20} />} 
                label="Controle de Eventos" 
                page="/admin/controle" 
                pathname={pathname} 
                setIsOpen={setIsOpen} 
              />
              <NavItem 
                icon={<PlusCircle size={20} />} 
                label="Criar Evento" 
                page="/admin/criar-evento" 
                pathname={pathname} 
                setIsOpen={setIsOpen} 
              />
            </>
          )}
        </nav>

        {/* Botão de Logout */}
        <div className="p-4 border-t border-gray-700">
          <button
            onClick={logout}
            className="flex items-center w-full px-4 py-3 text-sm font-medium rounded-lg text-gray-300 hover:bg-gray-700 hover:text-white transition-colors duration-200"
          >
            <LogOut size={20} />
            <span className="ml-3">Sair</span>
          </button>
        </div>
      </aside>
    </>
  );
}
