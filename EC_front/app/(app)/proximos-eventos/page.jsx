'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Search, Calendar, Loader2, AlertCircle } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

const API_BASE_URL = 'https://tccfrontback.onrender.com';

export default function ProximosEventosPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [allEvents, setAllEvents] = useState([]);
  const [filteredEvents, setFilteredEvents] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchUpcomingEvents();
  }, []);

  useEffect(() => {
    // Filter events when search query changes
    if (searchQuery.trim() === '') {
      setFilteredEvents(allEvents);
    } else {
      const filtered = allEvents.filter(event =>
        event.titulo.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (event.descricao && event.descricao.toLowerCase().includes(searchQuery.toLowerCase()))
      );
      setFilteredEvents(filtered);
    }
  }, [searchQuery, allEvents]);

  const fetchUpcomingEvents = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/get_proximos_eventos.php`);
      if (response.ok) {
        const data = await response.json();
        setAllEvents(data);
        setFilteredEvents(data);
      } else {
        setError(`Falha ao carregar eventos (Erro ${response.status})`);
      }
    } catch (err) {
      console.error('Erro ao buscar eventos:', err);
      setError('Erro de conexão. Verifique sua internet.');
    } finally {
      setIsLoading(false);
    }
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric'
    }).toUpperCase();
  };

  const handleEventClick = (eventId) => {
    router.push(`/evento/${eventId}`);
  };

  const handleEditEvent = (eventId, e) => {
    e.stopPropagation();
    router.push(`/admin/editar-evento/${eventId}`);
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Loader2 className="animate-spin text-yellow-500" size={48} />
      </div>
    );
  }

  if (error) {
    return (
      <div className="max-w-6xl mx-auto py-12">
        <div className="text-center">
          <AlertCircle className="mx-auto mb-4 text-red-400" size={64} />
          <p className="text-red-400 text-lg mb-4">{error}</p>
          <button
            onClick={fetchUpcomingEvents}
            className="bg-yellow-500 hover:bg-yellow-600 text-gray-900 font-bold py-2 px-6 rounded-lg transition"
          >
            Tentar Novamente
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl md:text-4xl font-bold text-white mb-2">Próximos Eventos</h1>
        <p className="text-gray-400">Fique por dentro do que está por vir!</p>
      </div>

      {/* Search Bar */}
      <div className="mb-8">
        <div className="relative">
          <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
          <input
            type="text"
            placeholder="Buscar pelo nome do evento..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-12 pr-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-yellow-500 focus:border-transparent"
          />
        </div>
      </div>

      {/* Events List */}
      {filteredEvents.length === 0 ? (
        <div className="text-center py-12 bg-gray-800 rounded-lg border border-gray-700">
          <Calendar className="mx-auto mb-4 text-gray-600" size={64} />
          <p className="text-gray-400 text-lg">
            {searchQuery 
              ? `Nenhum evento encontrado com "${searchQuery}".` 
              : 'Nenhum evento futuro encontrado.'}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-6">
          {filteredEvents.map((event) => (
            <div
              key={event.id}
              onClick={() => handleEventClick(event.id)}
              className="bg-gray-800 rounded-lg overflow-hidden shadow-lg hover:shadow-2xl transition-all duration-300 border border-gray-700 hover:border-yellow-500 cursor-pointer"
            >
              {/* Event Image */}
              {event.imagem_url ? (
                <div className="relative h-56 bg-gray-900">
                  <img
                    src={`${API_BASE_URL}${event.imagem_url}`}
                    alt={event.titulo}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      e.target.style.display = 'none';
                      e.target.parentElement.classList.add('flex', 'items-center', 'justify-center', 'bg-gradient-to-br', 'from-orange-500', 'to-yellow-500');
                    }}
                  />
                </div>
              ) : (
                <div className="h-56 bg-gradient-to-br from-orange-500 to-yellow-500 flex items-center justify-center">
                  <Calendar className="text-white" size={80} />
                </div>
              )}

              {/* Event Content */}
              <div className="p-6">
                {/* Date Badge */}
                <div className="inline-block bg-gradient-to-r from-orange-500 to-yellow-500 text-white text-xs font-bold px-3 py-1 rounded-full mb-3">
                  {formatDate(event.data_evento)}
                </div>

                {/* Title */}
                <h3 className="text-2xl font-bold text-white mb-3 hover:text-yellow-500 transition">
                  {event.titulo}
                </h3>

                {/* Description */}
                <p className="text-gray-400 mb-4 line-clamp-3 leading-relaxed">
                  {event.descricao || 'Descrição indisponível.'}
                </p>

                {/* Action Buttons */}
                <div className="flex flex-col sm:flex-row gap-3">
                  {user?.role === 'admin' && (
                    <button
                      onClick={(e) => handleEditEvent(event.id, e)}
                      className="flex-1 border border-gray-600 hover:border-gray-500 text-gray-300 hover:text-white font-semibold py-3 px-4 rounded-lg transition-colors"
                    >
                      ✏️ Editar Evento
                    </button>
                  )}
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      handleEventClick(event.id);
                    }}
                    className="flex-1 bg-gradient-to-r from-orange-500 to-yellow-500 hover:from-orange-600 hover:to-yellow-600 text-white font-bold py-3 px-4 rounded-lg transition-all shadow-lg"
                  >
                    Ver Detalhes →
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
