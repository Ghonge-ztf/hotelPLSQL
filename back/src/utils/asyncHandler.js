/**
 * Wrapper para evitar try/catch repetitivo en cada route handler.
 * Captura errores de Oracle y los mapea a respuestas HTTP.
 */
export const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch((err) => {
    const msg = err.message ?? 'Error interno del servidor';

    if (msg.includes('20001')) return res.status(404).json({ error: 'Empleado no encontrado' });
    if (msg.includes('20002')) return res.status(404).json({ error: 'Servicio no encontrado' });
    if (msg.includes('20003')) return res.status(404).json({ error: 'Registro de reserva-servicio no encontrado' });

    console.error('Oracle Error:', msg);
    res.status(500).json({ error: msg });
  });