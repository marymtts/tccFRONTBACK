'use client';

import React from 'react';
import { useRouter } from 'next/navigation';

// As props `notifications` e `onMarkAsRead` são injetadas pelo layout `app/(app)/layout.jsx`
export default function NotificationsPage({ notifications, onMarkAsRead }) {
  const router = useRouter();

  const handleNavigate = (eventId) => {
    // Lógica para navegar para o evento (talvez abrir modal direto)
    console.log(`Navegar para evento ${eventId}`);
    router.push('/calendario'); // Simplificado: vai para o calendário
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-white mb-6">Notificações</h1>
      <div className="bg-gray-800 rounded-lg shadow-xl p-6">
        {notifications?.length === 0 ? (
          <p className="text-gray-400">Nenhuma notificação nova.</p>
        ) : (
          <ul className="divide-y divide-gray-700">
            {notifications?.map(n => (
              <li key={n.id} className={`p-4 flex items-start ${n.read ? 'opacity-60' : ''}`}>
                <div className={`mt-1 h-2.5 w-2.5 rounded-full ${n.read ? 'bg-gray-600' : 'bg-yellow-500'}`} />
                <div className="ml-3 flex-1">
                  <p className="text-sm text-gray-300 mb-1">{n.text}</p>
                  <button 
                    onClick={() => handleNavigate(n.eventId)}
                    className="text-sm text-yellow-500 hover:underline mr-4"
                  >
                    Ver evento
                  </button>
                  {!n.read && (
                    <button 
                        onClick={() => onMarkAsRead(n.id)}
                        className="text-sm text-gray-400 hover:underline"
                    >
                        Marcar como lida
                    </button>
                  )}
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}