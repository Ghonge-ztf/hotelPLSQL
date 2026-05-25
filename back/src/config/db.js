import oracledb from 'oracledb';
import 'dotenv/config';

oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;

let pool;

export const initPool = async () => {
  pool = await oracledb.createPool({
    user:          process.env.DB_USER,
    password:      process.env.DB_PASSWORD,
    connectString: process.env.DB_CONNECT_STRING,
    poolMin:       2,
    poolMax:       10,
    poolIncrement: 1,
  });
  console.log('Pool de conexiones Oracle creado');
};

export const getConnection = () => pool.getConnection();


export const execCursor = async (sql, binds = {}) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(sql, {
      cur: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR },
      ...binds,
    });
    const rows = await result.outBinds.cur.getRows();
    await result.outBinds.cur.close();
    return rows;
  } finally {
    await conn?.close();
  }
};



export const execProc = async (sql, binds = {}) => {
  let conn;
  try {
    conn = await getConnection();
    await conn.execute(sql, binds);
  } finally {
    await conn?.close();
  }
};