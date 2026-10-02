#!/usr/bin/env bash
# Reset rápido de laboratorio: reutiliza un stack Docker FIJO (project_id = dbbhacklab)
# y solo cambia el contenido de la base de datos para apuntar a las migraciones de <proyecto>,
# en vez de destruir y recrear 6-8 contenedores por cada cambio de repo (eso lo sigue haciendo
# montar-lab.sh, y queda como respaldo si este reset no verifica limpio).
#
# Cada paso se emite al dashboard (anillo de % + feed en vivo) con emitir.py, para que no
# quede ciego mientras corre en segundo plano.
#
# Uso: reset-lab.sh <proyecto>
# Salida: "RESET_OK <proyecto>" si quedó verificado, o "FALLBACK" si cayó al modo seguro
# (stack nuevo vía montar-lab.sh) porque el reset no pasó la verificación.
set -uo pipefail
OBJ="${1:?uso: reset-lab.sh <proyecto>}"
REPO="$HOME/Documents/Proyectos/$OBJ"
D="$(cd "$(dirname "$0")" && pwd)"
export PATH="$HOME/Library/Python/3.9/bin:$HOME/.local/bin:$PATH"
FIXED_PID="dbbhacklab"
TOTAL=5

em(){ python3 "$D/emitir.py" "$@" >/dev/null 2>&1; }
paso(){ # paso <n> <nombre> <detalle>
  em ataque "R$1" corriendo "$2" "Lab" "-" "-" "$3"
}
paso_ok(){ # paso_ok <n> <nombre> <detalle>
  em ataque "R$1" defendido "$2" "Lab" "-" "-" "$3"
}

em init "$OBJ" "stack fijo ($FIXED_PID)" "Reset rápido · verificando esquema"
em meta "$TOTAL"

[ -d "$REPO" ] || {
  echo "NO_REPO"
  em meta 1
  em ataque R0 hallazgo "Repo no existe" "Lab" "-" "-" "No existe $REPO — revisa el nombre del proyecto en el selector"
  em estado completado
  exit 1
}
[ -f "$REPO/supabase/config.toml" ] || {
  echo "NO_SUPABASE"
  em meta 1
  em ataque R0 hallazgo "Sin stack Supabase" "Lab" "-" "-" "$OBJ no tiene supabase/config.toml — el reset de lab solo aplica a repos con stack Supabase; para este repo usa LANZAR en nivel LOW/MID (análisis estático), no necesita laboratorio"
  em estado completado
  exit 2
}

caer_a_modo_seguro(){
  local n="$1" motivo="$2"
  em ataque "R$n" hallazgo "Reset no verificó limpio" "Lab" "-" "-" "$motivo — cayendo a modo seguro (stack nuevo)"
  echo "FALLBACK $motivo"
  [ -n "${TMPROOT:-}" ] && rm -rf "$TMPROOT" 2>/dev/null
  exec bash "$D/montar-lab.sh" "$OBJ"
}

# 1/5 — copia temporal del supabase/ del repo con project_id forzado al fijo del kit,
#       para que el stack Docker sea siempre el mismo sin importar qué repo se está probando.
paso 1 "Preparando config" "Forzando project_id → $FIXED_PID para reusar el stack fijo"
TMPROOT="$(mktemp -d)"
WORKDIR="$TMPROOT/proyecto"
mkdir -p "$WORKDIR/supabase"
cp -R "$REPO/supabase/." "$WORKDIR/supabase/"
sed -i '' -E "s/^([[:space:]]*project_id[[:space:]]*=[[:space:]]*).*/\1\"$FIXED_PID\"/" "$WORKDIR/supabase/config.toml" \
  || caer_a_modo_seguro 1 "no se pudo forzar project_id"
paso_ok 1 "Config lista" "project_id forzado a $FIXED_PID"

# 2/5 — los puertos locales de Supabase (54321/54322/...) son fijos sin importar el project_id,
#       así que no puede haber OTRO stack corriendo (ni el propio de una repo, ni otro fijo) a la vez.
paso 2 "Bajando labs previos" "Liberando puertos 54321/54322/3000 si hay otro stack arriba"
OTROS="$(docker ps -a --format '{{.Names}}' 2>/dev/null | sed -n 's/^supabase_[a-z_]*_//p' | sort -u | grep -vx "$FIXED_PID" || true)"
if [ -n "$OTROS" ]; then
  for ANT in $OTROS; do
    docker ps -a --format '{{.Names}}' | grep -- "_${ANT}\$" | xargs -r docker rm -f >/dev/null 2>&1
  done
fi
lsof -ti:3000 2>/dev/null | xargs -r kill -9 2>/dev/null || true
paso_ok 2 "Puertos libres" "$([ -n "$OTROS" ] && echo "Bajado: $OTROS" || echo "No había otro stack arriba")"

# 3/5 — levantar el stack fijo si no está arriba, o reusarlo si ya corre con ese project_id.
paso 3 "Levantando stack fijo" "docker compose del stack $FIXED_PID (o reusándolo si ya corre)"
if ! docker ps --format '{{.Names}}' | grep -qx "supabase_db_${FIXED_PID}"; then
  supabase start --workdir "$WORKDIR" >"/tmp/dbb-reset-$OBJ.log" 2>&1 \
    || caer_a_modo_seguro 3 "supabase start falló"
fi
paso_ok 3 "Stack arriba" "supabase_db_${FIXED_PID} corriendo"

# 4/5 — reset de datos contra las migraciones del repo objetivo (rápido: no toca contenedores).
#       Progreso real: 1 tick por migración .sql genuinamente aplicada (leído en vivo de la
#       salida de "supabase db reset", no inventado/repartido).
shopt -s nullglob
MIGS=("$REPO"/supabase/migrations/*.sql)
shopt -u nullglob
N_MIG="${#MIGS[@]}"
[ "$N_MIG" -gt 0 ] || N_MIG=1
TOTAL=$((4 + N_MIG))
em meta "$TOTAL"
em evento info "Cargando $N_MIG migraciones de $OBJ..."

: > "/tmp/dbb-reset-$OBJ.migprog"
( yes | supabase db reset --workdir "$WORKDIR" 2>&1 | tee -a "/tmp/dbb-reset-$OBJ.log" \
  | while IFS= read -r LINEA; do
      case "$LINEA" in
        "Applying migration "*)
          i=$(($(cat "/tmp/dbb-reset-$OBJ.migprog" 2>/dev/null || echo 0) + 1))
          echo "$i" > "/tmp/dbb-reset-$OBJ.migprog"
          NOMBRE="$(echo "$LINEA" | sed -E 's/^Applying migration ([^ ]+)\.sql.*/\1/')"
          em ataque "R4-$i" defendido "Migración $i/$N_MIG" "Lab" "-" "-" "$NOMBRE"
          ;;
      esac
    done )
# PIPESTATUS[0]=yes (puede salir 141 por SIGPIPE, normal); PIPESTATUS[1]=supabase db reset (el que importa);
# PIPESTATUS[2]=tee; PIPESTATUS[3]=el while de arriba.
if [ "${PIPESTATUS[1]}" -ne 0 ]; then
  caer_a_modo_seguro 4 "db reset falló (ver /tmp/dbb-reset-$OBJ.log)"
fi
APLICADAS="$(cat "/tmp/dbb-reset-$OBJ.migprog" 2>/dev/null || echo 0)"
rm -f "/tmp/dbb-reset-$OBJ.migprog"
paso_ok 4 "Migraciones cargadas" "$APLICADAS/$N_MIG migraciones aplicadas para $OBJ"

# 5/5 — verificación DURA: toda tabla "create table" de las migraciones del repo debe existir
#       de verdad en el esquema resultante. Si falta una sola, no se confía en el reset.
#       "supabase db reset" reinicia el contenedor de Postgres al final ("Restarting containers..."),
#       así que psql puede fallar por una carrera (el contenedor aún no acepta conexiones) y no por
#       un esquema realmente roto — se reintenta con espera antes de declarar fallo real.
paso 5 "Verificando esquema" "Comparando tablas esperadas vs. reales en supabase_db_${FIXED_PID}"
ESPERADAS="$(grep -ohiE 'create table[[:space:]]+(if not exists[[:space:]]+)?"?[a-zA-Z_][a-zA-Z0-9_]*"?' "$REPO"/supabase/migrations/*.sql 2>/dev/null \
  | sed -E 's/.*[[:space:]]"?([a-zA-Z_][a-zA-Z0-9_]*)"?$/\1/' | tr 'A-Z' 'a-z' | sort -u)"
REALES=""
for _ in $(seq 1 10); do
  REALES="$(docker exec -i "supabase_db_${FIXED_PID}" psql -U postgres -d postgres -qtA \
    -c "select tablename from pg_tables where schemaname='public';" 2>/dev/null | tr -d ' ' | sort -u)"
  [ -n "$REALES" ] && break
  sleep 1
done

if [ -z "$REALES" ]; then
  caer_a_modo_seguro 5 "no se pudo leer el esquema para verificar (postgres no respondió tras reintentos)"
fi
FALTAN="$(comm -23 <(echo "$ESPERADAS") <(echo "$REALES") 2>/dev/null | grep -v '^$' || true)"
if [ -n "$FALTAN" ]; then
  caer_a_modo_seguro 5 "faltan tablas: $(echo "$FALTAN" | tr '\n' ' ')"
fi
N_TABLAS="$(echo "$REALES" | wc -l | tr -d ' ')"
paso_ok 5 "Esquema verificado" "$N_TABLAS tablas, todas las esperadas presentes"

em estado completado
rm -rf "$TMPROOT"
echo "RESET_OK $OBJ"
