import React from 'react';
import './Navbar.css';

// --- NOVIDADE ---: Aceita a nova prop 'onSobreNosClick'
function Navbar({ onEventosClick, onSobreNosClick }) { 
    return (
        <nav className="navbar navbar-expand-lg navbar-dark bg-dark sticky-top">
            <div className="container">
                <a className="navbar-brand d-flex align-items-center" href="#">
                    <i className="bi bi-calendar2-event-fill me-2 fs-4"></i>
                    <span className="fw-bold">Eventos Cotil</span>
                </a>

                <button
                    className="navbar-toggler"
                    type="button"
                    data-bs-toggle="collapse"
                    data-bs-target="#navbarNav"
                >
                    <span className="navbar-toggler-icon"></span>
                </button>

                <div className="collapse navbar-collapse" id="navbarNav">
                    <ul className="navbar-nav ms-auto align-items-center">
                        <li className="nav-item">
                            <a
                                className="nav-link"
                                href="#"
                                onClick={(e) => { e.preventDefault(); onEventosClick(); }}
                            >
                                Eventos
                            </a>
                        </li>
                        <li className="nav-item">
                            {/* --- NOVIDADE ---: Adiciona o onClick para o scroll */}
                            <a 
                                className="nav-link" 
                                href="#"
                                onClick={(e) => { e.preventDefault(); onSobreNosClick(); }}
                            >
                                Sobre Nós
                            </a>
                        </li>
                        <li className="nav-item ms-lg-3">
                            <a className="btn btn-divulgue" href="#">Divulgue!</a>
                        </li>
                    </ul>
                </div>
            </div>
        </nav>
    );
}

export default Navbar;