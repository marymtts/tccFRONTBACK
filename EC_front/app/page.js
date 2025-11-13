'use client';

import React, { useState } from 'react';
import { Loader } from 'lucide-react';
// Corrigido para usar um caminho relativo, o que resolve o erro de compilação do alias '@'.
import { useAuth } from './context/AuthContext';

// Esta é a Página de Login, a rota "/"
export default function LoginPage() {
  const { login, loading } = useAuth();
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    const result = await login(email);
    if (!result.success) {
      setError(result.message);
    }
  };

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-900 p-4">
      <div className="w-full max-w-md bg-gray-800 rounded-lg shadow-xl p-8">
        <div className="text-center mb-8">
           {/* Logo EC - similar ao da imagem */}
           <h1 className="text-5xl font-bold text-white mb-2">
             E<span className="text-yellow-500">*</span>C
           </h1>
           <p className="text-2xl font-light text-gray-300">Eventos Cotil</p>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label htmlFor="email" className="block text-sm font-medium text-gray-300 mb-2">
              Email Institucional
            </label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="ex: aluno@cotil.br"
              className="w-full px-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-yellow-500"
              required
            />
          </div>
          
          {error && <p className="text-red-400 text-sm mb-4 text-center">{error}</p>}

          <div className="mb-6">
            <button
              type="submit"
              disabled={loading}
              className="w-full bg-yellow-600 hover:bg-yellow-700 text-white font-bold py-3 px-4 rounded-lg focus:outline-none focus:shadow-outline transition duration-300 disabled:opacity-50 flex items-center justify-center"
            >
              {loading ? <Loader className="animate-spin" /> : 'Entrar'}
            </button>
          </div>
          
          <div className="text-center text-sm text-gray-400">
             <p className="mb-2">Emails de teste:</p>
             <p><code>aluno@cotil.br</code> (Aluno)</p>
             <p><code>prof@cotil.br</code> (Professor)</p>
          </div>
        </form>
      </div>
    </div>
  );
}