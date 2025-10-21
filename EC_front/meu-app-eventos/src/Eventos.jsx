import React, { useState, useEffect, useRef } from 'react'; // --- NOVIDADE ---: Importa o useRef
import './Eventos.css';

function Eventos() {
    const [eventos, setEventos] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const NUMERO_INICIAL_DE_EVENTOS = 3;
    const [eventosVisiveis, setEventosVisiveis] = useState(NUMERO_INICIAL_DE_EVENTOS);

    // --- NOVIDADE ---
    // Cria uma "referência" para a secção de eventos. Usaremos isto para o scroll.
    const eventsSectionRef = useRef(null);

    useEffect(() => {
        const fetchEventos = async () => {
            try {
                const response = await fetch('http://localhost/EC_back/api/eventos.php');
                if (!response.ok) throw new Error('A resposta da rede não foi OK');
                const data = await response.json();
                setEventos(data);
            } catch (error) {
                setError(error.message);
            } finally {
                setLoading(false);
            }
        };
        fetchEventos();
    }, []);

    const formatarData = (dataString) => {
        const data = new Date(dataString + 'T00:00:00');
        return new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: 'long', year: 'numeric' }).format(data);
    };

    const cardStyles = [
        { icon: 'bi-calendar-event', color: 'purple', linkText: 'Saiba Mais →' },
        { icon: 'bi-code-slash', color: 'pink', linkText: 'Inscreva-se Agora →' },
        { icon: 'bi-heart-fill', color: 'green', linkText: 'Veja como Ajudar →' }
    ];

    const handleVerMais = () => {
        setEventosVisiveis(eventos.length);
    };

    // --- NOVIDADE ---
    // Função para o botão "Ver Menos".
    const handleVerMenos = () => {
        // Restaura o número de eventos para o valor inicial.
        setEventosVisiveis(NUMERO_INICIAL_DE_EVENTOS);
        // Rola a página suavemente de volta para o topo da secção.
        eventsSectionRef.current.scrollIntoView({ behavior: 'smooth' });
    };

    if (loading) return <div className="text-center p-5 text-white">A carregar eventos...</div>;
    if (error) return <div className="text-center p-5 text-danger">Erro ao carregar eventos: {error}</div>;

    return (
        // --- NOVIDADE ---: Anexa a referência ao elemento da secção.
        <section className="events-section" ref={eventsSectionRef}>
            <div className="container">
                <h2 className="text-center mb-5">Próximos Eventos</h2>
                <div className="row g-4">
                    {eventos.slice(0, eventosVisiveis).map((evento, index) => {
                        const style = cardStyles[index % cardStyles.length];
                        return (
                            <div className="col-md-6 col-lg-4" key={evento.id}>
                                <div className="card event-card">
                                    <div className="card-body">
                                        <div className={`event-icon event-icon-${style.color}`}>
                                            <i className={`bi ${style.icon}`}></i>
                                        </div>
                                        <p className="card-subtitle mb-2 text-muted">{formatarData(evento.data_evento)}</p>
                                        <h5 className="card-title mb-3">{evento.titulo}</h5>
                                        <p className="card-text">{evento.descricao}</p>
                                        <a href="#" className={`mt-auto event-link-${style.color}`}>
                                            {style.linkText}
                                        </a>
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>

                <div className="text-center mt-5">
                    {/* --- MUDANÇA NA LÓGICA --- */}
                    {/* Botão "Ver Mais": aparece se houver mais eventos para mostrar. */}
                    {eventos.length > eventosVisiveis && (
                        <button className="btn btn-outline-light" onClick={handleVerMais}>
                            Ver Mais Eventos
                        </button>
                    )}

                    {/* Botão "Ver Menos": aparece se todos os eventos estiverem visíveis E
                        se o total de eventos for maior que o número inicial. */}
                    {eventosVisiveis === eventos.length && eventos.length > NUMERO_INICIAL_DE_EVENTOS && (
                        <button className="btn btn-outline-light" onClick={handleVerMenos}>
                            Ver Menos
                        </button>
                    )}
                </div>
            </div>
        </section>
    );
}

export default Eventos;