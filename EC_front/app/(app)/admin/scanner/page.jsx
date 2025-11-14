'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { QrCode, Loader2, AlertCircle } from 'lucide-react';
import { useAuth } from '../../../context/AuthContext';

const API_BASE_URL = 'https://tccfrontback.onrender.com';

export default function ScannerPage() {
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
        // Filter only future events
        const now = new Date();
        const futureEvents = data.filter(event => new Date(event.data_evento) >= now);
        setEvents(futureEvents);
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
    const date = new Date(dateString);
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric'
    });
  };

  const handleSelectEvent = (eventId) => {
    // In a real implementation, this would open a QR scanner
    // For web, we can show a manual input
    alert(`Scanner de QR Code não disponível na versão web.\n\nEm produção, esta funcionalidade utilizaria a câmera para escanear QR codes dos alunos e validar entrada no evento ${eventId}.`);
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
      <div className="max-w-4xl mx-auto py-12">
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
    <div className="max-w-4xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl md:text-4xl font-bold text-white mb-2">Validar Entradas</h1>
        <p className="text-gray-400">Selecione um evento para escanear QR codes</p>
      </div>

      {events.length === 0 ? (
        <div className="text-center py-12 bg-gray-800 rounded-lg border border-gray-700">
          <QrCode className="mx-auto mb-4 text-gray-600" size={64} />
          <p className="text-gray-400 text-lg">Nenhum evento futuro encontrado</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-4">
          {events.map((event) => (
            <div
              key={event.id}
              onClick={() => handleSelectEvent(event.id)}
              className="bg-gray-800 rounded-lg p-6 border border-gray-700 hover:border-yellow-500 cursor-pointer transition-all hover:shadow-lg"
            >
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <h3 className="text-xl font-bold text-white mb-2">{event.titulo}</h3>
                  <p className="text-gray-400">
                    <span className="text-yellow-500">{formatDate(event.data_evento)}</span>
                  </p>
                </div>
                <QrCode className="text-yellow-500" size={32} />
              </div>
            </div>
          ))}
        </div>
      )}

      <div className="mt-8 bg-gray-800 rounded-lg p-6 border border-gray-700">
        <p className="text-gray-400 text-sm">
          <strong>Nota:</strong> A funcionalidade de scanner de QR Code está otimizada para dispositivos móveis com câmera. 
          Na versão web, recomendamos usar o aplicativo mobile para validar entradas.
        </p>
      </div>
    </div>
  );
}
