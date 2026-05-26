import { Router } from 'express';
import { execCursor, execProc } from '../config/db.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

// GET /api/habitaciones
// router.get('/', asyncHandler(async (_req, res) => {
//   const rows = await execCursor(`BEGIN :cur := pkg_habitacion.listar_disponibles(); END;`);
//   res.json(rows);
// }));

// GET /api/habitaciones/disponibles
router.get('/', asyncHandler(async (_req, res) => {
  const rows = await execCursor(`BEGIN :cur := pkg_habitacion.listar_disponibles; END;`);
  res.json(rows);
}));

// GET /api/habitaciones/:id
// router.get('/:id', asyncHandler(async (req, res) => {
//   const rows = await execCursor(
//     `BEGIN :cur := pkg_habitacion.obtener(:id); END;`,
//     { id: Number(req.params.id) }
//   );
//   if (!rows.length) return res.status(404).json({ error: 'Habitación no encontrada' });
//   res.json(rows[0]);
// }));

// POST /api/habitaciones
router.post('/', asyncHandler(async (req, res) => {
  const { numero_habitacion, id_tipo, piso } = req.body;

  if (!numero_habitacion || !id_tipo || !piso)
    return res.status(400).json({ error: 'numero_habitacion, id_tipo y piso son requeridos' });

  await execProc(
    `BEGIN pkg_habitacion.insertar(:numero, :id_tipo, :piso); END;`,
    { numero: Number(numero_habitacion), id_tipo: Number(id_tipo), piso: Number(piso) }
  );
  res.status(201).json({ message: 'Habitación registrada correctamente' });
}));

// PATCH /api/habitaciones/:id/estado
router.patch('/:id/estado', asyncHandler(async (req, res) => {
  const { estado } = req.body;
  const estadosValidos = ['DISPONIBLE', 'OCUPADA', 'MANTENIMIENTO'];

  if (!estado || !estadosValidos.includes(estado.toUpperCase()))
    return res.status(400).json({ error: `estado debe ser uno de: ${estadosValidos.join(', ')}` });

  await execProc(
    `BEGIN pkg_habitacion.actualizar_estado(:id, :estado); END;`,
    { id: Number(req.params.id), estado: estado.toUpperCase() }
  );
  res.json({ message: `Estado actualizado a ${estado.toUpperCase()}` });
}));

// DELETE /api/habitaciones/:id
router.delete('/:id', asyncHandler(async (req, res) => {
  await execProc(
    `BEGIN pkg_habitacion.eliminar(:id); END;`,
    { id: Number(req.params.id) }
  );
  res.json({ message: 'Habitación eliminada correctamente' });
}));

export default router;