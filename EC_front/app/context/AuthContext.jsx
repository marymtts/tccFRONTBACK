'use client';

import React, { useState, createContext, useContext } from 'react';
import { useRouter } from 'next/navigation';
// Corrigido para usar um caminho relativo, o que resolve o erro de compilação do alias '@'.

const AuthContext = createContext(null);

const API_BASE_URL = 'https://tccfrontback.onrender.com';

export function AuthProvider({ children }) {
  const [email, setEmail] = useState('');
    const [senha, setSenha] = useState('');
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const handleLogin = async (e) => {
        e.preventDefault();
        setError('');

        try {
            const response = await fetch('http://https://tccfrontback.onrender.com/EC_back/api/login.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, senha }),
            });

            const data = await response.json();

            if (response.ok && data.jwt) {
                // Login bem-sucedido
                localStorage.setItem('authToken', data.jwt); // Guarda o token
                navigate('/admin/dashboard'); // Redireciona para o dashboard
            } else {
                // Login falhou
                setError(data.message || 'Erro ao tentar fazer login.');
            }
        } catch (err) {
            setError('Não foi possível conectar ao servidor.'); 
            console.log(err);
        }
    };

    return (
        <div className="container vh-100 d-flex justify-content-center align-items-center">
            <div className="card p-4" style={{ width: '100%', maxWidth: '400px' }}>
                <div className="card-body">
                    <h2 className="text-center mb-4">Login Admin</h2>
                    <form onSubmit={handleLogin}>
                        <div className="mb-3">
                            <label htmlFor="email" className="form-label">Email</label>
                            <input
                                type="email"
                                className="form-control"
                                id="email"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                required
                            />
                        </div>
                        <div className="mb-3">
                            <label htmlFor="senha" className="form-label">Senha</label>
                            <input
                                type="password"
                                className="form-control"
                                id="senha"
                                value={senha}
                                onChange={(e) => setSenha(e.target.value)}
                                required
                            />
                        </div>
                        {error && <div className="alert alert-danger">{error}</div>}
                        <button type="submit" className="btn btn-primary w-100">Entrar</button>
                    </form>
                </div>
            </div>
        </div>
    );
}

// Hook para facilitar o uso do contexto
export function useAuth() {
  return useContext(AuthContext);
}