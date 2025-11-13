'use client';

import React, { useState, useEffect } from 'react';
import { Loader2, Plus, Users, ClipboardCheck } from 'lucide-react';
import { useAuth } from '../../../context/AuthContext';
import { useRouter } from 'next/navigation';
import { database } from '../../../lib/database'; // Corrigido para caminho relativo e nome correto
import CreateEventModal from '../../../components/modals/CreateEventModal';
import AttendanceModal from '../../../components/modals/AttendanceModal';

export default function AdminPage() {
  const { user, token } = useAuth(); // <-- Pega o token
  const router = useRouter();
  
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showAttendanceModal, setShowAttendanceModal] = useState(null); // eventId

  const fetchEvents = () => {
    database.getEvents().then(data => { // Corrigido para 'database'
      // Idealmente, filtraríamos para mostrar apenas os eventos do professor logado
      setEvents(data);
      setLoading(false);
    }).catch(error => {
      console.error("Erro ao buscar eventos:", error);
      setLoading(false);
    });
  };

  useEffect(fetchEvents, []);
  
  // Proteção de Rota
  useEffect(() => {
    if (user && user.type !== 'professor') {
        router.push('/inicio'); // Redireciona se não for professor
    }
  }, [user, router]);

  const handleEventCreated = () => {
    fetchEvents(); // <-- Apenas recarrega os eventos da API
    setShowCreateModal(false);
  };

  if (loading || !user || user.type !== 'professor') {
    return <div className="flex justify-center items-center h-64"><Loader2 className="animate-spin text-white" size={48} /></div>;
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-3xl font-bold text-white">Gerenciar Eventos</h1>
        <button
          onClick={() => setShowCreateModal(true)}
          className="bg-yellow-600 hover:bg-yellow-700 text-white font-bold py-2 px-4 rounded-lg flex items-center"
        >
          <Plus size={20} className="mr-2" /> Criar Evento
        </button>
      </div>

      <div className="bg-gray-800 rounded-lg shadow-xl p-6">
        <h2 className="text-xl font-semibold text-white mb-4">Meus Eventos Cadastrados</h2>
        <div className="space-y-4">
          {events.length === 0 ? (
             <p className="text-gray-400">Você ainda não cadastrou nenhum evento.</p>
          ) : (
            events
              .sort((a, b) => new Date(a.data_evento) - new Date(b.data_evento)) // Corrigido para 'data_evento'
              .map(event => (
              <div key={event.id} className="bg-gray-700 p-4 rounded-lg flex flex-col md:flex-row justify-between items-start md:items-center">
                <div>
                  <h3 className="text-lg font-bold text-white">{event.titulo}</h3> {/* Corrigido para 'titulo' */}
                  <p className="text-sm text-gray-400">
                    {new Date(event.data_evento).toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'short' })} {/* Corrigido para 'data_evento' */}
                  </p>
                  <p className="text-sm text-gray-300 mt-1">
                    <Users size={14} className="inline mr-1" /> {event.inscritos_count || 0} inscritos
                  </p>
                </div>
                <button
                  onClick={() => setShowAttendanceModal(event.id)}
                  className="mt-4 md:mt-0 bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg flex items-center"
                >
                  <ClipboardCheck size={18} className="mr-2" /> Ver Presença
                </button>
              </div>
            ))
          )}
        </div>
      </div>
      
      {/* Modais do Admin */}
      {showCreateModal && (
        <CreateEventModal 
          onClose={() => setShowCreateModal(false)}
          onEventCreated={handleEventCreated}
        />
      )}
      {showAttendanceModal && (
        <AttendanceModal 
          eventId={showAttendanceModal}
          token={token} // <-- Passa o token
          onClose={() => setShowAttendanceModal(null)}
        />
      )}
    </div>
  );
}