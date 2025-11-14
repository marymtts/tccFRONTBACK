'use client';

import React, { useState, useEffect } from 'react';
import { Loader, Eye, EyeOff } from 'lucide-react';
import { useAuth } from './context/AuthContext';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

// Esta é a Página de Login, a rota "/"
export default function LoginPage() {
  const { login, loading, isAuthenticated } = useAuth();
  const [email, setEmail] = useState('');
  const [senha, setSenha] = useState('');
  const [error, setError] = useState('');
  const [obscureSenha, setObscureSenha] = useState(true);
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();

  // Se já está autenticado, redireciona
  useEffect(() => {
    if (!loading && isAuthenticated) {
      router.push('/inicio');
    }
  }, [loading, isAuthenticated, router]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);
    
    const result = await login(email, senha);
    
    if (!result.success) {
      setError(result.message);
      setIsLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-900">
        <Loader className="animate-spin text-yellow-500" size={48} />
      </div>
    );
  }

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-900 p-4">
      <div className="w-full max-w-md bg-gray-800 rounded-lg shadow-xl p-8">
        <div className="text-center mb-8">
           {/* Logo EC - similar ao mobile */}
           <h1 className="text-5xl font-bold text-white mb-2">
             E<span className="text-yellow-500">*</span>C
           </h1>
           <p className="text-2xl font-light text-gray-300 mb-4">Eventos Cotil</p>
           <h2 className="text-xl font-bold text-white">Bem-vindo(a) de volta!</h2>
           <p className="text-gray-400 mt-2">Faça login para continuar.</p>
        </div>

        <form onSubmit={handleSubmit}>
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
              className="w-full px-4 py-3 bg-gray-700 border border-transparent rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-yellow-500 focus:border-transparent"
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
                className="w-full px-4 py-3 bg-gray-700 border border-transparent rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-yellow-500 focus:border-transparent pr-12"
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
            className="w-full bg-gradient-to-r from-orange-500 to-yellow-500 hover:from-orange-600 hover:to-yellow-600 text-white font-bold py-3 px-4 rounded-lg focus:outline-none focus:shadow-outline transition duration-300 disabled:opacity-50 flex items-center justify-center shadow-lg"
          >
            {isLoading ? <Loader className="animate-spin" size={20} /> : 'Entrar'}
          </button>
          
          <div className="mt-6 text-center">
            <p className="text-gray-400 text-sm">
              Não tem uma conta?{' '}
              <Link href="/register" className="text-yellow-500 font-bold hover:text-yellow-400">
                Registre-se já!
              </Link>
            </p>
          </div>
        </form>
      </div>
    </div>
  );
}