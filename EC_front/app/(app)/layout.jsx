'use client';

import React, { useState, useEffect } from 'react';
// Corrigido para caminhos relativos para resolver erros de alias '@'
import { useAuth } from '../../context/AuthContext';
import { useRouter } from 'next/navigation'; // Esta linha está correta para Next.js
import Sidebar from '../../components/Sidebar';
import Header from '../../components/Header';
import { mockDatabase } from '../../lib/database';
import { Loader2 } from 'lucide-react';

// Este é o Layout do Dashboard, para usuários logados
export default function AppLayout({ children }) {
  const { isAuthenticated, user, loading: authLoading } = useAuth();
  const router = useRouter();
  
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [notifications, setNotifications] = useState([]);
  const [hasUnread, setHasUnread] = useState(false);

  // Busca notificações
  const fetchNotifications = () => {
     if (user) {
        mockDatabase.getNotifications(user.id).then(data => {
            setNotifications(data);
            setHasUnread(data.some(n => !n.read));
        });
     }
  };

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
    // Se está autenticado, busca as notificações
    fetchNotifications();
  }, [isAuthenticated, authLoading, user, router]);

  const handleMarkAsRead = (id) => {
    mockDatabase.markNotificationAsRead(id).then(() => {
        const newNotifications = notifications.map(n => 
            n.id === id ? { ...n, read: true } : n
        );
        setNotifications(newNotifications);
        setHasUnread(newNotifications.some(n => !n.read));
    });
  };

  // Mostrar loading enquanto o auth checa
  if (authLoading || !isAuthenticated) {
    return (
        <div className="flex items-center justify-center min-h-screen">
            <Loader2 className="animate-spin" size={48} />
        </div>
    );
  }
  
  // Clona o children (a página atual) e injeta as props (notifications, etc)
  // Isso é necessário para passar o estado das notificações para a página de notificações
   const pageContent = React.cloneElement(children, {
       notifications: notifications,
       onMarkAsRead: handleMarkAsRead,
   });

  return (
    <div className="flex min-h-screen">
      <Sidebar 
        userType={user.type} 
        isOpen={isSidebarOpen}
        setIsOpen={setIsSidebarOpen}
        hasUnreadNotifications={hasUnread}
      />

      <div className="flex-1 flex flex-col transition-all duration-300 ml-0 md:ml-64">
        <Header 
          onToggleSidebar={() => setIsSidebarOpen(!isSidebarOpen)} 
        />
        
        <main className="flex-1 p-4 md:p-8 bg-gray-800">
           {/* Renderiza a página atual com as props injetadas */}
           {pageContent}
        </main>
      </div>
    </div>
  );
}