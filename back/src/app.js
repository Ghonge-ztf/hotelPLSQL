import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';
import { initPool } from './config/db.js';

import huespedesRouter        from './routes/huespedes.js';
import habitacionesRouter     from './routes/habitaciones.js';
import reservasRouter         from './routes/reservas.js';
import pagosRouter            from './routes/pagos.js';
import empleadosRouter        from './routes/empleados.js';
import serviciosRouter        from './routes/servicios.js';
import reservaServiciosRouter from './routes/reservaServicios.js';

const app  = express();
const PORT = process.env.PORT ?? 3000;
const __dirname = path.dirname(fileURLToPath(import.meta.url));

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../../front')));

app.use('/api/huespedes',         huespedesRouter);
app.use('/api/habitaciones',      habitacionesRouter);
app.use('/api/reservas',          reservasRouter);
app.use('/api/pagos',             pagosRouter);
app.use('/api/empleados',         empleadosRouter);
app.use('/api/servicios',         serviciosRouter);
app.use('/api/reserva-servicios', reservaServiciosRouter);

app.get('/api/health', (_req, res) =>
  res.json({ status: 'OK', timestamp: new Date().toISOString() })
);

await initPool();
app.listen(PORT, () =>
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`)
);