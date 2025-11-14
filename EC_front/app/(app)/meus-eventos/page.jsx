'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Calendar, Loader2, AlertCircle } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

const API_BASE_URL = 'https://tccfrontback.onrender.com';

export default function MeusEventosPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [events, setEvents] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (user) {
      fetchMyEvents();
    }
  }, [user]);

  const fetchMyEvents = async () => {
    if (!user) {
      setError('Você precisa estar logado para ver seus eventos.');
      setIsLoading(false);
      return;
    }

    try {
      const response = await fetch(
        `${API_BASE_URL}/api/get_meus_eventos.php?id_aluno=${user.id}`
      );

      if (response.ok) {
        const data = await response.json();
        setEvents(data);
      } else if (response.status === 404) {
        // No events found
        setEvents([]);
      } else {
        setError(`Falha ao carregar seus eventos (Erro ${response.status})`);
      }
    } catch (err) {
      console.error('Erro ao buscar eventos:', err);
      setError('Erro de conexão. Verifique sua internet.');
    } finally {
      setIsLoading(false);
    }
  };

  const formatDate = (dateString) => {
    const parts = dateString.split(/[- :]/);
    const date = new Date(parts[0], parts[1] - 1, parts[2], parts[3] || 0, parts[4] || 0);
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'long',
      year: 'numeric'
    });
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
      <div className="max-w-4xl mx-auto">
        <div className="text-center py-12">
          <AlertCircle className="mx-auto mb-4 text-red-400" size={64} />
          <p className="text-red-400 text-lg">{error}</p>
          <button
            onClick={fetchMyEvents}
            className="mt-4 bg-yellow-500 hover:bg-yellow-600 text-gray-900 font-bold py-2 px-6 rounded-lg transition"
          >
            Tentar Novamente
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl md:text-4xl font-bold text-white mb-2">
          Meus Eventos Inscritos
        </h1>
        <p className="text-gray-400">
          Eventos em que você está inscrito
        </p>
      </div>

      {events.length === 0 ? (
        <div className="text-center py-12 bg-gray-800 rounded-lg border border-gray-700">
          <Calendar className="mx-auto mb-4 text-gray-600" size={64} />
          <p className="text-gray-400 text-lg">
            Você ainda não se inscreveu em nenhum evento.
          </p>
          <button
            onClick={() => router.push('/calendario')}
            className="mt-6 bg-gradient-to-r from-orange-500 to-yellow-500 hover:from-orange-600 hover:to-yellow-600 text-white font-bold py-3 px-6 rounded-lg transition"
          >
            Ver Eventos Disponíveis
          </button>
        </div>
      ) : (
        <div className="space-y-4">
          {events.map((event) => (
            <div
              key={event.id}
              onClick={() => handleEventClick(event.id)}
              className="bg-gray-800 rounded-lg shadow-lg hover:shadow-2xl transition-all duration-300 border border-gray-700 hover:border-yellow-500 cursor-pointer"
            >
              <div className="p-6 flex items-center justify-between">
                <div className="flex-1">
                  <h3 className="text-xl font-bold text-white mb-2">
                    {event.titulo || 'Evento sem título'}
                  </h3>
                  <p className="text-gray-400 flex items-center">
                    <Calendar size={16} className="mr-2" />
                    {formatDate(event.data_evento)}
                  </p>
                  {event.descricao && (
                    <p className="text-gray-500 mt-2 line-clamp-2">
                      {event.descricao}
                    </p>
                  )}
                </div>
                <div className="ml-4">
                  <svg
                    className="w-6 h-6 text-gray-500"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
