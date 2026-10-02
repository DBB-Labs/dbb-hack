---
name: strix
description: >
  Corre un pentest autónomo de Strix sobre el repositorio actual con un solo comando,
  sin entrar a la app ni recordar flags. Prepara una copia SIN secretos, lanza Strix
  con GLM-5.3 vía OpenRouter dentro de Docker, con tope de presupuesto y red aislada,
  y deja el informe fuera del proyecto. Usar cuando el usuario diga "/strix",
  "escanea la seguridad de este repo", "corre el pentest", "revisa vulnerabilidades".
---

# /strix — pentest de un repo con un comando

Objetivo: que Felipe escriba `/strix` en VS Code y Strix audite el repo actual,
sin pasos manuales y sin exponer secretos. Strix ya está instalado
(`~/.local/bin/strix`, v1.6.2) y la imagen del sandbox ya está en Docker.

**Cinco fases, en orden. Los frenos de la fase 0 NO se saltan.**

Argumentos que Felipe puede pasar tras `/strix`:
- una ruta → escanear ese repo en vez del actual.
- `deep` o `standard` → cambia el modo (por defecto `quick`).
- `--budget N` → cambia el tope en USD (por defecto 5).
- una URL viva (`http://localhost:3000`) → la agrega como segundo target.

---

## Fase 0 — Frenos (verificar antes de tocar nada)

```bash
REPO="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
echo "repo: $REPO"
```

1. **Docker corriendo.** Si `docker info` falla, `open -a Docker` y esperar hasta 60s.
   Si no arranca, parar y avisar.
2. **Proveedor configurado.** `STRIX_LLM` debe empezar con `openrouter/` y `LLM_API_KEY`
   debe empezar con `sk-or-`. Si no, parar: falta configurar OpenRouter en `~/.zshrc`.
   **Nunca** uses una API key de pago de OpenAI ni la escribas en ningún archivo del repo.
3. **La imagen del sandbox existe.** `docker image inspect "$STRIX_IMAGE"` debe pasar.
4. **Es un repo con código, no un estático ni un corpus.** Si es solo HTML/markdown,
   avisar que Strix no rinde ahí (ver la nota del cerebro sobre dónde sí sirve).

```bash
docker info >/dev/null 2>&1 || { open -a Docker; for i in $(seq 1 12); do sleep 5; docker info >/dev/null 2>&1 && break; done; }
docker info >/dev/null 2>&1 || { echo "Docker no arranca"; exit 1; }
# proveedor válido: ChatGPT (suscripción, sin techo de OpenRouter) u OpenRouter (con key)
case "$STRIX_LLM" in
  chatgpt/*) strix auth status 2>&1 | grep -qi 'signed in' || { echo "ChatGPT no conectado: strix auth login chatgpt"; exit 1; } ;;
  openrouter/*) [[ "$LLM_API_KEY" == sk-or-* ]] || { echo "Falta LLM_API_KEY de OpenRouter"; exit 1; } ;;
  *) echo "STRIX_LLM debe ser chatgpt/* u openrouter/*"; exit 1 ;;
esac
docker image inspect "$STRIX_IMAGE" >/dev/null 2>&1 || { echo "Falta la imagen de Strix"; exit 1; }
# la red aislada debe existir (si se limpió Docker, recrearla)
[ -n "$STRIX_DOCKER_SANDBOX_NETWORK" ] && { docker network inspect "$STRIX_DOCKER_SANDBOX_NETWORK" >/dev/null 2>&1 || docker network create "$STRIX_DOCKER_SANDBOX_NETWORK"; }
```

## Fase 1 — Copia limpia sin secretos (NO se escanea el repo real)

Strix monta la carpeta **con escritura** y el modelo lee todo lo que el agente abra,
`.env.local` incluido, y lo manda a OpenRouter sin redacción. Por eso **jamás** se
escanea el árbol de trabajo directo: se escanea una copia del commit actual, sin
secretos ni artefactos que soplen las respuestas.

```bash
WORK="$(mktemp -d /tmp/strix-XXXX)"; APP="$WORK/app"; mkdir -p "$APP"
git -C "$REPO" archive HEAD | tar -x -C "$APP"     # solo lo versionado en HEAD
# fuera todo lo sensible o ruidoso
# borrado seguro (find/rm sin depender de globs de zsh, que abortan si no hay match)
rm -rf "$APP/.git" "$APP/node_modules" "$APP/dist" "$APP/build" \
       "$APP/.claude" "$APP/.context" "$APP/.mcp.json" "$APP/forja" "$APP/Recursos" 2>/dev/null
# secretos: por nombre, con find (nunca al modelo)
find "$APP" -type f \( -name '.env' -o \( -name '.env.*' ! -name '.env.example' \) \
       -o -name '*.pem' -o -name '*.key' \) -delete 2>/dev/null
# artefactos que "soplan" hallazgos ya conocidos
find "$APP" -type d \( -iname '*auditoria*' -o -iname '*audit*' \) -exec rm -rf {} + 2>/dev/null
find "$APP" -type f \( -iname '*AUDIT*' -o -iname '*REVIEW*' -o -iname '*PROBLEMAS*' -o -iname '*MEJORAS*' \) -delete 2>/dev/null

# --- COPIA MAGRA (opcional, para ahorrar): solo código, fuera lo que no es código ---
# Se salta si Felipe pasó 'completa'. Reduce el costo de reconocimiento.
if [ "${LEAN:-1}" = "1" ]; then
  for d in docs Docs documentacion tests test __tests__ e2e cypress public static assets Logo Icon .github; do
    rm -rf "$APP/$d" 2>/dev/null
  done
  find "$APP" -type f \( -name '*.md' -o -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \
     -o -name '*.gif' -o -name '*.svg' -o -name '*.ico' -o -name '*.pdf' \) -delete 2>/dev/null
fi

# comprobar que no quedó ningún .env real
find "$APP" -maxdepth 3 -name '.env*' ! -name '.env.example' -print
echo "copia lista en: $APP  ($(find "$APP" -type f | wc -l | tr -d ' ') archivos)"
```

Si `git archive` falla (no es repo git), copiar con `rsync` excluyendo lo mismo
y avisar que se copió el árbol de trabajo, no un commit.

## Fase 2 — Correr Strix

```bash
MODE="${MODE:-quick}"; BUDGET="${BUDGET:-5}"
cd "$WORK"                                          # strix_runs/ queda aquí, NO en el repo
strix -n -t "$APP" ${URL:+-t "$URL"} \
  --scan-mode "$MODE" \
  --max-budget "$BUDGET"
echo "exit=$?"                                       # 0 limpio · 2 hay hallazgos · 1 error
```

- `-n` siempre (sin TUI, sale al terminar).
- `--max-budget` es el freno de gasto real de OpenRouter.
- Un `-t` con URL solo si Felipe la pasó y es local/autorizada.

## Fase 3 — Leer resultados y ARCHIVAR (permanente)

El run temporal queda en `"$WORK"/strix_runs/<run>/`. Revisar SIEMPRE `run.json`
antes de declarar algo limpio: un exit 0 solo cubre lo analizado.

```bash
RUN=$(ls -td "$WORK"/strix_runs/*/ | head -1)
echo "run: $RUN"
python3 -c "import json,sys; d=json.load(open('$RUN/run.json')); print('status:',d.get('status'),'| costo USD:',d.get('llm_usage',{}).get('cost'))" 2>/dev/null
ls "$RUN"/vulnerabilities/ 2>/dev/null
sed -n '1,60p' "$RUN/penetration_test_report.md" 2>/dev/null
```

Artefactos: `penetration_test_report.md`, `vulnerabilities/*.md`, `vulnerabilities.json`,
`findings.sarif`, `run.json`, `coverage.json`.

**Archivado obligatorio** — la data SIEMPRE queda visible en `~/Documents/STRIX ANALISIS`,
con esta estructura, para todo proyecto (existente o nuevo) y cada corrida:

```
~/Documents/STRIX ANALISIS/STRIX ANALISIS <año>/STRIX ANALISIS <proyecto>/STRIX ANALISIS <NN-Mes>/<fecha_hora_runid>/
```

```bash
PROJ_NAME="$(basename "$REPO")"
YEAR="$(date +%Y)"; MNUM="$(date +%m)"
case "$MNUM" in                          # case: idéntico en zsh y bash (los arrays NO lo son)
  01) MES=Enero;;   02) MES=Febrero;; 03) MES=Marzo;;      04) MES=Abril;;
  05) MES=Mayo;;    06) MES=Junio;;   07) MES=Julio;;      08) MES=Agosto;;
  09) MES=Septiembre;; 10) MES=Octubre;; 11) MES=Noviembre;; 12) MES=Diciembre;;
esac
STAMP="$(date +%Y-%m-%d_%H%M)_$(basename "$RUN")"
DEST="$HOME/Documents/STRIX ANALISIS/STRIX ANALISIS $YEAR/STRIX ANALISIS $PROJ_NAME/STRIX ANALISIS ${MNUM}-${MES}/$STAMP"
mkdir -p "$DEST"
cp -R "$RUN"/. "$DEST"/                 # informe, vulnerabilidades, sarif, run.json, coverage.json
echo "archivado en: $DEST"
```

> La API key NUNCA se copia aquí: solo se archivan los artefactos del run, no `$WORK/app`.

## Fase 4 — Informe a Felipe (máx. 10 líneas)

1. Veredicto: nº de hallazgos por severidad, o "sin hallazgos en lo analizado".
2. Costo real vs tope (`run.json`).
3. Ruta del informe completo y del SARIF.
4. Recordatorio si el exit fue 0 pero el status del run no fue completo.
5. **Siempre** dar la ruta de `$DEST` en `~/Documents/STRIX ANALISIS` (ahí queda la data).
6. Ofrecer remediar con `fix-security-vulnerabilities-with-strix`.

## Fase 5 — Limpiar el temporal (la data permanente ya está en Documents)

Como la Fase 3 ya archivó todo en `~/Documents/STRIX ANALISIS`, el temporal `$WORK`
(que contiene la copia del código) se puede borrar sin perder resultados.

```bash
rm -rf "$WORK"     # solo DESPUÉS de confirmar que $DEST tiene los artefactos
```

Nunca dejar `$WORK` con la copia del código olvidada en `/tmp` a largo plazo.

---

## Frenos permanentes (nunca, aunque lo pidan sin pensar)

1. **Nunca escanear producción** ni con credenciales reales.
2. **Nunca el árbol de trabajo con `.env`**: siempre la copia limpia de la fase 1.
3. **Nunca subir el código a Strix Cloud** desde este skill: es 100% local.
4. **Nunca escribir la API key** en el repo, en `strix_runs/`, ni en un commit.
5. `strix_runs/` guarda la conversación con lo que el agente leyó: tratarlo como sensible.
