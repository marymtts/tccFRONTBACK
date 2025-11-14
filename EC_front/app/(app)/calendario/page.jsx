'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Search, Calendar as CalendarIcon, Loader2 } from 'lucide-react';
import Calendar from 'react-calendar';
import 'react-calendar/dist/Calendar.css';
import { useAuth } from '../../context/AuthContext';

const API_BASE_URL = 'https://tccfrontback.onrender.com';

export default function CalendarioPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [events, setEvents] = useState([]);
  const [filteredEvents, setFilteredEvents] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [eventsMap, setEventsMap] = useState({});
  const [showCalendar, setShowCalendar] = useState(true);

  useEffect(() => {
    fetchEvents();
  }, []);

  useEffect(() => {
    // Filter events when search query changes
    if (searchQuery.trim() === '') {
      setFilteredEvents(events);
    } else {
      const filtered = events.filter(event =>
        event.titulo.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (event.descricao && event.descricao.toLowerCase().includes(searchQuery.toLowerCase()))
      );
      setFilteredEvents(filtered);
    }
  }, [searchQuery, events]);

  const fetchEvents = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/eventos.php`);
      if (response.ok) {
        const data = await response.json();
        setEvents(data);
        setFilteredEvents(data);
        
        // Create a map of dates to events for calendar markers
        const map = {};
        data.forEach(event => {
          const dateKey = new Date(event.data_evento).toDateString();
          if (!map[dateKey]) {
            map[dateKey] = [];
          }
          map[dateKey].push(event);
        });
        setEventsMap(map);
      } else {
        setError('Falha ao carregar eventos');
      }
    } catch (err) {
      console.error('Erro ao buscar eventos:', err);
      setError('Erro de conexão. Verifique sua internet.');
    } finally {
      setIsLoading(false);
    }
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('pt-BR', { 
      day: '2-digit', 
      month: 'short', 
      year: 'numeric' 
    }).toUpperCase();
  };

  const formatDateFull = (date) => {
    return date.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: 'long',
      year: 'numeric'
    });
  };

  const handleEventClick = (eventId) => {
    router.push(`/evento/${eventId}`);
  };

  const getTileClassName = ({ date, view }) => {
    if (view === 'month') {
      const dateKey = date.toDateString();
      if (eventsMap[dateKey]) {
        return 'has-events';
      }
    }
    return null;
  };

  const getEventsForDate = (date) => {
    const dateKey = date.toDateString();
    return eventsMap[dateKey] || [];
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Loader2 className="animate-spin text-yellow-500" size={48} />
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <p className="text-red-400 text-lg">{error}</p>
        <button
          onClick={fetchEvents}
          className="mt-4 bg-yellow-500 hover:bg-yellow-600 text-gray-900 font-bold py-2 px-6 rounded-lg transition"
        >
          Tentar Novamente
        </button>
      </div>
    );
  }

  const eventsForSelectedDate = getEventsForDate(selectedDate);

  return (
    <div className="max-w-6xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl md:text-4xl font-bold text-white mb-2">Calendário de Eventos</h1>
        <p className="text-gray-400">Explore os próximos eventos do Cotil</p>
      </div>

      {/* Toggle View Button */}
      <div className="mb-6">
        <button
          onClick={() => setShowCalendar(!showCalendar)}
          className="bg-gray-800 hover:bg-gray-700 text-white font-semibold py-2 px-6 rounded-lg transition border border-gray-700"
        >
          {showCalendar ? 'Ver Lista' : 'Ver Calendário'}
        </button>
      </div>

      {showCalendar ? (
        /* Calendar View */
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
          {/* Calendar Widget */}
          <div className="lg:col-span-2">
            <div className="bg-gray-800 rounded-lg shadow-lg p-6 border border-gray-700">
              <style jsx global>{`
                .react-calendar {
                  width: 100%;
                  background: transparent;
                  border: none;
                  font-family: inherit;
                  color: white;
                }
                .react-calendar__navigation {
                  display: flex;
                  margin-bottom: 1rem;
                }
                .react-calendar__navigation button {
                  color: white;
                  min-width: 44px;
                  background: #374151;
                  border: 1px solid #4B5563;
                  border-radius: 0.5rem;
                  padding: 0.5rem;
                  font-size: 1rem;
                  font-weight: bold;
                }
                .react-calendar__navigation button:enabled:hover,
                .react-calendar__navigation button:enabled:focus {
                  background-color: #4B5563;
                }
                .react-calendar__month-view__weekdays {
                  text-align: center;
                  font-weight: bold;
                  font-size: 0.875rem;
                  color: #9CA3AF;
                }
                .react-calendar__month-view__weekdays__weekday {
                  padding: 0.5rem;
                }
                .react-calendar__month-view__days__day {
                  color: white;
                  padding: 0.75rem;
                  border-radius: 0.5rem;
                }
                .react-calendar__month-view__days__day--weekend {
                  color: #D1D5DB;
                }
                .react-calendar__month-view__days__day--neighboringMonth {
                  color: #6B7280;
                }
                .react-calendar__tile:enabled:hover,
                .react-calendar__tile:enabled:focus {
                  background-color: #374151;
                }
                .react-calendar__tile--now {
                  background: #374151;
                }
                .react-calendar__tile--active {
                  background: linear-gradient(to right, #f97316, #eab308) !important;
                  color: white !important;
                  border-radius: 0.5rem;
                }
                .react-calendar__tile.has-events {
                  position: relative;
                  color: #eab308 !important;
                  font-weight: bold;
                }
                .react-calendar__tile.has-events::after {
                  content: '';
                  position: absolute;
                  bottom: 4px;
                  left: 50%;
                  transform: translateX(-50%);
                  width: 4px;
                  height: 4px;
                  background: #eab308;
                  border-radius: 50%;
                }
              `}</style>
              <Calendar
                onChange={setSelectedDate}
                value={selectedDate}
                tileClassName={getTileClassName}
                locale="pt-BR"
              />
            </div>
          </div>

          {/* Events for Selected Date */}
          <div className="lg:col-span-1">
            <div className="bg-gray-800 rounded-lg shadow-lg p-6 border border-gray-700">
              <h3 className="text-xl font-bold text-white mb-4">
                Eventos de {formatDateFull(selectedDate)}
              </h3>
              {eventsForSelectedDate.length === 0 ? (
                <p className="text-gray-400">Nenhum evento para este dia.</p>
              ) : (
                <div className="space-y-3">
                  {eventsForSelectedDate.map((event) => (
                    <div
                      key={event.id}
                      onClick={() => handleEventClick(event.id)}
                      className="bg-gray-700 hover:bg-gray-600 p-3 rounded-lg cursor-pointer transition"
                    >
                      <p className="text-white font-semibold text-sm line-clamp-2">
                        {event.titulo}
                      </p>
                      <p className="text-yellow-500 text-xs mt-1">
                        {formatDate(event.data_evento)}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      ) : (
        /* List View */
        <>
          {/* Search Bar */}
          <div className="mb-8">
            <div className="relative">
              <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
              <input
                type="text"
                placeholder="Buscar pelo nome do evento..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-12 pr-4 py-3 bg-gray-800 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-yellow-500 focus:border-transparent"
              />
            </div>
          </div>

          {/* Events List */}
          {filteredEvents.length === 0 ? (
            <div className="text-center py-12 bg-gray-800 rounded-lg">
              <CalendarIcon className="mx-auto mb-4 text-gray-600" size={64} />
              <p className="text-gray-400 text-lg">
                {searchQuery ? `Nenhum evento encontrado com "${searchQuery}".` : 'Nenhum evento futuro encontrado.'}
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-6">
              {filteredEvents.map((event) => (
                <div
                  key={event.id}
                  className="bg-gray-800 rounded-lg overflow-hidden shadow-lg hover:shadow-2xl transition-shadow duration-300 border border-gray-700 hover:border-yellow-500 cursor-pointer"
                  onClick={() => handleEventClick(event.id)}
                >
                  {/* Event Image */}
                  {event.imagem_url ? (
                    <div className="relative h-48 bg-gray-900">
                      <img
                        src={`${API_BASE_URL}${event.imagem_url}`}
                        alt={event.titulo}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          e.target.style.display = 'none';
                          e.target.parentElement.innerHTML = '<div class="flex items-center justify-center h-full bg-gradient-to-br from-orange-500 to-yellow-500"><svg class="text-white" width="64" height="64" fill="currentColor" viewBox="0 0 24 24"><path d="M19 3h-1V1h-2v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V8h14v11zM7 10h5v5H7z"/></svg></div>';
                        }}
                      />
                    </div>
                  ) : (
                    <div className="h-48 bg-gradient-to-br from-orange-500 to-yellow-500 flex items-center justify-center">
                      <CalendarIcon className="text-white" size={64} />
                    </div>
                  )}

                  {/* Event Content */}
                  <div className="p-6">
                    <p className="text-yellow-500 text-sm font-bold mb-2">
                      {formatDate(event.data_evento)}
                    </p>
                    <h3 className="text-xl font-bold text-white mb-3">
                      {event.titulo}
                    </h3>
                    <p className="text-gray-400 mb-4 line-clamp-3">
                      {event.descricao || 'Descrição indisponível.'}
                    </p>

                    {/* Action Buttons */}
                    <div className="flex flex-col sm:flex-row gap-3">
                      {user?.role === 'admin' && (
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            router.push(`/admin/editar-evento/${event.id}`);
                          }}
                          className="flex-1 border border-gray-600 hover:border-gray-500 text-gray-300 hover:text-white font-semibold py-2 px-4 rounded-lg transition-colors"
                        >
                          Editar Evento
                        </button>
                      )}
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          handleEventClick(event.id);
                        }}
                        className="flex-1 bg-gradient-to-r from-orange-500 to-yellow-500 hover:from-orange-600 hover:to-yellow-600 text-white font-bold py-2 px-4 rounded-lg transition-all"
                      >
                        Saiba mais
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}