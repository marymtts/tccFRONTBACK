'use client';

import React from 'react';
import { CheckCircle } from 'lucide-react';

export default function EventCard({ event, userId, onClick }) {
   // A lógica de inscrição agora vem da prop 'event.isRegistered'
   // que foi definida em /calendario/page.jsx
   const isRegistered = event.isRegistered; 
   const eventDate = new Date(event.date);

  return (
    <div 
        className="bg-gray-700 p-4 rounded-lg shadow-md flex flex-col md:flex-row items-start md:items-center justify-between"
    >
        <div className="flex items-center mb-4 md:mb-0">
            {/* Data */}
            <div className="text-center mr-4 bg-gray-800 p-3 rounded-lg w-20">
                <span className="block text-sm font-medium text-yellow-400 uppercase">
                    {eventDate.toLocaleString('pt-BR', { month: 'short' })}
                </span>
                <span className="block text-3xl font-bold text-white">
                    {eventDate.getDate()}
                </span>
                <span className="block text-sm text-gray-400">
                    {eventDate.getFullYear()}
                </span>
            </div>
            {/* Info */}
            <div>
                <h3 className="text-xl font-bold text-white">{event.title}</h3>
                <p className="text-sm text-gray-400">
                    {event.speaker} • {eventDate.toLocaleString('pt-BR', { hour: '2-digit', minute: '2-digit' })}
                </p>
                 {isRegistered && ( // <-- Esta lógica agora funciona
                    <span className="mt-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-700 text-green-100">
                        <CheckCircle size={14} className="mr-1" /> Inscrito
                    </span>
                )}
            </div>
        </div>
        
        {/* Botão */}
        <button 
            onClick={onClick}
            className="w-full md:w-auto bg-yellow-600 hover:bg-yellow-700 text-white font-bold py-2 px-4 rounded-lg transition duration-300"
        >
            Ver Detalhes
        </button>
    </div>
  );
}