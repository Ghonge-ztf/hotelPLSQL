import { Router } from 'express';
import { execCursor, execProc } from '../config/db.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

// GET /api/reservas — todas
router.get('/', asyncHandler(async (_req, res) => {
  const rows = await execCursor(`BEGIN :cur := pkg_reserva.listar_todas(); END;`);
  res.json(rows);
}));

// GET /api/reservas/activas
router.get('/activas', asyncHandler(async (_req, res) => {
  const rows = await execCursor(`BEGIN :cur := pkg_reserva.listar_activas(); END;`);
  res.json(rows);
}));

// GET /api/reservas/huesped/:idHuesped  ← DEBE IR ANTES DE /:id
router.get('/huesped/:idHuesped', asyncHandler(async (req, res) => {
  const rows = await execCursor(
    `BEGIN :cur := pkg_reserva.listar_por_huesped(:id_huesped); END;`,
    { id_huesped: Number(req.params.idHuesped) }
  );
  res.json(rows);
}));

// GET /api/reservas/:id
router.get('/:id', asyncHandler(async (req, res) => {
  const rows = await execCursor(
    `BEGIN :cur := pkg_reserva.obtener(:id); END;`,
    { id: Number(req.params.id) }
  );
  if (!rows.length) return res.status(404).json({ error: 'Reserva no encontrada' });
  res.json(rows[0]);
}));

// POST /api/reservas
router.post('/', asyncHandler(async (req, res) => {
  const { id_huesped, id_habitacion, id_empleado, fecha_entrada, fecha_salida } = req.body;
  if (!id_huesped || !id_habitacion || !fecha_entrada || !fecha_salida)
    return res.status(400).json({ error: 'id_huesped, id_habitacion, fecha_entrada y fecha_salida son requeridos' });
  if (new Date(fecha_salida) <= new Date(fecha_entrada))
    return res.status(400).json({ error: 'fecha_salida debe ser posterior a fecha_entrada' });

  await execProc(
    `BEGIN pkg_reserva.crear(:id_huesped, :id_habitacion, :id_empleado, :fecha_entrada, :fecha_salida); END;`,
    {
      id_huesped:     Number(id_huesped),
      id_habitacion:  Number(id_habitacion),
      id_empleado:    id_empleado ? Number(id_empleado) : null,
      fecha_entrada:  new Date(fecha_entrada),
      fecha_salida:   new Date(fecha_salida),
    }
  );
  res.status(201).json({ message: 'Reserva creada correctamente' });
}));

// PATCH /api/reservas/:id/activar  ← NUEVO (Check-in)
router.patch('/:id/activar', asyncHandler(async (req, res) => {
  await execProc(
    `BEGIN pkg_reserva.activar(:id); END;`,
    { id: Number(req.params.id) }
  );
  res.json({ message: 'Reserva activada. Habitación marcada como OCUPADA.' });
}));

// PATCH /api/reservas/:id/cancelar
router.patch('/:id/cancelar', asyncHandler(async (req, res) => {
  await execProc(
    `BEGIN pkg_reserva.cancelar(:id); END;`,
    { id: Number(req.params.id) }
  );
  res.json({ message: 'Reserva cancelada correctamente' });
}));

// PATCH /api/reservas/:id/completar
router.patch('/:id/completar', asyncHandler(async (req, res) => {
  await execProc(
    `BEGIN pkg_reserva.completar(:id); END;`,
    { id: Number(req.params.id) }
  );
  res.json({ message: 'Reserva completada. Habitación liberada.' });
}));

// DELETE /api/reservas/:id
router.delete('/:id', asyncHandler(async (req, res) => {
  await execProc(
    `BEGIN pkg_reserva.eliminar(:id); END;`,
    { id: Number(req.params.id) }
  );
  res.json({ message: 'Reserva eliminada correctamente' });
}));

export default router;