'use client';

import React, { useState, useEffect, use } from 'react';
import { useRouter } from 'next/navigation';
import { Users, Loader2, AlertCircle, User, Mail, Calendar } from 'lucide-react';
import { useAuth } from '../../../../context/AuthContext';

const API_BASE_URL = 'https://tccfrontback.onrender.com';

export default function VerInscritosPage({ params }) {
  const router = useRouter();
  const { user } = useAuth();
  const unwrappedParams = use(params);
  const [event, setEvent] = useState(null);
  const [subscribers, setSubscribers] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  // Redirect if not admin
  React.useEffect(() => {
    if (user && user.role !== 'admin') {
      router.push('/inicio');
    }
  }, [user, router]);

  useEffect(() => {
    if (unwrappedParams?.id) {
      fetchEventAndSubscribers();
    }
  }, [unwrappedParams?.id]);

  const fetchEventAndSubscribers = async () => {
    try {
      // Fetch event details
      const eventResponse = await fetch(`${API_BASE_URL}/api/eventos.php?id=${unwrappedParams.id}`);
      if (eventResponse.ok) {
        const eventData = await eventResponse.json();
        setEvent(eventData);
      }

      // Fetch subscribers
      const subsResponse = await fetch(`${API_BASE_URL}/api/get_inscritos.php?id_evento=${unwrappedParams.id}`);
      if (subsResponse.ok) {
        const subsData = await subsResponse.json();
        setSubscribers(Array.isArray(subsData) ? subsData : []);
      } else {
        setError('Falha ao carregar inscritos');
      }
    } catch (err) {
      console.error('Erro ao buscar dados:', err);
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
      month: 'long',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
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
            onClick={() => router.push('/admin/controle')}
            className="bg-yellow-500 hover:bg-yellow-600 text-gray-900 font-bold py-2 px-6 rounded-lg transition"
          >
            Voltar para Controle
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto">
      <div className="mb-8">
        <button
          onClick={() => router.push('/admin/controle')}
          className="text-gray-400 hover:text-white mb-4 flex items-center"
        >
          ← Voltar para Controle
        </button>
        <h1 className="text-3xl md:text-4xl font-bold text-white mb-2">
          Inscritos no Evento
        </h1>
        {event && (
          <div className="text-gray-400">
            <p className="text-xl mb-2">{event.titulo}</p>
            <p className="text-sm">
              <Calendar size={16} className="inline mr-2" />
              {formatDate(event.data_evento)}
            </p>
          </div>
        )}
      </div>

      <div className="bg-gray-800 rounded-lg shadow-lg p-6 border border-gray-700 mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <Users className="text-yellow-500 mr-3" size={32} />
            <div>
              <p className="text-gray-400 text-sm">Total de Inscritos</p>
              <p className="text-white text-3xl font-bold">{subscribers.length}</p>
            </div>
          </div>
          {event && event.max_participantes > 0 && (
            <div>
              <p className="text-gray-400 text-sm">Vagas Totais</p>
              <p className="text-white text-3xl font-bold">{event.max_participantes}</p>
            </div>
          )}
        </div>
      </div>

      {subscribers.length === 0 ? (
        <div className="text-center py-12 bg-gray-800 rounded-lg border border-gray-700">
          <Users className="mx-auto mb-4 text-gray-600" size={64} />
          <p className="text-gray-400 text-lg">Nenhum inscrito ainda</p>
        </div>
      ) : (
        <div className="bg-gray-800 rounded-lg shadow-lg border border-gray-700 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-900">
                <tr>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-300">Aluno</th>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-300">Email</th>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-300">RA</th>
                  <th className="px-6 py-4 text-left text-sm font-semibold text-gray-300">Check-in</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-700">
                {subscribers.map((sub, index) => (
                  <tr key={index} className="hover:bg-gray-700 transition">
                    <td className="px-6 py-4">
                      <div className="flex items-center">
                        <div className="w-10 h-10 rounded-full bg-gradient-to-r from-orange-500 to-yellow-500 flex items-center justify-center text-white font-bold mr-3">
                          {sub.nome ? sub.nome[0].toUpperCase() : <User size={20} />}
                        </div>
                        <span className="text-white font-medium">{sub.nome || 'Sem nome'}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center text-gray-300">
                        <Mail size={16} className="mr-2 text-gray-500" />
                        {sub.email || 'Sem email'}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-gray-300">{sub.ra || '-'}</span>
                    </td>
                    <td className="px-6 py-4">
                      {sub.validado == '1' ? (
                        <span className="bg-green-900 text-green-300 px-3 py-1 rounded-full text-sm font-semibold">
                          ✓ Validado
                        </span>
                      ) : (
                        <span className="bg-gray-700 text-gray-400 px-3 py-1 rounded-full text-sm">
                          Pendente
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
