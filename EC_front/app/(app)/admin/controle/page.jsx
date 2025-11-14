'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Users, Calendar, Loader2, AlertCircle, Edit2 } from 'lucide-react';
import { useAuth } from '../../../context/AuthContext';

const API_BASE_URL = 'https://tccfrontback.onrender.com';

export default function ControlePage() {
  const router = useRouter();
  const { user } = useAuth();
  const [events, setEvents] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  // Redirect if not admin
  React.useEffect(() => {
    if (user && user.role !== 'admin') {
      router.push('/inicio');
    }
  }, [user, router]);

  useEffect(() => {
    fetchEvents();
  }, []);

  const fetchEvents = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/eventos.php`);
      if (response.ok) {
        const data = await response.json();
        setEvents(data);
      } else {
        setError('Falha ao carregar eventos');
      }
    } catch (err) {
      console.error('Erro ao buscar eventos:', err);
      setError('Erro de conexão');
    } finally {
      setIsLoading(false);
    }
  };

  const formatDate = (dateString) => {
    const parts = dateString.split(/[- :]/);
    const date = new Date(parts[0], parts[1] - 1, parts[2], parts[3] || 0, parts[4] || 0);
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const handleViewSubscribers = (eventId) => {
    router.push(`/admin/ver-inscritos/${eventId}`);
  };

  const handleEditEvent = (eventId) => {
    router.push(`/admin/editar-evento/${eventId}`);
  };

  if (!user || user.role !== 'admin') {
    return null;
  }

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
            onClick={fetchEvents}
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
        <h1 className="text-3xl md:text-4xl font-bold text-white mb-2">Controle de Eventos</h1>
        <p className="text-gray-400">Gerencie todos os eventos cadastrados</p>
      </div>

      {events.length === 0 ? (
        <div className="text-center py-12 bg-gray-800 rounded-lg border border-gray-700">
          <Calendar className="mx-auto mb-4 text-gray-600" size={64} />
          <p className="text-gray-400 text-lg">Nenhum evento cadastrado</p>
          <button
            onClick={() => router.push('/admin/criar-evento')}
            className="mt-4 bg-gradient-to-r from-orange-500 to-yellow-500 hover:from-orange-600 hover:to-yellow-600 text-white font-bold py-2 px-6 rounded-lg transition"
          >
            Criar Primeiro Evento
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-6">
          {events
            .sort((a, b) => new Date(b.data_evento) - new Date(a.data_evento))
            .map((event) => (
              <div
                key={event.id}
                className="bg-gray-800 rounded-lg p-6 border border-gray-700 hover:border-yellow-500 transition-all"
              >
                <div className="flex flex-col md:flex-row md:items-center md:justify-between">
                  <div className="flex-1 mb-4 md:mb-0">
                    <h3 className="text-xl font-bold text-white mb-2">{event.titulo}</h3>
                    <p className="text-gray-400 mb-2">
                      <Calendar size={16} className="inline mr-2" />
                      {formatDate(event.data_evento)}
                    </p>
                    <div className="flex items-center text-gray-400">
                      <Users size={16} className="mr-2" />
                      <span>{event.inscritos_count || 0} inscritos</span>
                      {event.max_participantes > 0 && (
                        <span className="ml-2">/ {event.max_participantes} vagas</span>
                      )}
                    </div>
                  </div>

                  <div className="flex flex-col sm:flex-row gap-3">
                    <button
                      onClick={() => handleViewSubscribers(event.id)}
                      className="flex items-center justify-center bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-lg transition"
                    >
                      <Users size={18} className="mr-2" />
                      Ver Inscritos
                    </button>
                    <button
                      onClick={() => handleEditEvent(event.id)}
                      className="flex items-center justify-center border border-gray-600 hover:border-gray-500 text-gray-300 hover:text-white font-semibold py-2 px-4 rounded-lg transition"
                    >
                      <Edit2 size={18} className="mr-2" />
                      Editar
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
