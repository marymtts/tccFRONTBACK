'use client';

import React from 'react';
import { useAuth } from '../../context/AuthContext';
import { User, Mail, IdCard, LogOut } from 'lucide-react';
import QRCode from 'react-qr-code';

export default function ContaPage() {
  const { user, logout } = useAuth();

  if (!user) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <p className="text-gray-400">Erro: Usuário não encontrado.</p>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl md:text-4xl font-bold text-white mb-2">Minha Conta</h1>
        <p className="text-gray-400">Informações do seu perfil</p>
      </div>

      {/* Profile Card */}
      <div className="bg-gray-800 rounded-lg shadow-lg p-8 mb-6 border border-gray-700 relative">
        {/* Edit button - positioned top-right */}
        <button
          className="absolute top-4 right-4 text-gray-400 hover:text-white transition-colors"
          title="Editar Perfil"
        >
          <User size={20} />
        </button>

        <div className="flex flex-col items-center text-center">
          {/* Avatar */}
          <div className="w-24 h-24 rounded-full bg-gradient-to-r from-orange-500 to-yellow-500 flex items-center justify-center text-white font-bold text-4xl mb-6 shadow-lg">
            {user.nome ? user.nome[0].toUpperCase() : 'U'}
          </div>

          {/* Name */}
          <h2 className="text-2xl font-bold text-white mb-2">
            {user.nome}
          </h2>

          {/* Email */}
          <div className="flex items-center text-gray-400 mb-3">
            <Mail size={16} className="mr-2" />
            <span>{user.email}</span>
          </div>

          {/* RA - only for students */}
          {user.role === 'aluno' && user.ra && (
            <div className="inline-flex items-center px-4 py-2 bg-gray-900 rounded-full">
              <IdCard size={16} className="mr-2 text-gray-400" />
              <span className="text-gray-400 text-sm font-medium">
                RA: {user.ra}
              </span>
            </div>
          )}
        </div>
      </div>

      {/* QR Code Card - only for students */}
      {user.role === 'aluno' && (
        <div className="bg-gray-800 rounded-lg shadow-lg p-8 mb-6 border border-gray-700">
          <h3 className="text-xl font-bold text-white mb-4 text-center">
            Seu QR Code de Identificação
          </h3>
          <p className="text-gray-400 text-center mb-6">
            Use este código para fazer check-in nos eventos
          </p>
          
          {/* QR Code */}
          <div className="flex justify-center mb-4">
            <div className="bg-white p-6 rounded-lg shadow-lg">
              <QRCode
                value={JSON.stringify({
                  id: user.id,
                  nome: user.nome,
                  ra: user.ra,
                  email: user.email
                })}
                size={200}
                level="H"
              />
            </div>
          </div>

          <p className="text-gray-500 text-sm text-center">
            Apresente este QR Code na entrada dos eventos
          </p>
        </div>
      )}

      {/* Logout Button */}
      <button
        onClick={logout}
        className="w-full border border-gray-600 hover:border-gray-500 text-gray-300 hover:text-white font-semibold py-4 px-6 rounded-lg transition-colors flex items-center justify-center"
      >
        <LogOut size={20} className="mr-2" />
        Sair (Logout)
      </button>
    </div>
  );
}
