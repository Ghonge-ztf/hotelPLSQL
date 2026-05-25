import { Router } from 'express';
import { execCursor, execProc } from '../config/db.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

// GET /api/huespedes
router.get('/', asyncHandler(async (_req, res) => {
  const rows = await execCursor(`BEGIN :cur := pkg_huesped.listar_todos(); END;`);
  res.json(rows);
}));

// GET /api/huespedes/:id
router.get('/:id', asyncHandler(async (req, res) => {
  const rows = await execCursor(
    `BEGIN :cur := pkg_huesped.obtener(:id); END;`,
    { id: Number(req.params.id) }
  );
  if (!rows.length) return res.status(404).json({ error: 'Huésped no encontrado' });
  res.json(rows[0]);
}));

// POST /api/huespedes
router.post('/', asyncHandler(async (req, res) => {
  const { nombre, apellido, dni, email, telefono } = req.body;

  if (!nombre || !apellido || !dni)
    return res.status(400).json({ error: 'nombre, apellido y dni son requeridos' });

  await execProc(
    `BEGIN pkg_huesped.insertar(:nombre, :apellido, :dni, :email, :telefono); END;`,
    { nombre, apellido, dni, email: email ?? null, telefono: telefono ?? null }
  );
  res.status(201).json({ message: 'Huésped registrado correctamente' });
}));

// PUT /api/huespedes/:id
router.put('/:id', asyncHandler(async (req, res) => {
  const { nombre, apellido, email, telefono } = req.body;

  if (!nombre || !apellido)
    return res.status(400).json({ error: 'nombre y apellido son requeridos' });

  await execProc(
    `BEGIN pkg_huesped.actualizar(:id, :nombre, :apellido, :email, :telefono); END;`,
    { id: Number(req.params.id), nombre, apellido, email: email ?? null, telefono: telefono ?? null }
  );
  res.json({ message: 'Huésped actualizado correctamente' });
}));

// DELETE /api/huespedes/:id
router.delete('/:id', asyncHandler(async (req, res) => {
  await execProc(
    `BEGIN pkg_huesped.eliminar(:id); END;`,
    { id: Number(req.params.id) }
  );
  res.json({ message: 'Huésped eliminado correctamente' });
}));

export default router;