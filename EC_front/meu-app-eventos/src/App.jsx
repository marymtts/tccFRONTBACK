import React, { useRef } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';

// Importa os teus componentes e páginas
import Navbar from './Navbar';
import Eventos from './Eventos';
import SobreNos from './SobreNos';
import LoginPage from './LoginPage';
import AdminDashboard from './AdminDashboard';
import './App.css';

// Componente para a página inicial pública
function PaginaPublica() {
    const eventosRef = useRef(null);
    const sobreNosRef = useRef(null);

    const scrollToEventos = () => eventosRef.current.scrollIntoView({ behavior: 'smooth' });
    const scrollToSobreNos = () => sobreNosRef.current.scrollIntoView({ behavior: 'smooth' });

    return (
        <div>
            <Navbar onEventosClick={scrollToEventos} onSobreNosClick={scrollToSobreNos} />
            <main>
                <div ref={eventosRef}><Eventos /></div>
                <div ref={sobreNosRef}><SobreNos /></div>
            </main>
        </div>
    );
}

// Componente de Rota Protegida
function ProtectedRoute({ children }) {
    const token = localStorage.getItem('authToken');
    if (!token) {
        // Se não houver token, redireciona para a página de login
        return <Navigate to="/admin" replace />;
    }
    return children;
}

function App() {
    return (
        <Routes>
            {/* Rota para a página pública */}
            <Route path="/" element={<PaginaPublica />} />

            {/* Rota para a página de login */}
            <Route path="/admin" element={<LoginPage />} />

            {/* Rota protegida para o dashboard */}
            <Route 
                path="/admin/dashboard" 
                element={
                    <ProtectedRoute>
                        <AdminDashboard />
                    </ProtectedRoute>
                } 
            />
            
            {/* Rota para qualquer outro caminho não encontrado */}
            <Route path="*" element={<Navigate to="/" />} />
        </Routes>
    );
}

export default App;