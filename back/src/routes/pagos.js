import { Router } from 'express';
import { execCursor, execProc } from '../config/db.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

const METODOS_VALIDOS = ['EFECTIVO', 'TARJETA', 'TRANSFERENCIA'];

// GET /api/pagos
router.get('/', asyncHandler(async (_req, res) => {
  const rows = await execCursor(`BEGIN :cur := pkg_pago.listar_todos(); END;`);
  res.json(rows);
}));

// GET /api/pagos/reserva/:idReserva
router.get('/reserva/:idReserva', asyncHandler(async (req, res) => {
  const rows = await execCursor(
    `BEGIN :cur := pkg_pago.obtener_por_reserva(:id); END;`,
    { id: Number(req.params.idReserva) }
  );
  if (!rows.length) return res.status(404).json({ error: 'No hay pago registrado para esta reserva' });
  res.json(rows[0]);
}));

// GET /api/pagos/:id
router.get('/:id', asyncHandler(async (req, res) => {
  const rows = await execCursor(
    `BEGIN :cur := pkg_pago.obtener(:id); END;`,
    { id: Number(req.params.id) }
  );
  if (!rows.length) return res.status(404).json({ error: 'Pago no encontrado' });
  res.json(rows[0]);
}));

// POST /api/pagos
router.post('/', asyncHandler(async (req, res) => {
  const { id_reserva, metodo_pago } = req.body;

  if (!id_reserva || !metodo_pago)
    return res.status(400).json({ error: 'id_reserva y metodo_pago son requeridos' });

  if (!METODOS_VALIDOS.includes(metodo_pago.toUpperCase()))
    return res.status(400).json({ error: `metodo_pago debe ser: ${METODOS_VALIDOS.join(', ')}` });

  await execProc(
    `BEGIN pkg_pago.registrar(:id_reserva, :metodo); END;`,
    { id_reserva: Number(id_reserva), metodo: metodo_pago.toUpperCase() }
  );
  res.status(201).json({ message: 'Pago registrado correctamente' });
}));

// PATCH /api/pagos/:id/anular
router.patch('/:id/anular', asyncHandler(async (req, res) => {
  await execProc(
    `BEGIN pkg_pago.anular(:id); END;`,
    { id: Number(req.params.id) }
  );
  res.json({ message: 'Pago anulado correctamente' });
}));

export default router;