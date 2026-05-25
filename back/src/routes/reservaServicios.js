import { Router } from 'express';
import { execCursor, execProc } from '../config/db.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

// GET /api/reserva-servicios/reserva/:idReserva
router.get('/reserva/:idReserva', asyncHandler(async (req, res) => {
  const rows = await execCursor(
    `BEGIN :cur := pkg_reserva_servicio.listar_por_reserva(:id); END;`,
    { id: Number(req.params.idReserva) }
  );
  res.json(rows);
}));

// GET /api/reserva-servicios/:id
router.get('/:id', asyncHandler(async (req, res) => {
  const rows = await execCursor(
    `BEGIN :cur := pkg_reserva_servicio.obtener(:id); END;`,
    { id: Number(req.params.id) }
  );
  if (!rows.length) return res.status(404).json({ error: 'Registro no encontrado' });
  res.json(rows[0]);
}));

// POST /api/reserva-servicios
router.post('/', asyncHandler(async (req, res) => {
  const { id_reserva, id_servicio, cantidad, fecha_uso } = req.body;

  if (!id_reserva || !id_servicio)
    return res.status(400).json({ error: 'id_reserva e id_servicio son requeridos' });

  await execProc(
    `BEGIN pkg_reserva_servicio.insertar(:id_reserva, :id_servicio, :cantidad, :fecha_uso); END;`,
    {
      id_reserva:  Number(id_reserva),
      id_servicio: Number(id_servicio),
      cantidad:    Number(cantidad ?? 1),
      fecha_uso:   fecha_uso ? new Date(fecha_uso) : null,
    }
  );
  res.status(201).json({ message: 'Servicio agregado a la reserva correctamente' });
}));

// PUT /api/reserva-servicios/:id
router.put('/:id', asyncHandler(async (req, res) => {
  const { cantidad, fecha_uso } = req.body;

  await execProc(
    `BEGIN pkg_reserva_servicio.actualizar(:id, :cantidad, :fecha_uso); END;`,
    {
      id:        Number(req.params.id),
      cantidad:  Number(cantidad),
      fecha_uso: fecha_uso ? new Date(fecha_uso) : null,
    }
  );
  res.json({ message: 'Registro actualizado correctamente' });
}));

// DELETE /api/reserva-servicios/:id
router.delete('/:id', asyncHandler(async (req, res) => {
  await execProc(
    `BEGIN pkg_reserva_servicio.eliminar(:id); END;`,
    { id: Number(req.params.id) }
  );
  res.json({ message: 'Registro eliminado correctamente' });
}));

export default router;