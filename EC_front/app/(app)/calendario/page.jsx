'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Search, Calendar as CalendarIcon, Loader2 } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

const API_BASE_URL = 'https://tccfrontback.onrender.com';

export default function CalendarioPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [events, setEvents] = useState([]);
  const [filteredEvents, setFilteredEvents] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchEvents();
  }, []);

  useEffect(() => {
    // Filtra eventos quando a query de busca muda
    if (searchQuery.trim() === '') {
      setFilteredEvents(events);
    } else {
      const filtered = events.filter(event =>
        event.titulo.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (event.descricao && event.descricao.toLowerCase().includes(searchQuery.toLowerCase()))
      );
      setFilteredEvents(filtered);
    }
  }, [searchQuery, events]);

  const fetchEvents = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/get_proximos_eventos.php`);
      if (response.ok) {
        const data = await response.json();
        setEvents(data);
        setFilteredEvents(data);
      } else {
        setError('Falha ao carregar eventos');
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

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Loader2 className="animate-spin text-yellow-500" size={48} />
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <p className="text-red-400 text-lg">{error}</p>
        <button
          onClick={fetchEvents}
          className="mt-4 bg-yellow-500 hover:bg-yellow-600 text-gray-900 font-bold py-2 px-6 rounded-lg transition"
        >
          Tentar Novamente
        </button>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl md:text-4xl font-bold text-white mb-2">Próximos Eventos</h1>
        <p className="text-gray-400">Fique por dentro do que está por vir!</p>
      </div>

      {/* Barra de Busca */}
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

      {/* Lista de Eventos */}
      {filteredEvents.length === 0 ? (
        <div className="text-center py-12 bg-gray-800 rounded-lg">
          <CalendarIcon className="mx-auto mb-4 text-gray-600" size={64} />
          <p className="text-gray-400 text-lg">
            {searchQuery ? `Nenhum evento encontrado com "${searchQuery}".` : 'Nenhum evento futuro encontrado.'}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-6">
          {filteredEvents.map((event) => (
            <div
              key={event.id}
              className="bg-gray-800 rounded-lg overflow-hidden shadow-lg hover:shadow-2xl transition-shadow duration-300 border border-gray-700 hover:border-yellow-500 cursor-pointer"
              onClick={() => handleEventClick(event.id)}
            >
              {/* Imagem do Evento */}
              {event.imagem_url ? (
                <div className="relative h-48 bg-gray-900">
                  <img
                    src={`${API_BASE_URL}${event.imagem_url}`}
                    alt={event.titulo}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      e.target.style.display = 'none';
                      e.target.parentElement.innerHTML = '<div class="flex items-center justify-center h-full bg-gradient-to-br from-orange-500 to-yellow-500"><svg class="text-white" width="64" height="64" fill="currentColor" viewBox="0 0 24 24"><path d="M19 3h-1V1h-2v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V8h14v11zM7 10h5v5H7z"/></svg></div>';
                    }}
                  />
                </div>
              ) : (
                <div className="h-48 bg-gradient-to-br from-orange-500 to-yellow-500 flex items-center justify-center">
                  <CalendarIcon className="text-white" size={64} />
                </div>
              )}

              {/* Conteúdo do Card */}
              <div className="p-6">
                <p className="text-yellow-500 text-sm font-bold mb-2">
                  {formatDate(event.data_evento)}
                </p>
                <h3 className="text-xl font-bold text-white mb-3">
                  {event.titulo}
                </h3>
                <p className="text-gray-400 mb-4 line-clamp-3">
                  {event.descricao || 'Descrição indisponível.'}
                </p>

                {/* Botões de Ação */}
                <div className="flex flex-col sm:flex-row gap-3">
                  {user?.role === 'admin' && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        router.push(`/admin/editar-evento/${event.id}`);
                      }}
                      className="flex-1 border border-gray-600 hover:border-gray-500 text-gray-300 hover:text-white font-semibold py-2 px-4 rounded-lg transition-colors"
                    >
                      Editar Evento
                    </button>
                  )}
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      handleEventClick(event.id);
                    }}
                    className="flex-1 bg-gradient-to-r from-orange-500 to-yellow-500 hover:from-orange-600 hover:to-yellow-600 text-white font-bold py-2 px-4 rounded-lg transition-all"
                  >
                    Saiba mais
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