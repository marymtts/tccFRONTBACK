'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { Calendar, CheckCircle, ArrowRight } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export default function HomePage() {
  const router = useRouter();
  const { user } = useAuth();

  const navigate = (page) => {
    router.push(page);
  };

  return (
    <div className="max-w-full mx-auto">
      {/* Seção Hero com imagem de fundo */}
      <div 
        className="bg-gray-800 rounded-lg shadow-xl p-8 md:p-16 text-center mb-12 relative overflow-hidden"
        style={{
          backgroundImage: 'linear-gradient(rgba(23, 37, 84, 0.85), rgba(23, 37, 84, 0.85)), url("https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1200")',
          backgroundSize: 'cover',
          backgroundPosition: 'center'
        }}
      >
        <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">
          Fique por dentro de tudo que acontece no{' '}
          <span className="text-yellow-400">Cotil</span>.
        </h1>
        <p className="text-lg md:text-xl text-gray-300 mb-8 max-w-3xl mx-auto">
          O seu guia completo para os eventos, palestras, workshops e atividades que enriquecem sua jornada no colégio.
        </p>
        <button
          onClick={() => navigate('/proximos-eventos')}
          className="bg-gradient-to-r from-orange-500 to-yellow-500 hover:from-orange-600 hover:to-yellow-600 text-white font-bold py-4 px-8 rounded-lg text-lg transition duration-300 shadow-xl"
        >
          Ver Próximos Eventos
        </button>
      </div>

      {/* Seção "Por onde você quer começar?" */}
      <div className="mb-12">
        <h2 className="text-3xl font-bold text-white mb-6">Por onde você quer começar?</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          
          {/* Card: Próximos Eventos */}
          <button
            onClick={() => navigate('/proximos-eventos')}
            className="bg-gray-800 rounded-lg shadow-lg p-6 flex items-center text-left hover:bg-gray-700 transition duration-300 group border border-gray-700 hover:border-orange-500"
          >
            <div className="bg-gradient-to-br from-orange-500 to-yellow-500 p-4 rounded-lg mr-6 shadow-lg">
              <Calendar size={32} className="text-white" />
            </div>
            <div className="flex-1">
              <h3 className="text-xl font-bold text-white mb-1">Próximos Eventos</h3>
              <p className="text-gray-400">Fique por dentro do que está por vir!</p>
            </div>
            <ArrowRight size={24} className="text-gray-500 group-hover:text-yellow-500 transition-colors" />
          </button>

          {/* Card: Calendário */}
          <button
            onClick={() => navigate('/calendario')}
            className="bg-gray-800 rounded-lg shadow-lg p-6 flex items-center text-left hover:bg-gray-700 transition duration-300 group border border-gray-700 hover:border-orange-500"
          >
            <div className="bg-gradient-to-br from-orange-500 to-yellow-500 p-4 rounded-lg mr-6 shadow-lg">
              <Calendar size={32} className="text-white" />
            </div>
            <div className="flex-1">
              <h3 className="text-xl font-bold text-white mb-1">Calendário</h3>
              <p className="text-gray-400">Explore e programe suas participações</p>
            </div>
            <ArrowRight size={24} className="text-gray-500 group-hover:text-yellow-500 transition-colors" />
          </button>

          {/* Card: Meus Eventos - só para alunos */}
          {user?.role === 'aluno' && (
            <button
              onClick={() => navigate('/meus-eventos')}
              className="bg-gray-800 rounded-lg shadow-lg p-6 flex items-center text-left hover:bg-gray-700 transition duration-300 group border border-gray-700 hover:border-orange-500"
            >
              <div className="bg-gradient-to-br from-orange-500 to-yellow-500 p-4 rounded-lg mr-6 shadow-lg">
                <CheckCircle size={32} className="text-white" />
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-bold text-white mb-1">Meus Eventos</h3>
                <p className="text-gray-400">Eventos em que você está inscrito</p>
              </div>
              <ArrowRight size={24} className="text-gray-500 group-hover:text-yellow-500 transition-colors" />
            </button>
          )}
        </div>
      </div>

      {/* Seção "Quem Somos" */}
      <div className="bg-gray-800 rounded-lg shadow-lg p-8 md:p-12 mb-12">
        <h2 className="text-3xl font-bold text-white mb-6">Quem somos?</h2>
        <p className="text-gray-300 text-lg leading-relaxed mb-8">
          O "Eventos Cotil" é uma iniciativa 100% feita por alunos, para alunos. Nós percebemos que muitas oportunidades incríveis passavam despercebidas por falta de divulgação.
        </p>
        <p className="text-gray-300 text-lg leading-relaxed mb-8">
          Nossa missão é simples: conectar você a todas as experiências que o Cotil oferece, garantindo que ninguém perca a chance de aprender, se divertir e crescer.
        </p>
        <div className="bg-gray-900 rounded-lg p-12 text-center">
          <h3 className="text-2xl font-bold text-yellow-500">
            Equipe Eventos Cotil
          </h3>
        </div>
      </div>

      {/* Rodapé */}
      <div className="text-center py-8">
        <p className="text-gray-500 text-sm">
          © 2025 Eventos Cotil. Uma iniciativa de alunos para alunos.
        </p>
      </div>
    </div>
  );
}