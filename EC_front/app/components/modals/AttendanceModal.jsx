'use client';

import React, { useState, useEffect } from 'react';
import { Loader2, X, CheckCircle, XCircle } from 'lucide-react';
import { database } from '../../../lib/database'; // Corrigido para caminho relativo e API real

export default function AttendanceModal({ eventId, token, onClose }) { // <-- Recebe o token
    const [students, setStudents] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Passa o token para a API real
        database.getRegisteredStudents(eventId, token).then(data => { // Corrigido para 'database'
            setStudents(data);
            setLoading(false);
        }).catch(error => {
            console.error("Erro ao buscar inscritos:", error);
            setStudents([]);
            setLoading(false);
        });
    }, [eventId, token]);

    return (
     <div className="fixed inset-0 bg-black/70 z-50 flex items-center justify-center p-4">
        <div className="bg-gray-800 rounded-lg shadow-xl w-full max-w-2xl p-6 relative max-h-[90vh] flex flex-col">
            <button onClick={onClose} className="absolute top-4 right-4 text-gray-400 hover:text-white">
                <X size={24} />
            </button>
            <h2 className="text-2xl font-bold text-white mb-6">Lista de Inscritos</h2>
            
            {loading ? (
                <div className="flex justify-center items-center h-48"><Loader2 className="animate-spin text-white" size={40} /></div>
            ) : students.length === 0 ? (
                <p className="text-gray-400 text-center">Nenhum aluno inscrito.</p>
            ) : (
                <div className="overflow-y-auto">
                    <table className="w-full table-auto">
                        <thead className="sticky top-0 bg-gray-800">
                            <tr>
                                <th className="text-left p-3 text-sm font-semibold text-gray-400 uppercase">Aluno</th>
                                <th className="text-left p-3 text-sm font-semibold text-gray-400 uppercase">Email</th>
                                <th className="text-center p-3 text-sm font-semibold text-gray-400 uppercase">Presença</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-700">
                            {students.map(student => (
                                <tr key={student.id} className="hover:bg-gray-700">
                                    <td className="p-3 text-white">{student.nome}</td> {/* Corrigido de name para nome */}
                                    <td className="p-3 text-gray-300">{student.email}</td>
                                    <td className="p-3 text-center">
                                        {/* Sua API (get_inscritos_evento.php) precisa retornar
                                          um campo 'presenca' (1 para presente, 0 para ausente)
                                          para isso funcionar.
                                        */}
                                        {student.presenca ? (
                                            <CheckCircle size={20} className="text-green-500 mx-auto" />
                                        ) : (
                                            <XCircle size={20} className="text-red-500 mx-auto" />
                                        )}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
     </div>
    );
}