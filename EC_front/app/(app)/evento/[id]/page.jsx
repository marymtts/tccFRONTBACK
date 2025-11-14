'use client';

import React, { useState, useEffect, use } from 'react';
import { useRouter } from 'next/navigation';
import { 
  Calendar, 
  Clock, 
  Users, 
  Loader2, 
  AlertCircle,
  CheckCircle,
  XCircle 
} from 'lucide-react';
import { useAuth } from '../../../context/AuthContext';

const API_BASE_URL = 'https://tccfrontback.onrender.com';

export default function EventoPage({ params }) {
  const router = useRouter();
  const { user } = useAuth();
  const unwrappedParams = use(params);
  const [event, setEvent] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [isRegistering, setIsRegistering] = useState(false);
  const [isCanceling, setIsCanceling] = useState(false);
  const [isRegistered, setIsRegistered] = useState(false);
  const [feedbackMessage, setFeedbackMessage] = useState(null);

  useEffect(() => {
    if (unwrappedParams?.id) {
      fetchEventDetails();
    }
  }, [unwrappedParams?.id, user]);

  const fetchEventDetails = async () => {
    try {
      const eventId = unwrappedParams.id;
      let url = `${API_BASE_URL}/api/eventos.php?id=${eventId}`;
      
      if (user) {
        url += `&user_id=${user.id}`;
      }

      const response = await fetch(url);
      
      if (response.ok) {
        const data = await response.json();
        setEvent(data);
        setIsRegistered(data.usuario_esta_inscrito || false);
      } else {
        setError('Falha ao carregar dados do evento');
      }
    } catch (err) {
      console.error('Erro ao buscar evento:', err);
      setError('Erro de conexão');
    } finally {
      setIsLoading(false);
    }
  };

  const handleRegistration = async () => {
    if (!user) {
      showFeedback('Você precisa estar logado para se inscrever.', 'error');
      setTimeout(() => router.push('/'), 2000);
      return;
    }

    if (user.role !== 'aluno') {
      showFeedback('Apenas alunos podem se inscrever em eventos.', 'error');
      return;
    }

    setIsRegistering(true);
    
    try {
      const response = await fetch(`${API_BASE_URL}/api/registrar_participacao.php`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id_aluno: user.id.toString(),
          id_evento: unwrappedParams.id.toString(),
        }),
      });

      const data = await response.json();

      if (response.status === 201) {
        showFeedback(data.message || 'Inscrição realizada com sucesso!', 'success');
        setIsRegistered(true);
        fetchEventDetails(); // Reload to update count
      } else {
        showFeedback(data.message || 'Erro ao se inscrever', 'error');
      }
    } catch (err) {
      showFeedback('Erro de conexão ao tentar se inscrever.', 'error');
    } finally {
      setIsRegistering(false);
    }
  };

  const handleCancellation = async () => {
    setIsCanceling(true);
    
    try {
      const token = localStorage.getItem('jwt_token');
      const response = await fetch(`${API_BASE_URL}/api/cancelar_participacao.php`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          id_evento: unwrappedParams.id.toString(),
        }),
      });

      const data = await response.json();

      if (response.ok) {
        showFeedback(data.message || 'Inscrição cancelada!', 'success');
        setIsRegistered(false);
        fetchEventDetails(); // Reload to update count
      } else {
        showFeedback(data.message || 'Erro ao cancelar', 'error');
      }
    } catch (err) {
      showFeedback('Erro de conexão ao cancelar.', 'error');
    } finally {
      setIsCanceling(false);
    }
  };

  const showFeedback = (message, type) => {
    setFeedbackMessage({ message, type });
    setTimeout(() => setFeedbackMessage(null), 4000);
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'long',
      year: 'numeric'
    });
  };

  const formatTime = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString('pt-BR', {
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const formatVagas = (max, current) => {
    const maxVagas = parseInt(max) || 0;
    const inscritos = parseInt(current) || 0;
    return `${inscritos}/${maxVagas} inscritos`;
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Loader2 className="animate-spin text-yellow-500" size={48} />
      </div>
    );
  }

  if (error || !event) {
    return (
      <div className="max-w-4xl mx-auto py-12">
        <div className="text-center">
          <AlertCircle className="mx-auto mb-4 text-red-400" size={64} />
          <p className="text-red-400 text-lg mb-4">{error || 'Evento não encontrado'}</p>
          <button
            onClick={() => router.push('/calendario')}
            className="bg-yellow-500 hover:bg-yellow-600 text-gray-900 font-bold py-2 px-6 rounded-lg transition"
          >
            Voltar para Calendário
          </button>
        </div>
      </div>
    );
  }

  const hasInscricao = event.inscricao == '1' || event.inscricao == 1;
  const maxVagas = parseInt(event.max_participantes) || 0;
  const inscritos = parseInt(event.inscritos_count) || 0;
  const progressPercentage = maxVagas > 0 ? (inscritos / maxVagas) * 100 : 0;

  return (
    <div className="max-w-6xl mx-auto">
      {/* Feedback Message */}
      {feedbackMessage && (
        <div className={`fixed top-4 right-4 z-50 p-4 rounded-lg shadow-lg ${
          feedbackMessage.type === 'success' ? 'bg-green-600' : 'bg-red-600'
        }`}>
          <div className="flex items-center text-white">
            {feedbackMessage.type === 'success' ? (
              <CheckCircle size={20} className="mr-2" />
            ) : (
              <XCircle size={20} className="mr-2" />
            )}
            <span>{feedbackMessage.message}</span>
          </div>
        </div>
      )}

      {/* Event Image */}
      {event.imagem_url ? (
        <div className="relative h-72 bg-gray-900 rounded-lg overflow-hidden mb-8">
          <img
            src={`${API_BASE_URL}${event.imagem_url}`}
            alt={event.titulo}
            className="w-full h-full object-cover"
            onError={(e) => {
              e.target.style.display = 'none';
            }}
          />
        </div>
      ) : (
        <div className="h-72 bg-gradient-to-br from-orange-500 to-yellow-500 rounded-lg flex items-center justify-center mb-8">
          <Calendar className="text-white" size={120} />
        </div>
      )}

      {/* Event Content */}
      <div className="bg-gray-800 rounded-lg shadow-lg p-8 border border-gray-700">
        {/* Title */}
        <h1 className="text-3xl md:text-4xl font-bold text-white mb-8">
          {event.titulo || 'Evento sem título'}
        </h1>

        {/* Event Info Section */}
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-white mb-6">Informações do Evento</h2>
          
          <div className="space-y-6">
            {/* Date */}
            <div className="flex items-start">
              <div className="bg-gradient-to-br from-orange-500 to-yellow-500 p-3 rounded-lg mr-4">
                <Calendar size={24} className="text-white" />
              </div>
              <div>
                <p className="text-gray-400 text-sm">Data</p>
                <p className="text-white text-lg font-semibold">
                  {formatDate(event.data_evento)}
                </p>
              </div>
            </div>

            {/* Time */}
            <div className="flex items-start">
              <div className="bg-gradient-to-br from-orange-500 to-yellow-500 p-3 rounded-lg mr-4">
                <Clock size={24} className="text-white" />
              </div>
              <div>
                <p className="text-gray-400 text-sm">Horário</p>
                <p className="text-white text-lg font-semibold">
                  {formatTime(event.data_evento)}
                </p>
              </div>
            </div>

            {/* Vagas - only show if inscricao is enabled */}
            {hasInscricao && (
              <div className="flex items-start">
                <div className="bg-gradient-to-br from-orange-500 to-yellow-500 p-3 rounded-lg mr-4">
                  <Users size={24} className="text-white" />
                </div>
                <div className="flex-1">
                  <p className="text-gray-400 text-sm">Vagas</p>
                  <p className="text-white text-lg font-semibold mb-2">
                    {formatVagas(event.max_participantes, event.inscritos_count)}
                  </p>
                  {/* Progress Bar */}
                  <div className="w-full bg-gray-700 rounded-full h-3 overflow-hidden">
                    <div
                      className="bg-gradient-to-r from-orange-500 to-yellow-500 h-full transition-all duration-300"
                      style={{ width: `${Math.min(progressPercentage, 100)}%` }}
                    />
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Divider */}
        <div className="border-t border-gray-700 my-8" />

        {/* Description */}
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-white mb-4">Sobre o Evento</h2>
          <p className="text-gray-300 text-lg leading-relaxed whitespace-pre-line">
            {event.descricao || 'Descrição não disponível.'}
          </p>
        </div>

        {/* Action Buttons - only show for students if inscricao is enabled */}
        {hasInscricao && user?.role === 'aluno' && (
          <div className="flex flex-col sm:flex-row gap-4">
            {isRegistered ? (
              <button
                onClick={handleCancellation}
                disabled={isCanceling}
                className="flex-1 border-2 border-red-500 hover:bg-red-500 text-red-500 hover:text-white font-bold py-4 px-6 rounded-lg transition-all disabled:opacity-50 flex items-center justify-center"
              >
                {isCanceling ? (
                  <Loader2 className="animate-spin" size={20} />
                ) : (
                  <>
                    <XCircle size={20} className="mr-2" />
                    Cancelar Inscrição
                  </>
                )}
              </button>
            ) : (
              <button
                onClick={handleRegistration}
                disabled={isRegistering || inscritos >= maxVagas}
                className="flex-1 bg-gradient-to-r from-orange-500 to-yellow-500 hover:from-orange-600 hover:to-yellow-600 text-white font-bold py-4 px-6 rounded-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center shadow-lg"
              >
                {isRegistering ? (
                  <Loader2 className="animate-spin" size={20} />
                ) : inscritos >= maxVagas ? (
                  'Vagas Esgotadas'
                ) : (
                  <>
                    <CheckCircle size={20} className="mr-2" />
                    Inscrever-se
                  </>
                )}
              </button>
            )}
          </div>
        )}

        {/* Info for non-students */}
        {hasInscricao && user?.role !== 'aluno' && (
          <div className="bg-gray-900 border border-gray-700 rounded-lg p-4">
            <p className="text-gray-400 text-center">
              Apenas alunos podem se inscrever em eventos
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
