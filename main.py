import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import date, time, datetime, timedelta

# =====================================================
# CONFIG
# =====================================================

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL no definida")

app = FastAPI(title="Sistema de Turnos")

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # desarrollo
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================================================
# DB CONNECTION
# =====================================================

def get_conn():
    return psycopg2.connect(
        DATABASE_URL,
        sslmode="require",
        cursor_factory=RealDictCursor
    )

# =====================================================
# MODELOS
# =====================================================
class TurnoReservaIn(BaseModel):
    servicio_id: int
    fecha: date
    hora: time
    cliente_nombre: str
    cliente_telefono: str

class ServicioIn(BaseModel):
    nombre: str
    descripcion: str | None = None
    duracion_minutos: int

class HorarioIn(BaseModel):
    servicio_id: int
    dia_semana: int  # 0-6 (lunes=0)
    hora_inicio: time
    hora_fin: time

class TurnoReservaIn(BaseModel):
    servicio_id: int
    fecha: date
    hora: time

# =====================================================
# SERVICIOS
# =====================================================

@app.get("/servicios")
def listar_servicios():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM servicios WHERE activo = TRUE ORDER BY id")
            return cur.fetchall()

@app.post("/servicios")
def crear_servicio(data: ServicioIn):
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO servicios (nombre, descripcion, duracion_minutos)
                VALUES (%s, %s, %s)
                RETURNING *
            """, (data.nombre, data.descripcion, data.duracion_minutos))
            conn.commit()
            return cur.fetchone()

# =====================================================
# HORARIOS
# =====================================================

@app.get("/servicios/{servicio_id}/horarios")
def horarios_servicio(servicio_id: int):
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT * FROM horarios_servicio
                WHERE servicio_id = %s
                ORDER BY dia_semana, hora_inicio
            """, (servicio_id,))
            return cur.fetchall()

@app.post("/horarios")
def crear_horario(data: HorarioIn):
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO horarios_servicio
                (servicio_id, dia_semana, hora_inicio, hora_fin)
                VALUES (%s, %s, %s, %s)
                RETURNING *
            """, (
                data.servicio_id,
                data.dia_semana,
                data.hora_inicio,
                data.hora_fin
            ))
            conn.commit()
            return cur.fetchone()

# =====================================================
# DISPONIBILIDAD
# =====================================================

@app.get("/disponibilidad")
def disponibilidad(servicio_id: int, fecha: date):
    with get_conn() as conn:
        with conn.cursor() as cur:

            cur.execute("SELECT * FROM servicios WHERE id = %s", (servicio_id,))
            servicio = cur.fetchone()
            if not servicio:
                raise HTTPException(404, "Servicio no encontrado")

            duracion = servicio["duracion_minutos"]
            dia_semana = fecha.weekday()

            cur.execute("""
                SELECT * FROM horarios_servicio
                WHERE servicio_id = %s AND dia_semana = %s
            """, (servicio_id, dia_semana))
            horarios = cur.fetchall()

            cur.execute("""
                SELECT hora FROM turnos
                WHERE servicio_id = %s
                AND fecha = %s
                AND estado = 'reservado'
            """, (servicio_id, fecha))

            ocupados = {r["hora"] for r in cur.fetchall()}
            disponibles = []

            for h in horarios:
                inicio = datetime.combine(fecha, h["hora_inicio"])
                fin = datetime.combine(fecha, h["hora_fin"])

                while inicio + timedelta(minutes=duracion) <= fin:
                    hora_turno = inicio.time()
                    if hora_turno not in ocupados:
                        disponibles.append(hora_turno.strftime("%H:%M"))
                    inicio += timedelta(minutes=duracion)

            return disponibles

# =====================================================
# TURNOS
# =====================================================

from fastapi import HTTPException

@app.post("/turnos/reservar")
def reservar_turno(data: TurnoReservaIn):
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO turnos
                    (servicio_id, fecha, hora, estado, cliente_nombre, cliente_telefono)
                    VALUES (%s, %s, %s, 'reservado', %s, %s)
                    RETURNING id
                """, (
                    data.servicio_id,
                    data.fecha,
                    data.hora,
                    data.cliente_nombre,
                    data.cliente_telefono,
                ))
                turno_id = cur.fetchone()[0]
                conn.commit()
                return {"ok": True, "turno_id": turno_id}
    except Exception:
        # Si ya tenés unique constraint (servicio_id, fecha, hora)
        raise HTTPException(status_code=400, detail="Turno ya reservado")


@app.get("/turnos")
def listar_turnos():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT t.*, s.nombre AS servicio
                FROM turnos t
                JOIN servicios s ON s.id = t.servicio_id
                ORDER BY fecha, hora
            """)
            return cur.fetchall()


from fastapi import HTTPException
from whatsapp import enviar_whatsapp

@app.post("/turnos/reservar")
def reservar_turno(data: TurnoReservaIn):
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO turnos
                    (servicio_id, fecha, hora, estado, cliente_nombre, cliente_telefono)
                    VALUES (%s, %s, %s, 'reservado', %s, %s)
                    RETURNING id
                """, (
                    data.servicio_id,
                    data.fecha,
                    data.hora,
                    data.cliente_nombre,
                    data.cliente_telefono,
                ))

                turno_id = cur.fetchone()[0]
                conn.commit()

        # 📩 MENSAJE WHATSAPP
        mensaje = (
            f"✅ *Turno confirmado*\n\n"
            f"👤 {data.cliente_nombre}\n"
            f"📅 {data.fecha.strftime('%d/%m/%Y')}\n"
            f"⏰ {data.hora.strftime('%H:%M')}\n\n"
            f"Gracias por reservar."
        )

        enviar_whatsapp(
            telefono=data.cliente_telefono,
            mensaje=mensaje,
        )

        return {"ok": True, "turno_id": turno_id}

    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail="Error al reservar turno",
        )

import os
import requests

WHATSAPP_TOKEN = os.getenv("WHATSAPP_TOKEN")
WHATSAPP_PHONE_ID = os.getenv("WHATSAPP_PHONE_ID")

def enviar_whatsapp(telefono: str, mensaje: str):
    url = f"https://graph.facebook.com/v18.0/{WHATSAPP_PHONE_ID}/messages"

    headers = {
        "Authorization": f"Bearer {WHATSAPP_TOKEN}",
        "Content-Type": "application/json",
    }

    payload = {
        "messaging_product": "whatsapp",
        "to": telefono,
        "type": "text",
        "text": {"body": mensaje},
    }

    r = requests.post(url, json=payload, headers=headers)
    return r.status_code, r.text


