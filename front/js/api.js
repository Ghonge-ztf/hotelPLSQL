const BASE_URL = 'http://localhost:3000/api';

async function apiFetch(endpoint, options = {}) {
  const res = await fetch(`${BASE_URL}${endpoint}`, {
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || `Error ${res.status}`);
  return data;
}

// ── HABITACIONES ──
const Habitaciones = {
  getAll: () => apiFetch('/habitaciones'),
  getDisponibles: () => apiFetch('/habitaciones/disponibles'),
  getById: (id) => apiFetch(`/habitaciones/${id}`),
  create: (body) => apiFetch('/habitaciones', { method: 'POST', body: JSON.stringify(body) }),
  updateEstado: (id, estado) => apiFetch(`/habitaciones/${id}/estado`, { method: 'PATCH', body: JSON.stringify({ estado }) }),
  delete: (id) => apiFetch(`/habitaciones/${id}`, { method: 'DELETE' }),
};

// ── RESERVAS ──
// ── RESERVAS ──
const Reservas = {
  getAll:        ()    => apiFetch('/reservas'),
  getActivas:    ()    => apiFetch('/reservas/activas'),
  getByHuesped:  (id)  => apiFetch(`/reservas/huesped/${id}`),
  getById:       (id)  => apiFetch(`/reservas/${id}`),
  create:        (body)=> apiFetch('/reservas', { method: 'POST', body: JSON.stringify(body) }),
  activar:       (id)  => apiFetch(`/reservas/${id}/activar`,  { method: 'PATCH' }),
  cancelar:      (id)  => apiFetch(`/reservas/${id}/cancelar`, { method: 'PATCH' }),
  completar:     (id)  => apiFetch(`/reservas/${id}/completar`,{ method: 'PATCH' }),
  delete:        (id)  => apiFetch(`/reservas/${id}`,          { method: 'DELETE' }),
};
// ── PAGOS ──
const Pagos = {
  getAll: () => apiFetch('/pagos'),
  getById: (id) => apiFetch(`/pagos/${id}`),
  getByReserva: (idReserva) => apiFetch(`/pagos/reserva/${idReserva}`),
  create: (body) => apiFetch('/pagos', { method: 'POST', body: JSON.stringify(body) }),
  anular: (id) => apiFetch(`/pagos/${id}/anular`, { method: 'PATCH' }),
};

// ── HUÉSPEDES ──
const Huespedes = {
  getAll: () => apiFetch('/huespedes'),
  getById: (id) => apiFetch(`/huespedes/${id}`),
  create: (body) => apiFetch('/huespedes', { method: 'POST', body: JSON.stringify(body) }),
  update: (id, body) => apiFetch(`/huespedes/${id}`, { method: 'PUT', body: JSON.stringify(body) }),
  delete: (id) => apiFetch(`/huespedes/${id}`, { method: 'DELETE' }),
};

// ── EMPLEADOS ──
const Empleados = {
  getAll: () => apiFetch('/empleados'),
  getById: (id) => apiFetch(`/empleados/${id}`),
  create: (body) => apiFetch('/empleados', { method: 'POST', body: JSON.stringify(body) }),
  update: (id, body) => apiFetch(`/empleados/${id}`, { method: 'PUT', body: JSON.stringify(body) }),
  delete: (id) => apiFetch(`/empleados/${id}`, { method: 'DELETE' }),
};

// ── SERVICIOS ──
const Servicios = {
  getAll: () => apiFetch('/servicios'),
  getById: (id) => apiFetch(`/servicios/${id}`),
  create: (body) => apiFetch('/servicios', { method: 'POST', body: JSON.stringify(body) }),
  update: (id, body) => apiFetch(`/servicios/${id}`, { method: 'PUT', body: JSON.stringify(body) }),
  delete: (id) => apiFetch(`/servicios/${id}`, { method: 'DELETE' }),
};

// ── TOAST ──
function showToast(msg, type = 'info') {
  const container = document.getElementById('toastContainer');
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.textContent = msg;
  container.appendChild(toast);
  setTimeout(() => toast.remove(), 3500);
}

// ── BADGE ESTADO ──
function badgeEstado(estado) {
  const map = {
    DISPONIBLE: 'badge-green', OCUPADA: 'badge-red',
    MANTENIMIENTO: 'badge-yellow', ACTIVA: 'badge-blue',
    CANCELADA: 'badge-red', COMPLETADA: 'badge-gray',
    PAGADO: 'badge-green', ANULADO: 'badge-red',
  };
  return `<span class="badge ${map[estado] || 'badge-gray'}">${estado}</span>`;
}

function formatDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('es-EC', { day: '2-digit', month: 'short', year: 'numeric' });
}