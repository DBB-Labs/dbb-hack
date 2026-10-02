# DBB-HACK — estándar de construcción

Herramienta de pentest interna de DBB (skill `/dbb-hack`, consola "DBB Labs" en
http://localhost:8899 vía `dashboard/servir.sh`). Reemplaza a [[strix]] (descartado por costo/proveedor:
techo de concurrencia de OpenRouter, ChatGPT Plus sin Codex). Corre gratis sobre Claude Code.
Es un producto que Felipe piensa ofrecer a clientes; kapa21 maneja dinero real y debe quedar
"blindado de verdad".

## Regla de cero falsos positivos

**Construir perfecto, sin errores.** Felipe rechaza con fuerza los falsos positivos y lo decorativo:
"si somos así con nosotros mismos, qué dirá un cliente".

- SIEMPRE probar/verificar un vector de verdad antes de darlo por bueno.
- Los gráficos del dashboard muestran datos REALES (docker stats/logs), nunca inventados.
- Nunca fallar en silencio en la UI (usa `window.onerror` visible).
- Ser honesto sobre alcance: un pentest ≠ cumplir ISO/leyes; lo planificado se marca como planificado,
  nunca como hecho.
- Nunca atacar producción; siempre laboratorio local aislado. Si el lab del objetivo no está montado,
  el resultado es "no probado" — nunca se inventa un resultado.

## Los 4 niveles

Ver `niveles.md` para el detalle completo. Resumen: **LOW** (CI/PR, estático, minutos) → **MID**
(+ revisión humana por playbooks, sigue sin tocar la app) → **FULL** (+ laboratorio aislado, ataques
en vivo, DAST) → **BAMF** (máximo blindaje para dinero real/regulado: ASVS L2/L3, WSTG, fuzzing,
flujos de dinero, supply-chain, mapa de cumplimiento CMF/Ley 21.719/ISO 27002).

El nivel se elige por el riesgo del objetivo: landing estática → LOW; Kapa21 (dinero real,
regulado) → BAMF.

## Pendientes (kapa21-v2, sesión 28.09.2026)

- [ ] Revisar y fusionar `DBB-Labs/kapa21-v2#346` (fix bucket) — decisión del equipo, PR sin fusionar.
- [ ] **A6**: rate-limit de fuerza bruta en el borde (Vercel Firewall + Supabase Auth prod).
- [ ] **B3** (overdraw): sembrar cuentas con saldo en el lab para ejecutarlo de verdad — hoy queda
  "no-probado" honesto porque no había cuentas sembradas, no porque se descartó.

Detalle de la sesión que originó estos pendientes en el Cerebro:
`raw/daily/2026-09-28/sesion-dbb-hack.md` y `raw/daily/2026-09-28/claude-code.md`.
