'use client';

import React, { useState } from 'react';
import { Loader2, X } from 'lucide-react';
import { useAuth } from '../../context/AuthContext'; // Corrigido
import { database } from '../../lib/database'; // Corrigido

export default function CreateEventModal({ onClose, onEventCreated }) {
    const { user, token } = useAuth(); // <-- Pega o token
    const [title, setTitle] = useState('');
    const [date, setDate] = useState('');
    const [description, setDescription] = useState('');
    const [inscricao, setInscricao] = useState(true); // Novo estado
    const [maxParticipantes, setMaxParticipantes] = useState(''); // Novo estado
    const [imagem, setImagem] = useState(null); // Novo estado para o arquivo
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        
        // Em vez de JSON, criamos FormData
        const formData = new FormData();
        formData.append('titulo', title);
        formData.append('data_evento', date);
        formData.append('descricao', description);
        formData.append('inscricao', inscricao ? '1' : '0'); // Envia '1' ou '0'
        
        if (inscricao && maxParticipantes) {
          formData.append('max_participantes', maxParticipantes);
        }
        
        if (imagem) {
          formData.append('imagem_evento', imagem); // Anexa o arquivo
        }

        // A API de criar evento agora espera o formData e o token
        // Corrigido de mockDatabase para database
        const result = await database.createEvent(formData, token); 
        
        if (result.success) {
            onEventCreated(); // Apenas avisa a página pai para recarregar
        } else {
          // TODO: Mostrar mensagem de erro
          console.error(result.message);
        }
        setLoading(false);
    };

    return (
     <div className="fixed inset-0 bg-black/70 z-50 flex items-center justify-center p-4">
        <div className="bg-gray-800 rounded-lg shadow-xl w-full max-w-lg p-6 relative">
            <button onClick={onClose} className="absolute top-4 right-4 text-gray-400 hover:text-white">
                <X size={24} />
            </button>
            <h2 className="text-2xl font-bold text-white mb-6">Cadastrar Nova Palestra</h2>
            
            <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                    <label className="block text-sm font-medium text-gray-300 mb-1">Título da Palestra</label>
                    <input 
                        type="text" 
                        value={title}
                        onChange={(e) => setTitle(e.target.value)}
                        className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-yellow-500"
                        required 
                    />
                </div>
                <div>
                    <label className="block text-sm font-medium text-gray-300 mb-1">Data e Hora</label>
                    <input 
                        type="datetime-local" 
                        value={date}
                        onChange={(e) => setDate(e.target.value)}
                        className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
                        required 
                    />
                </div>
                 <div>
                    <label className="block text-sm font-medium text-gray-300 mb-1">Descrição</label>
                    <textarea
                        value={description}
                        onChange={(e) => setDescription(e.target.value)}
                        rows="3"
                        className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-yellow-500"
                        required 
                    />
                </div>
                
                {/* Novos campos para 'inscricao' e 'max_participantes' */}
                 <div className="flex items-center space-x-4">
                    <div className="flex items-center">
                        <input 
                            id="inscricao"
                            type="checkbox" 
                            checked={inscricao}
                            onChange={(e) => setInscricao(e.target.checked)}
                            className="h-4 w-4 bg-gray-700 border-gray-600 rounded text-yellow-600 focus:ring-yellow-500"
                        />
                        <label htmlFor="inscricao" className="ml-2 block text-sm font-medium text-gray-300">Permitir Inscrição</label>
                    </div>
                    {inscricao && (
                       <div className="flex-1">
                           <label className="block text-sm font-medium text-gray-300 mb-1">Max. Vagas (opcional)</label>
                            <input 
                                type="number" 
                                value={maxParticipantes}
                                onChange={(e) => setMaxParticipantes(e.target.value)}
                                placeholder="Ex: 50"
                                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-yellow-500"
                            />
                       </div>
                    )}
                </div>

                {/* Novo campo para 'imagem_evento' */}
                <div>
                    <label className="block text-sm font-medium text-gray-300 mb-1">Imagem do Evento (Opcional)</label>
                    <input 
                        type="file" 
                        onChange={(e) => setImagem(e.target.files[0])}
                        accept="image/png, image/jpeg, image/gif"
                        className="w-full text-sm text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-yellow-600 file:text-white hover:file:bg-yellow-700"
                    />
                </div>
                
                <div className="pt-4">
                    <button
                        type="submit"
                        disabled={loading}
                        className="w-full bg-yellow-600 hover:bg-yellow-700 text-white font-bold py-3 px-4 rounded-lg transition duration-300 disabled:opacity-50 flex items-center justify-center"
                    >
                        {loading ? <Loader2 className="animate-spin" /> : 'Salvar Evento'}
                    </button>
                </div>
            </form>
        </div>
     </div>
    );
}