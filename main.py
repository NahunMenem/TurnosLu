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

class PagoTurnoIn(BaseModel):
    turno_id: int
    metodo: str
    monto: float

class HorarioIn(BaseModel):
    servicio_id: int
    dia_semana: int  # 0-6 (lunes=0)
    hora_inicio: time
    hora_fin: time

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

@app.get("/turnos")
def listar_turnos():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT
                    t.*,
                    s.nombre AS servicio,
                    COALESCE(SUM(p.monto), 0) AS total_pagado
                FROM turnos t
                JOIN servicios s ON s.id = t.servicio_id
                LEFT JOIN pagos_turno p ON p.turno_id = t.id
                GROUP BY t.id, s.nombre
                ORDER BY t.fecha, t.hora
            """)
            return cur.fetchall()



import os
import requests
from fastapi import HTTPException

WHATSAPP_TOKEN = os.getenv("WHATSAPP_TOKEN")
WHATSAPP_PHONE_ID = os.getenv("WHATSAPP_PHONE_ID")


# =====================================================
# 📞 NORMALIZAR TELÉFONO ARGENTINA
# =====================================================
def normalizar_telefono_ar(telefono: str) -> str:
    """
    Convierte cualquier formato argentino a:
    549XXXXXXXXXX
    """
    tel = telefono.strip()
    tel = tel.replace(" ", "").replace("-", "").replace("+", "")

    # ya correcto
    if tel.startswith("549") and len(tel) >= 12:
        return tel

    # ej: 543811234567 → 5493811234567
    if tel.startswith("54"):
        return "549" + tel[2:]

    # ej: 93811234567 → 5493811234567
    if tel.startswith("9"):
        return "54" + tel

    # ej: 3811234567 → 5493811234567
    return "549" + tel


# =====================================================
# 📩 ENVIAR WHATSAPP
# =====================================================
def enviar_whatsapp(telefono: str, mensaje: str):
    if not WHATSAPP_TOKEN or not WHATSAPP_PHONE_ID:
        print("❌ WhatsApp: token o phone_id faltante")
        return

    telefono = normalizar_telefono_ar(telefono)

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

    try:
        r = requests.post(url, json=payload, headers=headers, timeout=10)
        print("📩 WhatsApp status:", r.status_code)
        print("📩 WhatsApp response:", r.text)
    except Exception as e:
        print("❌ WhatsApp exception:", str(e))


# =====================================================
# 📅 RESERVAR TURNO
# =====================================================
@app.post("/turnos/reservar")
def reservar_turno(data: TurnoReservaIn):
    with get_conn() as conn:
        with conn.cursor() as cur:
            try:
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

                turno_id = cur.fetchone()["id"]
                conn.commit()

            except Exception:
                raise HTTPException(
                    status_code=400,
                    detail="Turno ya reservado",
                )

    # 📩 MENSAJE
    mensaje = (
        f"✅ *Turno confirmado*\n\n"
        f"👤 {data.cliente_nombre}\n"
        f"📅 {data.fecha.strftime('%d/%m/%Y')}\n"
        f"⏰ {data.hora.strftime('%H:%M')}\n\n"
        f"Gracias por reservar."
    )

    # WhatsApp NO bloqueante
    try:
        enviar_whatsapp(data.cliente_telefono, mensaje)
    except Exception:
        pass

    return {"ok": True, "turno_id": turno_id}

@app.post("/turnos/{turno_id}/confirmar")
def confirmar_turno(turno_id: int):
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE turnos SET confirmado = TRUE WHERE id = %s",
                (turno_id,)
            )

            if cur.rowcount == 0:
                raise HTTPException(404, "Turno no encontrado")

            conn.commit()

    return {"ok": True}

@app.post("/pagos")
def registrar_pago(data: PagoTurnoIn):
    if data.metodo not in ("efectivo", "tarjeta", "transferencia"):
        raise HTTPException(400, "Método inválido")

    with get_conn() as conn:
        with conn.cursor() as cur:
            # verificar turno
            cur.execute(
                "SELECT id FROM turnos WHERE id = %s",
                (data.turno_id,)
            )
            if not cur.fetchone():
                raise HTTPException(404, "Turno no existe")

            cur.execute("""
                INSERT INTO pagos_turno (turno_id, metodo, monto)
                VALUES (%s, %s, %s)
            """, (
                data.turno_id,
                data.metodo,
                data.monto
            ))

            conn.commit()

    return {"ok": True}




