'use client';

import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { useRouter } from 'next/navigation';
import Sidebar from '../components/Sidebar';
import Header from '../components/Header';
import { Loader2 } from 'lucide-react';

// Este é o Layout do Dashboard, para usuários logados
export default function AppLayout({ children }) {
  const { isAuthenticated, user, loading: authLoading } = useAuth();
  const router = useRouter();
  
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  useEffect(() => {
    // Se a autenticação ainda está carregando, não faça nada
    if (authLoading) {
      return;
    }
    // Se não está autenticado e terminou de carregar, redireciona para o login
    if (!isAuthenticated) {
      router.push('/');
      return;
    }
  }, [isAuthenticated, authLoading, user, router]);

  // Mostrar loading enquanto o auth checa
  if (authLoading || !isAuthenticated) {
    return (
        <div className="flex items-center justify-center min-h-screen bg-gray-900">
            <Loader2 className="animate-spin text-yellow-500" size={48} />
        </div>
    );
  }

  return (
    <div className="flex min-h-screen bg-gray-900">
      <Sidebar 
        isOpen={isSidebarOpen}
        setIsOpen={setIsSidebarOpen}
      />

      <div className="flex-1 flex flex-col transition-all duration-300 ml-0 md:ml-64">
        <Header 
          onToggleSidebar={() => setIsSidebarOpen(!isSidebarOpen)} 
        />
        
        <main className="flex-1 p-4 md:p-8 bg-gray-900">
           {children}
        </main>
      </div>
    </div>
  );
}