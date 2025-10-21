import React from 'react';
import { useNavigate } from 'react-router-dom';

function AdminDashboard() {
    const navigate = useNavigate();

    const handleLogout = () => {
        localStorage.removeItem('authToken'); // Remove o token
        navigate('/admin'); // Redireciona para o login
    };

    return (
        <div className="container mt-5">
            <div className="d-flex justify-content-between align-items-center mb-4">
                <h1>Painel Administrativo</h1>
                <button className="btn btn-danger" onClick={handleLogout}>Sair (Logout)</button>
            </div>
            <p>Bem-vindo à sua área restrita! Aqui podes gerir os eventos e utilizadores.</p>
            {/* Futuramente, aqui entrarão as tabelas de gestão */}
        </div>
    );
}

export default AdminDashboard;