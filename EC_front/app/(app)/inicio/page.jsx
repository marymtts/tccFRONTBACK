'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { Calendar, Bell, ArrowRight } from 'lucide-react';

export default function HomePage() {
  const router = useRouter();

  const navigate = (page) => {
    router.push(page);
  };

  return (
    <div className="max-w-4xl mx-auto">
      {/* Seção Hero */}
      <div className="bg-gray-900 rounded-lg shadow-xl p-8 md:p-12 text-center mb-12" style={{
          backgroundImage: 'url("https://images.unsplash.com/photo-1511795409837-09bbd3d0dae6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3wzNjc5ODV8MHwxfGFsbHx8fHx8fHx8fDE3MzEyNTc5NTh8&ixlib=rb-4.0.3&q=80&w=1080")', // Imagem de fundo sutil
          backgroundBlendMode: 'overlay',
          backgroundColor: 'rgba(23, 37, 84, 0.7)', // Um azul escuro, parecido com o do EC
          backgroundSize: 'cover',
          backgroundPosition: 'center'
      }}>
        <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">
          Fique por dentro de tudo que acontece no <span className="text-yellow-400">Cotil</span>.
        </h1>
        <p className="text-lg md:text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
          O seu guia completo para os eventos, palestras, workshops e atividades que enriquecem sua jornada no colégio.
        </p>
        <button
          onClick={() => navigate('/calendario')}
          className="bg-red-600 hover:bg-red-700 text-white font-bold py-3 px-8 rounded-lg text-lg transition duration-300 shadow-lg"
        >
          Ver Próximos Eventos
        </button>
      </div>

      {/* Seção "Por onde você quer começar?" */}
      <div className="mb-8">
        <h2 className="text-3xl font-bold text-white mb-6">Por onde você quer começar?</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          
          {/* Card: Próximos Eventos */}
          <button
            onClick={() => navigate('/calendario')}
            className="bg-gray-800 rounded-lg shadow-lg p-6 flex items-center text-left hover:bg-gray-700 transition duration-300 group"
          >
            <div className="bg-red-600 p-4 rounded-lg mr-6">
              <Calendar size={32} className="text-white" />
            </div>
            <div className="flex-1">
              <h3 className="text-xl font-bold text-white mb-1">Próximos Eventos</h3>
              <p className="text-gray-400">Fique por dentro do que está por vir!</p>
            </div>
            <ArrowRight size={24} className="text-gray-500 group-hover:text-white transition-colors" />
          </button>

          {/* Card: Notificações */}
          <button
            onClick={() => navigate('/notificacoes')}
            className="bg-gray-800 rounded-lg shadow-lg p-6 flex items-center text-left hover:bg-gray-700 transition duration-300 group"
          >
            <div className="bg-blue-600 p-4 rounded-lg mr-6">
              <Bell size={32} className="text-white" />
            </div>
            <div className="flex-1">
              <h3 className="text-xl font-bold text-white mb-1">Notificações</h3>
              <p className="text-gray-400">Veja os avisos mais recentes.</p>
            </div>
            <ArrowRight size={24} className="text-gray-500 group-hover:text-white transition-colors" />
          </button>
        </div>
      </div>
    </div>
  );
}