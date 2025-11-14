// Mock database adapter - This will be replaced with real API calls
const API_BASE_URL = 'https://tccfrontback.onrender.com';

export const database = {
  async getEvents() {
    const response = await fetch(`${API_BASE_URL}/api/eventos.php`);
    if (!response.ok) throw new Error('Failed to fetch events');
    return response.json();
  },

  async getMyRegisteredEventIds(userId, token) {
    // This endpoint needs to be created or we need to use a different approach
    // For now, return empty array
    return [];
  },

  async registerForEvent(eventId, userId, token) {
    const response = await fetch(`${API_BASE_URL}/api/registrar_participacao.php`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({ id_evento: eventId, id_aluno: userId })
    });
    return response.json();
  },

  async cancelEventRegistration(eventId, userId, token) {
    const response = await fetch(`${API_BASE_URL}/api/cancelar_participacao.php`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({ id_evento: eventId, id_aluno: userId })
    });
    return response.json();
  }
};
