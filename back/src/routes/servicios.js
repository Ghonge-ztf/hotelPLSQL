import { Router } from 'express';
import { execCursor, execProc } from '../config/db.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

// GET /api/servicios
router.get('/', asyncHandler(async (_req, res) => {
  const rows = await execCursor(`BEGIN :cur := pkg_servicio.listar(); END;`);
  res.json(rows);
}));

// GET /api/servicios/:id
router.get('/:id', asyncHandler(async (req, res) => {
  const rows = await execCursor(
    `BEGIN :cur := pkg_servicio.obtener(:id); END;`,
    { id: Number(req.params.id) }
  );
  if (!rows.length) return res.status(404).json({ error: 'Servicio no encontrado' });
  res.json(rows[0]);
}));

// POST /api/servicios
router.post('/', asyncHandler(async (req, res) => {
  const { nombre, descripcion, precio } = req.body;

  if (!nombre || precio === undefined)
    return res.status(400).json({ error: 'nombre y precio son requeridos' });

  await execProc(
    `BEGIN pkg_servicio.insertar(:nombre, :descripcion, :precio); END;`,
    { nombre, descripcion: descripcion ?? null, precio: Number(precio) }
  );
  res.status(201).json({ message: 'Servicio creado correctamente' });
}));

// PUT /api/servicios/:id
router.put('/:id', asyncHandler(async (req, res) => {
  const { nombre, descripcion, precio } = req.body;

  await execProc(
    `BEGIN pkg_servicio.actualizar(:id, :nombre, :descripcion, :precio); END;`,
    { id: Number(req.params.id), nombre, descripcion: descripcion ?? null, precio: Number(precio) }
  );
  res.json({ message: 'Servicio actualizado correctamente' });
}));

// DELETE /api/servicios/:id
router.delete('/:id', asyncHandler(async (req, res) => {
  await execProc(
    `BEGIN pkg_servicio.eliminar(:id); END;`,
    { id: Number(req.params.id) }
  );
  res.json({ message: 'Servicio eliminado correctamente' });
}));

export default router;