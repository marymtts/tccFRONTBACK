'use client';

import React, { useState } from 'react';
import { Loader, Eye, EyeOff, ArrowLeft } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function RegisterPage() {
  const { register } = useAuth();
  const router = useRouter();
  
  const [ra, setRa] = useState('');
  const [nome, setNome] = useState('');
  const [email, setEmail] = useState('');
  const [senha, setSenha] = useState('');
  const [obscureSenha, setObscureSenha] = useState(true);
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);
    
    const result = await register(ra, nome, email, senha);
    setIsLoading(false);
    
    if (result.success) {
      // Redireciona para o login com mensagem de sucesso
      router.push('/?registered=true');
    } else {
      setError(result.message);
    }
  };

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-900 p-4">
      <div className="w-full max-w-md bg-gray-800 rounded-lg shadow-xl p-8">
        <div className="flex items-center mb-6">
          <Link href="/" className="text-gray-400 hover:text-white">
            <ArrowLeft size={24} />
          </Link>
          <h2 className="text-2xl font-bold text-white ml-4">Voltar</h2>
        </div>

        <div className="text-center mb-8">
           <h1 className="text-5xl font-bold text-white mb-2">
             E<span className="text-yellow-500">*</span>C
           </h1>
           <p className="text-2xl font-light text-gray-300 mb-4">Eventos Cotil</p>
           <h2 className="text-xl font-bold text-white">Crie sua conta</h2>
           <p className="text-gray-400 mt-2">É rápido e fácil.</p>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label htmlFor="ra" className="block text-sm font-medium text-gray-400 mb-2">
              RA
            </label>
            <input
              type="text"
              id="ra"
              value={ra}
              onChange={(e) => setRa(e.target.value)}
              placeholder="000000"
              className="w-full px-4 py-3 bg-gray-700 border border-transparent rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-yellow-500"
              required
            />
          </div>

          <div className="mb-4">
            <label htmlFor="nome" className="block text-sm font-medium text-gray-400 mb-2">
              Nome Completo
            </label>
            <input
              type="text"
              id="nome"
              value={nome}
              onChange={(e) => setNome(e.target.value)}
              placeholder="Seu Nome"
              className="w-full px-4 py-3 bg-gray-700 border border-transparent rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-yellow-500"
              required
            />
          </div>
          
          <div className="mb-4">
            <label htmlFor="email" className="block text-sm font-medium text-gray-400 mb-2">
              Email
            </label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="seu@email.com"
              className="w-full px-4 py-3 bg-gray-700 border border-transparent rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-yellow-500"
              required
            />
          </div>
          
          <div className="mb-6">
            <label htmlFor="senha" className="block text-sm font-medium text-gray-400 mb-2">
              Senha
            </label>
            <div className="relative">
              <input
                type={obscureSenha ? "password" : "text"}
                id="senha"
                value={senha}
                onChange={(e) => setSenha(e.target.value)}
                placeholder="••••••••"
                className="w-full px-4 py-3 bg-gray-700 border border-transparent rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-yellow-500 pr-12"
                required
              />
              <button
                type="button"
                onClick={() => setObscureSenha(!obscureSenha)}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-300"
              >
                {obscureSenha ? <EyeOff size={20} /> : <Eye size={20} />}
              </button>
            </div>
          </div>
          
          {error && (
            <div className="mb-4 p-3 bg-red-900/30 border border-red-500 rounded-lg">
              <p className="text-red-400 text-sm text-center">{error}</p>
            </div>
          )}

          <button
            type="submit"
            disabled={isLoading}
            className="w-full bg-gradient-to-r from-orange-500 to-yellow-500 hover:from-orange-600 hover:to-yellow-600 text-white font-bold py-3 px-4 rounded-lg focus:outline-none transition duration-300 disabled:opacity-50 flex items-center justify-center shadow-lg"
          >
            {isLoading ? <Loader className="animate-spin" size={20} /> : 'Criar Conta'}
          </button>
          
          <div className="mt-6 text-center">
            <p className="text-gray-400 text-sm">
              Já tem uma conta?{' '}
              <Link href="/" className="text-yellow-500 font-bold hover:text-yellow-400">
                Faça login
              </Link>
            </p>
          </div>
        </form>
      </div>
    </div>
  );
}
