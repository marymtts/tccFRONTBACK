'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Calendar, Clock, Users, Upload, Loader2, CheckCircle, XCircle } from 'lucide-react';
import { useAuth } from '../../../context/AuthContext';

const API_BASE_URL = 'https://tccfrontback.onrender.com';

export default function CriarEventoPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [isLoading, setIsLoading] = useState(false);
  const [feedbackMessage, setFeedbackMessage] = useState(null);
  const [formData, setFormData] = useState({
    titulo: '',
    descricao: '',
    dataEvento: '',
    horaEvento: '',
    requerInscricao: true,
    maxParticipantes: ''
  });
  const [selectedImage, setSelectedImage] = useState(null);

  // Redirect if not admin
  React.useEffect(() => {
    if (user && user.role !== 'admin') {
      router.push('/inicio');
    }
  }, [user, router]);

  const handleImageChange = (e) => {
    if (e.target.files && e.target.files[0]) {
      setSelectedImage(e.target.files[0]);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!formData.titulo || !formData.dataEvento || !formData.horaEvento) {
      showFeedback('Por favor, preencha todos os campos obrigatórios.', 'error');
      return;
    }

    setIsLoading(true);

    try {
      // Combine date and time
      const dateTime = `${formData.dataEvento} ${formData.horaEvento}:00`;

      const formDataToSend = new FormData();
      formDataToSend.append('titulo', formData.titulo);
      formDataToSend.append('descricao', formData.descricao);
      formDataToSend.append('data_evento', dateTime);
      formDataToSend.append('inscricao', formData.requerInscricao ? '1' : '0');
      formDataToSend.append('max_participantes', formData.maxParticipantes || '0');

      if (selectedImage) {
        formDataToSend.append('imagem_evento', selectedImage);
      }

      const response = await fetch(`${API_BASE_URL}/api/eventos.php`, {
        method: 'POST',
        body: formDataToSend,
      });

      const data = await response.json();

      if (response.status === 201) {
        showFeedback(data.message || 'Evento criado com sucesso!', 'success');
        setTimeout(() => router.push('/admin'), 2000);
      } else {
        showFeedback(data.message || `Erro ${response.status}`, 'error');
      }
    } catch (error) {
      console.error('Erro ao criar evento:', error);
      showFeedback('Erro de conexão. Verifique o servidor.', 'error');
    } finally {
      setIsLoading(false);
    }
  };

  const showFeedback = (message, type) => {
    setFeedbackMessage({ message, type });
    setTimeout(() => setFeedbackMessage(null), 4000);
  };

  if (!user || user.role !== 'admin') {
    return null;
  }

  return (
    <div className="max-w-4xl mx-auto">
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

      <div className="mb-8">
        <h1 className="text-3xl md:text-4xl font-bold text-white mb-2">Criar Novo Evento</h1>
        <p className="text-gray-400">Preencha os dados do evento</p>
      </div>

      <form onSubmit={handleSubmit} className="bg-gray-800 rounded-lg shadow-lg p-8 border border-gray-700">
        {/* Título */}
        <div className="mb-6">
          <label className="block text-gray-300 font-semibold mb-2">
            Título do Evento *
          </label>
          <input
            type="text"
            value={formData.titulo}
            onChange={(e) => setFormData({ ...formData, titulo: e.target.value })}
            className="w-full px-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-yellow-500"
            placeholder="Ex: Palestra sobre IA"
            required
          />
        </div>

        {/* Descrição */}
        <div className="mb-6">
          <label className="block text-gray-300 font-semibold mb-2">
            Descrição
          </label>
          <textarea
            value={formData.descricao}
            onChange={(e) => setFormData({ ...formData, descricao: e.target.value })}
            className="w-full px-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-yellow-500"
            rows="5"
            placeholder="Descreva o evento..."
          />
        </div>

        {/* Data e Hora */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <div>
            <label className="block text-gray-300 font-semibold mb-2">
              <Calendar size={16} className="inline mr-2" />
              Data do Evento *
            </label>
            <input
              type="date"
              value={formData.dataEvento}
              onChange={(e) => setFormData({ ...formData, dataEvento: e.target.value })}
              className="w-full px-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-yellow-500"
              required
            />
          </div>
          <div>
            <label className="block text-gray-300 font-semibold mb-2">
              <Clock size={16} className="inline mr-2" />
              Horário *
            </label>
            <input
              type="time"
              value={formData.horaEvento}
              onChange={(e) => setFormData({ ...formData, horaEvento: e.target.value })}
              className="w-full px-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-yellow-500"
              required
            />
          </div>
        </div>

        {/* Requer Inscrição */}
        <div className="mb-6">
          <label className="flex items-center cursor-pointer">
            <input
              type="checkbox"
              checked={formData.requerInscricao}
              onChange={(e) => setFormData({ ...formData, requerInscricao: e.target.checked })}
              className="w-5 h-5 text-yellow-500 bg-gray-700 border-gray-600 rounded focus:ring-yellow-500"
            />
            <span className="ml-3 text-gray-300">Requer inscrição prévia</span>
          </label>
        </div>

        {/* Max Participantes */}
        {formData.requerInscricao && (
          <div className="mb-6">
            <label className="block text-gray-300 font-semibold mb-2">
              <Users size={16} className="inline mr-2" />
              Máximo de Participantes
            </label>
            <input
              type="number"
              value={formData.maxParticipantes}
              onChange={(e) => setFormData({ ...formData, maxParticipantes: e.target.value })}
              className="w-full px-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-yellow-500"
              placeholder="0 = ilimitado"
              min="0"
            />
          </div>
        )}

        {/* Imagem */}
        <div className="mb-8">
          <label className="block text-gray-300 font-semibold mb-2">
            <Upload size={16} className="inline mr-2" />
            Imagem do Evento
          </label>
          <input
            type="file"
            accept="image/*"
            onChange={handleImageChange}
            className="w-full px-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:bg-gradient-to-r file:from-orange-500 file:to-yellow-500 file:text-white file:cursor-pointer"
          />
          {selectedImage && (
            <p className="mt-2 text-gray-400 text-sm">
              Arquivo selecionado: {selectedImage.name}
            </p>
          )}
        </div>

        {/* Buttons */}
        <div className="flex flex-col sm:flex-row gap-4">
          <button
            type="button"
            onClick={() => router.push('/admin')}
            className="flex-1 border border-gray-600 hover:border-gray-500 text-gray-300 hover:text-white font-semibold py-3 px-6 rounded-lg transition-colors"
          >
            Cancelar
          </button>
          <button
            type="submit"
            disabled={isLoading}
            className="flex-1 bg-gradient-to-r from-orange-500 to-yellow-500 hover:from-orange-600 hover:to-yellow-600 text-white font-bold py-3 px-6 rounded-lg transition-all disabled:opacity-50 flex items-center justify-center shadow-lg"
          >
            {isLoading ? (
              <Loader2 className="animate-spin" size={20} />
            ) : (
              'Criar Evento'
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
