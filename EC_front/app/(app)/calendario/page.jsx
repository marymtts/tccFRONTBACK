'use client';

import React, { useState, useEffect } from 'react';
import { Loader2 } from 'lucide-react';
import { useAuth } from '../../../context/AuthContext';
import { database } from '../../../lib/database';
import EventCard from '../../../components/cards/EventCard';
import EventModal from '../../../components/modals/EventModal';

export default function CalendarPage() {
  const { user, token } = useAuth(); // <-- Pega o token
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedEvent, setSelectedEvent] = useState(null); // Para o modal

  // Função para buscar e mesclar dados
  const fetchAllData = async () => {
    if (!user || !token) {
      setLoading(false);
      return; // Não fazer nada se não houver usuário ou token
    }
    
    setLoading(true);
    try {
      // 1. Busca todos os eventos
      const allEvents = await database.getEvents();
      
      // 2. Busca os IDs dos eventos do usuário
      const myEventIds = await database.getMyRegisteredEventIds(user.id, token);

      // 3. Mescla os dados
      const mergedEvents = allEvents.map(event => ({
        ...event,
        isRegistered: myEventIds.includes(event.id) // Adiciona o status de inscrito
      }));

      setEvents(mergedEvents);

    } catch (error) {
      console.error("Erro ao buscar dados da página de calendário:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAllData();
  }, [user, token]); // Roda de novo se o user ou token mudarem

  // Esta função é chamada pelo Modal quando uma inscrição/cancelamento é feita
  const handleEventRegistrationUpdate = (eventId, isNowUnregistered = false) => {
    setEvents(prevEvents => 
      prevEvents.map(event => {
        if (event.id === eventId) {
          const newInscritosCount = isNowUnregistered 
            ? (event.inscritos_count || 1) - 1 // Garante que não fique negativo
            : (event.inscritos_count || 0) + 1;

          return {
            ...event,
            isRegistered: !isNowUnregistered,
            inscritos_count: newInscritosCount,
          };
        }
        return event;
      })
    );

    // Atualiza também o evento selecionado (no modal) para refletir a mudança
    setSelectedEvent(prevSelected => {
      if (prevSelected && prevSelected.id === eventId) {
        const newInscritosCount = isNowUnregistered
          ? (prevSelected.inscritos_count || 1) - 1
          : (prevSelected.inscritos_count || 0) + 1;
        
        return {
          ...prevSelected,
          isRegistered: !isNowUnregistered,
          inscritos_count: newInscritosCount,
        };
      }
      return prevSelected;
    });
  };

  if (loading) {
    return <div className="flex justify-center items-center h-64"><Loader2 className="animate-spin text-white" size={48} /></div>;
  }

  return (
    <div>
      <h1 className="text-3xl font-bold text-white mb-6">Calendário de Eventos</h1>
      <div className="bg-gray-800 rounded-lg shadow-xl p-6">
        {events.length === 0 ? (
          <p className="text-gray-400">Nenhum evento agendado no momento.</p>
        ) : (
          <div className="space-y-4">
            {events
              .sort((a, b) => new Date(a.data_evento) - new Date(b.data_evento)) // Ordena por data
              .map(event => (
              <EventCard 
                key={event.id} 
                event={event} 
                onClick={() => setSelectedEvent(event)} 
              />
            ))}
          </div>
        )}
      </div>
      
      {/* Modal de Detalhes/Inscrição */}
      {selectedEvent && (
        <EventModal 
          event={selectedEvent} 
          onClose={() => setSelectedEvent(null)}
          onRegisterSuccess={handleEventRegistrationUpdate} // Passa a função de atualização
        />
      )}
    </div>
  );
}