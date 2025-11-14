'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { Plus, Users, QrCode } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export default function AdminPage() {
  const { user } = useAuth();
  const router = useRouter();

  // Redirect if not admin
  React.useEffect(() => {
    if (user && user.role !== 'admin') {
      router.push('/inicio');
    }
  }, [user, router]);

  if (!user || user.role !== 'admin') {
    return null;
  }

  const adminCards = [
    {
      icon: <QrCode size={48} />,
      title: 'Validar Entradas',
      description: 'Validar check-in de participantes nos eventos',
      href: '/admin/scanner',
      bgColor: 'from-blue-500 to-blue-600'
    },
    {
      icon: <Users size={48} />,
      title: 'Controle de Eventos',
      description: 'Ver inscritos e gerenciar eventos',
      href: '/admin/controle',
      bgColor: 'from-purple-500 to-purple-600'
    },
    {
      icon: <Plus size={48} />,
      title: 'Criar Evento',
      description: 'Adicionar um novo evento ao calendário',
      href: '/admin/criar-evento',
      bgColor: 'from-green-500 to-green-600'
    }
  ];

  return (
    <div className="max-w-6xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl md:text-4xl font-bold text-white mb-2">Painel Administrativo</h1>
        <p className="text-gray-400">Gerencie eventos e participantes</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {adminCards.map((card, index) => (
          <button
            key={index}
            onClick={() => router.push(card.href)}
            className="bg-gray-800 rounded-lg shadow-lg p-8 hover:shadow-2xl transition-all duration-300 border border-gray-700 hover:border-yellow-500 text-left group"
          >
            <div className={`w-16 h-16 rounded-lg bg-gradient-to-br ${card.bgColor} flex items-center justify-center text-white mb-4 group-hover:scale-110 transition-transform`}>
              {card.icon}
            </div>
            <h3 className="text-xl font-bold text-white mb-2">{card.title}</h3>
            <p className="text-gray-400">{card.description}</p>
          </button>
        ))}
      </div>

      {/* Quick Stats */}
      <div className="mt-12 bg-gray-800 rounded-lg shadow-lg p-6 border border-gray-700">
        <h2 className="text-2xl font-bold text-white mb-4">Bem-vindo, {user.nome}!</h2>
        <p className="text-gray-400">
          Use as opções acima para gerenciar os eventos do Cotil.
        </p>
      </div>
    </div>
  );
}