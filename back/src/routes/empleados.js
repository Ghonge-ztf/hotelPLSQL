import { Router } from 'express';
import { execCursor, execProc } from '../config/db.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const router = Router();

// GET /api/empleados
router.get('/', asyncHandler(async (_req, res) => {
  const rows = await execCursor(`BEGIN :cur := pkg_empleado.listar(); END;`);
  res.json(rows);
}));

// GET /api/empleados/:id
router.get('/:id', asyncHandler(async (req, res) => {
  const rows = await execCursor(
    `BEGIN :cur := pkg_empleado.obtener(:id); END;`,
    { id: Number(req.params.id) }
  );
  if (!rows.length) return res.status(404).json({ error: 'Empleado no encontrado' });
  res.json(rows[0]);
}));

// POST /api/empleados
router.post('/', asyncHandler(async (req, res) => {
  const { nombre, apellido, cargo, email, salario } = req.body;

  if (!nombre || !apellido || !cargo)
    return res.status(400).json({ error: 'nombre, apellido y cargo son requeridos' });

  await execProc(
    `BEGIN pkg_empleado.insertar(:nombre, :apellido, :cargo, :email, :salario); END;`,
    { nombre, apellido, cargo, email: email ?? null, salario: salario ?? null }
  );
  res.status(201).json({ message: 'Empleado creado correctamente' });
}));

// PUT /api/empleados/:id
router.put('/:id', asyncHandler(async (req, res) => {
  const { nombre, apellido, cargo, email, salario } = req.body;

  await execProc(
    `BEGIN pkg_empleado.actualizar(:id, :nombre, :apellido, :cargo, :email, :salario); END;`,
    { id: Number(req.params.id), nombre, apellido, cargo, email: email ?? null, salario: salario ?? null }
  );
  res.json({ message: 'Empleado actualizado correctamente' });
}));

// DELETE /api/empleados/:id
router.delete('/:id', asyncHandler(async (req, res) => {
  await execProc(
    `BEGIN pkg_empleado.eliminar(:id); END;`,
    { id: Number(req.params.id) }
  );
  res.json({ message: 'Empleado eliminado correctamente' });
}));

export default router;