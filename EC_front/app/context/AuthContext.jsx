'use client';

import React, { useState, createContext, useContext, useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';

const AuthContext = createContext(null);

const API_BASE_URL = 'https://tccfrontback.onrender.com';

// Função auxiliar para decodificar JWT
function decodeJWT(token) {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch (e) {
    console.error('Erro ao decodificar JWT:', e);
    return null;
  }
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const router = useRouter();
  const pathname = usePathname();

  // Verifica o token ao carregar
  useEffect(() => {
    const token = localStorage.getItem('jwt_token');
    if (token) {
      const decoded = decodeJWT(token);
      if (decoded && decoded.data) {
        // Verifica se o token expirou
        if (decoded.exp && decoded.exp * 1000 > Date.now()) {
          setUser(decoded.data);
          setIsAuthenticated(true);
        } else {
          // Token expirado
          localStorage.removeItem('jwt_token');
        }
      }
    }
    setLoading(false);
  }, []);

  const login = async (email, senha) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/login.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, senha }),
      });

      const data = await response.json();

      if (response.ok && data.jwt) {
        // Salva o token
        localStorage.setItem('jwt_token', data.jwt);
        
        // Decodifica e salva o usuário
        const decoded = decodeJWT(data.jwt);
        if (decoded && decoded.data) {
          setUser(decoded.data);
          setIsAuthenticated(true);
          
          // Redireciona baseado no role
          if (decoded.data.role === 'admin') {
            router.push('/admin');
          } else {
            router.push('/inicio');
          }
          
          return { success: true };
        }
      }
      
      return { 
        success: false, 
        message: data.message || 'Erro ao tentar fazer login.' 
      };
    } catch (err) {
      console.error('Erro no login:', err);
      return { 
        success: false, 
        message: 'Não foi possível conectar ao servidor.' 
      };
    }
  };

  const register = async (ra, nome, email, senha) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/registrar_aluno.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ra, nome, email, senha }),
      });

      const data = await response.json();

      if (response.status === 201) {
        return { success: true, message: data.message };
      }
      
      return { 
        success: false, 
        message: data.message || 'Erro ao tentar registrar.' 
      };
    } catch (err) {
      console.error('Erro no registro:', err);
      return { 
        success: false, 
        message: 'Não foi possível conectar ao servidor.' 
      };
    }
  };

  const logout = () => {
    localStorage.removeItem('jwt_token');
    setUser(null);
    setIsAuthenticated(false);
    router.push('/');
  };

  return (
    <AuthContext.Provider value={{ 
      user, 
      loading, 
      isAuthenticated, 
      login, 
      register,
      logout 
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}